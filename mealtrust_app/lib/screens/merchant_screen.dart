import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/voucher.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/nourish_components.dart';
import 'login_screen.dart';

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
  bool _redeemed = false;
  VerifyResult? _result;
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
      _redeemTxSignature = null;
      _redeemExplorerUrl = null;
      _redeemCluster = null;
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

  String _statusLabel(String status) {
    switch (status) {
      case 'revoked':
        return 'Revoked voucher';
      case 'already_redeemed':
        return 'Already redeemed';
      case 'merchant_not_approved':
        return 'Merchant not approved';
      case 'unknown_voucher':
        return 'Unknown voucher';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final merchantId = AuthService.instance.merchantId ?? '?';
    return NourishShell(
      roleLabel: 'Merchant / Cafeteria',
      title: 'NourishChain',
      subtitle: 'Merchant $merchantId',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Reset scanner',
          onPressed: _reset,
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Sign out',
          onPressed: _logout,
        ),
      ],
      chips: [
        NourishPill(
          label: _scanning ? 'Scan mode' : 'Review mode',
          icon: _scanning ? Icons.qr_code_scanner : Icons.receipt_long,
          background: const Color(0x193D6DE1),
          foreground: NourishColors.blue,
          borderColor: const Color(0x263D6DE1),
        ),
      ],
      scrollable: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          final hero = NourishHeaderPanel(
            roleLabel: 'Merchant checkout',
            headline: 'Verify first. Redeem once. Block duplicates.',
            body:
                'The cashier sees one clear decision: valid, revoked, already used, or unauthorized. If the pass is valid, redemption writes a live checkpoint to localnet.',
            badges: const [
              NourishPill(
                label: 'Happy path = verify then redeem',
                icon: Icons.check_circle_outline,
                background: Color(0x14FFFFFF),
                foreground: Colors.white,
              ),
            ],
            trailing: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: const Icon(Icons.storefront,
                  color: Colors.white, size: 36),
            ),
          );

          final mainCard = _loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _redeemed && _redeemTxSignature != null
                  ? _buildSuccessCard()
                  : _result != null
                      ? _buildVerificationCard()
                      : _buildScannerCard();

          final secondary = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const NourishSectionTitle(
                title: 'Merchant flow',
                subtitle: 'Scan, validate, redeem, and keep the line moving.',
              ),
              const SizedBox(height: 12),
              NourishStatusCard(
                title: _scanning ? 'Scanner ready' : 'Verification in progress',
                body:
                    _scanning ? 'Camera or manual entry is ready for the next student.' : 'The cashier is reviewing a pass before redemption.',
                icon: _scanning ? Icons.qr_code_scanner : Icons.receipt_long,
                accent: NourishColors.blue,
                trailing: OutlinedButton(
                  onPressed: _reset,
                  child: const Text('Reset scanner'),
                ),
              ),
              const SizedBox(height: 12),
              NourishActionCard(
                title: 'Why this screen matters',
                body:
                    'The cashier only needs to know whether the pass is valid. The trust layer hides hardship details, but exposes the exact reason a voucher is blocked.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    _MiniMerchantLine(label: '1', value: 'Scan or type voucher ID'),
                    _MiniMerchantLine(label: '2', value: 'Verify status against shared trust state'),
                    _MiniMerchantLine(label: '3', value: 'Redeem exactly once if valid'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              NourishActionCard(
                title: 'Failure states',
                body:
                    'A blocked voucher should read clearly and stop the cashier from redeeming it twice.',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    NourishPill(label: 'Already redeemed', icon: Icons.done_all, background: Color(0x140FAF8F), foreground: NourishColors.green, borderColor: Color(0x260FAF8F)),
                    NourishPill(label: 'Revoked', icon: Icons.cancel_outlined, background: Color(0x14D95F5F), foreground: Colors.red, borderColor: Color(0x26D95F5F)),
                    NourishPill(label: 'Unauthorized merchant', icon: Icons.block, background: Color(0x14EB851C), foreground: Color(0xFFE37A4A), borderColor: Color(0x26EB851C)),
                  ],
                ),
              ),
            ],
          );

          if (wide) {
            return RefreshIndicator(
              onRefresh: () async => _reset(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    hero,
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: mainCard),
                        const SizedBox(width: 16),
                        SizedBox(width: 350, child: secondary),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reset(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  hero,
                  const SizedBox(height: 18),
                  mainCard,
                  const SizedBox(height: 16),
                  secondary,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScannerCard() {
    return NourishActionCard(
      title: 'Scan or type the voucher ID',
      body:
          'Point the camera at the student QR. If the demo browser cannot use the camera, type the voucher ID manually and keep the flow moving.',
      child: Column(
        children: [
          Container(
            height: 310,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
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
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  Positioned(
                    top: 18,
                    left: 18,
                    child: NourishPill(
                      label: 'Camera live',
                      icon: Icons.visibility,
                      background: Colors.white.withValues(alpha: 0.14),
                      foreground: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const NourishInlineNotice(
            icon: Icons.info_outline,
            title: 'Fallback',
            body:
                'If the scanner is blocked, enter the voucher ID manually and continue. The verify and redeem sequence stays the same.',
            accent: NourishColors.green,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualController,
                  decoration: const InputDecoration(
                    labelText: 'Voucher ID',
                    hintText: 'VCH-1001',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
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
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  final v = _manualController.text.trim();
                  if (v.isNotEmpty) {
                    setState(() => _scanning = false);
                    _verify(v);
                  }
                },
                icon: const Icon(Icons.search),
                label: const Text('Verify'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    final isValid = _result!.valid;
    final color = isValid ? NourishColors.green : Colors.red;
    final icon = isValid ? Icons.verified : Icons.cancel;
    final voucher = _result!.voucher;

    return NourishActionCard(
      title: 'Verification result',
      body:
          isValid ? 'The pass is valid. Confirm redemption to write the checkpoint.' : 'The pass is blocked. Do not redeem.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NourishStatusCard(
            title: isValid ? 'Valid voucher' : _statusLabel(_result!.status),
            body: _result!.message,
            icon: icon,
            accent: color,
            trailing: isValid
                ? const NourishPill(
                    label: 'Ready to redeem',
                    icon: Icons.arrow_forward,
                    background: Color(0x140FAF8F),
                    foreground: NourishColors.green,
                    borderColor: Color(0x260FAF8F),
                  )
                : null,
          ),
          const SizedBox(height: 14),
          if (voucher != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Voucher ${voucher.id}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: NourishColors.ink)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      NourishPill(
                        label: 'Student ${voucher.studentId}',
                        icon: Icons.person_outline,
                        background: const Color(0x14FFFFFF),
                        foreground: NourishColors.ink,
                        borderColor: const Color(0x1A17332D),
                      ),
                      NourishPill(
                        label: 'Status ${voucher.state.toUpperCase()}',
                        icon: Icons.layers_outlined,
                        background: const Color(0x14FFFFFF),
                        foreground: NourishColors.ink,
                        borderColor: const Color(0x1A17332D),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          if (isValid)
            ElevatedButton.icon(
              onPressed: _loading ? null : _redeem,
              icon: const Icon(Icons.done_all),
              label: const Text('Confirm redemption'),
            )
          else
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan another voucher'),
            ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    return NourishActionCard(
      title: 'Redemption recorded',
      body:
          'The voucher was redeemed and written to localnet. The cashier can move on to the next student or rescan.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NourishStatusCard(
            title: 'Redeemed successfully',
            body:
                'Checkpoint written${_redeemCluster != null ? " on ${_redeemCluster!}" : ""}. One meal approved.',
            icon: Icons.verified,
            accent: NourishColors.green,
            trailing: const NourishPill(
              label: 'Live chain write',
              icon: Icons.link,
              background: Color(0x140FAF8F),
              foreground: NourishColors.green,
              borderColor: Color(0x260FAF8F),
            ),
          ),
          if (_redeemTxSignature != null) ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: _redeemExplorerUrl == null
                  ? null
                  : () => _openExplorer(_redeemExplorerUrl!),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9945FF), Color(0xFF14F195)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Solana ${_redeemCluster ?? "localnet"}: ${_shortSig(_redeemTxSignature!)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const Icon(Icons.open_in_new,
                        size: 14, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan next voucher'),
          ),
        ],
      ),
    );
  }
}

class _MiniMerchantLine extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMerchantLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: NourishColors.blue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: NourishColors.slate, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
