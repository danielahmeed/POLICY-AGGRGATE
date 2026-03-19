import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insurer_dashboard/screens/insurer_login_screen.dart';

void main() {
  runApp(const InsurerDashboardApp());
}

class InsurerDashboardApp extends StatelessWidget {
  const InsurerDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HDFC Insurer Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D4ED8)),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const InsurerLoginScreen(),
    );
  }
}
