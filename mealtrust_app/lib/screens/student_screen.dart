import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/voucher.dart';
import 'login_screen.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  bool _loading = false;
  Voucher? _voucher;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _lookupVoucher());
  }

  Future<void> _lookupVoucher() async {
    setState(() {
      _loading = true;
      _error = null;
      _voucher = null;
    });
    try {
      final voucher = await ApiService.getMyVoucher();
      if (!mounted) return;
      setState(() {
        _voucher = voucher;
        if (voucher == null) {
          _error = 'No active voucher found on your account yet.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not connect to server. Check your network.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Pass'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _lookupVoucher,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _lookupVoucher,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C4A0).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF00C4A0).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, color: Color(0xFF00C4A0)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.displayName ?? 'Student',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${auth.studentId ?? "-"} · ${auth.email ?? ""}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Your Meal Voucher',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Show this QR at the cafeteria cashier. One use only.',
                  style: TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 24),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (!_loading && _error != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child:
                      Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                ),
              if (!_loading && _voucher != null) _buildVoucherCard(_voucher!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherCard(Voucher voucher) {
    final stateColor = voucher.isActive
        ? const Color(0xFF00C4A0)
        : voucher.isRedeemed
            ? Colors.blue
            : Colors.red;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: stateColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: stateColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voucher.isActive
                          ? 'Valid Meal Pass'
                          : voucher.isRedeemed
                              ? 'Already Used'
                              : 'Revoked Pass',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(voucher.id,
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: voucher.isActive
                    ? QrImageView(
                        data: voucher.id,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                      )
                    : Column(
                        children: [
                          Icon(
                            voucher.isRedeemed ? Icons.done_all : Icons.block,
                            size: 80,
                            color: stateColor.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            voucher.isRedeemed
                                ? 'This voucher has been used.'
                                : 'This voucher has been revoked.\nContact Student Affairs.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 14),
                          ),
                        ],
                      ),
              ),
              if (voucher.isActive)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.black38),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Show this QR at the cafeteria cashier. One use only.',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
