import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_data.dart';
import '../models/cow_record.dart';
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

  @override
  Widget build(BuildContext context) {
    final store = LocalGoshalaStore.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('गाय सूची'),
        actions: [
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
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'ID, नाम, tag, नस्ल, स्वास्थ्य या स्थिति खोजें',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _statusFilter,
                      decoration: const InputDecoration(labelText: 'स्थिति'),
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

class CowDetailScreen extends StatelessWidget {
  const CowDetailScreen({required this.cow, super.key});
  final CowRecord cow;

  Future<void> _delete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('गाय का रिकॉर्ड हटाएं?'),
        content: Text('${cow.name} का रिकॉर्ड स्थायी रूप से हट जाएगा।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('रद्द करें'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('हटाएं'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !context.mounted) return;
    await LocalGoshalaStore.instance.deleteCow(cow.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Cow ID / Tag', '${cow.id} • ${cow.tag}'),
      ('नाम', cow.name),
      ('नस्ल', cow.breed.isEmpty ? 'अज्ञात' : cow.breed),
      ('लिंग', cow.gender.isEmpty ? 'अज्ञात' : cow.gender),
      ('उम्र', '${cow.age} वर्ष'),
      ('रंग', cow.color.isEmpty ? 'अज्ञात' : cow.color),
      ('आगमन तिथि', _formatDate(cow.arrivalDate)),
      (
        'आगमन स्रोत',
        cow.sourceDetails.isEmpty ? 'कोई विवरण नहीं' : cow.sourceDetails,
      ),
      ('स्वास्थ्य स्थिति', cow.health.isEmpty ? 'अज्ञात' : cow.health),
      ('स्थिति', cow.statusLabel),
      ('वजन', cow.weight.isEmpty ? 'अज्ञात' : cow.weight),
      (
        'टीकाकरण',
        cow.vaccination.isEmpty ? 'कोई जानकारी नहीं' : cow.vaccination,
      ),
      ('मेडिकल स्थिति', cow.disease.isEmpty ? 'कोई जानकारी नहीं' : cow.disease),
      ('नोट्स', cow.notes.isEmpty ? 'कोई नोट्स नहीं' : cow.notes),
      ('बनाया गया', _formatDate(cow.createdAt)),
      ('अंतिम अपडेट', _formatDate(cow.updatedAt)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('गाय详情'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => CowFormScreen(cow: cow))),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () => _delete(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: CowAvatar(cow: cow, size: 110)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              cow.name.isEmpty ? cow.tag : cow.name,
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
              _StatusChip(label: cow.statusLabel),
              _StatusChip(
                label: cow.health,
                backgroundColor: const Color(0xFFE8F6ED),
                textColor: _forest,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _InfoTable(rows: rows),
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
  late String _gender;
  late String _status;
  late DateTime _arrivalDate;
  String? _photoData;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final cow = widget.cow;
    _id = TextEditingController(text: cow?.id ?? '');
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
    _gender = cow?.gender ?? 'मादा';
    _status = cow?.statusLabel ?? 'स्वस्थ';
    _arrivalDate = cow?.arrivalDate ?? DateTime.now();
    _photoData = cow?.photoData;
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
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _photoData = base64Encode(bytes));
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final cow = CowRecord(
        id: _id.text.trim().isEmpty
            ? 'COW-${DateTime.now().millisecondsSinceEpoch}'
            : _id.text.trim(),
        tag: _tag.text.trim().isEmpty ? _id.text.trim() : _tag.text.trim(),
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
        photoData: _photoData,
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
        title: Text(widget.cow == null ? 'गाय जोड़ें' : 'गाय编辑 करें'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Center(
              child: Stack(
                children: [
                  CowAvatar(
                    cow: CowRecord(
                      id: _id.text.trim(),
                      tag: _tag.text.trim(),
                      name: _name.text.trim(),
                      age: int.tryParse(_age.text.trim()) ?? 0,
                      breed: _breed.text.trim(),
                      gender: _gender,
                      arrivalDate: _arrivalDate,
                      health: _status,
                      notes: _notes.text.trim(),
                      photoData: _photoData,
                    ),
                    size: 94,
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
            _textField(_id, 'Cow ID / Tag Number', required: false),
            _textField(_tag, 'Tag Number', required: false),
            _textField(_name, 'नाम'),
            _textField(_breed, 'नस्ल'),
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
              decoration: const InputDecoration(labelText: 'स्थिति'),
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
                Expanded(child: _textField(_weight, 'वजन', required: false)),
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
            _textField(_notes, 'नोट्स', maxLines: 4, required: false),
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
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
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

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
