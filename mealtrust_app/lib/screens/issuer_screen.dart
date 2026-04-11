import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../models/voucher.dart';

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

  Future<void> _openExplorer(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _revokeVoucher(String voucherId) async {
    final reason = await _showRevokeDialog();
    if (reason == null) return;
    try {
      await ApiService.revokeVoucher(voucherId, reason);
      await _loadVouchers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voucher revoked.')),
        );
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

  Future<String?> _showRevokeDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Voucher'),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(labelText: 'Reason (e.g. eligibility lost)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Revoke')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issuer — Student Affairs'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Issue Voucher'),
            Tab(text: 'Manage Vouchers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildIssueTab(),
          _buildManageTab(),
        ],
      ),
    );
  }

  Widget _buildIssueTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Issue a new meal voucher',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
              'Eligibility is verified offline by Student Affairs before issuance.',
              style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 24),
          TextField(
            controller: _studentIdController,
            decoration: const InputDecoration(
              labelText: 'Student ID',
              prefixIcon: Icon(Icons.person),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _issueVoucher(),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loading ? null : _issueVoucher,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.add_card),
            label: Text(_loading ? 'Issuing...' : 'Issue Voucher'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _messageIsError
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _messageIsError
                        ? Colors.red.shade200
                        : Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_message!,
                      style: TextStyle(
                          color: _messageIsError
                              ? Colors.red.shade700
                              : Colors.green.shade700)),
                  if (_lastTxSignature != null) ...[
                    const SizedBox(height: 10),
                    if (_lastExplorerUrl != null)
                      InkWell(
                        onTap: () => _openExplorer(_lastExplorerUrl!),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9945FF), Color(0xFF14F195)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.link,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                'Recorded on Solana ${_lastCluster ?? "localnet"}: ${_shortSig(_lastTxSignature!)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.open_in_new,
                                  size: 12, color: Colors.white),
                            ],
                          ),
                        ),
                      )
                    else
                      Text(
                        'Recorded on Solana ${_lastCluster ?? "localnet"}: ${_shortSig(_lastTxSignature!)}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildManageTab() {
    return RefreshIndicator(
      onRefresh: _loadVouchers,
      child: _vouchers.isEmpty
          ? const Center(child: Text('No vouchers found.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _vouchers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final v = _vouchers[i];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      v.isActive
                          ? Icons.check_circle
                          : v.isRedeemed
                              ? Icons.done_all
                              : Icons.cancel,
                      color: v.isActive
                          ? Colors.green
                          : v.isRedeemed
                              ? Colors.blue
                              : Colors.red,
                    ),
                    title: Text(v.id,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Student: ${v.studentId}'),
                    trailing: _StateChip(state: v.state),
                    onLongPress: v.isActive
                        ? () => _revokeVoucher(v.id)
                        : null,
                  ),
                );
              },
            ),
    );
  }
}

class _StateChip extends StatelessWidget {
  final String state;
  const _StateChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final color = state == 'active'
        ? Colors.green
        : state == 'redeemed'
            ? Colors.blue
            : Colors.red;
    return Chip(
      label: Text(state,
          style: TextStyle(fontSize: 11, color: color.shade700)),
      backgroundColor: color.shade50,
      side: BorderSide(color: color.shade200),
      padding: EdgeInsets.zero,
    );
  }
}
