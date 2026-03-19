import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/bff_api_service.dart';
import '../theme/app_theme.dart';
import 'create_password_screen.dart';

class SignupOtpScreen extends StatefulWidget {
  final String mobileNumber;
  final String customerId;

  const SignupOtpScreen({
    super.key,
    required this.mobileNumber,
    required this.customerId,
  });

  @override
  State<SignupOtpScreen> createState() => _SignupOtpScreenState();
}

class _SignupOtpScreenState extends State<SignupOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  int _timerSeconds = 30;
  Timer? _timer;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _timerSeconds = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() {
          _timerSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await BffApiService.verifySignupOtp(
        mobileNumber: widget.mobileNumber,
        otp: otp,
      );

      if (!mounted) return;

      if (response['verified'] == true) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CreatePasswordScreen(
              customerId: widget.customerId,
            ),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response['message'] as String? ?? 'Invalid OTP';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('Verify OTP'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryBlue,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacing32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge * 2),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sms_outlined, color: AppTheme.primaryBlue, size: 64),
                  const SizedBox(height: AppTheme.spacing24),
                  const Text(
                    'OTP Verification',
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the 6-digit code sent to\n+91 ${widget.mobileNumber}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 14),
                  ),
                  const SizedBox(height: AppTheme.spacing32),
                  
                  // OTP Input Fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 45,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: AppTheme.backgroundGrey,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                            if (_controllers.every((c) => c.text.isNotEmpty)) {
                              _handleVerify();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  
                  const SizedBox(height: AppTheme.spacing32),
                  
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryRed),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.primaryRed, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                  ],
                  
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleVerify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Verify OTP', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacing24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Didn\'t receive code? ', style: TextStyle(color: AppTheme.textGrey)),
                      TextButton(
                        onPressed: _timerSeconds == 0 ? _startTimer : null,
                        child: Text(
                          _timerSeconds > 0 ? 'Resend in ${_timerSeconds}s' : 'Resend OTP',
                          style: TextStyle(
                            color: _timerSeconds > 0 ? AppTheme.textGrey : AppTheme.primaryRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
