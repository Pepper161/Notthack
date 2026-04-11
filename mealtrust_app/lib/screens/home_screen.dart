import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'issuer_screen.dart';
import 'student_screen.dart';
import 'merchant_screen.dart';
import 'auditor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    switch (auth.role) {
      case 'student':
        return const StudentScreen();
      case 'issuer':
        return const IssuerScreen();
      case 'merchant':
        return const MerchantScreen();
      case 'auditor':
        return const AuditorScreen();
      default:
        return const LoginScreen();
    }
  }
}
