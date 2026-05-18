import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'sale_receipt_modal.dart';

class RecordSaleSheet extends StatefulWidget {
  const RecordSaleSheet({super.key});
  @override
  State<RecordSaleSheet> createState() => _RecordSaleSheetState();
}

class _RecordSaleSheetState extends State<RecordSaleSheet> {
  Staff? _staff;
  String _paymentMethod = 'Cash';
  final _notesCtrl = TextEditingController();
  final List<SaleLine> _lines = [];
  bool _saving = false;

  static const _paymentMethods = ['Cash', 'GCash', 'Maya', 'Card', 'Other'];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _total => _lines.fold(0.0, (a, l) => a + l.lineTotal);

  // ── Service picker — full card grid sheet ──────────────────────────────────
  void _openServicePicker(BuildContext context) {
    final state = context.read<AppState>();
    final services = state.services.where((s) => s.active).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.spa_outlined,
                      color: AppColors.purple, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Select Service',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetCtx)),
              ]),
            ),
            const Divider(height: 1),
            if (services.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No active services.',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: services.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final s = services[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() => _lines.add(SaleLine(
                              refType: 'service',
                              refId: s.id!,
                              name: s.name,
                              unitPrice: s.price,
                            )));
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.white10, width: 0.5),
                        ),
                        child: Row(children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.purple.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.spa_outlined,
                                color: AppColors.purple, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981)
                                          .withOpacity(0.12),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(formatPeso(s.price),
                                        style: const TextStyle(
                                            color: Color(0xFF10B981),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.schedule_outlined,
                                      size: 11,
                                      color: AppColors.textMuted),
                                  const SizedBox(width: 3),
                                  Text('${s.durationMin} min',
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11)),
                                ]),
                              ],
                            ),
                          ),
                          const Icon(Icons.add_circle_outline,
                              color: AppColors.purple, size: 22),
                        ]),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Item picker ────────────────────────────────────────────────────────────
  void _openItemPicker(BuildContext context) {
    final state = context.read<AppState>();
    final items = state.items.where((i) => i.stock > 0).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx2) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      color: Color(0xFF3B82F6), size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Select Product',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetCtx2)),
              ]),
            ),
            const Divider(height: 1),
            if (items.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No items with stock available.',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() => _lines.add(SaleLine(
                              refType: 'item',
                              refId: item.id!,
                              name: item.name,
                              unitPrice: item.price,
                            )));
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.white10, width: 0.5),
                        ),
                        child: Row(children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.inventory_2_outlined,
                                color: Color(0xFF3B82F6), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981)
                                          .withOpacity(0.12),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(formatPeso(item.price),
                                        style: const TextStyle(
                                            color: Color(0xFF10B981),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Stock: ${item.stock}',
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11)),
                                ]),
                              ],
                            ),
                          ),
                          const Icon(Icons.add_circle_outline,
                              color: Color(0xFF3B82F6), size: 22),
                        ]),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Save & show receipt ────────────────────────────────────────────────────
  Future<void> _save(BuildContext context) async {
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Add at least one item or service.')));
      return;
    }
    setState(() => _saving = true);
    final appState = context.read<AppState>();
    final sale = Sale(
      staffId: _staff?.id,
      total: _total,
      paymentMethod: _paymentMethod,
      notes:
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    await appState.recordSale(sale, _lines);

    // Reload sales to get the inserted ID
    final sales = await appState.salesInRange(
      DateTime.now().subtract(const Duration(seconds: 5)),
      DateTime.now().add(const Duration(seconds: 5)),
    );
    final savedSale = sales.isNotEmpty ? sales.first : sale;
    final savedLines =
        savedSale.id != null ? await appState.linesFor(savedSale.id!) : _lines;

    final staffName = _staff?.name;

    if (!mounted) return;
    Navigator.pop(context);

    // Show receipt modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SaleReceiptModal(
        sale: savedSale,
        lines: savedLines,
        staffName: staffName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_outlined,
                      color: AppColors.purple, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                    child: Text('Record Sale',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700))),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ]),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),

            Expanded(
              child: SingleChildScrollView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Staff
                    DropdownButtonFormField<Staff>(
                      value: _staff,
                      decoration: const InputDecoration(
                          labelText: 'Staff (optional)',
                          prefixIcon: Icon(Icons.person_outline, size: 18)),
                      dropdownColor: AppColors.surfaceAlt,
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('— None —')),
                        ...state.staffList
                            .where((s) => s.active)
                            .map((s) => DropdownMenuItem(
                                value: s, child: Text(s.name))),
                      ],
                      onChanged: (v) => setState(() => _staff = v),
                    ),
                    const SizedBox(height: 12),

                    // Payment method
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: const InputDecoration(
                          labelText: 'Payment Method',
                          prefixIcon: Icon(Icons.payments_outlined, size: 18)),
                      dropdownColor: AppColors.surfaceAlt,
                      items: _paymentMethods
                          .map((m) =>
                              DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _paymentMethod = v ?? 'Cash'),
                    ),
                    const SizedBox(height: 20),

                    // Add buttons
                    Row(children: [
                      const Text('Order Items',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const Spacer(),
                      _addButton(
                        icon: Icons.spa_outlined,
                        label: '+ Service',
                        color: AppColors.purple,
                        onTap: () => _openServicePicker(context),
                      ),
                      const SizedBox(width: 8),
                      _addButton(
                        icon: Icons.inventory_2_outlined,
                        label: '+ Product',
                        color: const Color(0xFF3B82F6),
                        onTap: () => _openItemPicker(context),
                      ),
                    ]),
                    const SizedBox(height: 10),

                    // Line items
                    if (_lines.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        alignment: Alignment.center,
                        child: const Text(
                          'Tap + Service or + Product to add items',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ...List.generate(_lines.length, (i) {
                        final l = _lines[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white10, width: 0.5),
                          ),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: (l.refType == 'service'
                                        ? AppColors.purple
                                        : const Color(0xFF3B82F6))
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                l.refType == 'service'
                                    ? Icons.spa_outlined
                                    : Icons.inventory_2_outlined,
                                size: 14,
                                color: l.refType == 'service'
                                    ? AppColors.purple
                                    : const Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  Text(
                                    '${l.refType == "service" ? "Service" : "Product"} · ${formatPeso(l.unitPrice)} each',
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Text(formatPeso(l.lineTotal),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.purple,
                                    fontSize: 14)),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _lines.removeAt(i)),
                              child: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 20,
                                  color: AppColors.textMuted),
                            ),
                          ]),
                        );
                      }),

                    if (_lines.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      const Divider(height: 24),

                      // Total summary box
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.purple.withOpacity(0.15),
                              AppColors.purpleDark.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.purple.withOpacity(0.25)),
                        ),
                        child: Row(children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_lines.length} item${_lines.length == 1 ? "" : "s"}',
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12),
                              ),
                              const Text('TOTAL',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      letterSpacing: 1)),
                            ],
                          ),
                          const Spacer(),
                          Text(formatPeso(_total),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                  color: AppColors.purple)),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        prefixIcon: Icon(Icons.notes_outlined, size: 18),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : () => _save(context),
                        icon: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_outline),
                        label: Text(_saving
                            ? 'Saving…'
                            : 'Complete Sale  •  ${formatPeso(_total)}'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
