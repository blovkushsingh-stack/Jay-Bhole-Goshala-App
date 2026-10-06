import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

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

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'सभी उत्पाद';

  static const List<String> _categories = [
    'सभी उत्पाद',
    'जैविक खाद',
    'आयुर्वेदिक / अर्क',
    'पूजा सामग्री',
  ];

  @override
  void initState() {
    super.initState();
    LocalGoshalaStore.instance.loadProductsFromCloud();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getProductCategory(ProductRecord product) {
    if (product.category.isNotEmpty && product.category != 'अन्य') {
      return product.category;
    }
    final name = product.name.toLowerCase();
    if (name.contains('खाद') || name.contains('कम्पोस्ट')) {
      return 'जैविक खाद';
    }
    if (name.contains('अर्क') || name.contains('नीम') || name.contains('पाउडर')) {
      return 'आयुर्वेदिक / अर्क';
    }
    if (name.contains('कंडे') || name.contains('गोबर') || name.contains('हवन')) {
      return 'पूजा सामग्री';
    }
    return 'अन्य';
  }

  List<ProductRecord> _getFilteredProducts(List<ProductRecord> allProducts) {
    final query = _searchController.text.trim().toLowerCase();
    return allProducts.where((p) {
      final category = _getProductCategory(p);
      final matchesCategory =
          _selectedCategory == 'सभी उत्पाद' || category == _selectedCategory;
      final matchesQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Future<void> _showAddEditProductDialog(BuildContext context,
      {ProductRecord? product}) async {
    final isEditing = product != null;
    final String targetId = isEditing && product.id.trim().isNotEmpty
        ? product.id.trim()
        : 'PROD-${DateTime.now().millisecondsSinceEpoch}';

    final nameController = TextEditingController(text: product?.name ?? '');
    final descController = TextEditingController(text: product?.description ?? '');
    final priceController =
        TextEditingController(text: product != null ? '${product.price}' : '');
    final stockController =
        TextEditingController(text: product != null ? '${product.stock}' : '');
    String selectedCat =
        product != null ? _getProductCategory(product) : 'जैविक खाद';
    String currentPhotoUrl = product?.photoUrl ?? '';
    Uint8List? newPhotoBytes;
    bool isSaving = false;
    String? errorMessage;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(
                      isEditing
                          ? Icons.edit_note_rounded
                          : Icons.add_business_rounded,
                      color: _forest),
                  const SizedBox(width: 8),
                  Text(isEditing ? 'उत्पाद संपादित करें' : 'नया उत्पाद जोड़ें'),
                ],
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Photo Picker Box
                        Center(
                          child: InkWell(
                            onTap: () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 85,
                              );
                              if (picked != null) {
                                final bytes = await picked.readAsBytes();
                                setDialogState(() {
                                  newPhotoBytes = bytes;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: _leaf,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: const Color(0xFFC7DBC5), width: 1.5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: newPhotoBytes != null
                                    ? Image.memory(newPhotoBytes!,
                                        fit: BoxFit.cover)
                                    : (currentPhotoUrl.isNotEmpty
                                        ? Image.network(
                                            currentPhotoUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                        Icons
                                                            .broken_image_rounded,
                                                        color: _forest,
                                                        size: 36),
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Icon(Icons.add_a_photo_outlined,
                                                  color: _forest, size: 32),
                                              SizedBox(height: 4),
                                              Text(
                                                'फोटो चुनें',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: _forest,
                                                ),
                                              ),
                                            ],
                                          )),
                              ),
                            ),
                          ),
                        ),
                        if (newPhotoBytes != null ||
                            currentPhotoUrl.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Center(
                            child: TextButton.icon(
                              onPressed: () async {
                                final picker = ImagePicker();
                                final picked = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 85,
                                );
                                if (picked != null) {
                                  final bytes = await picked.readAsBytes();
                                  setDialogState(() {
                                    newPhotoBytes = bytes;
                                  });
                                }
                              },
                              icon: const Icon(Icons.change_circle_outlined,
                                  size: 16),
                              label: const Text('फोटो बदलें (Replace)',
                                  style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),

                        // Name
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'उत्पाद का नाम *',
                            hintText: 'उदा. नीम पाउडर / गोबर कंडे',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'उत्पाद नाम दर्ज करें'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Description
                        TextFormField(
                          controller: descController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'विवरण (Description) *',
                            hintText:
                                'उदा. प्राकृतिक देखभाल हेतु शत-प्रतिशत शुद्ध',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'विवरण दर्ज करें'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Price & Stock
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: priceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'मूल्य (₹) *',
                                  prefixText: '₹ ',
                                ),
                                validator: (v) {
                                  final val = int.tryParse(v?.trim() ?? '');
                                  if (val == null || val <= 0) {
                                    return 'मान्य मूल्य';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: stockController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'स्टॉक (नग) *',
                                ),
                                validator: (v) {
                                  final val = int.tryParse(v?.trim() ?? '');
                                  if (val == null || val < 0) {
                                    return 'मान्य स्टॉक';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Category
                        DropdownButtonFormField<String>(
                          initialValue: selectedCat,
                          decoration: const InputDecoration(
                            labelText: 'श्रेणी (Category)',
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'जैविक खाद', child: Text('जैविक खाद')),
                            DropdownMenuItem(
                                value: 'आयुर्वेदिक / अर्क',
                                child: Text('आयुर्वेदिक / अर्क')),
                            DropdownMenuItem(
                                value: 'पूजा सामग्री',
                                child: Text('पूजा सामग्री')),
                            DropdownMenuItem(value: 'अन्य', child: Text('अन्य')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedCat = val);
                            }
                          },
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 16, color: Colors.red),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: TextStyle(
                                        color: Colors.red.shade900,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('रद्द करें'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: _forest),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() {
                            isSaving = true;
                            errorMessage = null;
                          });

                          try {
                            String finalPhotoUrl = currentPhotoUrl;
                            String? photoUploadWarning;

                            // 1 & 2: Only upload to Storage if a new photo was selected.
                            // If photo was not changed (newPhotoBytes == null), Storage upload is skipped.
                            if (newPhotoBytes != null) {
                              try {
                                finalPhotoUrl = await LocalGoshalaStore.instance
                                    .uploadProductPhoto(
                                  productId: targetId,
                                  bytes: newPhotoBytes!,
                                );
                              } catch (uploadError) {
                                debugPrint('Photo upload failed: $uploadError');
                                photoUploadWarning = uploadError.toString();
                                // 3: Storage upload failure must not fail the entire product update.
                                finalPhotoUrl = currentPhotoUrl;
                              }
                            }

                            final updatedProd = ProductRecord(
                              id: targetId,
                              name: nameController.text.trim(),
                              description: descController.text.trim(),
                              price: int.parse(priceController.text.trim()),
                              stock: int.parse(stockController.text.trim()),
                              category: selectedCat,
                              photoUrl: finalPhotoUrl,
                              icon: product?.icon ?? Icons.eco_outlined,
                            );

                            if (isEditing) {
                              await LocalGoshalaStore.instance
                                  .updateProduct(updatedProd);
                            } else {
                              await LocalGoshalaStore.instance
                                  .addProduct(updatedProd);
                            }

                            // Refresh product list from Firestore after success
                            await LocalGoshalaStore.instance
                                .loadProductsFromCloud();

                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                              if (photoUploadWarning != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEditing
                                          ? 'उत्पाद विवरण अपडेट हो गया, परंतु फोटो अपलोड नहीं हो सकी: $photoUploadWarning'
                                          : 'उत्पाद सहेजा गया, परंतु फोटो अपलोड नहीं हो सकी: $photoUploadWarning',
                                    ),
                                    backgroundColor: Colors.orange.shade800,
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isEditing
                                        ? 'उत्पाद रिकॉर्ड सफलतापूर्वक अपडेट हुआ।'
                                        : 'नया उत्पाद सफलतापूर्वक जोड़ा गया।'),
                                    backgroundColor: _forest,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            debugPrint('Product save/update error: $e');
                            if (dialogCtx.mounted) {
                              setDialogState(() {
                                isSaving = false;
                                errorMessage = 'अपडेट करने में त्रुटि: $e';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('त्रुटि: $e'),
                                  backgroundColor: Colors.redAccent,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          }
                        },
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(isSaving
                      ? (isEditing ? 'अपडेट हो रहा है...' : 'सेव हो रहा है...')
                      : (isEditing ? 'अपडेट करें' : 'सेव करें')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteProduct(
      BuildContext context, ProductRecord product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('उत्पाद हटाएं?'),
        content: Text(
            'क्या आप "${product.name}" का उत्पाद रिकॉर्ड हटाना चाहते हैं?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('रद्द करें'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('हटाएं'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await LocalGoshalaStore.instance.deleteProduct(product.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('उत्पाद सफलतापूर्वक हटा दिया गया।')),
        );
      }
    }
  }

  void _showProductDetail(BuildContext context, ProductRecord product,
      {bool isAdmin = false}) {
    final category = _getProductCategory(product);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Category Badge & Close Button
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _leaf,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded,
                                  size: 14, color: _forest),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '100% शुद्ध देशी गौ उत्पाद • $category',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _forest,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(dialogCtx),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Large Product Icon / Uploaded Image
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: _leaf,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: const Color(0xFFD6E5D4), width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x10000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(23),
                        child: _buildProductImage(product, 120, 54),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Product Name
                  Center(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Short Description
                  Center(
                    child: Text(
                      product.description,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price and Available Stock Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAF6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE4EDE2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'सहयोग मूल्य',
                              style: TextStyle(color: _muted, fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${product.price}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: _forest,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'उपलब्धता',
                              style: TextStyle(color: _muted, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            _ProductStockBadge(stock: product.stock),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Detailed Information & Features
                  const Text(
                    'उत्पाद विशेषताएं एवं जानकारी:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _ProductFeatureBullet(
                    text:
                        'देशी गोमाता के पवित्र पंचगव्य व शुद्ध प्राकृतिक तत्वों से निर्मित।',
                  ),
                  const _ProductFeatureBullet(
                    text:
                        'शत-प्रतिशत रसायन मुक्त (Chemical Free) एवं पर्यावरण-अनुकूल।',
                  ),
                  const _ProductFeatureBullet(
                    text:
                        'इस उत्पाद की खरीद का समस्त सहयोग सीधे गौमाता के आहार व सेवा में उपयोग होता है।',
                  ),
                  const SizedBox(height: 18),

                  // WhatsApp Order Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final orderText = '''
नमस्ते, ${BrandConfig.hindiCommitteeName}!
मुझे निम्नलिखित गौ उत्पाद का ऑर्डर करना है:
• उत्पाद: ${product.name}
• मूल्य: ₹${product.price}
• विवरण: ${product.description}
कृपया उपलब्धता और डिलीवरी का विवरण साझा करें।
''';
                        Clipboard.setData(ClipboardData(text: orderText));
                        Share.share(
                          orderText,
                          subject: 'गौ उत्पाद ऑर्डर - ${product.name}',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ऑर्डर संदेश WhatsApp हेतु तैयार है।'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_outlined, size: 20),
                      label: const Text(
                        'WhatsApp पर ऑर्डर करें',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Call Order Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _forest,
                        side: const BorderSide(color: _forest),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.phone_in_talk_rounded,
                                    color: _forest),
                                SizedBox(width: 8),
                                Text('कॉल संपर्क विवरण'),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  BrandConfig.hindiCommitteeName,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'पता: ${BrandConfig.address}',
                                  style:
                                      TextStyle(fontSize: 12, color: _muted),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'गौशाला सेवा समिति से संपर्क करने हेतु कृपया WhatsApp शेयर विकल्प का उपयोग करें अथवा सीधे गौशाला परिसर पधारें।',
                                  style: TextStyle(fontSize: 12, height: 1.4),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('ठीक है'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.phone_outlined, size: 20),
                      label: const Text(
                        'कॉल संपर्क विवरण',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),

                  // Admin Edit / Delete Actions inside Detail Dialog
                  if (isAdmin) ...[
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _forest,
                              side: const BorderSide(color: _forest),
                            ),
                            onPressed: () {
                              Navigator.pop(dialogCtx);
                              _showAddEditProductDialog(context,
                                  product: product);
                            },
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('संपादित करें'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                            onPressed: () {
                              Navigator.pop(dialogCtx);
                              _confirmDeleteProduct(context, product);
                            },
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18),
                            label: const Text('हटाएं'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      initialData: FirebaseBackend.instance.cachedCurrentUserProfile,
      stream: FirebaseBackend.instance.userProfileChanges(),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final isAdmin = user?.isAdmin ?? false;

        return AnimatedBuilder(
          animation: LocalGoshalaStore.instance,
          builder: (context, _) {
            final products = LocalGoshalaStore.instance.products;
            final filtered = _getFilteredProducts(products);

            return SecondaryScaffold(
              title: 'गौ उत्पाद (Products)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Banner
                  const _ProductsHeroCard(),
                  const SizedBox(height: 16),

                  // Admin Add Product Button
                  if (isAdmin) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _forest,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _showAddEditProductDialog(context),
                        icon: const Icon(Icons.add_circle_outline_rounded,
                            size: 20),
                        label: const Text(
                          'नया उत्पाद जोड़ें (Add Product)',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'उत्पाद खोजें (उदा. नीम, खाद, कंडे, अर्क)...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(cat),
                            selectedColor: _leaf,
                            labelStyle: TextStyle(
                              color: isSelected ? _forest : _ink,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected
                                    ? _forest
                                    : const Color(0xFFDCE4DA),
                              ),
                            ),
                            onSelected: (_) =>
                                setState(() => _selectedCategory = cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Product List / Grid
                  if (filtered.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'इस खोज अथवा श्रेणी में कोई उत्पाद उपलब्ध नहीं है।',
                          style: TextStyle(color: _muted, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        int columns = 1;
                        double childAspectRatio = 0.85;

                        if (width >= 1200) {
                          columns = 4;
                          childAspectRatio = isAdmin ? 0.70 : 0.80;
                        } else if (width >= 900) {
                          columns = 3;
                          childAspectRatio = isAdmin ? 0.74 : 0.84;
                        } else if (width >= 600) {
                          columns = 2;
                          childAspectRatio = isAdmin ? 0.80 : 0.90;
                        } else {
                          columns = 1;
                        }

                        if (columns == 1) {
                          // Mobile 1-column layout
                          return Column(
                            children: filtered
                                .map((product) => _ProductCardMobile(
                                      product: product,
                                      isAdmin: isAdmin,
                                      onTap: () => _showProductDetail(
                                          context, product,
                                          isAdmin: isAdmin),
                                      onEdit: isAdmin
                                          ? () => _showAddEditProductDialog(
                                              context,
                                              product: product)
                                          : null,
                                      onDelete: isAdmin
                                          ? () => _confirmDeleteProduct(
                                              context, product)
                                          : null,
                                    ))
                                .toList(),
                          );
                        }

                        // Desktop / Tablet 2-4 responsive columns
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: childAspectRatio,
                          ),
                          itemBuilder: (context, index) {
                            final product = filtered[index];
                            return _ProductCardGrid(
                              product: product,
                              isAdmin: isAdmin,
                              onTap: () => _showProductDetail(context, product,
                                  isAdmin: isAdmin),
                              onEdit: isAdmin
                                  ? () => _showAddEditProductDialog(context,
                                      product: product)
                                  : null,
                              onDelete: isAdmin
                                  ? () => _confirmDeleteProduct(context, product)
                                  : null,
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ProductsHeroCard extends StatelessWidget {
  const _ProductsHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_forest, Color(0xFF1B4E32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x202F6B45),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'प्राकृतिक एवं जैविक • गौ आधारित',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const BrandLogo(size: 30),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'गौशाला शुद्ध जैविक उत्पाद',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'देशी गोमाता के पंचगव्य एवं प्राकृतिक तत्वों से निर्मित। बिक्री से प्राप्त शत-प्रतिशत सहयोग गौसेवा में समर्पित।',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCardMobile extends StatelessWidget {
  const _ProductCardMobile({
    required this.product,
    required this.onTap,
    this.isAdmin = false,
    this.onEdit,
    this.onDelete,
  });

  final ProductRecord product;
  final VoidCallback onTap;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE4EDE2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: _leaf,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildProductImage(product, 76, 36),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              '₹${product.price}',
                              style: const TextStyle(
                                color: _forest,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.description,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _ProductStockBadge(stock: product.stock),
                            FilledButton.icon(
                              onPressed: onTap,
                              icon: const Icon(Icons.shopping_bag_outlined,
                                  size: 15),
                              label: const Text('ऑर्डर करें'),
                              style: FilledButton.styleFrom(
                                backgroundColor: _forest,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isAdmin) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: _forest,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('संपादित करें (Edit)',
                          style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('हटाएं (Delete)',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCardGrid extends StatelessWidget {
  const _ProductCardGrid({
    required this.product,
    required this.onTap,
    this.isAdmin = false,
    this.onEdit,
    this.onDelete,
  });

  final ProductRecord product;
  final VoidCallback onTap;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE4EDE2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 94,
                decoration: BoxDecoration(
                  color: _leaf,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildProductImage(product, 94, 40),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                product.description,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${product.price}',
                    style: const TextStyle(
                      color: _forest,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  _ProductStockBadge(stock: product.stock),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: FilledButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.shopping_bag_outlined, size: 15),
                  label:
                      const Text('ऑर्डर करें', style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    backgroundColor: _forest,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 30,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _forest,
                            padding: EdgeInsets.zero,
                            side: const BorderSide(color: Color(0xFFC7DBC5)),
                          ),
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 13),
                          label: const Text('Edit',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SizedBox(
                        height: 30,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            padding: EdgeInsets.zero,
                            side: BorderSide(color: Colors.red.shade200),
                          ),
                          onPressed: onDelete,
                          icon:
                              const Icon(Icons.delete_outline_rounded, size: 13),
                          label: const Text('Delete',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductStockBadge extends StatelessWidget {
  const _ProductStockBadge({required this.stock});
  final int stock;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    String label;
    if (stock <= 0) {
      bg = const Color(0xFFFFEBEE);
      textColor = Colors.red.shade800;
      label = 'स्टॉक समाप्त';
    } else if (stock < 10) {
      bg = const Color(0xFFFFF3E0);
      textColor = const Color(0xFFE65100);
      label = 'स्टॉक: $stock';
    } else {
      bg = const Color(0xFFE8F6ED);
      textColor = _forest;
      label = 'स्टॉक: $stock नग';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Widget _buildProductImage(ProductRecord product, double size, double iconSize) {
  if (product.hasPhoto) {
    return Image.network(
      product.photoUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          Icon(product.icon, color: _forest, size: iconSize),
    );
  }
  return Icon(product.icon, color: _forest, size: iconSize);
}

class _ProductFeatureBullet extends StatelessWidget {
  const _ProductFeatureBullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 15, color: _forest),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: _ink, height: 1.35),
            ),
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
