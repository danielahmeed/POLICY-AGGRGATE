import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import '../services/bff_api_service.dart';
import 'dashboard_screen.dart';
import 'recovery_verification_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _customerIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // Slideshow state
  final List<String> _slidingImages = [
    'assets/images/health-care-svgrepo-com.svg',
    'assets/images/insurance-umbrella-svgrepo-com.svg',
    'assets/images/mortgage-insurance-svgrepo-com.svg',
  ];
  int _currentImageIndex = 0;
  Timer? _slideshowTimer;

  @override
  void initState() {
    super.initState();
    _startSlideshow();
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    _customerIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startSlideshow() {
    _slideshowTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % _slidingImages.length;
        });
      }
    });
  }

  void _handleLogin() async {
    final customerId = _customerIdController.text.trim();
    final password = _passwordController.text.trim();

    if (customerId.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both Customer ID and Password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call BFF login API
      final response = await BffApiService.login(
        customerId: customerId,
        password: password,
      );

      if (!mounted) return;

      // Extract token and customer data from response
      final token = response['token'] as String?;
      final customerData = response['customer'] as Map<String, dynamic>?;

      if (token != null && customerData != null) {
        final resolvedCustomerId = customerData['customerId']?.toString();
        if (resolvedCustomerId == null || resolvedCustomerId.isEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Login succeeded but customer ID was missing in response.';
          });
          return;
        }
        // Store token for future API calls (can implement secure storage later)
        // For now, pass customer ID to DashboardScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DashboardScreen(customerId: resolvedCustomerId),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid response from server';
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 850;
          
          final illustration = Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/images/hdfc-bank-logo.svg',
                  width: isMobile ? 150 : 200,
                ),
                const SizedBox(height: AppTheme.spacing16),
                Text(
                  'Welcome',
                  style: (isMobile 
                    ? Theme.of(context).textTheme.headlineSmall 
                    : Theme.of(context).textTheme.headlineMedium)?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                ),
                SizedBox(height: isMobile ? AppTheme.spacing16 : AppTheme.spacing32),
                // Illustration Slideshow
                SizedBox(
                  width: isMobile ? 200 : 300,
                  height: isMobile ? 200 : 300,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 800),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: SvgPicture.asset(
                              _slidingImages[_currentImageIndex],
                              key: ValueKey<int>(_currentImageIndex),
                              width: isMobile ? 100 : 150,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Insurance Dashboard',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? AppTheme.spacing16 : AppTheme.spacing32),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing24,
                    vertical: AppTheme.spacing12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.darkestBlue,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Text(
                    'Instant Claim Settlement, "24/7 Support"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: isMobile ? 11 : 13,
                    ),
                  ),
                ),
              ],
            ),
          );

          final loginForm = Container(
            color: isMobile ? Colors.white : AppTheme.backgroundGrey,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing24,
                  vertical: AppTheme.spacing48,
                ),
                child: Container(
                  width: isMobile ? double.infinity : 400,
                  constraints: const BoxConstraints(maxWidth: 450),
                  padding: const EdgeInsets.all(AppTheme.spacing32),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge * 2),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Login',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 24 : 32,
                              ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing32),
                      
                      // Customer ID
                      const Text(
                        'Customer ID/User ID',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customerIdController,
                        decoration: InputDecoration(
                          hintText: 'Enter your Customer ID/User ID',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RecoveryVerificationScreen(mode: RecoveryMode.getCustomerId),
                            ),
                          );
                        },
                        child: const Text(
                          'Get Customer ID',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.spacing16),
                      
                      // Password
                      const Text(
                        'Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword 
                                  ? Icons.visibility_off 
                                  : Icons.visibility,
                              color: AppTheme.primaryBlue,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RecoveryVerificationScreen(mode: RecoveryMode.forgotPassword),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.spacing32),
                      
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppTheme.spacing8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing16),
                      ],
                      
                      // Continue Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'New User? ',
                            style: TextStyle(color: Colors.white70),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SignupScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Sign up now',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
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
          );

          if (isMobile) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  illustration,
                  loginForm,
                ],
              ),
            );
          } else {
            return Row(
              children: [
                Expanded(flex: 5, child: illustration),
                Expanded(flex: 4, child: loginForm),
              ],
            );
          }
        },
      ),
    );
  }
}
