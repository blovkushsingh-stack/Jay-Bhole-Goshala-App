import 'package:flutter/material.dart';

import '../../branding/brand_config.dart';
import '../../home_screen.dart';
import '../../models/app_user.dart';
import '../../screens.dart';
import '../../services/firebase_backend.dart';
import '../../widgets/brand_logo.dart';
import '../ai_assistant_screen.dart';
import '../cows_screen.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({required this.user, super.key});

  final AppUser user;

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout करें?'),
        content: const Text('क्या आप अपने खाते से लॉगआउट करना चाहते हैं?'),
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

  @override
  Widget build(BuildContext context) {
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
                  'श्रद्धालु / उपयोगकर्ता पोर्टल (User Portal)',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Welcome Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [BrandConfig.primary, Color(0xFF1B4E32)],
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
                                Icons.person_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'श्रद्धालु / User',
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
                      'गावो विश्वस्य मातरः — गौमाता की सेवा ही परमात्मा की सेवा है।',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Devotee Actions
              const Text(
                'गौसेवा सुविधाएं (Devotee Services)',
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
                  _UserActionTile(
                    icon: Icons.volunteer_activism_rounded,
                    title: 'गौ-सेवा दान',
                    subtitle: 'ऑनलाइन दान व सहयोग',
                    color: const Color(0xFFC97A2E),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DonationScreen(),
                        ),
                      );
                    },
                  ),
                  _UserActionTile(
                    icon: Icons.pets_rounded,
                    title: 'गौ दर्शन',
                    subtitle: 'गौवंश की जानकारी',
                    color: BrandConfig.primary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CowsScreen()),
                      );
                    },
                  ),
                  _UserActionTile(
                    icon: Icons.photo_library_outlined,
                    title: 'गौशाला गैलरी',
                    subtitle: 'छायाचित्र व दर्शन',
                    color: const Color(0xFF2C6BB3),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const GalleryScreen(),
                        ),
                      );
                    },
                  ),
                  _UserActionTile(
                    icon: Icons.handshake_outlined,
                    title: 'स्वयंसेवक सेवा',
                    subtitle: 'गौसेवा दल से जुड़ें',
                    color: const Color(0xFF7A4DB3),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const VolunteersScreen(),
                        ),
                      );
                    },
                  ),
                  _UserActionTile(
                    icon: Icons.place_outlined,
                    title: 'स्थान व संपर्क',
                    subtitle: 'गौशाला दर्शन मार्ग',
                    color: const Color(0xFF388E3C),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LocationScreen(),
                        ),
                      );
                    },
                  ),
                  _UserActionTile(
                    icon: Icons.auto_awesome_rounded,
                    title: 'AI गौ-सहायक',
                    subtitle: 'गौमाता व समिति के प्रश्न',
                    color: const Color(0xFFD35400),
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
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const HomeScreen()));
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
        ),
      ),
    );
  }
}

class _UserActionTile extends StatelessWidget {
  const _UserActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
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
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, size: 20, color: color),
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
