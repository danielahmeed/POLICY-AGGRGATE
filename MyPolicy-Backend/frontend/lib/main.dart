import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/analytical_dashboard.dart';
import 'screens/recovery_verification_screen.dart';
import 'screens/recovery_otp_screen.dart';
import 'screens/policy_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/signup_otp_screen.dart';
import 'screens/create_password_screen.dart';
import 'screens/help_screen.dart';
import 'screens/faq_screen.dart';
import 'screens/documents_screen.dart';
import 'models/policy_model.dart';
import 'utils/app_routes.dart';

void main() {
  runApp(const HDFCInsuranceApp());
}

/// Main application widget
class HDFCInsuranceApp extends StatelessWidget {
  const HDFCInsuranceApp({super.key});

  Map<String, dynamic>? _routeArgs(RouteSettings settings) {
    return settings.arguments as Map<String, dynamic>?;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HDFC Insurance Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.login,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.login:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          
          case AppRoutes.dashboard:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => DashboardScreen(
                customerId: args['customerId'],
              ),
            );

          case AppRoutes.analytics:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => AnalyticsDashboard(
                customerName: args['customerName'],
                customerId: args['customerId'],
              ),
            );

          case AppRoutes.recovery:
            final args = _routeArgs(settings);
            return MaterialPageRoute(
              builder: (_) => RecoveryVerificationScreen(
                mode: args?['mode'] ?? RecoveryMode.forgotPassword,
              ),
            );

          case AppRoutes.otp:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => RecoveryOtpScreen(
                customerId: args['customerId'],
                destination: args['destination'],
              ),
            );

          case AppRoutes.policyDetail:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => PolicyDetailScreen(
                policy: args['policy'] as Policy,
                customerId: args['customerId'],
                customerName: args['customerName'],
              ),
            );

          case AppRoutes.profile:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => ProfileScreen(
                customerName: args['customerName'],
                customerId: args['customerId'],
              ),
            );

          case AppRoutes.signup:
            return MaterialPageRoute(builder: (_) => const SignupScreen());

          case AppRoutes.signupOtp:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => SignupOtpScreen(
                mobileNumber: args['mobileNumber'],
                customerId: args['customerId'] ?? '',
              ),
            );

          case AppRoutes.createPassword:
            final args = _routeArgs(settings);
            return MaterialPageRoute(
              builder: (_) => CreatePasswordScreen(
                customerId: args?['customerId'] ?? '',
              ),
            );

          case AppRoutes.help:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => HelpScreen(
                customerName: args['customerName'],
                customerId: args['customerId'],
              ),
            );

          case AppRoutes.faq:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => FaqScreen(
                customerName: args['customerName'],
                customerId: args['customerId'],
              ),
            );

          case AppRoutes.documents:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => DocumentsScreen(
                customerName: args['customerName'],
                customerId: args['customerId'],
              ),
            );

          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(child: Text('No route defined for ${settings.name}')),
              ),
            );
        }
      },
    );
  }
}