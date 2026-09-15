import 'package:flutter/material.dart';

import 'app_data.dart';
import 'branding/brand_config.dart';
import 'screens.dart';
import 'screens/cows_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'widgets/brand_logo.dart';

const _forest = Color(0xFF2F6B45);
const _deepForest = Color(0xFF1F4F34);
const _leaf = Color(0xFFE7F1E5);
const _saffron = Color(0xFFE58B3A);
const _ink = Color(0xFF243127);
const _muted = Color(0xFF6B756D);

enum HomeDestination {
  donation,
  gaushala,
  cows,
  gallery,
  contact,
  location,
  assistant,
  volunteers,
  finance,
  notices,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  void _openDestination(HomeDestination destination) {
    final screen = switch (destination) {
      HomeDestination.donation => const DonationScreen(),
      HomeDestination.gaushala => const CowsScreen(),
      HomeDestination.cows => const CowsScreen(),
      HomeDestination.gallery => const GalleryScreen(),
      HomeDestination.contact => const ContactScreen(),
      HomeDestination.location => const LocationScreen(),
      HomeDestination.assistant => const AiAssistantScreen(),
      HomeDestination.volunteers => const VolunteersScreen(),
      HomeDestination.finance => const FinanceScreen(),
      HomeDestination.notices => const NoticesScreen(),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _openUpdate(UpdateItem update) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UpdateDetailScreen(update: update)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedTab == 0
          ? AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              titleSpacing: 20,
              title: Row(
                children: [
                  const BrandLogo(size: 38),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      BrandConfig.committeeName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'सूचनाएं',
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('अभी कोई नई सूचना नहीं है।')),
                  ),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: _selectedTab == 0
          ? SafeArea(
              top: false,
              child: _HomeContent(
                onAction: _openDestination,
                onUpdate: _openUpdate,
              ),
            )
          : _tabScreens[_selectedTab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        backgroundColor: Colors.white,
        indicatorColor: _leaf,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'होम',
          ),
          NavigationDestination(
            icon: Icon(Icons.grass_outlined),
            selectedIcon: Icon(Icons.grass),
            label: 'गौशाला',
          ),
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined),
            selectedIcon: Icon(Icons.volunteer_activism),
            label: 'दान',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'प्रोडक्ट्स',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'प्रोफाइल',
          ),
        ],
      ),
    );
  }
}

const _tabScreens = [
  SizedBox.shrink(),
  CowsScreen(),
  DonationScreen(),
  ProductsScreen(),
  ProfileScreen(),
];

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.onAction, required this.onUpdate});

  final ValueChanged<HomeDestination> onAction;
  final ValueChanged<UpdateItem> onUpdate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth > 600 ? 40.0 : 20.0;
        return AnimatedBuilder(
          animation: LocalGoshalaStore.instance,
          builder: (context, _) {
            final store = LocalGoshalaStore.instance;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                4,
                horizontalPadding,
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroBanner(
                    onDonate: () => onAction(HomeDestination.donation),
                  ),
                  const SizedBox(height: 14),
                  _WelcomeStatusCard(store: store),
                  const SizedBox(height: 14),
                  _AiServiceCard(
                    onTap: () => onAction(HomeDestination.assistant),
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(title: 'लाइव गौशाला आँकड़े'),
                  const SizedBox(height: 12),
                  _StatsGrid(store: store),
                  const SizedBox(height: 28),
                  const _SectionTitle(title: 'आज की सेवा'),
                  const SizedBox(height: 12),
                  _TodayTasksCard(store: store),
                  const SizedBox(height: 28),
                  const _SectionTitle(title: 'त्वरित कार्य'),
                  const SizedBox(height: 12),
                  _QuickActions(onAction: onAction),
                  const SizedBox(height: 28),
                  const _SectionTitle(title: 'हाल की गतिविधियाँ'),
                  const SizedBox(height: 12),
                  _RecentActivityList(store: store),
                  const SizedBox(height: 28),
                  const _SectionTitle(title: 'गौ सेवा के प्रमुख कार्य'),
                  const SizedBox(height: 12),
                  const _SevaGrid(),
                  const SizedBox(height: 28),
                  _DonationBanner(
                    onDonate: () => onAction(HomeDestination.donation),
                  ),
                  const SizedBox(height: 30),
                  const _SectionTitle(title: 'नवीनतम जानकारी'),
                  const SizedBox(height: 12),
                  _UpdatesList(onUpdate: onUpdate),
                  const SizedBox(height: 28),
                  _ContactCard(onAction: onAction),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onDonate});

  final VoidCallback onDonate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _deepForest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A1F4F34),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  BrandConfig.hindiCommitteeName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  BrandConfig.tagline,
                  style: TextStyle(
                    color: Color(0xFFD9E8D4),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'गौमाता की सेवा में आपका सहयोग हमारे लिए अमूल्य है।',
                  style: TextStyle(color: Color(0xFFD9E8D4), height: 1.4),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onDonate,
                  icon: const Icon(Icons.volunteer_activism_outlined, size: 18),
                  label: const Text('अभी दान करें'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _saffron,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(flex: 2, child: BrandLogo(size: 132)),
        ],
      ),
    );
  }
}

