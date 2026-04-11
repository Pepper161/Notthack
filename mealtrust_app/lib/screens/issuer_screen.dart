import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/voucher.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/nourish_components.dart';
import 'login_screen.dart';

class IssuerScreen extends StatefulWidget {
  const IssuerScreen({super.key});

  @override
  State<IssuerScreen> createState() => _IssuerScreenState();
}

class _IssuerScreenState extends State<IssuerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _studentIdController = TextEditingController();
  bool _loading = false;
  bool _resetting = false;
  String? _message;
  bool _messageIsError = false;
  String? _lastTxSignature;
  String? _lastExplorerUrl;
  String? _lastCluster;
  List<Voucher> _vouchers = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadVouchers();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _loadVouchers() async {
    try {
      final vouchers = await ApiService.getVouchers();
      if (!mounted) return;
      setState(() => _vouchers = vouchers);
    } catch (_) {}
  }

  Future<void> _issueVoucher() async {
    final studentId = _studentIdController.text.trim();
    if (studentId.isEmpty) {
      setState(() {
        _message = 'Enter a student ID first.';
        _messageIsError = true;
      });
      return;
    }
    setState(() {
      _loading = true;
      _lastTxSignature = null;
      _lastExplorerUrl = null;
      _lastCluster = null;
    });
    try {
      final result = await ApiService.issueVoucher(studentId);
      if (!mounted) return;
      final onChain = result['onChain'] as Map<String, dynamic>?;
      setState(() {
        _message = result['message'] ?? 'Voucher issued: ${result['voucherId']}';
        _messageIsError = false;
        _lastTxSignature = onChain?['signature'];
        _lastExplorerUrl = onChain?['explorerUrl'];
        _lastCluster = onChain?['cluster'];
        _studentIdController.clear();
      });
      await _loadVouchers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Error: $e';
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetDemo() async {
    setState(() => _resetting = true);
    try {
      await ApiService.resetSeed();
      await _loadVouchers();
      if (!mounted) return;
      setState(() {
        _message = 'Demo state reset.';
        _messageIsError = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Demo reset complete.')));
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Reset failed: $e';
          _messageIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  Future<void> _openExplorer(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _revokeVoucher(String voucherId) async {
    final reason = await _showReasonDialog(
      title: 'Revoke voucher',
      label: 'Reason code',
      hint: 'eligibility_lost',
      confirmText: 'Revoke',
    );
    if (reason == null) return;
    try {
      final resp = await ApiService.revokeVoucher(voucherId, reason);
      final onChain = resp['onChain'] as Map<String, dynamic>?;
      await _loadVouchers();
      if (mounted) {
        setState(() {
          _message = resp['message'] ?? 'Voucher revoked.';
          _messageIsError = false;
          _lastTxSignature = onChain?['signature'];
          _lastExplorerUrl = onChain?['explorerUrl'];
          _lastCluster = onChain?['cluster'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _overrideVoucher(String voucherId) async {
    final reason = await _showReasonDialog(
      title: 'Log override',
      label: 'Override reason',
      hint: 'manual_review_approved',
      confirmText: 'Log',
    );
    if (reason == null) return;
    try {
      final resp = await ApiService.logOverride(voucherId, reason);
      final onChain = resp['onChain'] as Map<String, dynamic>?;
      await _loadVouchers();
      if (mounted) {
        setState(() {
          _message = resp['message'] ?? 'Override logged.';
          _messageIsError = false;
          _lastTxSignature = onChain?['signature'];
          _lastExplorerUrl = onChain?['explorerUrl'];
          _lastCluster = onChain?['cluster'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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

  Future<String?> _showReasonDialog({
    required String title,
    required String label,
    required String hint,
    required String confirmText,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = AuthService.instance.displayName ?? AuthService.instance.email ?? 'Student Affairs';
    final activeCount = _vouchers.where((v) => v.isActive).length;
    final redeemedCount = _vouchers.where((v) => v.isRedeemed).length;
    final revokedCount = _vouchers.where((v) => v.isRevoked).length;

    return NourishShell(
      roleLabel: 'Issuer / Student Affairs',
      title: 'NourishChain',
      subtitle: role,
      actions: [
        IconButton(
          icon: const Icon(Icons.restart_alt),
          tooltip: 'Reset demo data',
          onPressed: _resetting ? null : _resetDemo,
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Sign out',
          onPressed: _logout,
        ),
      ],
      chips: [
        NourishPill(
          label: 'Issuer view',
          icon: Icons.admin_panel_settings,
          background: const Color(0x193D6DE1),
          foreground: NourishColors.blue,
          borderColor: const Color(0x263D6DE1),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1020;
          final hero = NourishHeaderPanel(
            roleLabel: 'Student Affairs',
            headline: 'Issue support, revoke eligibility, and log override decisions.',
            body:
                'This surface keeps the issuer in control of issuance and remediation, while the on-chain layer captures the shared trust state and audit checkpoints.',
            badges: [
              NourishPill(
                label: 'Active $activeCount',
                icon: Icons.check_circle_outline,
                background: const Color(0x14FFFFFF),
                foreground: Colors.white,
              ),
              NourishPill(
                label: 'Redeemed $redeemedCount',
                icon: Icons.done_all,
                background: const Color(0x14FFFFFF),
                foreground: Colors.white,
              ),
              NourishPill(
                label: 'Revoked $revokedCount',
                icon: Icons.cancel_outlined,
                background: const Color(0x14FFFFFF),
                foreground: Colors.white,
              ),
            ],
            trailing: const Icon(Icons.admin_panel_settings,
                color: Colors.white, size: 38),
          );

          final main = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_message != null) ...[
                _messageBanner(),
                const SizedBox(height: 16),
              ],
              TabBar(
                controller: _tabs,
                labelColor: NourishColors.ink,
                unselectedLabelColor: NourishColors.slate,
                indicatorColor: NourishColors.green,
                tabs: const [
                  Tab(text: 'Issue Voucher'),
                  Tab(text: 'Manage Vouchers'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: wide ? 620 : 700,
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _buildIssueTab(),
                    _buildManageTab(),
                  ],
                ),
              ),
            ],
          );

          final sidebar = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const NourishSectionTitle(
                title: 'Issuer dashboard',
                subtitle: 'Operational controls, demo reset, and ledger summary.',
              ),
              const SizedBox(height: 12),
              NourishStatusCard(
                title: 'Issuer stance',
                body:
                    'Student Affairs issues the voucher, revokes it when eligibility changes, and logs manual overrides as distinct audited events.',
                icon: Icons.admin_panel_settings,
                accent: NourishColors.blue,
                trailing: OutlinedButton(
                  onPressed: _resetting ? null : _resetDemo,
                  child: Text(_resetting ? 'Resetting...' : 'Reset demo'),
                ),
              ),
              const SizedBox(height: 12),
              NourishActionCard(
                title: 'What this screen controls',
                body:
                    'This is the only place where issuance, revocation, and remediation are initiated. Everything else is downstream of these actions.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    _MiniRoleLine(label: 'Issue', value: 'Create seeded or new student voucher'),
                    _MiniRoleLine(label: 'Revoke', value: 'Cut off eligibility before redemption'),
                    _MiniRoleLine(label: 'Override', value: 'Log one-time manual review decisions'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              NourishActionCard(
                title: 'Live totals',
                body: 'These counts update from the seeded backend state.',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 150,
                      child: NourishMetricCard(
                        label: 'Active',
                        value: '$activeCount',
                        accent: NourishColors.green,
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: NourishMetricCard(
                        label: 'Redeemed',
                        value: '$redeemedCount',
                        accent: NourishColors.blue,
                        icon: Icons.done_all,
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: NourishMetricCard(
                        label: 'Revoked',
                        value: '$revokedCount',
                        accent: Colors.red,
                        icon: Icons.cancel_outlined,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        hero,
                        const SizedBox(height: 18),
                        main,
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 360,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: sidebar,
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                hero,
                const SizedBox(height: 16),
                sidebar,
                const SizedBox(height: 16),
                main,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _messageBanner() {
    final onChain = _lastTxSignature != null;
    return NourishActionCard(
      title: _messageIsError ? 'Action failed' : 'Action complete',
      body: _message ?? '',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onChain)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NourishColors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: NourishColors.green.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('On-chain checkpoint',
                      style: TextStyle(
                          color: NourishColors.green,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    '${_lastCluster ?? "localnet"} • ${_shortSig(_lastTxSignature!)}',
                    style: const TextStyle(
                      color: NourishColors.ink,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  if (_lastExplorerUrl != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _openExplorer(_lastExplorerUrl!),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Open in explorer'),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIssueTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final form = NourishActionCard(
          title: 'Issue a new meal voucher',
          body:
              'Eligibility is decided before issuance. The voucher is then available to the student as a wallet-free QR pass.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _issueVoucher(),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _loading ? null : _issueVoucher,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add_card),
                label: Text(_loading ? 'Issuing...' : 'Issue voucher'),
              ),
            ],
          ),
        );

        final guide = const NourishActionCard(
          title: 'How issuance works',
          body:
              'The issuer prepares support for an eligible student. Redemption and revocation are the only chain-backed state changes.',
          child: NourishInlineNotice(
            icon: Icons.info_outline,
            title: 'Pre-issuance rule',
            body:
                'This flow only creates or refreshes a voucher. Hardship decisioning stays off-chain and out of the redemption path.',
            accent: NourishColors.green,
          ),
        );

        final reset = NourishStatusCard(
          title: 'Demo control',
          body:
              'Use reset before stage demos to restore the seeded vouchers and keep the happy path predictable.',
          icon: Icons.restart_alt,
          accent: NourishColors.blue,
          trailing: OutlinedButton(
            onPressed: _resetting ? null : _resetDemo,
            child: Text(_resetting ? 'Resetting...' : 'Reset demo'),
          ),
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    form,
                    const SizedBox(height: 16),
                    guide,
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    reset,
                    const SizedBox(height: 12),
                    NourishActionCard(
                      title: 'Issuer shortcuts',
                      body: 'Keep the demo path predictable.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: const [
                          _MiniRoleLine(label: '1', value: 'Seed or issue before the cashier sees a QR'),
                          _MiniRoleLine(label: '2', value: 'Revoke when eligibility changes'),
                          _MiniRoleLine(label: '3', value: 'Log one-time override decisions'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            form,
            const SizedBox(height: 16),
            guide,
            const SizedBox(height: 16),
            reset,
          ],
        );
      },
    );
  }

  Widget _buildManageTab() {
    return RefreshIndicator(
      onRefresh: _loadVouchers,
      child: _vouchers.isEmpty
          ? const Center(child: Text('No vouchers found.'))
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: _vouchers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final v = _vouchers[i];
                final stateColor = v.isActive
                    ? NourishColors.green
                    : v.isRedeemed
                        ? NourishColors.blue
                        : Colors.red;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: stateColor.withValues(alpha: 0.16)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: CircleAvatar(
                      backgroundColor: stateColor.withValues(alpha: 0.12),
                      child: Icon(
                        v.isActive
                            ? Icons.check_circle
                            : v.isRedeemed
                                ? Icons.done_all
                                : Icons.cancel,
                        color: stateColor,
                      ),
                    ),
                    title: Text(v.id,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(
                      '${v.studentName ?? v.studentId} • ${v.amountLabel ?? "1 meal"}',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'revoke') {
                          _revokeVoucher(v.id);
                        } else if (value == 'override') {
                          _overrideVoucher(v.id);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'revoke',
                          child: Text('Revoke voucher'),
                        ),
                        PopupMenuItem(
                          value: 'override',
                          child: Text('Log override'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _MiniRoleLine extends StatelessWidget {
  final String label;
  final String value;

  const _MiniRoleLine({required this.label, required this.value});

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
