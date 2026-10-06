import 'package:flutter/material.dart';

import '../../app_data.dart';
import '../../branding/brand_config.dart';
import '../../home_screen.dart';
import '../../models/app_user.dart';
import '../../screens.dart';
import '../../services/firebase_backend.dart';
import '../../widgets/brand_logo.dart';
import '../ai_assistant_screen.dart';
import '../cows_screen.dart';
import '../staff_management_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({required this.user, super.key});

  final AppUser user;

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout करें?'),
        content: const Text(
          'क्या आप व्यवस्थापक खाते से लॉगआउट करना चाहते हैं?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('रद्द करें'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseBackend.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _runPhotoMigration(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('फोटो माइग्रेशन शुरू करें?'),
        content: const Text(
          'यह प्रक्रिया Firestore में मौजूद पुरानी बड़ी Base64 फोटो को Firebase Storage में सुरक्षित रूप से ट्रांसफर करेगी और डेटाबेस का आकार हल्का करेगी ताकि CursorWindow ओवरफ्लो न हो।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('रद्द करें'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('माइग्रेशन शुरू करें'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('फोटो माइग्रेशन चल रहा है, कृपया प्रतीक्षा करें...'),
        duration: Duration(seconds: 3),
      ),
    );

    try {
      final count = await LocalGoshalaStore.instance.migrateLegacyCowPhotos();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count > 0
                  ? 'सफलतापूर्वक $count रिकॉर्ड्स को Firebase Storage में माइग्रेट किया गया।'
                  : 'सभी रिकॉर्ड्स पहले से ही अनुकूलित हैं (0 माइग्रेशन आवश्यक)।',
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('माइग्रेशन त्रुटि: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = LocalGoshalaStore.instance;

    return Scaffold(
      backgroundColor: BrandConfig.cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        title: Row(
          children: [
            const BrandLogo(size: 34),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  BrandConfig.committeeName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: BrandConfig.ink,
                  ),
                ),
                const Text(
                  'व्यवस्थापक डैशबोर्ड (Admin Portal)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: BrandConfig.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'मुख्य ऐप देखें',
            icon: const Icon(Icons.home_outlined),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const HomeScreen()));
            },
          ),
          IconButton(
            tooltip: 'लॉगआउट',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _logout(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final cowCount = store.cows.length;
            final healthyCount = store.healthyCows;
            final balance = store.income - store.expense;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin Welcome Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [BrandConfig.primary, Color(0xFF1E462F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: BrandConfig.primary.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.admin_panel_settings_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Admin Access',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              user.email,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'प्रणाम, ${user.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'गौशाला का पूर्ण नियंत्रण एवं प्रशासनिक प्रबंधन',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Quick Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'कुल गौवंश',
                          value: '$cowCount',
                          subtitle: '$healthyCount स्वस्थ',
                          icon: Icons.pets_rounded,
                          color: BrandConfig.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'मासिक शेष',
                          value: '₹$balance',
                          subtitle: 'आय - व्यय',
                          icon: Icons.account_balance_wallet_outlined,
                          color: const Color(0xFFC97A2E),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'दैनिक Checklist',
                          value: '${store.completedChecklist}/4',
                          subtitle: 'पूर्ण कार्य',
                          icon: Icons.task_alt_rounded,
                          color: const Color(0xFF2C6BB3),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'व्यवस्थापकीय मॉड्यूल (Admin Management)',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: BrandConfig.ink,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: [
                      _AdminActionTile(
                        icon: Icons.badge_outlined,
                        title: 'कर्मचारी प्रबंधन',
                        subtitle: 'Staff Management',
                        badgeText: 'Admin Only',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AdminGate(
                                child: StaffManagementScreen(),
                              ),
                            ),
                          );
                        },
                      ),
                      _AdminActionTile(
                        icon: Icons.pets_rounded,
                        title: 'गौवंश रिकॉर्ड्स',
                        subtitle: 'Cows Registry',
                        badgeText: 'प्रबंधन',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CowsScreen(),
                            ),
                          );
                        },
                      ),
                      _AdminActionTile(
                        icon: Icons.account_balance_rounded,
                        title: 'वित्तीय लेखा-जोखा',
                        subtitle: 'Finance & Accounts',
                        badgeText: 'ऑडिट',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const FinanceScreen(),
                            ),
                          );
                        },
                      ),
                      _AdminActionTile(
                        icon: Icons.volunteer_activism_rounded,
                        title: 'दान प्रबंधन',
                        subtitle: 'Donations & Receipts',
                        badgeText: 'रसीद',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DonationScreen(),
                            ),
                          );
                        },
                      ),
                      _AdminActionTile(
                        icon: Icons.settings_suggest_rounded,
                        title: 'समिति सेटिंग्स',
                        subtitle: 'System & Branding',
                        badgeText: 'Settings',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AdminGate(child: SettingsScreen()),
                            ),
                          );
                        },
                      ),
                      _AdminActionTile(
                        icon: Icons.auto_awesome_rounded,
                        title: 'गौशाला AI सहायक',
                        subtitle: 'Smart Assistant',
                        badgeText: 'AI',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AiAssistantScreen(),
                            ),
                          );
                        },
                      ),
                      _AdminActionTile(
                        icon: Icons.cloud_sync_rounded,
                        title: 'फोटो माइग्रेशन',
                        subtitle: 'DB Optimization',
                        badgeText: 'Storage',
                        onTap: () => _runPhotoMigration(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Public Screen Shortcut Button
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    },
                    icon: const Icon(Icons.open_in_browser_rounded),
                    label: const Text(
                      'सार्वजनिक मुख्य स्क्रीन देखें (Public View)',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5ECE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: BrandConfig.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: BrandConfig.muted),
          ),
        ],
      ),
    );
  }
}

class _AdminActionTile extends StatelessWidget {
  const _AdminActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5ECE3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: BrandConfig.leaf,
                  child: Icon(icon, size: 19, color: BrandConfig.primary),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6EF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: BrandConfig.primary,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: BrandConfig.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: BrandConfig.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
