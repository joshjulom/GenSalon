import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/photo_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/photo_avatar.dart';

class StaffManagementScreen extends StatelessWidget {
  const StaffManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: state.staffList.isEmpty
          ? const Center(
              child: Text('No staff added yet.',
                  style: TextStyle(color: AppColors.textMuted)))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: state.staffList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final s = state.staffList[i];
                return Card(
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: PhotoAvatar(
                        photoPath: s.photoPath,
                        initials: s.name,
                        radius: 22),
                    title: Text(s.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${s.role} • ${s.active ? "Active" : "Inactive"}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: AppColors.purple, size: 20),
                          onPressed: () => _openForm(context, staff: s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.textMuted, size: 20),
                          onPressed: () => _delete(context, s),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Staff'),
        backgroundColor: AppColors.purple,
      ),
    );
  }

  void _openForm(BuildContext context, {Staff? staff}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AppState>(),
        child: _StaffFormSheet(staff: staff),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Staff s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Staff?'),
        content: Text('Remove ${s.name} from staff?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await context.read<AppState>().deleteStaff(s.id!);
  }
}

class _StaffFormSheet extends StatefulWidget {
  final Staff? staff;
  const _StaffFormSheet({this.staff});
  @override
  State<_StaffFormSheet> createState() => _StaffFormSheetState();
}

class _StaffFormSheetState extends State<_StaffFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _role;
  late TextEditingController _phone;
  bool _active = true;
  String? _photoPath;
  bool _saving = false;

  static const _roles = [
    'Stylist', 'Colorist', 'Manicurist', 'Pedicurist',
    'Receptionist', 'Manager', 'Cashier', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.staff?.name ?? '');
    _role = TextEditingController(text: widget.staff?.role ?? 'Stylist');
    _phone = TextEditingController(text: widget.staff?.phone ?? '');
    _active = widget.staff?.active ?? true;
    _photoPath = widget.staff?.photoPath;
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final path = await PhotoService.pickAndPersist();
    if (path != null) setState(() => _photoPath = path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final s = Staff(
      id: widget.staff?.id,
      name: _name.text.trim(),
      role: _role.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      photoPath: _photoPath,
      active: _active,
    );
    if (widget.staff == null) {
      await context.read<AppState>().addStaff(s);
    } else {
      await context.read<AppState>().updateStaff(s);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: Text(
                        widget.staff == null ? 'Add Staff' : 'Edit Staff',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700))),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 16),

              // Photo picker
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      _photoPath != null && File(_photoPath!).existsSync()
                          ? CircleAvatar(
                              radius: 40,
                              backgroundImage:
                                  FileImage(File(_photoPath!)))
                          : const CircleAvatar(
                              radius: 40,
                              backgroundColor: AppColors.surfaceAlt,
                              child: Icon(Icons.person_outline,
                                  size: 36, color: AppColors.textMuted)),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.purple,
                          child: const Icon(Icons.camera_alt,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _roles.contains(_role.text) ? _role.text : 'Other',
                decoration: const InputDecoration(labelText: 'Role'),
                dropdownColor: AppColors.surfaceAlt,
                items: _roles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => _role.text = v ?? 'Stylist',
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phone,
                decoration:
                    const InputDecoration(labelText: 'Phone (optional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _active,
                activeColor: AppColors.purple,
                onChanged: (v) => setState(() => _active = v),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          widget.staff == null ? 'Add Staff' : 'Save Changes'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
