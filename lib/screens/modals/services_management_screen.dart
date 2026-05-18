import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class ServicesManagementScreen extends StatelessWidget {
  const ServicesManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.watch<AppState>().services;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: services.isEmpty
          ? const Center(
              child: Text('No services added yet.',
                  style: TextStyle(color: AppColors.textMuted)))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: services.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final s = services[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.purple.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.spa_outlined,
                              color: AppColors.purple, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                  child: Text(s.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                ),
                                if (!s.active)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white12,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Inactive',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textMuted)),
                                  ),
                              ]),
                              const SizedBox(height: 4),
                              Row(children: [
                                Text(formatPeso(s.price),
                                    style: const TextStyle(
                                        color: AppColors.purple,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                                const SizedBox(width: 10),
                                const Icon(Icons.schedule_outlined,
                                    size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 3),
                                Text('${s.durationMin} min',
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12)),
                              ]),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: AppColors.purple, size: 20),
                              onPressed: () =>
                                  _openForm(context, service: s),
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.textMuted, size: 20),
                              onPressed: () => _delete(context, s),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Service'),
        backgroundColor: AppColors.purple,
      ),
    );
  }

  void _openForm(BuildContext context, {Service? service}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AppState>(),
        child: _ServiceFormSheet(service: service),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Service s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Service?'),
        content: Text('Remove "${s.name}" from the service list?'),
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
    if (ok == true && context.mounted) {
      await context.read<AppState>().deleteService(s.id!);
    }
  }
}

class _ServiceFormSheet extends StatefulWidget {
  final Service? service;
  const _ServiceFormSheet({this.service});
  @override
  State<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<_ServiceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _price;
  late TextEditingController _duration;
  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.service?.name ?? '');
    _price = TextEditingController(
        text: widget.service != null
            ? widget.service!.price.toStringAsFixed(2)
            : '');
    _duration = TextEditingController(
        text: widget.service?.durationMin.toString() ?? '30');
    _active = widget.service?.active ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final svc = Service(
      id: widget.service?.id,
      name: _name.text.trim(),
      price: double.tryParse(_price.text) ?? 0,
      durationMin: int.tryParse(_duration.text) ?? 30,
      active: _active,
    );
    if (widget.service == null) {
      await context.read<AppState>().addService(svc);
    } else {
      await context.read<AppState>().updateService(svc);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.spa_outlined,
                    color: AppColors.purple, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.service == null ? 'Add Service' : 'Edit Service',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 20),

            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Service Name',
                prefixIcon: Icon(Icons.spa_outlined, size: 18),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _price,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixText: '₱ ',
                    prefixIcon: Icon(Icons.payments_outlined, size: 18),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _duration,
                  decoration: const InputDecoration(
                    labelText: 'Duration (min)',
                    prefixIcon: Icon(Icons.schedule_outlined, size: 18),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (int.tryParse(v) == null) return 'Invalid';
                    return null;
                  },
                ),
              ),
            ]),
            const SizedBox(height: 4),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('Shown in booking & sale dropdowns',
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 12)),
              value: _active,
              activeColor: AppColors.purple,
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(widget.service == null
                        ? 'Add Service'
                        : 'Save Changes'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
