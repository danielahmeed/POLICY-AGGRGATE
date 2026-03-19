import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'insurer_portal_screen.dart';

class InsurerLoginScreen extends StatefulWidget {
  const InsurerLoginScreen({super.key});

  @override
  State<InsurerLoginScreen> createState() => _InsurerLoginScreenState();
}

class _InsurerLoginScreenState extends State<InsurerLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Demo credentials for insurer login
  static const String _validUsername = 'Pratick';
  static const String _validPassword = 'pass8888';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    // Simulate a short network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username == _validUsername && password == _validPassword) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const InsurerPortalScreen(),
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid username or password';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // HDFC Logo and Title
              Column(
                children: [
                  SvgPicture.asset(
                    'assets/images/hdfc-bank-logo.svg',
                    height: 60,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Insurer Portal',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Login Card
              Container(
                width: 420,
                decoration: BoxDecoration(
                  color: const Color(0xFF0451B5),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Error Message
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Username field
                    const Text(
                      'Username',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          hintText: 'Enter username',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: const Icon(Icons.person_outline,
                              color: Color(0xFF1D4ED8)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 16),
                        ),
                        onSubmitted: (_) => _handleLogin(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password field
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Enter password',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: Color(0xFF1D4ED8)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 16),
                        ),
                        onSubmitted: (_) => _handleLogin(),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Login Button
                    Center(
                      child: SizedBox(
                        width: 150,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFED1C24),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor:
                                const Color(0xFFED1C24).withValues(alpha: 0.7),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
