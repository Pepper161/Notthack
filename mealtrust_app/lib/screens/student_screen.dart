import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../models/voucher.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final _idController = TextEditingController();
  bool _loading = false;
  Voucher? _voucher;
  String? _error;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _lookupVoucher() async {
    final id = _idController.text.trim();
    if (id.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _voucher = null;
    });
    try {
      final voucher = await ApiService.getStudentVoucher(id);
      if (!mounted) return;
      setState(() {
        _voucher = voucher;
        if (voucher == null) _error = 'No active voucher found for "$id".';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not connect to server. Check your network.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Pass')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Your Meal Voucher',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
                'Enter your student ID to retrieve your QR pass. No wallet needed.',
                style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 24),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'Student ID',
                prefixIcon: Icon(Icons.badge),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _lookupVoucher(),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loading ? null : _lookupVoucher,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search),
              label: Text(_loading ? 'Looking up...' : 'Get My Pass'),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_error!,
                    style: TextStyle(color: Colors.red.shade700)),
              ),
            if (_voucher != null) _buildVoucherCard(_voucher!),
          ],
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
                  color: stateColor.withOpacity(0.2),
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
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
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
                            voucher.isRedeemed
                                ? Icons.done_all
                                : Icons.block,
                            size: 80,
                            color: stateColor.withOpacity(0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            voucher.isRedeemed
                                ? 'This voucher has been used.'
                                : 'This voucher has been revoked.\nContact Student Affairs.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
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
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 16, color: Colors.black38),
                        const SizedBox(width: 8),
                        const Expanded(
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
