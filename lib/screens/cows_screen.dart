import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../app_data.dart';
import '../branding/brand_config.dart';
import '../home_screen.dart';
import '../models/app_user.dart';
import '../models/cow_record.dart';
import '../services/firebase_backend.dart';
import '../widgets/cow_avatar.dart';

const _forest = Color(0xFF2F6B45);
const _leaf = Color(0xFFE7F1E5);
const _ink = Color(0xFF243127);
const _muted = Color(0xFF6B756D);

class CowsScreen extends StatefulWidget {
  const CowsScreen({super.key});

  @override
  State<CowsScreen> createState() => _CowsScreenState();
}

class _CowsScreenState extends State<CowsScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = 'सभी';
  String _healthFilter = 'सभी';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CowRecord> _filteredCows(List<CowRecord> cows) {
    final query = _searchController.text.trim().toLowerCase();
    return cows.where((cow) {
      final searchableText = [
        cow.id,
        cow.tag,
        cow.name,
        cow.breed,
        cow.color,
        cow.health,
        cow.status,
        cow.gender,
        cow.weight,
      ].join(' ').toLowerCase();
      final matchesSearch = query.isEmpty || searchableText.contains(query);
      final matchesStatus =
          _statusFilter == 'सभी' ||
          cow.statusLabel.toLowerCase() == _statusFilter.toLowerCase();
      final matchesHealth =
          _healthFilter == 'सभी' ||
          cow.health.toLowerCase() == _healthFilter.toLowerCase();
      return matchesSearch && matchesStatus && matchesHealth;
    }).toList();
  }

  Future<void> _openForm([CowRecord? cow]) async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => CowFormScreen(cow: cow)));
    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _openScanner(List<CowRecord> cows) {
    showDialog<void>(
      context: context,
      builder: (ctx) => CowScannerDialog(cows: cows),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = LocalGoshalaStore.instance;
    return StreamBuilder<AppUser?>(
      stream: FirebaseBackend.instance.userProfileChanges(),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        // In local/offline mode or before login, allow local operations; when logged in, respect role permissions
        final canAdd = user == null || user.hasPermission(AppPermission.cows);

        return Scaffold(
          appBar: AppBar(
            title: const Text('गाय सूची'),
            actions: [
              IconButton(
                tooltip: 'QR / Barcode स्कैन करें',
                onPressed: () => _openScanner(store.cows),
                icon: const Icon(Icons.qr_code_scanner_rounded),
              ),
              if (canAdd)
                IconButton(
                  tooltip: 'गाय जोड़ें',
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
            ],
          ),
          body: AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              final cows = _filteredCows(store.cows);
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _leaf,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'कुल गायें',
                                style: TextStyle(color: _muted, fontSize: 12),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${store.cows.length}',
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (canAdd)
                          FilledButton.icon(
                            onPressed: () => _openForm(),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('गाय जोड़ें'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _forest,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText:
                                'ID, नाम, tag, नस्ल, स्वास्थ्य या स्थिति खोजें',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'QR / Barcode स्कैन',
                        onPressed: () => _openScanner(store.cows),
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: _forest,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _statusFilter,
                          decoration: const InputDecoration(
                            labelText: 'स्थिति',
                          ),
                          items: _statusOptions
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _statusFilter = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _healthFilter,
                          decoration: const InputDecoration(
                            labelText: 'स्वास्थ्य स्थिति',
                          ),
                          items: _healthOptions
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _healthFilter = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (cows.isEmpty)
                    _EmptyCows(onAdd: () => _openForm())
                  else
                    ...cows.map((cow) => _CowCard(cow: cow)),
                ],
              );
            },
          ),
        );
      },
    );
  }

  static const List<String> _statusOptions = [
    'सभी',
    'स्वस्थ',
    'उपचार चल रहा है',
    'गर्भवती',
    'नया आगमन',
    'अन्य',
  ];

  static const List<String> _healthOptions = [
    'सभी',
    'स्वस्थ',
    'उपचार चल रहा है',
    'गर्भवती',
    'नया आगमन',
    'अन्य',
  ];
}

