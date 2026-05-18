import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/photo_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class ItemsManagementScreen extends StatelessWidget {
  const ItemsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<AppState>().items;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Items Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text('No items added yet.',
                  style: TextStyle(color: AppColors.textMuted)))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final item = items[i];
                final lowStock = item.stock <= item.lowStockThreshold;
                return Card(
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: item.photoPath != null &&
                            File(item.photoPath!).existsSync()
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(item.photoPath!),
                                width: 44, height: 44, fit: BoxFit.cover))
                        : Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.inventory_2_outlined,
                                color: AppColors.textMuted)),
                    title: Text(item.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatPeso(item.price),
                            style: const TextStyle(
                                color: AppColors.purple, fontSize: 12)),
                        Row(children: [
                          Text('Stock: ${item.stock}',
                              style: TextStyle(
                                  color: lowStock
                                      ? const Color(0xFFF59E0B)
                                      : AppColors.textMuted,
                                  fontSize: 12)),
                          if (lowStock) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.warning_amber_outlined,
                                size: 12, color: Color(0xFFF59E0B)),
                          ],
                        ]),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: AppColors.purple, size: 20),
                          onPressed: () => _openForm(context, item: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.textMuted, size: 20),
                          onPressed: () => _delete(context, item),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_box_outlined),
        label: const Text('Add Item'),
        backgroundColor: AppColors.purple,
      ),
    );
  }

  void _openForm(BuildContext context, {Item? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AppState>(),
        child: _ItemFormSheet(item: item),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Item item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Item?'),
        content: Text('Remove "${item.name}" from inventory?'),
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
    if (ok == true) await context.read<AppState>().deleteItem(item.id!);
  }
}

class _ItemFormSheet extends StatefulWidget {
  final Item? item;
  const _ItemFormSheet({this.item});
  @override
  State<_ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends State<_ItemFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _sku;
  late TextEditingController _price;
  late TextEditingController _stock;
  late TextEditingController _threshold;
  String? _photoPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item?.name ?? '');
    _sku = TextEditingController(text: widget.item?.sku ?? '');
    _price = TextEditingController(
        text: widget.item != null ? widget.item!.price.toStringAsFixed(2) : '');
    _stock = TextEditingController(
        text: widget.item?.stock.toString() ?? '0');
    _threshold = TextEditingController(
        text: widget.item?.lowStockThreshold.toString() ?? '5');
    _photoPath = widget.item?.photoPath;
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _price.dispose();
    _stock.dispose();
    _threshold.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final path = await PhotoService.pickAndPersist();
    if (path != null) setState(() => _photoPath = path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final item = Item(
      id: widget.item?.id,
      name: _name.text.trim(),
      sku: _sku.text.trim().isEmpty ? null : _sku.text.trim(),
      price: double.tryParse(_price.text) ?? 0,
      stock: int.tryParse(_stock.text) ?? 0,
      photoPath: _photoPath,
      lowStockThreshold: int.tryParse(_threshold.text) ?? 5,
    );
    if (widget.item == null) {
      await context.read<AppState>().addItem(item);
    } else {
      await context.read<AppState>().updateItem(item);
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
                        widget.item == null ? 'Add Item' : 'Edit Item',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700))),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 16),

              // Photo
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      _photoPath != null && File(_photoPath!).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(File(_photoPath!),
                                  width: 80, height: 80, fit: BoxFit.cover))
                          : Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.add_photo_alternate_outlined,
                                  size: 32, color: AppColors.textMuted)),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.purple,
                          child: const Icon(Icons.camera_alt,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sku,
                decoration:
                    const InputDecoration(labelText: 'SKU (optional)'),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    decoration: const InputDecoration(
                        labelText: 'Price (₱)', prefixText: '₱ '),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stock,
                    decoration: const InputDecoration(labelText: 'Stock Qty'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: _threshold,
                decoration: const InputDecoration(
                    labelText: 'Low Stock Alert Threshold'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

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
                      : Text(widget.item == null ? 'Add Item' : 'Save Changes'),
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
