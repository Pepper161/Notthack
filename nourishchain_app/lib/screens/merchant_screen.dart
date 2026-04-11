import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/voucher.dart';
import 'login_screen.dart';

// merchantId is NO LONGER hardcoded. It is bound to the authenticated
// merchant account at login time. The backend derives it from the session
// and ignores any value the client might send, which closes the loophole
// where any user could pretend to be any merchant.

class MerchantScreen extends StatefulWidget {
  const MerchantScreen({super.key});

  @override
  State<MerchantScreen> createState() => _MerchantScreenState();
}

class _MerchantScreenState extends State<MerchantScreen> {
  final _manualController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();

  bool _scanning = true;
  bool _loading = false;
  VerifyResult? _result;
  bool _redeemed = false;
  String? _redeemTxSignature;
  String? _redeemExplorerUrl;
  String? _redeemCluster;

  @override
  void dispose() {
    _manualController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onQrDetected(String voucherId) {
    if (!_scanning) return;
    _scannerController.stop();
    setState(() => _scanning = false);
    _verify(voucherId);
  }

  Future<void> _verify(String voucherId) async {
    setState(() {
      _loading = true;
      _result = null;
      _redeemed = false;
    });
    try {
      final result = await ApiService.verifyVoucher(voucherId);
      if (!mounted) return;
      setState(() => _result = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e')),
        );
        _reset();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _redeem() async {
    if (_result?.voucher == null) return;
    setState(() => _loading = true);
    try {
      final resp = await ApiService.redeemVoucher(_result!.voucher!.id);
      if (!mounted) return;
      final onChain = resp['onChain'] as Map<String, dynamic>?;
      setState(() {
        _redeemed = true;
        _redeemTxSignature = onChain?['signature'];
        _redeemExplorerUrl = onChain?['explorerUrl'];
        _redeemCluster = onChain?['cluster'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Redemption failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() {
    setState(() {
      _scanning = true;
      _result = null;
      _redeemed = false;
      _redeemTxSignature = null;
      _redeemExplorerUrl = null;
      _redeemCluster = null;
      _manualController.clear();
    });
    _scannerController.start();
  }

  Future<void> _openExplorer(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _shortSig(String sig) {
    if (sig.length <= 14) return sig;
    return '${sig.substring(0, 6)}…${sig.substring(sig.length - 6)}';
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
        title: Text(
            'Merchant — ${auth.merchantId ?? "?"}'),
        actions: [
          if (!_scanning)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Scan again',
              onPressed: _reset,
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _scanning
              ? _buildScanner()
              : _buildResult(),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            alignment: Alignment.center,
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: (capture) {
                  for (final barcode in capture.barcodes) {
                    if (barcode.rawValue != null) {
                      _onQrDetected(barcode.rawValue!);
                      break;
                    }
                  }
                },
              ),
              // Scan frame overlay
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('Point camera at student QR',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Or enter voucher ID manually:',
                    style: TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualController,
                        decoration: const InputDecoration(
                          hintText: 'VCH-1001',
                          isDense: true,
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (v) {
                          if (v.trim().isNotEmpty) {
                            setState(() => _scanning = false);
                            _verify(v.trim());
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final v = _manualController.text.trim();
                        if (v.isNotEmpty) {
                          setState(() => _scanning = false);
                          _verify(v);
                        }
                      },
                      child: const Text('Verify'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    if (_result == null) return const SizedBox();

    if (_redeemed) {
      return _buildSuccessRedeemed();
    }

    final isValid = _result!.valid;
    final color = isValid ? const Color(0xFF00C4A0) : Colors.red;
    final icon = isValid ? Icons.check_circle : Icons.cancel;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(icon, size: 64, color: color),
                const SizedBox(height: 12),
                Text(
                  isValid ? 'Valid Voucher' : _statusLabel(_result!.status),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
                const SizedBox(height: 8),
                Text(_result!.message,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontSize: 14, color: Colors.black54)),
                if (_result!.voucher != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  _infoRow('Voucher ID', _result!.voucher!.id),
                  _infoRow('Student ID', _result!.voucher!.studentId),
                  _infoRow('Status', _result!.voucher!.state.toUpperCase()),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (isValid)
            ElevatedButton.icon(
              onPressed: _loading ? null : _redeem,
              icon: const Icon(Icons.done),
              label: const Text('Confirm Redemption'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C4A0),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Another'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessRedeemed() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.verified, size: 80, color: Colors.green),
                const SizedBox(height: 16),
                const Text('Redeemed Successfully',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
                const SizedBox(height: 8),
                Text(
                    'Checkpoint written${_redeemCluster != null ? " on ${_redeemCluster!}" : ""}. Meal approved.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54)),
                if (_redeemTxSignature != null) ...[
                  const SizedBox(height: 16),
                  if (_redeemExplorerUrl != null)
                    InkWell(
                      onTap: () => _openExplorer(_redeemExplorerUrl!),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9945FF), Color(0xFF14F195)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.link,
                                size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'View on Solana ${_redeemCluster ?? "localnet"}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _shortSig(_redeemTxSignature!),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.open_in_new,
                                size: 14, color: Colors.white),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Tx: ${_shortSig(_redeemTxSignature!)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.black54,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Next Customer'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'already_redeemed':
        return 'Already Used';
      case 'revoked':
        return 'Voucher Revoked';
      case 'merchant_not_approved':
        return 'Merchant Not Approved';
      case 'unknown_voucher':
        return 'Voucher Not Found';
      default:
        return 'Invalid';
    }
  }
}
