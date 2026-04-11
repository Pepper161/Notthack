import 'package:flutter/material.dart';
import 'issuer_screen.dart';
import 'student_screen.dart';
import 'merchant_screen.dart';
import 'auditor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C4A0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.restaurant, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MealTrust',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E))),
                      Text('Select your role to continue',
                          style:
                              TextStyle(fontSize: 13, color: Colors.black54)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _RoleCard(
                      icon: Icons.admin_panel_settings,
                      label: 'Issuer',
                      subtitle: 'Student Affairs',
                      color: const Color(0xFF4A6FE3),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const IssuerScreen())),
                    ),
                    _RoleCard(
                      icon: Icons.qr_code,
                      label: 'Student',
                      subtitle: 'Beneficiary',
                      color: const Color(0xFF00C4A0),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const StudentScreen())),
                    ),
                    _RoleCard(
                      icon: Icons.storefront,
                      label: 'Merchant',
                      subtitle: 'Cafeteria Cashier',
                      color: const Color(0xFFE37A4A),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const MerchantScreen())),
                    ),
                    _RoleCard(
                      icon: Icons.history,
                      label: 'Auditor',
                      subtitle: 'Finance / Compliance',
                      color: const Color(0xFF7B4AE3),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const AuditorScreen())),
                    ),
                  ],
                ),
              ),
              Center(
                child: Text(
                  'Blockchain-backed • Zero personal data on-chain',
                  style: TextStyle(fontSize: 11, color: Colors.black38),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 4),
            Text(subtitle,
                style:
                    const TextStyle(fontSize: 12, color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}
