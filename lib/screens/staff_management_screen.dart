import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../branding/brand_config.dart';
import '../models/staff_member.dart';
import '../services/firebase_backend.dart';
import '../services/staff_service.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final _service = StaffService();
  final _picker = ImagePicker();
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'All';
  String _selectedStatus = 'All';

  Future<void> _showCreateEditDialog({StaffMember? staff}) async {
    final isEditing = staff != null;
    final fullNameController = TextEditingController(
      text: staff?.fullName ?? '',
    );
    final mobileController = TextEditingController(
      text: staff?.mobileNumber ?? '',
    );
    final addressController = TextEditingController(text: staff?.address ?? '');
    final roleController = TextEditingController(text: staff?.role ?? '');
    final dutiesController = TextEditingController(
      text: staff?.assignedDuties ?? '',
    );
    final salaryController = TextEditingController(text: staff?.salary ?? '');
    var joiningDate = staff?.joiningDate ?? DateTime.now();
    var isActive = staff?.isActive ?? true;
    String? photoData = staff?.profilePhotoData;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Staff' : 'Add Staff'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () async {
                          final picked = await _picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85,
                          );
                          if (picked == null) return;
                          final file = File(picked.path);
                          final bytes = await file.readAsBytes();
                          setState(() => photoData = base64Encode(bytes));
                        },
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: BrandConfig.leaf,
                          backgroundImage:
                              photoData != null && photoData!.isNotEmpty
                              ? MemoryImage(base64Decode(photoData!))
                              : null,
                          child: photoData == null || photoData!.isEmpty
                              ? const Icon(Icons.person_add_alt_1_outlined)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Mobile number',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Address'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: roleController,
                        decoration: const InputDecoration(
                          labelText: 'Role/designation',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: dutiesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Assigned duties',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: salaryController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Salary (optional)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(child: Text('Joining date')),
                          TextButton(
                            onPressed: () async {
                              final selected = await showDatePicker(
                                context: context,
                                initialDate: joiningDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (selected != null) {
                                setState(() => joiningDate = selected);
                              }
                            },
                            child: Text(
                              '${joiningDate.day}/${joiningDate.month}/${joiningDate.year}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: isActive,
                        onChanged: (value) => setState(() => isActive = value),
                        title: const Text('Active'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    final finalStaff =
                        (staff ??
                                StaffMember(
                                  id: _service.generateId(),
                                  fullName: '',
                                  mobileNumber: '',
                                  address: '',
                                  role: '',
                                  joiningDate: DateTime.now(),
                                  assignedDuties: '',
                                  isActive: true,
                                ))
                            .copyWith(
                              fullName: fullNameController.text.trim(),
                              mobileNumber: mobileController.text.trim(),
                              address: addressController.text.trim(),
                              role: roleController.text.trim(),
                              assignedDuties: dutiesController.text.trim(),
                              salary: salaryController.text.trim(),
                              joiningDate: joiningDate,
                              isActive: isActive,
                              profilePhotoData: photoData ?? '',
                            );

                    try {
                      await _service.saveStaff(finalStaff);
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing ? 'Staff updated' : 'Staff added',
                          ),
                        ),
                      );
                    } catch (error) {
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Failed to save staff: $error')),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _markAttendance(
    StaffMember staff,
    StaffAttendanceStatus status,
  ) async {
    try {
      await _service.updateAttendance(staff.id, DateTime.now(), status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${staff.fullName} marked as ${status.label}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attendance update failed: $error')),
      );
    }
  }

  Future<void> _deleteStaff(StaffMember staff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate staff?'),
        content: Text(
          '${staff.fullName} will be marked inactive and hidden from active list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final updated = staff.copyWith(isActive: false);
    try {
      await _service.saveStaff(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${staff.fullName} deactivated')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to deactivate staff: $error')),
        );
      }
    }
  }

  List<StaffMember> _filteredStaff(List<StaffMember> staff) {
    final search = _searchController.text.trim().toLowerCase();
    return staff.where((member) {
      final matchesSearch =
          search.isEmpty ||
          member.fullName.toLowerCase().contains(search) ||
          member.role.toLowerCase().contains(search) ||
          member.mobileNumber.toLowerCase().contains(search);
      final matchesRole =
          _selectedRole == 'All' || member.role == _selectedRole;
      final matchesStatus =
          _selectedStatus == 'All' ||
          (_selectedStatus == 'Active' && member.isActive) ||
          (_selectedStatus == 'Inactive' && !member.isActive);
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roles = <String>{
      'All',
      'Manager',
      'Caretaker',
      'Volunteer',
      'Guard',
      'Cook',
      'Cleaner',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FirebaseBackend.instance.isAvailable
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateEditDialog(),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add Staff'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Text(
            'Staff Management',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: BrandConfig.ink,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showCreateEditDialog(),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add Staff'),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<StaffMember>>(
            stream: _service.watchStaff(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error loading staff: ${snapshot.error}'),
                  ),
                );
              }

              final staff = snapshot.data ?? const <StaffMember>[];
              final filtered = _filteredStaff(staff);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search by name, role, mobile',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          items: roles
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedRole = value ?? 'All'),
                          decoration: const InputDecoration(labelText: 'Role'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedStatus,
                          items: const [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text('All statuses'),
                            ),
                            DropdownMenuItem(
                              value: 'Active',
                              child: Text('Active'),
                            ),
                            DropdownMenuItem(
                              value: 'Inactive',
                              child: Text('Inactive'),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedStatus = value ?? 'All'),
                          decoration: const InputDecoration(
                            labelText: 'Status',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text('No staff found for the selected filters.'),
                      ),
                    )
                  else
                    ...filtered.map(
                      (member) => _StaffCard(
                        member: member,
                        onEdit: () => _showCreateEditDialog(staff: member),
                        onDeactivate: () => _deleteStaff(member),
                        onView: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StaffDetailScreen(staff: member),
                          ),
                        ),
                        onMarkPresent: () => _markAttendance(
                          member,
                          StaffAttendanceStatus.present,
                        ),
                        onMarkAbsent: () => _markAttendance(
                          member,
                          StaffAttendanceStatus.absent,
                        ),
                        onMarkLeave: () => _markAttendance(
                          member,
                          StaffAttendanceStatus.leave,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({
    required this.member,
    required this.onEdit,
    required this.onDeactivate,
    required this.onView,
    required this.onMarkPresent,
    required this.onMarkAbsent,
    required this.onMarkLeave,
  });

  final StaffMember member;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback onView;
  final VoidCallback onMarkPresent;
  final VoidCallback onMarkAbsent;
  final VoidCallback onMarkLeave;

  @override
  Widget build(BuildContext context) {
    final avatar = member.profilePhotoData.isNotEmpty
        ? MemoryImage(base64Decode(member.profilePhotoData))
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BrandConfig.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: BrandConfig.leaf,
          backgroundImage: avatar,
          child: avatar == null ? Text(member.profileInitials) : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.fullName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: member.isActive
                    ? Colors.green.shade50
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                member.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: member.isActive
                      ? Colors.green.shade800
                      : Colors.grey.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(member.displayRole),
            const SizedBox(height: 4),
            Text(member.mobileNumber),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view':
                onView();
                break;
              case 'edit':
                onEdit();
                break;
              case 'deactivate':
                onDeactivate();
                break;
              case 'present':
                onMarkPresent();
                break;
              case 'absent':
                onMarkAbsent();
                break;
              case 'leave':
                onMarkLeave();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
            const PopupMenuItem(value: 'present', child: Text('Mark Present')),
            const PopupMenuItem(value: 'absent', child: Text('Mark Absent')),
            const PopupMenuItem(value: 'leave', child: Text('Mark Leave')),
          ],
        ),
      ),
    );
  }
}

