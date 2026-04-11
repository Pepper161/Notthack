import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'issuer_screen.dart';
import 'student_screen.dart';
import 'merchant_screen.dart';
import 'auditor_screen.dart';

/// Root auth gate. Replaces the old "pick your role" home screen.
///
/// Previously, anyone could tap any role tile and walk into any part of the
/// app. That was the loophole. Now:
///
///   - If not logged in → [LoginScreen]
///   - If logged in → the SINGLE screen that matches their server-assigned
///     role. Students can't see issuer/merchant/auditor UI. Merchants can't
///     see student/issuer UI. And so on.
///
/// Role is decided by the backend at login; the client just reads it from
/// [AuthService] and picks the corresponding screen.
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
        // Unknown role: force them back to login.
        return const LoginScreen();
    }
  }
}
