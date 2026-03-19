import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/bff_api_service.dart';
import '../theme/app_theme.dart';
import 'signup_otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _dobController = TextEditingController();
  
  DateTime? _selectedDate;
  bool _isEmailUnique = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _handleContinue() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final response = await BffApiService.signup(
          name: _nameController.text,
          email: _emailController.text,
          mobileNumber: _mobileController.text,
          dob: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        );

        if (!mounted) return;

        if (response['customerId'] != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SignupOtpScreen(
                mobileNumber: _mobileController.text,
                customerId: response['customerId'] as String,
              ),
            ),
          );
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = response['message'] as String? ?? 'Signup failed';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.toString().replaceFirst('Exception: ', '');
            if (_errorMessage!.toLowerCase().contains('email')) {
              _isEmailUnique = false;
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('Sign Up'),
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
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge * 2),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Provide your details to get started',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: AppTheme.spacing32),

                    // Full Name
                    _buildLabel('Full Name'),
                    TextFormField(
                      controller: _nameController,
                      validator: (value) => (value == null || value.isEmpty) ? 'Please enter your name' : null,
                      decoration: _buildInputDecoration('Enter your full name'),
                    ),
                    const SizedBox(height: AppTheme.spacing20),

                    // Email
                    _buildLabel('Email Address'),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setState(() => _isEmailUnique = true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Invalid email format';
                        if (!_isEmailUnique) return 'Email is already registered';
                        return null;
                      },
                      decoration: _buildInputDecoration('Enter your email'),
                    ),
                    const SizedBox(height: AppTheme.spacing20),

                    // Mobile
                    _buildLabel('Mobile Number'),
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter mobile number';
                        if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Must be 10 digits';
                        return null;
                      },
                      decoration: _buildInputDecoration('Enter 10-digit number'),
                    ),
                    const SizedBox(height: AppTheme.spacing20),

                    // DOB
                    _buildLabel('Date of Birth'),
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) => (value == null || value.isEmpty) ? 'Please select date of birth' : null,
                      decoration: _buildInputDecoration('Select DOB').copyWith(
                        suffixIcon: const Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
                      ),
                    ),
                    
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppTheme.spacing16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: AppTheme.spacing32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorStyle: const TextStyle(color: Colors.white),
    );
  }
}