class _EmptyCows extends StatelessWidget {
  const _EmptyCows({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: _leaf,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        const Icon(Icons.pets_outlined, color: _forest, size: 52),
        const SizedBox(height: 10),
        const Text(
          'अभी कोई गाय दर्ज नहीं है',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'पहली गाय की जानकारी भरकर गौशाला प्रबंधन शुरू करें।',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('पहली गाय जोड़ें'),
        ),
      ],
    ),
  );
}

class _CowCard extends StatelessWidget {
  const _CowCard({required this.cow});
  final CowRecord cow;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => CowDetailScreen(cow: cow))),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CowAvatar(cow: cow, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${cow.name} • ${cow.tag}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cow.breed} • ${cow.age} वर्ष • ${cow.gender}',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _StatusChip(label: cow.statusLabel),
                      const SizedBox(width: 8),
                      if (cow.health.isNotEmpty)
                        _StatusChip(
                          label: cow.health,
                          backgroundColor: const Color(0xFFE8F6ED),
                          textColor: _forest,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    this.backgroundColor = const Color(0xFFF0F2EC),
    this.textColor = _ink,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    ),
  );
}

class CowDetailScreen extends StatefulWidget {
  const CowDetailScreen({this.cow, this.cowId, super.key})
      : assert(cow != null || cowId != null, 'Either cow or cowId must be provided');

  final CowRecord? cow;
  final String? cowId;

  @override
  State<CowDetailScreen> createState() => _CowDetailScreenState();
}