class StaffDetailScreen extends StatelessWidget {
  const StaffDetailScreen({required this.staff, super.key});

  final StaffMember staff;

  @override
  Widget build(BuildContext context) {
    final avatar = staff.profilePhotoData.isNotEmpty
        ? MemoryImage(base64Decode(staff.profilePhotoData))
        : null;

    final todayStatus = staff.attendance.isNotEmpty
        ? staff.attendance.last.status.label
        : 'No record';

    return Scaffold(
      appBar: AppBar(title: Text(staff.fullName)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 46,
              backgroundColor: BrandConfig.leaf,
              backgroundImage: avatar,
              child: avatar == null
                  ? Text(
                      staff.profileInitials,
                      style: const TextStyle(fontSize: 28),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          _InfoCard(
            title: 'Basic Details',
            rows: [
              ('Name', staff.fullName),
              ('Role', staff.role),
              ('Mobile', staff.mobileNumber),
              ('Status', staff.isActive ? 'Active' : 'Inactive'),
              (
                'Joining date',
                '${staff.joiningDate.day}/${staff.joiningDate.month}/${staff.joiningDate.year}',
              ),
              ('Salary', staff.salary.isEmpty ? 'Not specified' : staff.salary),
            ],
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Address & Duties',
            rows: [
              ('Address', staff.address),
              ('Assigned duties', staff.assignedDuties),
            ],
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Attendance',
            rows: [
              ('Today', todayStatus),
              ('Total entries', staff.attendance.length.toString()),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BrandConfig.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      row.$1,
                      style: const TextStyle(color: BrandConfig.muted),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
