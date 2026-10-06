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

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({required this.user, super.key});

  final AppUser user;

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  final List<Map<String, dynamic>> _dailyTasks = [
    {'title': 'सुबह का चारा व दाना वितरण', 'done': true},
    {'title': 'गौशाला शेड की धुलाई व सफाई', 'done': true},
    {'title': 'बीमार/उपचाराधीन गौवंश निरीक्षण', 'done': false},
    {'title': 'शाम का चारा, जल व सुरक्षा जांच', 'done': false},
  ];

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout करें?'),
        content: const Text('क्या आप Staff खाते से लॉगआउट करना चाहते हैं?'),
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
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
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
                  'कर्मचारी / सेवक डैशबोर्ड (Staff Portal)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC97A2E),
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
            onPressed: _logout,
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Staff Welcome Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD47C28), Color(0xFF9E5412)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFD47C28,
                          ).withValues(alpha: 0.25),
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
                                    Icons.engineering_outlined,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Staff Member',
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
                              widget.user.email,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'जय गोमाता, ${widget.user.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'दैनिक गौसेवा, चारा प्रबंधन एवं पशु देखभाल पोर्टल',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Quick Numbers
                  Row(
                    children: [
                      Expanded(
                        child: _StaffMetricTile(
                          title: 'गौवंश संख्या',
                          value: '$cowCount',
                          subtitle: 'गौशाला में दर्ज',
                          icon: Icons.pets_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StaffMetricTile(
                          title: 'स्वस्थ गौवंश',
                          value: '$healthyCount',
                          subtitle: 'सक्रिय देखभाल',
                          icon: Icons.health_and_safety_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StaffMetricTile(
                          title: 'दैनिक कार्य',
                          value:
                              '${_dailyTasks.where((t) => t['done'] == true).length}/${_dailyTasks.length}',
                          subtitle: 'आज की सूची',
                          icon: Icons.checklist_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Today's Routine Task Card
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Color(0xFFE5ECE3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: BrandConfig.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'आज की दैनिक दिनचर्या (Daily Checklist)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: BrandConfig.ink,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          for (int i = 0; i < _dailyTasks.length; i++)
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              title: Text(
                                _dailyTasks[i]['title'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: BrandConfig.ink,
                                  fontWeight: _dailyTasks[i]['done'] as bool
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  decoration: _dailyTasks[i]['done'] as bool
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              value: _dailyTasks[i]['done'] as bool,
                              activeColor: BrandConfig.primary,
                              onChanged: (val) {
                                setState(() {
                                  _dailyTasks[i]['done'] = val ?? false;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'कर्मचारी कार्य (Staff Operations)',
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
                    childAspectRatio: 1.3,
                    children: [
                      if (widget.user.hasPermission(AppPermission.cows))
                        _StaffActionTile(
                          icon: Icons.pets_rounded,
                          title: 'गौवंश देखभाल',
                          subtitle: 'रिकॉर्ड देखें व जोड़ें',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CowsScreen(),
                              ),
                            );
                          },
                        ),
                      if (widget.user.hasPermission(AppPermission.finance))
                        _StaffActionTile(
                          icon: Icons.receipt_long_rounded,
                          title: 'दैनिक खर्च',
                          subtitle: 'चारा/दवा प्रविष्टि',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const FinanceScreen(),
                              ),
                            );
                          },
                        ),
                      if (widget.user.hasPermission(AppPermission.feed))
                        _StaffActionTile(
                          icon: Icons.grass_rounded,
                          title: 'चारा व स्टॉक',
                          subtitle: 'स्टॉक प्रविष्टि',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                            );
                          },
                        ),
                      if (widget.user.hasPermission(AppPermission.volunteers))
                        _StaffActionTile(
                          icon: Icons.group_outlined,
                          title: 'सेवक उपस्थिति',
                          subtitle: 'श्रमदान व हाजिरी',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const VolunteersScreen(),
                              ),
                            );
                          },
                        ),
                      _StaffActionTile(
                        icon: Icons.notifications_active_outlined,
                        title: 'सूचनाएं',
                        subtitle: 'महत्वपूर्ण नोटिस',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NoticesScreen(),
                            ),
                          );
                        },
                      ),
                      _StaffActionTile(
                        icon: Icons.auto_awesome_rounded,
                        title: 'AI सहायक',
                        subtitle: 'चारा/स्वास्थ्य सलाह',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AiAssistantScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

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

class _StaffMetricTile extends StatelessWidget {
  const _StaffMetricTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

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
          Icon(icon, size: 20, color: const Color(0xFFC97A2E)),
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

class _StaffActionTile extends StatelessWidget {
  const _StaffActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFFFF2DF),
              child: Icon(icon, size: 19, color: const Color(0xFFC97A2E)),
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
