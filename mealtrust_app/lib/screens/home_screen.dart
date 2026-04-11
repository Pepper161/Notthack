import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/auth_service.dart';
import '../widgets/nourish_components.dart';
import 'auditor_screen.dart';
import 'issuer_screen.dart';
import 'login_screen.dart';
import 'merchant_screen.dart';
import 'student_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _tabs = <_HomeTab>[
    _HomeTab('Home', LucideIcons.layoutDashboard),
    _HomeTab('Issuer', LucideIcons.badgePlus),
    _HomeTab('Student', Icons.badge_outlined),
    _HomeTab('Merchant', LucideIcons.scanLine),
    _HomeTab('Auditor', Icons.history_edu),
  ];

  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = _roleToIndex(AuthService.instance.role);
  }

  int _roleToIndex(String? role) {
    switch (role) {
      case 'issuer':
        return 1;
      case 'student':
        return 2;
      case 'merchant':
        return 3;
      case 'auditor':
        return 4;
      default:
        return 0;
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Widget _pageFor(int index) {
    switch (index) {
      case 1:
        return const IssuerScreen();
      case 2:
        return const StudentScreen();
      case 3:
        return const MerchantScreen();
      case 4:
        return const AuditorScreen();
      default:
        return const _OverviewPane();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    if (!auth.isLoggedIn) return const LoginScreen();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1120;
        return Scaffold(
          backgroundColor: NourishColors.cream,
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isWide) _DesktopRail(
                  index: _index,
                  tabs: _tabs,
                  onChanged: (next) => setState(() => _index = next),
                  onLogout: () => _logout(context),
                  roleLabel: auth.displayName ?? auth.email ?? 'Signed in',
                ),
                Expanded(
                  child: Column(
                    children: [
                      _TopBar(
                        currentTab: _tabs[_index],
                        onLogout: () => _logout(context),
                        roleLabel: auth.displayName ?? auth.email ?? 'Signed in',
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: KeyedSubtree(
                            key: ValueKey(_index),
                            child: _pageFor(_index),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (next) => setState(() => _index = next),
                  destinations: const [
                    NavigationDestination(icon: Icon(LucideIcons.layoutDashboard), label: 'Home'),
                    NavigationDestination(icon: Icon(LucideIcons.badgePlus), label: 'Issuer'),
                    NavigationDestination(icon: Icon(Icons.badge_outlined), label: 'Student'),
                    NavigationDestination(icon: Icon(LucideIcons.scanLine), label: 'Merchant'),
                    NavigationDestination(icon: Icon(Icons.history_edu), label: 'Auditor'),
                  ],
                ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final _HomeTab currentTab;
  final VoidCallback onLogout;
  final String roleLabel;

  const _TopBar({
    required this.currentTab,
    required this.onLogout,
    required this.roleLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.64),
        border: const Border(
          bottom: BorderSide(color: Color(0x1A17332D)),
        ),
      ),
      child: Row(
        children: [
          const NourishBrandMark(size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NourishChain',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: NourishColors.ink,
                  ),
                ),
                Text(
                  roleLabel,
                  style: const TextStyle(
                    color: NourishColors.slate,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          NourishPill(
            label: currentTab.label,
            icon: currentTab.icon,
            background: const Color(0x113D6DE1),
            foreground: NourishColors.blue,
            borderColor: const Color(0x223D6DE1),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            tooltip: 'Sign out',
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}

class _DesktopRail extends StatelessWidget {
  final int index;
  final List<_HomeTab> tabs;
  final ValueChanged<int> onChanged;
  final VoidCallback onLogout;
  final String roleLabel;

  const _DesktopRail({
    required this.index,
    required this.tabs,
    required this.onChanged,
    required this.onLogout,
    required this.roleLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 332,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF9F6EF), Color(0xFFF2EEDF)],
        ),
        border: Border(
          right: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: NourishHeaderPanel(
              roleLabel: 'NourishChain',
              headline: 'Choose a role, then tell the trust story.',
              body:
                  'The shell separates issuer, student, merchant, and auditor into distinct work surfaces so the demo can feel like a real system instead of a single page.',
              badges: const [
                NourishPill(
                  label: 'Wallet-free UX',
                  icon: LucideIcons.shield,
                  background: Color(0x14FFFFFF),
                  foreground: Colors.white,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _RailCard(
              title: 'Current session',
              subtitle: roleLabel,
              icon: LucideIcons.userCircle2,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RailDestination(
                      selected: index == i,
                      tab: tabs[i],
                      onTap: () => onChanged(i),
                    ),
                  ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Demo sequence',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: NourishColors.slate,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const _RailStep(label: '1. Issuer seeds or issues'),
                const _RailStep(label: '2. Student shows QR only'),
                const _RailStep(label: '3. Merchant verifies and redeems'),
                const _RailStep(label: '4. Duplicate attempt is blocked'),
                const _RailStep(label: '5. Auditor inspects history'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(LucideIcons.logOut, size: 18),
              label: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _RailCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1A17332D)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: NourishColors.ink,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: NourishColors.ink,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: NourishColors.slate,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RailDestination extends StatelessWidget {
  final bool selected;
  final _HomeTab tab;
  final VoidCallback onTap;

  const _RailDestination({
    required this.selected,
    required this.tab,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? const Color(0x2217332D)
                : Colors.transparent,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? NourishColors.ink
                    : const Color(0x1A17332D),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                tab.icon,
                color: selected ? Colors.white : NourishColors.slate,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tab.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: selected ? NourishColors.ink : NourishColors.slate,
                ),
              ),
            ),
            if (selected)
              const Icon(LucideIcons.chevronRight, size: 18, color: NourishColors.ink),
          ],
        ),
      ),
    );
  }
}

class _RailStep extends StatelessWidget {
  final String label;

  const _RailStep({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          color: NourishColors.slate,
          height: 1.3,
        ),
      ),
    );
  }
}

class _HomeTab {
  final String label;
  final IconData icon;

  const _HomeTab(this.label, this.icon);
}

class _OverviewPane extends StatelessWidget {
  const _OverviewPane();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NourishHeaderPanel(
            roleLabel: 'NourishChain overview',
            headline: 'One trust layer. Four roles. Zero wallets.',
            body:
                'The interface is organized like a control room: Student Affairs issues and revokes, the student shows a pass, the cashier redeems, and finance audits the same history.',
            badges: const [
              NourishPill(
                label: 'Switch-style role hub',
                icon: LucideIcons.switchCamera,
                background: Color(0x14FFFFFF),
                foreground: Colors.white,
              ),
              NourishPill(
                label: 'Localnet live',
                icon: LucideIcons.link,
                background: Color(0x14FFFFFF),
                foreground: Colors.white,
              ),
            ],
            trailing: const Icon(LucideIcons.squareStack, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              SizedBox(
                width: 184,
                child: NourishMetricCard(
                  label: 'roles',
                  value: '4',
                  accent: NourishColors.green,
                  icon: Icons.layers_outlined,
                ),
              ),
              SizedBox(
                width: 184,
                child: NourishMetricCard(
                  label: 'student wallet',
                  value: '0',
                  accent: NourishColors.blue,
                  icon: LucideIcons.walletCards,
                ),
              ),
              SizedBox(
                width: 184,
                child: NourishMetricCard(
                  label: 'shared trust state',
                  value: '1 layer',
                  accent: NourishColors.gold,
                  icon: LucideIcons.shieldCheck,
                ),
              ),
              SizedBox(
                width: 184,
                child: NourishMetricCard(
                  label: 'local chain',
                  value: 'live',
                  accent: NourishColors.violet,
                  icon: LucideIcons.link,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final cards = const [
                _OverviewCard(
                  title: 'Issuer / Student Affairs',
                  subtitle: 'Issue, revoke, override',
                  body:
                      'Manage voucher issuance, revoke eligibility when it changes, and log appeal decisions as explicit overrides.',
                  icon: LucideIcons.badgePlus,
                  accent: NourishColors.green,
                ),
                _OverviewCard(
                  title: 'Student / Beneficiary',
                  subtitle: 'Wallet-free QR pass',
                  body:
                      'Show a pass, not a wallet. The student surface is calm, minimal, and focused on one thing: being eligible and visible.',
                  icon: Icons.badge_outlined,
                  accent: NourishColors.blue,
                ),
                _OverviewCard(
                  title: 'Merchant / Cafeteria',
                  subtitle: 'Scan, verify, redeem',
                  body:
                      'Scan first, verify second, redeem once. A second attempt is blocked and shown clearly to the cashier.',
                  icon: LucideIcons.scanLine,
                  accent: NourishColors.gold,
                ),
                _OverviewCard(
                  title: 'Auditor / Finance',
                  subtitle: 'History and checkpoints',
                  body:
                      'See the same event trail and the same on-chain / off-chain markers that explain what happened and when.',
                  icon: Icons.history_edu,
                  accent: NourishColors.violet,
                ),
              ];

              return GridView.count(
                crossAxisCount: wide ? 2 : 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: wide ? 1.95 : 1.45,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: cards,
              );
            },
          ),
          const SizedBox(height: 18),
          NourishActionCard(
            title: 'Demo sequence',
            body:
                'The live story is intentionally narrow: seed or issue, show QR, redeem at CAF-A, attempt again at CAF-B, then inspect the audit log.',
            child: Column(
              children: const [
                _TimelineRow(step: '1', label: 'Issuer issues or seeds a voucher.'),
                _TimelineRow(step: '2', label: 'Student shows a wallet-free QR pass.'),
                _TimelineRow(step: '3', label: 'Merchant verifies and redeems once.'),
                _TimelineRow(step: '4', label: 'Second attempt is blocked across merchants.'),
                _TimelineRow(step: '5', label: 'Auditor sees the same history.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String step;
  final String label;

  const _TimelineRow({required this.step, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: NourishColors.ink,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                label,
                style: const TextStyle(
                  color: NourishColors.ink,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String body;
  final IconData icon;
  final Color accent;

  const _OverviewCard({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0x1A17332D)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: NourishColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.6,
                        color: NourishColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(
              color: NourishColors.ink,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
