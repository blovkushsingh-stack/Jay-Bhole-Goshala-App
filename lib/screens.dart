import 'package:flutter/material.dart';

import 'app_data.dart';
import 'branding/brand_config.dart';
import 'models/app_user.dart';
import 'screens/auth_screen.dart';
import 'screens/staff_management_screen.dart';
import 'services/firebase_backend.dart';
import 'widgets/brand_logo.dart';

const _forest = Color(0xFF2F6B45);
const _deepForest = Color(0xFF1F4F34);
const _leaf = Color(0xFFE7F1E5);
const _saffron = Color(0xFFE58B3A);
const _ink = Color(0xFF243127);
const _muted = Color(0xFF6B756D);

class UpdateItem {
  const UpdateItem({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class SecondaryScaffold extends StatelessWidget {
  const SecondaryScaffold({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const BrandLogo(size: 32),
            const SizedBox(width: 9),
            Flexible(child: Text(title)),
          ],
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: child,
        ),
      ),
    );
  }
}

class GaushalaScreen extends StatelessWidget {
  const GaushalaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SecondaryScaffold(
      title: 'गौशाला',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IntroCard(
            eyebrow: 'गौशाला परिचय',
            title: BrandConfig.committeeName,
            text:
                'यह जानकारी अभी नमूना रूप में है। वास्तविक समिति जानकारी बाद में यहां जोड़ी जा सकती है।',
            icon: Icons.pets_rounded,
          ),
          const SizedBox(height: 20),
          const _PageHeading(title: 'उद्देश्य'),
          const SizedBox(height: 10),
          const _TextPanel(
            text:
                'गौमाता की सेवा, संरक्षण और सम्मान के साथ समाज में सेवा भावना को मजबूत करना हमारा प्रमुख उद्देश्य है।',
          ),
          const SizedBox(height: 24),
          const _PageHeading(title: 'गौ सेवा के कार्य'),
          const SizedBox(height: 10),
          const _ServiceList(
            items: [
              (
                'चारा व्यवस्था',
                'गौवंश के लिए पौष्टिक चारे की नियमित व्यवस्था।',
                Icons.grass_rounded,
              ),
              (
                'पानी व्यवस्था',
                'स्वच्छ और पर्याप्त पेयजल की देखभाल।',
                Icons.water_drop_outlined,
              ),
              (
                'चिकित्सा सेवा',
                'स्वास्थ्य जांच और जरूरत के अनुसार उपचार।',
                Icons.medical_services_outlined,
              ),
              (
                'गौ संरक्षण',
                'असहाय और जरूरतमंद गौवंश की सुरक्षित देखभाल।',
                Icons.shield_outlined,
              ),
              (
                'स्वच्छता व्यवस्था',
                'गौशाला परिसर की नियमित सफाई और स्वच्छता।',
                Icons.cleaning_services_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _PageHeading(title: 'गौशाला की basic information'),
          const SizedBox(height: 10),
          _DetailsPanel(
            rows: [
              ('समिति', BrandConfig.hindiCommitteeName),
              ('स्थान', BrandConfig.address),
              ('सेवा समय', '24 घंटे सेवा'),
              ('स्थिति', 'जानकारी जल्द अपडेट होगी'),
            ],
          ),
        ],
      ),
    );
  }
}

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final _customAmountController = TextEditingController();
  final _donorNameController = TextEditingController();
  final _donorMobileController = TextEditingController();
  int? _selectedAmount;

  @override
  void dispose() {
    _customAmountController.dispose();
    _donorNameController.dispose();
    _donorMobileController.dispose();
    super.dispose();
  }

  void _selectAmount(int amount) {
    setState(() {
      _selectedAmount = amount;
      _customAmountController.clear();
    });
  }

  void _showUnavailableMessage() {
    final amount =
        _selectedAmount ?? int.tryParse(_customAmountController.text);
    if (amount == null ||
        amount <= 0 ||
        _donorNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('नाम और मान्य दान राशि दर्ज करें।')),
      );
      return;
    }
    LocalGoshalaStore.instance.addPendingDonation(
      name: _donorNameController.text.trim(),
      mobile: _donorMobileController.text.trim(),
      amount: amount,
    );
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            BrandLogo(size: 38),
            SizedBox(width: 10),
            Expanded(child: Text('दान receipt')),
          ],
        ),
        content: Text(
          '${BrandConfig.hindiCommitteeName}\n\n'
          'दाता: ${_donorNameController.text.trim()}\n'
          'राशि: ₹$amount\n\n'
          'यह स्थानीय receipt draft है। भुगतान gateway और UPI verification '
          'अभी उपलब्ध नहीं हैं।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('बंद करें'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SecondaryScaffold(
      title: 'दान',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _IntroCard(
            eyebrow: 'सेवा का अवसर',
            title: 'गौ सेवा में अपना योगदान दें',
            text:
                'आपका छोटा सा सहयोग भी किसी गौमाता के भोजन, चिकित्सा और देखभाल में काम आ सकता है।',
            icon: Icons.volunteer_activism_rounded,
          ),
          const SizedBox(height: 24),
          const _PageHeading(title: 'दान राशि चुनें'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [51, 101, 251, 501, 1100]
                .map(
                  (amount) => ChoiceChip(
                    label: Text('₹$amount'),
                    selected: _selectedAmount == amount,
                    onSelected: (_) => _selectAmount(amount),
                    selectedColor: _leaf,
                    labelStyle: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _customAmountController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() => _selectedAmount = null),
            decoration: const InputDecoration(
              labelText: 'अपनी राशि दर्ज करें',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _donorNameController,
            decoration: const InputDecoration(labelText: 'दाता का नाम'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _donorMobileController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'मोबाइल नंबर (वैकल्पिक)',
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _showUnavailableMessage,
              icon: const Icon(Icons.volunteer_activism_outlined),
              label: const Text('दान करें'),
              style: FilledButton.styleFrom(
                backgroundColor: _forest,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Receipt draft स्थानीय रूप से बनेगा; payment gateway और UPI verification बाद में जोड़े जाएंगे।',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = LocalGoshalaStore.instance.products;
    return SecondaryScaffold(
      title: 'प्रोडक्ट्स',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PageHeading(title: 'गौशाला से जुड़े उत्पाद'),
          const SizedBox(height: 8),
          const Text(
            'कीमत और stock स्थानीय रिकॉर्ड से दिख रहे हैं। order confirmation के लिए संपर्क करें।',
            style: TextStyle(color: _muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          ...products.map((product) => _ProductCard(product: product)),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final ProductRecord product;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE4)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _leaf,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(product.icon, color: _forest, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  product.description,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '₹${product.price}  ·  stock ${product.stock}',
                  style: TextStyle(
                    color: _saffron,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'जानकारी देखें',
            onPressed: () =>
                _showMessage(context, 'Order/contact सुविधा जल्द उपलब्ध होगी।'),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final committee = LocalGoshalaStore.instance.committee;
    return SecondaryScaffold(
      title: 'प्रोफाइल',
      child: StreamBuilder<AppUser?>(
        stream: FirebaseBackend.instance.userProfileChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          final isLoggedIn = user != null;
          final role = user?.role ?? UserRole.viewer;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isLoggedIn) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE0E8DE)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: role.isAdmin
                            ? _forest
                            : (role.isStaff ? _saffron : _deepForest),
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                color: _ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: role.isAdmin
                                    ? _leaf
                                    : (role.isStaff
                                          ? const Color(0xFFFFF1DC)
                                          : const Color(0xFFEAEAEA)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                role.label,
                                style: TextStyle(
                                  color: role.isAdmin
                                      ? _forest
                                      : (role.isStaff ? _saffron : _ink),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _IntroCard(
                eyebrow: 'समिति जानकारी',
                title: committee.name,
                text:
                    'गौ सेवा और समाज सेवा के लिए समर्पित समिति। विस्तृत जानकारी जल्द जोड़ी जाएगी।',
                icon: Icons.account_circle_outlined,
              ),
              const SizedBox(height: 20),
              _DetailsPanel(
                rows: [
                  ('संपर्क', 'मोबाइल और WhatsApp settings में जोड़ें'),
                  ('पता', committee.address),
                  ('UPI', BrandConfig.upi),
                ],
              ),
              const SizedBox(height: 16),
              if (!isLoggedIn)
                _ProfileAction(
                  icon: Icons.lock_outline,
                  title: 'Firebase सुरक्षित प्रवेश',
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const AuthScreen())),
                ),
              if (role.isAdmin) ...[
                _ProfileAction(
                  icon: Icons.groups_2_outlined,
                  title: 'Staff Management (व्यवस्थापक)',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const AdminGate(child: StaffManagementScreen()),
                    ),
                  ),
                ),
                _ProfileAction(
                  icon: Icons.settings_outlined,
                  title: 'समिति Settings (व्यवस्थापक)',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminGate(child: SettingsScreen()),
                    ),
                  ),
                ),
              ],
              _ProfileAction(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () =>
                    _showMessage(context, 'Privacy Policy जल्द उपलब्ध होगी।'),
              ),
              _ProfileAction(
                icon: Icons.info_outline_rounded,
                title: 'About App',
                onTap: () => _showMessage(
                  context,
                  'ऐप की विस्तृत जानकारी जल्द उपलब्ध होगी।',
                ),
              ),
              if (isLoggedIn) ...[
                const SizedBox(height: 8),
                _ProfileAction(
                  icon: Icons.logout_rounded,
                  title: 'लॉगआउट करें (Sign Out)',
                  onTap: () async {
                    await FirebaseBackend.instance.signOut();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('सफलतापूर्वक लॉगआउट किया गया।'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SecondaryScaffold(
      title: 'गौशाला की फोटो',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PageHeading(title: 'गौशाला झलकियां'),
          const SizedBox(height: 8),
          const Text(
            'वास्तविक गौशाला तस्वीरें बाद में यहां जोड़ी जा सकती हैं।',
            style: TextStyle(color: _muted, height: 1.4),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 190,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: _leaf,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.photo_library_outlined,
                      color: _forest,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'फोटो ${index + 1}',
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SecondaryScaffold(
      title: 'संपर्क करें',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _IntroCard(
            eyebrow: 'संपर्क',
            title: BrandConfig.committeeName,
            text:
                'मोबाइल नंबर जल्द जोड़ा जाएगा। कृपया संपर्क जानकारी अपडेट होने तक प्रतीक्षा करें।',
            icon: Icons.contact_phone_outlined,
          ),
          const SizedBox(height: 20),
          const _DetailsPanel(
            rows: [
              ('पता', BrandConfig.address),
              ('फोन', 'मोबाइल नंबर जल्द जोड़ा जाएगा'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'कॉल करें',
                  icon: Icons.phone_outlined,
                  onTap: () =>
                      _showMessage(context, 'मोबाइल नंबर जल्द जोड़ा जाएगा।'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: 'WhatsApp',
                  icon: Icons.chat_outlined,
                  onTap: () => _showMessage(
                    context,
                    'WhatsApp सुविधा जल्द उपलब्ध होगी।',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SecondaryScaffold(
      title: 'स्थान देखें',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _IntroCard(
            eyebrow: 'गौशाला का पता',
            title: 'जय भोले गौशाला समिति',
            text: BrandConfig.address,
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 20),
          Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _leaf,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, color: _forest, size: 52),
                SizedBox(height: 8),
                Text(
                  'मानचित्र जल्द जोड़ा जाएगा',
                  style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showMessage(
                context,
                'Google Maps location जल्द जोड़ी जाएगी।',
              ),
              icon: const Icon(Icons.location_on_outlined),
              label: const Text('स्थान देखें'),
              style: FilledButton.styleFrom(
                backgroundColor: _forest,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UpdateDetailScreen extends StatelessWidget {
  const UpdateDetailScreen({required this.update, super.key});

  final UpdateItem update;

  @override
  Widget build(BuildContext context) {
    return SecondaryScaffold(
      title: 'जानकारी',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _leaf,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(update.icon, color: _forest, size: 44),
          ),
          const SizedBox(height: 22),
          Text(
            update.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'दिनांक: जल्द उपलब्ध होगी',
            style: TextStyle(color: _saffron, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          Text(
            update.description,
            style: const TextStyle(color: _muted, height: 1.6, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.eyebrow,
    required this.title,
    required this.text,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _deepForest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: Color(0xFFB8D7A6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFFD9E8D4),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Icon(icon, color: const Color(0xFFFFE0B5), size: 48),
        ],
      ),
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(color: _ink, fontWeight: FontWeight.w800),
  );
}

class _TextPanel extends StatelessWidget {
  const _TextPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE7ECE4)),
    ),
    child: Text(text, style: const TextStyle(color: _muted, height: 1.5)),
  );
}

class _ServiceList extends StatelessWidget {
  const _ServiceList({required this.items});

  final List<(String, String, IconData)> items;

  @override
  Widget build(BuildContext context) => Column(
    children: items
        .map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
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
                  child: Icon(item.$3, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.$2,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          height: 1.35,
                        ),
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

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE7ECE4)),
    ),
    child: Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      row.$1,
                      style: const TextStyle(color: _muted, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
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
          )
          .toList(),
    ),
  );
}

class _SampleNotice extends StatelessWidget {
  const _SampleNotice();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0DD),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF5D3A7)),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline_rounded, color: _saffron),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'यह sample/demo data है। वास्तविक आंकड़े बाद में अपडेट होंगे।',
            style: TextStyle(color: _ink, fontSize: 13, height: 1.35),
          ),
        ),
      ],
    ),
  );
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      backgroundColor: _leaf,
      foregroundColor: _forest,
      child: Icon(icon),
    ),
    title: Text(
      title,
      style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
    ),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 18),
    label: Text(label),
    style: FilledButton.styleFrom(
      backgroundColor: _forest,
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
  );
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class VolunteersScreen extends StatefulWidget {
  const VolunteersScreen({super.key});

  @override
  State<VolunteersScreen> createState() => _VolunteersScreenState();
}

class _VolunteersScreenState extends State<VolunteersScreen> {
  final _nameController = TextEditingController();
  final _store = LocalGoshalaStore.instance;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SecondaryScaffold(
      title: 'श्रमदान और सेवक',
      child: AnimatedBuilder(
        animation: _store,
        builder: (context, _) {
          final progress = _store.volunteers.isEmpty
              ? 0
              : (_store.presentVolunteers / _store.volunteers.length * 100)
                    .round();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailsPanel(
                rows: [
                  (
                    'आज उपस्थित',
                    '${_store.presentVolunteers}/${_store.volunteers.length}',
                  ),
                  ('कार्य प्रगति', '$progress%'),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'सेवक का नाम',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'सेवक जोड़ें',
                    onPressed: () {
                      _store.addVolunteer(_nameController.text);
                      _nameController.clear();
                    },
                    icon: const Icon(Icons.person_add_alt_1),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._store.volunteers.map(
                (volunteer) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: volunteer.present
                          ? _leaf
                          : const Color(0xFFFFF0DD),
                      child: Icon(
                        volunteer.present ? Icons.check : Icons.person_outline,
                        color: volunteer.present ? _forest : _saffron,
                      ),
                    ),
                    title: Text(volunteer.name),
                    subtitle: Text('${volunteer.task} · ${volunteer.phone}'),
                    trailing: Switch(
                      value: volunteer.present,
                      onChanged: (_) => _store.toggleAttendance(volunteer),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = LocalGoshalaStore.instance;
    return SecondaryScaffold(
      title: 'आय-व्यय',
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _FinanceMetric(
                  label: 'आय',
                  value: store.income,
                  color: _forest,
                ),
                const SizedBox(width: 10),
                _FinanceMetric(
                  label: 'व्यय',
                  value: store.expense,
                  color: _saffron,
                ),
                const SizedBox(width: 10),
                _FinanceMetric(
                  label: 'शेष',
                  value: store.income - store.expense,
                  color: _deepForest,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _PageHeading(title: 'इस महीने के रिकॉर्ड'),
            const SizedBox(height: 10),
            ...store.ledger.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  entry.isIncome
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: entry.isIncome ? _forest : _saffron,
                ),
                title: Text(entry.title),
                subtitle: Text(entry.category),
                trailing: Text(
                  '${entry.isIncome ? '+' : '-'} ₹${entry.amount}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const _SampleNotice(),
          ],
        ),
      ),
    );
  }
}

class _FinanceMetric extends StatelessWidget {
  const _FinanceMetric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _muted)),
          const SizedBox(height: 5),
          Text(
            '₹$value',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

class NoticesScreen extends StatelessWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = LocalGoshalaStore.instance;
    return SecondaryScaffold(
      title: 'सूचनाएं और रिपोर्ट',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PageHeading(title: 'समिति की नवीनतम सूचनाएं'),
          const SizedBox(height: 10),
          ...store.notices.map(
            (notice) => Card(
              child: ListTile(
                leading: Icon(
                  notice.type == 'चिकित्सा'
                      ? Icons.medical_services_outlined
                      : Icons.campaign_outlined,
                  color: _forest,
                ),
                title: Text(notice.title),
                subtitle: Text('${notice.type} · ${notice.message}'),
                trailing: IconButton(
                  tooltip: 'WhatsApp संदेश',
                  onPressed: () =>
                      _showMessage(context, 'WhatsApp संदेश draft तैयार है।'),
                  icon: const Icon(Icons.share_outlined),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _PageHeading(title: 'रिपोर्ट'),
          const SizedBox(height: 8),
          _TextPanel(
            text:
                'आज की checklist: ${store.completedChecklist}/4 पूर्ण\n'
                'गौवंश: ${store.cows.length} · स्वस्थ: ${store.healthyCows}\n'
                'मासिक balance: ₹${store.income - store.expense}',
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () =>
                _showMessage(context, 'रिपोर्ट sharing जल्द उपलब्ध होगी।'),
            icon: const Icon(Icons.share_outlined),
            label: const Text('रिपोर्ट संदेश बनाएं'),
          ),
        ],
      ),
    );
  }
}

class RoleGate extends StatelessWidget {
  const RoleGate({
    required this.child,
    required this.allowedRoles,
    this.customRestrictedMessage,
    super.key,
  });

  final Widget child;
  final List<UserRole> allowedRoles;
  final String? customRestrictedMessage;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: FirebaseBackend.instance.userProfileChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profile = snapshot.data;
        final role = profile?.role ?? UserRole.viewer;
        final isAuthorized =
            profile != null && profile.isActive && allowedRoles.contains(role);

        if (!isAuthorized) {
          return UnauthorizedAccessScreen(
            allowedRoles: allowedRoles,
            currentRole: profile?.role,
            message: customRestrictedMessage,
          );
        }
        return child;
      },
    );
  }
}

class AdminGate extends StatelessWidget {
  const AdminGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RoleGate(
      allowedRoles: const [UserRole.admin],
      customRestrictedMessage:
          'यह भाग केवल अधिकृत व्यवस्थापक (Admin) के लिए सुरक्षित है।',
      child: child,
    );
  }
}

class StaffGate extends StatelessWidget {
  const StaffGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RoleGate(
      allowedRoles: const [UserRole.admin, UserRole.staff],
      customRestrictedMessage:
          'यह भाग केवल व्यवस्थापक (Admin) और कर्मचारी (Staff) के लिए उपलब्ध है।',
      child: child,
    );
  }
}

class UnauthorizedAccessScreen extends StatelessWidget {
  const UnauthorizedAccessScreen({
    this.allowedRoles = const [UserRole.admin],
    this.currentRole,
    this.message,
    super.key,
  });

  final List<UserRole> allowedRoles;
  final UserRole? currentRole;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final defaultMessage =
        message ??
        'यह सेक्शन केवल अधिकृत ${allowedRoles.map((r) => r.label).join(' / ')} उपयोगकर्ताओं के लिए सीमित है।';

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.block_rounded, size: 42, color: _forest),
                  const SizedBox(height: 16),
                  const Text(
                    'अनधिकृत प्रवेश (Access Denied)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    defaultMessage,
                    style: const TextStyle(color: _muted, height: 1.5),
                  ),
                  if (currentRole != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'वर्तमान भूमिका: ${currentRole!.label}',
                      style: const TextStyle(
                        color: _forest,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('वापस जाएं'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          FirebaseBackend.instance.signOut();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const AuthScreen(),
                            ),
                          );
                        },
                        child: const Text('खाता बदलें / Login'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final committee = LocalGoshalaStore.instance.committee;
    return SecondaryScaffold(
      title: 'समिति Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandLogo(size: 76, showName: true),
          const SizedBox(height: 20),
          const _PageHeading(title: 'Branding और संपर्क'),
          const SizedBox(height: 12),
          _DetailsPanel(
            rows: [
              ('समिति नाम', committee.name),
              ('पता', committee.address),
              (
                'मोबाइल',
                committee.mobile.isEmpty ? 'अभी सेट नहीं है' : committee.mobile,
              ),
              (
                'WhatsApp',
                committee.whatsapp.isEmpty
                    ? 'अभी सेट नहीं है'
                    : committee.whatsapp,
              ),
              (
                'UPI ID',
                committee.upiId.isEmpty ? 'अभी सेट नहीं है' : committee.upiId,
              ),
              ('Logo', committee.logoAsset),
            ],
          ),
          const SizedBox(height: 14),
          const _TextPanel(
            text:
                'ये fields central configuration से नियंत्रित हैं। assets/branding/logo_placeholder.svg की जगह आपका असली logo जोड़ा जा सकता है।',
          ),
          const SizedBox(height: 18),
          const _PageHeading(title: 'About App'),
          const SizedBox(height: 8),
          const _TextPanel(
            text:
                'Digital Goshala App का उद्देश्य स्थानीय गौसेवा, सेवक, दान, products और reports को एक सरल offline-first workspace में व्यवस्थित करना है।',
          ),
          const SizedBox(height: 18),
          const _PageHeading(title: 'Privacy Policy'),
          const SizedBox(height: 8),
          const _TextPanel(
            text:
                'स्थानीय demo data device/app state में रहता है। किसी backend या AI service को data भेजने से पहले आपकी अनुमति और privacy policy configuration आवश्यक होगी।',
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await FirebaseBackend.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Admin Logout'),
            ),
          ),
        ],
      ),
    );
  }
}
