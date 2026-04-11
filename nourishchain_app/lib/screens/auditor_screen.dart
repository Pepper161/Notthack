import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/voucher.dart';
import 'login_screen.dart';

class AuditorScreen extends StatefulWidget {
  const AuditorScreen({super.key});

  @override
  State<AuditorScreen> createState() => _AuditorScreenState();
}

class _AuditorScreenState extends State<AuditorScreen> {
  List<AuditEvent> _events = [];
  SolanaStatus? _solana;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final events = await ApiService.getAuditHistory();
      final status = await ApiService.getSolanaStatus();
      if (!mounted) return;
      setState(() {
        _events = events.reversed.toList(); // newest first
        _solana = status;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load audit log: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openExplorer(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    if (_solana != null) _buildSolanaBanner(_solana!),
                    _buildSummaryBar(),
                    Expanded(
                      child: _events.isEmpty
                          ? const Center(child: Text('No events recorded yet.'))
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: _events.length,
                                itemBuilder: (_, i) => _EventTile(
                                  event: _events[i],
                                  index: i,
                                  onOpenExplorer: _openExplorer,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildSolanaBanner(SolanaStatus status) {
    final isLive = status.enabled;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLive
              ? [const Color(0xFF9945FF), const Color(0xFF14F195)]
              : [Colors.grey.shade400, Colors.grey.shade600],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.link, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLive
                      ? 'Solana ${status.cluster ?? "localnet"} — LIVE'
                      : 'Solana — offline',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                if (status.wallet != null)
                  Text(
                    '${_short(status.wallet!)}  •  ${status.balance?.toStringAsFixed(3) ?? "?"} SOL',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontFamily: 'monospace'),
                  ),
              ],
            ),
          ),
          if (status.wallet != null)
            IconButton(
              icon: const Icon(Icons.open_in_new,
                  color: Colors.white, size: 18),
              tooltip: 'View wallet on Solana Explorer',
              onPressed: () => _openExplorer(
                  'https://explorer.solana.com/address/${status.wallet}?cluster=custom&customUrl=${Uri.encodeComponent(status.rpcUrl ?? 'http://127.0.0.1:8899')}'),
            ),
        ],
      ),
    );
  }

  String _short(String addr) {
    if (addr.length < 12) return addr;
    return '${addr.substring(0, 6)}…${addr.substring(addr.length - 6)}';
  }

  Widget _buildSummaryBar() {
    final counts = <String, int>{};
    for (final e in _events) {
      counts[e.type] = (counts[e.type] ?? 0) + 1;
    }
    return Container(
      color: const Color(0xFF7B4AE3).withOpacity(0.06),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _sumChip('Issued', counts['voucher_issued'] ?? 0, Colors.blue),
          _sumChip('Redeemed', counts['voucher_redeemed'] ?? 0, Colors.green),
          _sumChip('Blocked', counts['voucher_redemption_blocked'] ?? 0,
              Colors.orange),
          _sumChip('Revoked', counts['voucher_revoked'] ?? 0, Colors.red),
        ],
      ),
    );
  }

  Widget _sumChip(String label, int count, Color color) {
    return Column(
      children: [
        Text('$count',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.black45)),
      ],
    );
  }
}

// ─── Event tile ──────────────────────────────────────────────────────────────

class _EventTile extends StatelessWidget {
  final AuditEvent event;
  final int index;
  final void Function(String) onOpenExplorer;

  const _EventTile({
    required this.event,
    required this.index,
    required this.onOpenExplorer,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(event.type);
    final icon = _iconFor(event.type);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            if (index != 0)
              Container(
                  width: 2, height: 24, color: Colors.grey.withOpacity(0.2)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(event.label,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontSize: 13)),
                    Text(_formatTime(event.timestamp),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black38)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(event.voucherId,
                    style: const TextStyle(
                        fontSize: 12, fontFamily: 'monospace')),
                if (event.merchantId != null)
                  Text('Merchant: ${event.merchantId}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black45)),
                if (event.reason != null)
                  Text('Reason: ${event.reason}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.red.shade300)),
                if (event.isOnChain) ...[
                  const SizedBox(height: 8),
                  _OnChainBadge(
                    signature: event.txSignature!,
                    onTap: () => onOpenExplorer(event.explorerUrl!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'voucher_issued':
        return Colors.blue;
      case 'voucher_redeemed':
        return Colors.green;
      case 'voucher_revoked':
        return Colors.red;
      case 'voucher_redemption_blocked':
        return Colors.orange;
      case 'override_logged':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'voucher_issued':
        return Icons.add_card;
      case 'voucher_redeemed':
        return Icons.done_all;
      case 'voucher_revoked':
        return Icons.cancel;
      case 'voucher_redemption_blocked':
        return Icons.block;
      case 'override_logged':
        return Icons.warning;
      default:
        return Icons.circle;
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _OnChainBadge extends StatelessWidget {
  final String signature;
  final VoidCallback onTap;

  const _OnChainBadge({required this.signature, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final short = signature.length > 12
        ? '${signature.substring(0, 6)}…${signature.substring(signature.length - 6)}'
        : signature;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9945FF), Color(0xFF14F195)],
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'Solana: $short',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.open_in_new, size: 11, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