class _AiServiceCard extends StatelessWidget {
  const _AiServiceCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: BrandConfig.leaf,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            const BrandLogo(size: 48),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI गौसेवा सहायक',
                    style: TextStyle(
                      color: BrandConfig.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'आज के काम, संदेश और reports एक जगह बनाएं',
                    style: TextStyle(color: BrandConfig.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: BrandConfig.primary),
          ],
        ),
      ),
    ),
  );
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.store});

  final LocalGoshalaStore store;

  @override
  Widget build(BuildContext context) {
    final underTreatment = (store.cows.length - store.healthyCows).clamp(
      0,
      999999,
    );
    final stats = [
      ('कुल गौवंश', '${store.cows.length}', Icons.pets_outlined),
      ('स्वस्थ गौवंश', '${store.healthyCows}', Icons.favorite_outline_rounded),
      ('उपचाराधीन', '$underTreatment', Icons.medical_services_outlined),
      ('आज आए गौवंश', '0', Icons.calendar_today_outlined),
      ('आज का चारा', '0', Icons.grass_rounded),
      ('आज की चिकित्सा', '0', Icons.health_and_safety_outlined),
      ('आज का दान', '₹${store.income}', Icons.volunteer_activism_outlined),
      (
        'आज का खर्च',
        '₹${store.expense}',
        Icons.account_balance_wallet_outlined,
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        mainAxisExtent: 118,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) => _StatCard(
        label: stats[index].$1,
        value: stats[index].$2,
        icon: stats[index].$3,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _forest, size: 22),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onAction});

  final ValueChanged<HomeDestination> onAction;

  @override
  Widget build(BuildContext context) {
    const actions = [
      ('गौ जोड़ें', Icons.pets_outlined, HomeDestination.cows),
      ('चारा दर्ज करें', Icons.grass_rounded, HomeDestination.gaushala),
      (
        'स्वास्थ्य रिकॉर्ड',
        Icons.medical_services_outlined,
        HomeDestination.cows,
      ),
      (
        'दान दर्ज करें',
        Icons.volunteer_activism_outlined,
        HomeDestination.donation,
      ),
      ('खर्च दर्ज करें', Icons.receipt_long_outlined, HomeDestination.finance),
      ('AI गौसेवा', Icons.auto_awesome_outlined, HomeDestination.assistant),
      ('श्रमदान', Icons.groups_outlined, HomeDestination.volunteers),
      ('सूचनाएं', Icons.campaign_outlined, HomeDestination.notices),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        mainAxisExtent: 86,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onAction(action.$3),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE7ECE4)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _leaf,
                  foregroundColor: _forest,
                  child: Icon(action.$2, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    action.$1,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SevaGrid extends StatelessWidget {
  const _SevaGrid();

  @override
  Widget build(BuildContext context) {
    const seva = [
      ('चारा सेवा', Icons.grass_rounded),
      ('पानी की व्यवस्था', Icons.water_drop_outlined),
      ('चिकित्सा सेवा', Icons.medical_services_outlined),
      ('गौ संरक्षण', Icons.shield_outlined),
      ('स्वच्छता सेवा', Icons.cleaning_services_outlined),
    ];
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: seva.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => Container(
          width: 142,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _leaf,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(seva[index].$2, color: _forest, size: 26),
              Text(
                seva[index].$1,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeStatusCard extends StatelessWidget {
  const _WelcomeStatusCard({required this.store});

  final LocalGoshalaStore store;

  @override
  Widget build(BuildContext context) {
    final pendingTasks = [
      store.checklist['चारा'] == true ? 'Completed' : 'Pending',
      store.checklist['पानी'] == true ? 'Completed' : 'Pending',
      store.checklist['सफाई'] == true ? 'Completed' : 'Pending',
      store.checklist['चिकित्सा'] == true ? 'Completed' : 'Pending',
    ].where((status) => status == 'Pending').length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7ECE4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'आज की गौसेवा स्थिति',
                  style: TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pendingTasks == 0
                      ? 'आज की सभी सेवा गतिविधियाँ पूर्ण हैं।'
                      : 'आज $pendingTasks कार्य अभी लंबित हैं।',
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _leaf,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: _forest),
                const SizedBox(width: 8),
                Text(
                  '${store.completedChecklist}/4',
                  style: const TextStyle(
                    color: _forest,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayTasksCard extends StatelessWidget {
  const _TodayTasksCard({required this.store});

  final LocalGoshalaStore store;

  @override
  Widget build(BuildContext context) {
    final tasks = [
      ('चारा देना', store.checklist['चारा'] ?? false),
      ('पानी की व्यवस्था', store.checklist['पानी'] ?? false),
      ('गौशाला सफाई', store.checklist['सफाई'] ?? false),
      ('स्वास्थ्य जांच', store.checklist['चिकित्सा'] ?? false),
      ('दवा / उपचार', false),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7ECE4)),
      ),
      child: Column(
        children: tasks.map((task) {
          final isCompleted = task.$2;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCompleted ? _leaf : const Color(0xFFF6F4F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.pending_actions_outlined,
                    size: 18,
                    color: isCompleted ? _forest : _muted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.$1,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  isCompleted ? 'Completed' : 'Pending',
                  style: TextStyle(
                    color: isCompleted ? _forest : _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList({required this.store});

  final LocalGoshalaStore store;

  @override
  Widget build(BuildContext context) {
    final activities = <_ActivityItem>[];

    if (store.cows.isNotEmpty) {
      activities.add(
        _ActivityItem(
          title: 'नई गाय जोड़ी गई',
          subtitle: '${store.cows.length} गौवंश अब रजिस्टर में हैं।',
          icon: Icons.pets_outlined,
        ),
      );
    }

    if (store.donors.isNotEmpty) {
      final latestDonor = store.donors.last;
      activities.add(
        _ActivityItem(
          title: 'दान प्राप्त हुआ',
          subtitle: '${latestDonor.name} ने ₹${latestDonor.amount} दिया।',
          icon: Icons.volunteer_activism_outlined,
        ),
      );
    }

    if (store.ledger.isNotEmpty) {
      final latest = store.ledger.first;
      activities.add(
        _ActivityItem(
          title: latest.isIncome ? 'दान दर्ज हुआ' : 'खर्च दर्ज हुआ',
          subtitle: '${latest.title} • ₹${latest.amount}',
          icon: latest.isIncome
              ? Icons.trending_up_outlined
              : Icons.trending_down_outlined,
        ),
      );
    }

    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7ECE4)),
        ),
        child: const Text(
          'अभी कोई गतिविधि उपलब्ध नहीं है',
          style: TextStyle(color: _muted),
        ),
      );
    }

    return Column(
      children: activities
          .map(
            (activity) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE7ECE4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _leaf,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(activity.icon, size: 18, color: _forest),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activity.subtitle,
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

class _DonationBanner extends StatelessWidget {
  const _DonationBanner({required this.onDonate});

  final VoidCallback onDonate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0DD),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF5D3A7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite_rounded, color: _saffron, size: 28),
          const SizedBox(height: 12),
          Text(
            'गौ सेवा में अपना योगदान दें',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'आपका छोटा सा सहयोग भी किसी गौमाता के भोजन, चिकित्सा और देखभाल में काम आ सकता है।',
            style: TextStyle(color: _muted, height: 1.45),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onDonate,
            icon: const Icon(Icons.volunteer_activism_outlined, size: 18),
            label: const Text('दान करें'),
            style: FilledButton.styleFrom(backgroundColor: _forest),
          ),
        ],
      ),
    );
  }
}

class _UpdatesList extends StatelessWidget {
  const _UpdatesList({required this.onUpdate});

  final ValueChanged<UpdateItem> onUpdate;

  @override
  Widget build(BuildContext context) {
    const updates = [
      UpdateItem(
        title: 'गौशाला में नई सेवा व्यवस्था',
        description: 'सेवा कार्य को और व्यवस्थित बनाने के लिए नई पहल।',
        icon: Icons.campaign_outlined,
      ),
      UpdateItem(
        title: 'चारा सेवा अभियान',
        description: 'गौमाता के लिए पौष्टिक चारे की विशेष व्यवस्था।',
        icon: Icons.eco_outlined,
      ),
      UpdateItem(
        title: 'गौ चिकित्सा शिविर',
        description: 'नियमित स्वास्थ्य जांच और चिकित्सा परामर्श।',
        icon: Icons.medical_services_outlined,
      ),
    ];
    return Column(
      children: updates
          .map(
            (update) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onUpdate(update),
                child: Ink(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE7ECE4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _leaf,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(update.icon, color: _forest),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              update.title,
                              style: const TextStyle(
                                color: _ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              update.description,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: _muted),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.onAction});

  final ValueChanged<HomeDestination> onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _deepForest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            BrandConfig.committeeName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          const _ContactLine(
            icon: Icons.phone_outlined,
            text: BrandConfig.phone,
          ),
          const _ContactLine(
            icon: Icons.location_on_outlined,
            text: BrandConfig.address,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ContactButton(
                label: 'कॉल करें',
                icon: Icons.phone_outlined,
                onPressed: () => onAction(HomeDestination.contact),
              ),
              _ContactButton(
                label: 'WhatsApp',
                icon: Icons.chat_outlined,
                onPressed: () => onAction(HomeDestination.contact),
              ),
              _ContactButton(
                label: 'स्थान देखें',
                icon: Icons.location_on_outlined,
                onPressed: () => onAction(HomeDestination.location),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFB8D7A6)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFFD9E8D4), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0x66FFFFFF)),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: _ink,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
