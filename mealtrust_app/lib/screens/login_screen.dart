import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'issuer_screen.dart';
import 'student_screen.dart';
import 'merchant_screen.dart';
import 'auditor_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await AuthService.instance.login(email, password);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    _routeByRole();
  }

  void _routeByRole() {
    final role = AuthService.instance.role;
    final Widget target;
    switch (role) {
      case 'student':
        target = const StudentScreen();
        break;
      case 'issuer':
        target = const IssuerScreen();
        break;
      case 'merchant':
        target = const MerchantScreen();
        break;
      case 'auditor':
        target = const AuditorScreen();
        break;
      default:
        setState(() => _error = 'Unknown role "$role" — contact admin.');
        return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => target),
    );
  }

  void _fillDemo(String email) {
    _emailController.text = email;
    _passwordController.text = 'password123';
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C4A0),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.restaurant,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MealTrust',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A2E))),
                            Text('Sign in to continue',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    size: 18, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_error!,
                                      style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loading ? null : _submit,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.login),
                          label:
                              Text(_loading ? 'Signing in...' : 'Sign in'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Demo accounts (password: password123)',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54)),
                  const SizedBox(height: 8),
                  _demoAccount('Student — Aisha', 'aisha@student.uni.edu',
                      Icons.qr_code, const Color(0xFF00C4A0)),
                  _demoAccount('Student — Ravi', 'ravi@student.uni.edu',
                      Icons.qr_code, const Color(0xFF00C4A0)),
                  _demoAccount('Issuer — Student Affairs', 'affairs@uni.edu',
                      Icons.admin_panel_settings, const Color(0xFF4A6FE3)),
                  _demoAccount('Merchant — Cafeteria A',
                      'cafe-a@merchant.uni.edu', Icons.storefront,
                      const Color(0xFFE37A4A)),
                  _demoAccount('Merchant — Cafeteria B',
                      'cafe-b@merchant.uni.edu', Icons.storefront,
                      const Color(0xFFE37A4A)),
                  _demoAccount('Merchant — Cafeteria X (blocked)',
                      'cafe-x@merchant.uni.edu', Icons.storefront,
                      const Color(0xFFE37A4A)),
                  _demoAccount('Auditor — Finance', 'audit@uni.edu',
                      Icons.history, const Color(0xFF7B4AE3)),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Blockchain-backed • Zero personal data on-chain',
                      style: TextStyle(fontSize: 11, color: Colors.black38),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _demoAccount(String label, String email, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: _loading ? null : () => _fillDemo(email),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(email,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black45,
                            fontFamily: 'monospace')),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}
