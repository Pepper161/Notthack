import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/voucher.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/nourish_components.dart';
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
  String _filter = 'all';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        _events = events.reversed.toList();
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

  List<AuditEvent> get _filteredEvents {
    final query = _searchController.text.trim().toLowerCase();
    return _events.where((event) {
      final matchesFilter = _filter == 'all' || event.type == _filter;
      final matchesQuery = query.isEmpty ||
          event.voucherId.toLowerCase().contains(query) ||
          (event.merchantId ?? '').toLowerCase().contains(query) ||
          (event.studentId ?? '').toLowerCase().contains(query) ||
          (event.reason ?? '').toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final e in _events) {
      counts[e.type] = (counts[e.type] ?? 0) + 1;
    }

    return NourishShell(
      roleLabel: 'Auditor / Finance',
      title: 'NourishChain',
      subtitle: 'Audit history and chain status',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _load,
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Sign out',
          onPressed: _logout,
        ),
      ],
      chips: [
        NourishPill(
          label: _solana?.enabled == true ? 'localnet live' : 'chain offline',
          icon: _solana?.enabled == true ? Icons.link : Icons.link_off,
          background: const Color(0x193D6DE1),
          foreground: NourishColors.blue,
          borderColor: const Color(0x263D6DE1),
        ),
      ],
      scrollable: false,
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator()),
            )
          : _error != null
              ? _buildError()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1100;
                    final hero = NourishHeaderPanel(
                      roleLabel: 'Audit trail',
                      headline: 'See the same state, the same history, and the same checkpoint story.',
                      body:
                          'Auditors do not need the hidden hardship reasoning. They need the visible events, the live chain status, and a clean path to explain what happened.',
                      badges: [
                        NourishPill(
                          label: 'Issued ${counts['voucher_issued'] ?? 0}',
                          icon: Icons.add_card,
                          background: const Color(0x14FFFFFF),
                          foreground: Colors.white,
                        ),
                        NourishPill(
                          label: 'Redeemed ${counts['voucher_redeemed'] ?? 0}',
                          icon: Icons.done_all,
                          background: const Color(0x14FFFFFF),
                          foreground: Colors.white,
                        ),
                        NourishPill(
                          label: 'Blocked ${counts['voucher_redemption_blocked'] ?? 0}',
                          icon: Icons.block,
                          background: const Color(0x14FFFFFF),
                          foreground: Colors.white,
                        ),
                      ],
                      trailing: const Icon(Icons.history, color: Colors.white, size: 38),
                    );

                    final filters = NourishActionCard(
                      title: 'Audit filters',
                      body:
                          'Use the filter chips and search box to isolate issuances, redemptions, revocations, blocked redemptions, or overrides.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Search voucher, student, merchant, or reason',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _filterChip('all', 'All'),
                              _filterChip('voucher_issued', 'Issued'),
                              _filterChip('voucher_redeemed', 'Redeemed'),
                              _filterChip('voucher_revoked', 'Revoked'),
                              _filterChip('voucher_redemption_blocked', 'Blocked'),
                              _filterChip('override_logged', 'Override'),
                            ],
                          ),
                        ],
                      ),
                    );

                    final stats = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSolanaBanner(),
                        const SizedBox(height: 12),
                        _buildSummaryBar(counts),
                        const SizedBox(height: 12),
                        NourishActionCard(
                          title: 'What auditors should look for',
                          body:
                              'The important thing is not hidden hardship details. It is the sequence of events, the chain signature, and the reason a voucher became blocked.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: const [
                              _MiniAuditLine(label: '1', value: 'A clean issuance event'),
                              _MiniAuditLine(label: '2', value: 'A redeem event with a Solana signature'),
                              _MiniAuditLine(label: '3', value: 'A blocked or revoked follow-up explained by state'),
                            ],
                          ),
                        ),
                      ],
                    );

                    final timeline = Expanded(
                      child: _filteredEvents.isEmpty
                          ? const Center(child: Text('No events matched the current filters.'))
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: const EdgeInsets.only(bottom: 12),
                                itemCount: _filteredEvents.length,
                                itemBuilder: (_, i) => _EventTile(
                                  event: _filteredEvents[i],
                                  index: i,
                                  onOpenExplorer: _openExplorer,
                                ),
                              ),
                            ),
                    );

                    if (wide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          hero,
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 4, child: Column(children: [stats, const SizedBox(height: 12), filters])),
                              const SizedBox(width: 16),
                              Expanded(flex: 5, child: SizedBox(height: 720, child: timeline)),
                            ],
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        hero,
                        const SizedBox(height: 16),
                        stats,
                        const SizedBox(height: 12),
                        filters,
                        const SizedBox(height: 12),
                        SizedBox(height: 640, child: timeline),
                      ],
                    );
                  },
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

  Widget _buildSolanaBanner() {
    final status = _solana;
    final isLive = status?.enabled == true;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLive
              ? [const Color(0xFF9945FF), const Color(0xFF14F195)]
              : [Colors.grey.shade500, Colors.grey.shade700],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.link, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLive
                      ? 'Solana ${status?.cluster ?? "localnet"} — LIVE'
                      : 'Solana — offline',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                if (status?.wallet != null)
                  Text(
                    '${_short(status!.wallet!)}  •  ${status.balance?.toStringAsFixed(3) ?? "?"} SOL',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          ),
          if (status?.wallet != null)
            IconButton(
              icon: const Icon(Icons.open_in_new,
                  color: Colors.white, size: 18),
              tooltip: 'View wallet on Solana Explorer',
              onPressed: () => _openExplorer(
                  'https://explorer.solana.com/address/${status!.wallet}?cluster=custom&customUrl=${Uri.encodeComponent(status.rpcUrl ?? 'http://127.0.0.1:8899')}'),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(Map<String, int> counts) {
    return Row(
      children: [
        Expanded(
          child: NourishMetricCard(
            label: 'Issued',
            value: '${counts['voucher_issued'] ?? 0}',
            accent: NourishColors.blue,
            icon: Icons.add_card,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: NourishMetricCard(
            label: 'Redeemed',
            value: '${counts['voucher_redeemed'] ?? 0}',
            accent: NourishColors.green,
            icon: Icons.done_all,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: NourishMetricCard(
            label: 'Blocked',
            value: '${counts['voucher_redemption_blocked'] ?? 0}',
            accent: Colors.orange,
            icon: Icons.block,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: NourishMetricCard(
            label: 'Revoked',
            value: '${counts['voucher_revoked'] ?? 0}',
            accent: Colors.red,
            icon: Icons.cancel,
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: NourishColors.green.withValues(alpha: 0.14),
      labelStyle: TextStyle(
        color: selected ? NourishColors.greenDark : NourishColors.slate,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(
        color: selected
            ? NourishColors.green.withValues(alpha: 0.24)
            : Colors.black.withValues(alpha: 0.06),
      ),
      backgroundColor: Colors.white,
    );
  }

  String _short(String addr) {
    if (addr.length < 12) return addr;
    return '${addr.substring(0, 6)}…${addr.substring(addr.length - 6)}';
  }
}

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
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.28)),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            if (index != 0)
              Container(width: 2, height: 22, color: Colors.grey.withValues(alpha: 0.18)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(event.label,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
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
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (event.merchantId != null)
                      _smallChip('Merchant ${event.merchantId}', color),
                    if (event.studentId != null)
                      _smallChip('Student ${event.studentId}', Colors.black54),
                    if (event.reason != null)
                      _smallChip(event.reason!, Colors.red.shade400),
                  ],
                ),
                if (event.isOnChain) ...[
                  const SizedBox(height: 10),
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

  Widget _smallChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'voucher_issued':
        return NourishColors.blue;
      case 'voucher_redeemed':
        return NourishColors.green;
      case 'voucher_revoked':
        return Colors.red;
      case 'voucher_redemption_blocked':
        return Colors.orange;
      case 'override_logged':
        return NourishColors.violet;
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9945FF), Color(0xFF14F195)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link, size: 12, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              'Solana: $short',
              style: const TextStyle(
                fontSize: 10.5,
                color: Colors.white,
                fontWeight: FontWeight.w700,
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

class _MiniAuditLine extends StatelessWidget {
  final String label;
  final String value;

  const _MiniAuditLine({required this.label, required this.value});

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