class _CowDetailScreenState extends State<CowDetailScreen> {
  CowRecord? _cow;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cow = widget.cow;
    if (_cow == null && widget.cowId != null) {
      _loadCow();
    }
  }

  Future<void> _loadCow() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final found = await LocalGoshalaStore.instance.getCowById(widget.cowId!);
    if (mounted) {
      setState(() {
        _cow = found;
        _isLoading = false;
        if (found == null) {
          _errorMessage = 'गौवंश ID "${widget.cowId}" का रिकॉर्ड नहीं मिला।';
        }
      });
    }
  }

  Future<void> _delete(BuildContext context, CowRecord targetCow) async {
    final isAdmin = await FirebaseBackend.instance.isCurrentUserAdmin();
    if (!isAdmin) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('केवल व्यवस्थापक (Admin) ही रिकॉर्ड हटा सकते हैं।'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('गाय का रिकॉर्ड हटाएं?'),
        content: Text(
          '${targetCow.name.isEmpty ? targetCow.tag : targetCow.name} का रिकॉर्ड स्थायी रूप से हट जाएगा। क्या आप वाकई इसे हटाना चाहते हैं?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('रद्द करें'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('हटाएं'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !context.mounted) return;
    try {
      await LocalGoshalaStore.instance.deleteCow(targetCow.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('रिकॉर्ड सफलतापूर्वक हटा दिया गया।'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('रिकॉर्ड हटाने में त्रुटि: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _shareBiodata(CowRecord targetCow) {
    final biodataText = '''
${BrandConfig.hindiCommitteeName} (पंजीकृत)
${BrandConfig.tagline}
----------------------------------------
गौवंश बायोडेटा पहचान पत्र (Cow Profile)
----------------------------------------
गौवंश ID: ${targetCow.id}
टैग नंबर: ${targetCow.tag}
नाम: ${targetCow.name.isEmpty ? 'बिना नाम' : targetCow.name}
नस्ल: ${targetCow.breed.isEmpty ? 'अज्ञात' : targetCow.breed}
लिंग: ${targetCow.gender}
उम्र: ${targetCow.age} वर्ष
रंग: ${targetCow.color.isEmpty ? 'अज्ञात' : targetCow.color}
स्वास्थ्य स्थिति: ${targetCow.health}
वर्तमान स्थिति: ${targetCow.statusLabel}
दुधारू: ${targetCow.isMilking ? 'हाँ (${targetCow.dailyMilkYield})' : 'नहीं'}
गर्भावस्था: ${targetCow.pregnancyStatus}
आगमन तिथि: ${_formatDate(targetCow.arrivalDate)}
आगमन स्रोत: ${targetCow.sourceDetails.isEmpty ? 'कोई विवरण नहीं' : targetCow.sourceDetails}
टीकाकरण: ${targetCow.vaccination.isEmpty ? 'कोई जानकारी नहीं' : targetCow.vaccination}
मेडिकल विवरण: ${targetCow.disease.isEmpty ? 'कोई रोग नहीं' : targetCow.disease}
नोट्स: ${targetCow.notes.isEmpty ? 'कोई नोट्स नहीं' : targetCow.notes}
----------------------------------------
QR/बायोडेटा लिंक: ${targetCow.publicBiodataUrl}
Barcode ID: ${targetCow.id}
''';

    Share.share(
      biodataText,
      subject: 'गौवंश बायोडेटा - ${targetCow.name.isEmpty ? targetCow.tag : targetCow.name}',
    );
  }

  void _showPrintIdCardDialog(BuildContext context, CowRecord targetCow) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        contentPadding: const EdgeInsets.all(16),
        title: const Row(
          children: [
            Icon(Icons.badge_outlined, color: _forest),
            SizedBox(width: 8),
            Text('गौवंश पहचान पत्र (ID Card)'),
          ],
        ),
        content: SingleChildScrollView(
          child: Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD3DEC8), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: const BoxDecoration(
                    color: _forest,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        BrandConfig.hindiCommitteeName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'गौवंश डिजिटल पहचान पत्र (Official ID Card)',
                        style: TextStyle(color: Color(0xFFE2F0DC), fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      CowAvatar(cow: targetCow, size: 74),
                      const SizedBox(height: 8),
                      Text(
                        targetCow.name.isEmpty ? targetCow.tag : targetCow.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _leaf,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Cow ID: ${targetCow.id}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _forest,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(1.2),
                        },
                        children: [
                          TableRow(
                            children: [
                              const Text('टैग नंबर:', style: TextStyle(color: _muted, fontSize: 11)),
                              Text(targetCow.tag, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          TableRow(
                            children: [
                              const Text('नस्ल:', style: TextStyle(color: _muted, fontSize: 11)),
                              Text(targetCow.breed, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          TableRow(
                            children: [
                              const Text('लिंग / उम्र:', style: TextStyle(color: _muted, fontSize: 11)),
                              Text('${targetCow.gender} • ${targetCow.age} वर्ष', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          TableRow(
                            children: [
                              const Text('स्वास्थ्य:', style: TextStyle(color: _muted, fontSize: 11)),
                              Text(targetCow.health, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFE0E8DE)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: QrImageView(
                                  data: targetCow.publicBiodataUrl,
                                  version: QrVersions.auto,
                                  size: 80,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'QR (बायोडेटा URL)',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: _forest,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFE0E8DE)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: BarcodeWidget(
                                  barcode: Barcode.code128(),
                                  data: targetCow.id,
                                  width: 140,
                                  height: 45,
                                  drawText: true,
                                  style: const TextStyle(fontSize: 9, color: _ink),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Barcode (Cow ID)',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: _forest,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'QR स्कैन करें और गौवंश का संपूर्ण पब्लिक बायोडेटा देखें',
                        style: TextStyle(fontSize: 9, color: _muted, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: targetCow.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cow ID (${targetCow.id}) कॉपी हो गया।')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('कॉपी ID'),
          ),
          FilledButton.icon(
            onPressed: () {
              _shareBiodata(targetCow);
              Navigator.pop(dialogCtx);
            },
            icon: const Icon(Icons.share_rounded, size: 16),
            label: const Text('शेयर / प्रिंट'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('बंद करें'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('गौवंश बायोडेटा (Biodata)')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text('गौवंश की जानकारी लोड हो रही है...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _cow == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('गौवंश बायोडेटा (Biodata)')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 54,
                  color: Colors.orange,
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'गौवंश रिकॉर्ड उपलब्ध नहीं है।',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('वापस जाएं'),
                  style: FilledButton.styleFrom(backgroundColor: _forest),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: LocalGoshalaStore.instance,
      builder: (context, _) {
        final currentCow = LocalGoshalaStore.instance.cows.firstWhere(
          (c) => c.id == _cow!.id,
          orElse: () => _cow!,
        );

        final rows = <(String, String)>[
          ('Cow ID', currentCow.id),
          ('टैग नंबर', currentCow.tag),
          ('नाम', currentCow.name.isEmpty ? 'बिना नाम' : currentCow.name),
          ('नस्ल', currentCow.breed.isEmpty ? 'अज्ञात' : currentCow.breed),
          ('लिंग', currentCow.gender.isEmpty ? 'अज्ञात' : currentCow.gender),
          ('उम्र', '${currentCow.age} वर्ष'),
          ('रंग', currentCow.color.isEmpty ? 'अज्ञात' : currentCow.color),
          ('दुधारू स्थिति', currentCow.isMilking ? 'हाँ (दुधारू)' : 'नहीं'),
          if (currentCow.isMilking && currentCow.dailyMilkYield.isNotEmpty)
            ('दैनिक दूध उत्पादन', currentCow.dailyMilkYield),
          ('गर्भावस्था स्थिति', currentCow.pregnancyStatus),
          if (currentCow.expectedCalvingDate != null)
            ('संभावित प्रसव तिथि', _formatDate(currentCow.expectedCalvingDate!)),
          ('आगमन तिथि', _formatDate(currentCow.arrivalDate)),
          (
            'आगमन स्रोत',
            currentCow.sourceDetails.isEmpty ? 'कोई विवरण नहीं' : currentCow.sourceDetails,
          ),
          ('स्वास्थ्य स्थिति', currentCow.health.isEmpty ? 'अज्ञात' : currentCow.health),
          ('स्थिति', currentCow.statusLabel),
          ('वजन', currentCow.weight.isEmpty ? 'अज्ञात' : currentCow.weight),
          (
            'टीकाकरण',
            currentCow.vaccination.isEmpty ? 'कोई जानकारी नहीं' : currentCow.vaccination,
          ),
          ('मेडिकल स्थिति', currentCow.disease.isEmpty ? 'कोई जानकारी नहीं' : currentCow.disease),
          ('नोट्स', currentCow.notes.isEmpty ? 'कोई नोट्स नहीं' : currentCow.notes),
          ('बनाया गया', _formatDate(currentCow.createdAt)),
          ('अंतिम अपडेट', _formatDate(currentCow.updatedAt)),
        ];

        return StreamBuilder<AppUser?>(
          stream: FirebaseBackend.instance.userProfileChanges(),
          builder: (context, snapshot) {
            final user = snapshot.data;
            final canEdit = user != null && user.hasPermission(AppPermission.cows);
            final isAdmin = user?.isAdmin ?? false;

            return Scaffold(
              appBar: AppBar(
                leading: Navigator.canPop(context)
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.home_outlined),
                        tooltip: 'मुख्य पृष्ठ',
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                          );
                        },
                      ),
                title: const Text('गाय विवरण (Biodata)'),
                actions: [
                  IconButton(
                    tooltip: 'पहचान पत्र प्रिंट / डाउनलोड',
                    onPressed: () => _showPrintIdCardDialog(context, currentCow),
                    icon: const Icon(Icons.print_outlined),
                  ),
                  IconButton(
                    tooltip: 'बायोडेटा शेयर करें',
                    onPressed: () => _shareBiodata(currentCow),
                    icon: const Icon(Icons.share_outlined),
                  ),
                  if (canEdit)
                    IconButton(
                      tooltip: 'संपादित करें (Edit Biodata)',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CowFormScreen(cow: currentCow),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  if (isAdmin)
                    IconButton(
                      tooltip: 'Delete (केवल Admin)',
                      onPressed: () => _delete(context, currentCow),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                    ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(child: CowAvatar(cow: currentCow, size: 110)),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      currentCow.name.isEmpty ? currentCow.tag : currentCow.name,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusChip(label: currentCow.statusLabel),
                      _StatusChip(
                        label: currentCow.health,
                        backgroundColor: const Color(0xFFE8F6ED),
                        textColor: _forest,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Digital Identity QR & Barcode Card
                  _DigitalIdCard(
                    cow: currentCow,
                    onPrint: () => _showPrintIdCardDialog(context, currentCow),
                    onShare: () => _shareBiodata(currentCow),
                    onEdit: canEdit
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CowFormScreen(cow: currentCow),
                              ),
                            )
                        : null,
                  ),

                  const SizedBox(height: 18),
                  _InfoTable(rows: rows),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DigitalIdCard extends StatelessWidget {
  const _DigitalIdCard({
    required this.cow,
    required this.onPrint,
    required this.onShare,
    this.onEdit,
  });

  final CowRecord cow;
  final VoidCallback onPrint;
  final VoidCallback onShare;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E8DE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
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
              const Icon(Icons.qr_code_2_rounded, color: _forest, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'डिजिटल पहचान (QR Code & Barcode)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18, color: _muted),
                tooltip: 'Cow ID कॉपी करें',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: cow.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cow ID (${cow.id}) कॉपी हो गया।')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _leaf,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Cow ID: ',
                  style: TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w600),
                ),
                Text(
                  cow.id,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _forest,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              final qrWidget = Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5ECE3)),
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: cow.publicBiodataUrl,
                      version: QrVersions.auto,
                      size: 110,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'QR (बायोडेटा URL)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _forest,
                      ),
                    ),
                  ],
                ),
              );

              final barcodeWidget = Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5ECE3)),
                ),
                child: Column(
                  children: [
                    BarcodeWidget(
                      barcode: Barcode.code128(),
                      data: cow.id,
                      width: 170,
                      height: 55,
                      drawText: true,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _ink),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Barcode (Cow ID)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _forest,
                      ),
                    ),
                  ],
                ),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    qrWidget,
                    const SizedBox(height: 12),
                    barcodeWidget,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  qrWidget,
                  barcodeWidget,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPrint,
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: const Text('आईडी कार्ड प्रिंट'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('शेयर बायोडेटा'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          if (onEdit != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                label: const Text('बायोडेटा संपादित करें (Edit / Update)'),
                style: FilledButton.styleFrom(
                  backgroundColor: _forest,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTable extends StatelessWidget {
  const _InfoTable({required this.rows});
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
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 128,
                    child: Text(row.$1, style: const TextStyle(color: _muted)),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
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

class CowFormScreen extends StatefulWidget {
  const CowFormScreen({this.cow, super.key});
  final CowRecord? cow;

  @override
  State<CowFormScreen> createState() => _CowFormScreenState();
}

class _CowFormScreenState extends State<CowFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _id;
  late final TextEditingController _tag;
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _breed;
  late final TextEditingController _color;
  late final TextEditingController _sourceDetails;
  late final TextEditingController _weight;
  late final TextEditingController _vaccination;
  late final TextEditingController _disease;
  late final TextEditingController _notes;
  late final TextEditingController _dailyMilkYield;
  late String _gender;
  late String _status;
  late bool _isMilking;
  late String _pregnancyStatus;
  late DateTime _arrivalDate;
  DateTime? _expectedCalvingDate;
  String? _photoUrl;
  Uint8List? _selectedPhotoBytes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final cow = widget.cow;
    _id = TextEditingController(text: cow?.id ?? CowRecord.generateCowId());
    _tag = TextEditingController(text: cow?.tag ?? '');
    _name = TextEditingController(text: cow?.name ?? '');
    _age = TextEditingController(text: cow == null ? '' : '${cow.age}');
    _breed = TextEditingController(text: cow?.breed ?? '');
    _color = TextEditingController(text: cow?.color ?? '');
    _sourceDetails = TextEditingController(text: cow?.sourceDetails ?? '');
    _weight = TextEditingController(text: cow?.weight ?? '');
    _vaccination = TextEditingController(text: cow?.vaccination ?? '');
    _disease = TextEditingController(text: cow?.disease ?? '');
    _notes = TextEditingController(text: cow?.notes ?? '');
    _dailyMilkYield = TextEditingController(text: cow?.dailyMilkYield ?? '');
    _gender = cow?.gender ?? 'मादा';
    _status = cow?.statusLabel ?? 'स्वस्थ';
    _isMilking = cow?.isMilking ?? false;
    _pregnancyStatus =
        cow?.pregnancyStatus ??
        (_status == 'गर्भवती' ? 'गर्भवती' : 'गैर-गर्भवती');
    _arrivalDate = cow?.arrivalDate ?? DateTime.now();
    _expectedCalvingDate = cow?.expectedCalvingDate;
    _photoUrl = cow?.photoUrl ?? cow?.photoData;
  }

  @override
  void dispose() {
    for (final controller in [
      _id,
      _tag,
      _name,
      _age,
      _breed,
      _color,
      _sourceDetails,
      _weight,
      _vaccination,
      _disease,
      _notes,
      _dailyMilkYield,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _selectedPhotoBytes = bytes);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _arrivalDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) setState(() => _arrivalDate = date);
  }

  Future<void> _pickCalvingDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _expectedCalvingDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _expectedCalvingDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final cowId = _id.text.trim().isEmpty
          ? CowRecord.generateCowId()
          : _id.text.trim();
      final cowTag = _tag.text.trim().isEmpty ? cowId : _tag.text.trim();

      String? finalPhotoUrl = _photoUrl;
      if (_selectedPhotoBytes != null) {
        try {
          finalPhotoUrl = await LocalGoshalaStore.instance.uploadCowPhoto(
            cowId: cowId,
            bytes: _selectedPhotoBytes!,
          );
        } catch (uploadErr) {
          debugPrint('Cow photo upload to Firebase Storage failed: $uploadErr');
          if (mounted) {
            final errorText = uploadErr is StateError
                ? 'फोटो अपलोड करने के लिए लॉगिन आवश्यक है।'
                : 'फोटो अपलोड विफल: ${FirebaseBackend.userFriendlyAuthError(uploadErr)}';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorText),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
          return;
        }
      }

      final cow = CowRecord(
        id: cowId,
        tag: cowTag,
        name: _name.text.trim(),
        age: int.tryParse(_age.text.trim()) ?? 0,
        breed: _breed.text.trim(),
        gender: _gender,
        arrivalDate: _arrivalDate,
        health: _status,
        notes: _notes.text.trim(),
        status: _status,
        color: _color.text.trim(),
        sourceDetails: _sourceDetails.text.trim(),
        weight: _weight.text.trim(),
        vaccination: _vaccination.text.trim(),
        disease: _disease.text.trim(),
        photoUrl: finalPhotoUrl,
        photoData: finalPhotoUrl,
        goshalaId: widget.cow?.goshalaId ?? 'jay-bhole-goshala',
        isMilking: _isMilking,
        pregnancyStatus: _pregnancyStatus,
        dailyMilkYield: _dailyMilkYield.text.trim(),
        expectedCalvingDate: _pregnancyStatus == 'गर्भवती'
            ? _expectedCalvingDate
            : null,
        createdAt: widget.cow?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.cow == null) {
        await LocalGoshalaStore.instance.addCow(cow);
      } else {
        await LocalGoshalaStore.instance.updateCow(cow);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'रिकॉर्ड सेव करने में समस्या हुई। कृपया फिर से प्रयास करें।',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cow == null ? 'गाय जोड़ें' : 'गाय संपादित करें'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 47,
                    backgroundColor: _leaf,
                    backgroundImage: _selectedPhotoBytes != null
                        ? MemoryImage(_selectedPhotoBytes!)
                        : (_photoUrl != null && _photoUrl!.trim().isNotEmpty
                            ? NetworkImage(_photoUrl!.trim())
                            : null),
                    child: (_selectedPhotoBytes == null &&
                            (_photoUrl == null || _photoUrl!.trim().isEmpty))
                        ? const Icon(Icons.pets_rounded, color: _forest, size: 40)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IconButton.filled(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.camera_alt_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _textField(
              _id,
              'Cow ID (स्वतः जनरेटेड Unique ID)',
              helperText: 'प्रत्येक गाय के लिए यह यूनिक ID स्वतः बनती है',
              required: true,
            ),
            _textField(_tag, 'Tag Number (टैग नंबर / पहचान)', required: false),
            _textField(_name, 'नाम (वैकल्पिक)', required: false),
            _textField(_breed, 'नस्ल (उदा. गिर, साहीवाल, थारपारकर)'),
            Row(
              children: [
                Expanded(child: _textField(_age, 'उम्र (वर्ष)', numeric: true)),
                const SizedBox(width: 12),
                Expanded(child: _textField(_color, 'रंग', required: false)),
              ],
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'लिंग'),
              items: const ['मादा', 'नर', 'अन्य']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _gender = value);
                }
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0E8DE)),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'क्या यह दुधारू गाय है? (Milking)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                value: _isMilking,
                activeThumbColor: _forest,
                onChanged: (val) => setState(() => _isMilking = val),
              ),
            ),
            if (_isMilking) ...[
              const SizedBox(height: 10),
              _textField(
                _dailyMilkYield,
                'दैनिक औसत दूध उत्पादन (उदा. 8 लीटर)',
                required: false,
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _pregnancyStatus,
              decoration: const InputDecoration(
                labelText: 'गर्भावस्था स्थिति (Pregnancy Status)',
              ),
              items: CowRecord.pregnancyStatusOptions
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _pregnancyStatus = value);
                }
              },
            ),
            if (_pregnancyStatus == 'गर्भवती') ...[
              const SizedBox(height: 10),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE0E8DE)),
                ),
                tileColor: Colors.white,
                title: const Text('संभावित प्रसव तिथि (Expected Calving Date)'),
                subtitle: Text(
                  _expectedCalvingDate == null
                      ? 'तारीख चुनें'
                      : _formatDate(_expectedCalvingDate!),
                  style: TextStyle(
                    color: _expectedCalvingDate == null ? _muted : _forest,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: const Icon(Icons.event_outlined),
                onTap: _pickCalvingDate,
              ),
            ],
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('आगमन तिथि'),
              subtitle: Text(_formatDate(_arrivalDate)),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: _pickDate,
            ),
            _textField(_sourceDetails, 'स्रोत / आगमन विवरण', required: false),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'स्वास्थ्य स्थिति'),
              items: CowRecord.healthStatusOptions
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    _weight,
                    'वजन (उदा. 350 kg)',
                    required: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textField(
                    _vaccination,
                    'टीकाकरण जानकारी',
                    required: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _textField(
              _disease,
              'वर्तमान बीमारी / मेडिकल स्थिति',
              required: false,
            ),
            const SizedBox(height: 4),
            _textField(
              _notes,
              'नोट्स / विशेष देखभाल निर्देश',
              maxLines: 3,
              required: false,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'सेव हो रहा है...' : 'रिकॉर्ड सेव करें'),
              style: FilledButton.styleFrom(
                backgroundColor: _forest,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool numeric = false,
    int maxLines = 1,
    bool required = true,
    String? helperText,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label दर्ज करें';
              }
              if (numeric && int.tryParse(value.trim()) == null) {
                return 'मान्य संख्या दर्ज करें';
              }
              return null;
            }
          : null,
    ),
  );
}

class CowScannerDialog extends StatefulWidget {
  const CowScannerDialog({required this.cows, super.key});
  final List<CowRecord> cows;

  @override
  State<CowScannerDialog> createState() => _CowScannerDialogState();
}

class _CowScannerDialogState extends State<CowScannerDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSearch([String? rawInput]) async {
    final input = (rawInput ?? _controller.text).trim();
    if (input.isEmpty) {
      setState(() => _errorMessage = 'कृपया QR/Barcode कोड या Cow ID दर्ज करें।');
      return;
    }

    var cleanCode = input;
    final uri = Uri.tryParse(input);
    if (uri != null && uri.queryParameters.containsKey('id')) {
      cleanCode = uri.queryParameters['id']!.trim();
    } else if (cleanCode.contains('COW-')) {
      final match = RegExp(r'COW-[A-Za-z0-9-]+').firstMatch(cleanCode);
      if (match != null) {
        cleanCode = match.group(0)!;
      }
    }

    CowRecord? matched;
    for (final cow in widget.cows) {
      final idLower = cow.id.trim().toLowerCase();
      final tagLower = cow.tag.trim().toLowerCase();
      final nameLower = cow.name.trim().toLowerCase();
      final inputLower = input.toLowerCase();
      final cleanLower = cleanCode.toLowerCase();

      if (idLower == cleanLower ||
          idLower == inputLower ||
          tagLower == cleanLower ||
          tagLower == inputLower ||
          (input.length >= 2 && nameLower == inputLower)) {
        matched = cow;
        break;
      }
    }

    if (matched != null) {
      if (mounted) {
        Navigator.pop(context);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CowDetailScreen(cow: matched!)),
        );
      }
      return;
    }

    // Try fetching from Cloud Firestore
    final cloudCow = await LocalGoshalaStore.instance.getCowById(cleanCode);
    if (cloudCow != null && mounted) {
      Navigator.pop(context);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CowDetailScreen(cow: cloudCow)),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _errorMessage = 'ID / कोड "$input" से कोई गौवंश रिकॉर्ड नहीं मिला।';
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) {
      _controller.text = text;
      _handleSearch(text);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('क्लिपबोर्ड में कोई टेक्स्ट नहीं मिला।')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.qr_code_scanner_rounded, color: _forest, size: 26),
          SizedBox(width: 8),
          Expanded(child: Text('QR / Barcode स्कैनर')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'स्कैनर गन / डिवाइस से कोड स्कैन करें अथवा सीधे Cow ID दर्ज करें:',
              style: TextStyle(fontSize: 13, color: _muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Cow ID / Barcode / QR डेटा',
                hintText: 'उदा. COW-261002-12345',
                prefixIcon: const Icon(Icons.qr_code_2_rounded),
                suffixIcon: IconButton(
                  tooltip: 'क्लिपबोर्ड से पेस्ट करें',
                  icon: const Icon(Icons.paste_rounded),
                  onPressed: _pasteFromClipboard,
                ),
              ),
              onSubmitted: _handleSearch,
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (widget.cows.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'पंजीकृत गौवंश (त्वरित चयन):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _ink),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.cows.take(6).map((c) {
                  return ActionChip(
                    avatar: const Icon(Icons.pets, size: 14, color: _forest),
                    label: Text(
                      '${c.name.isNotEmpty ? c.name : c.tag} (${c.id})',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onPressed: () {
                      _controller.text = c.id;
                      _handleSearch(c.id);
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('रद्द करें'),
        ),
        FilledButton.icon(
          onPressed: () => _handleSearch(),
          icon: const Icon(Icons.search_rounded, size: 18),
          label: const Text('बायोडेटा खोलें'),
          style: FilledButton.styleFrom(backgroundColor: _forest),
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
