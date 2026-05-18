import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class SaleReceiptModal extends StatelessWidget {
  final Sale sale;
  final List<SaleLine> lines;
  final String? staffName;
  final String? clientName;

  const SaleReceiptModal({
    super.key,
    required this.sale,
    required this.lines,
    this.staffName,
    this.clientName,
  });

  String get _receiptNo =>
      '#${sale.id?.toString().padLeft(6, '0') ?? '000001'}';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.97,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Receipt',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Receipt body
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  // Receipt card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purple.withOpacity(0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Purple header band
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 22),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.purpleDark,
                                AppColors.purple,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20)),
                          ),
                          child: Column(
                            children: [
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5),
                                  children: [
                                    TextSpan(
                                        text: 'Gen',
                                        style:
                                            TextStyle(color: Colors.white)),
                                    TextSpan(
                                        text: 'Salon',
                                        style: TextStyle(
                                            color: Color(0xFFE9D5FF))),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'OFFICIAL RECEIPT',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  letterSpacing: 2.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Jagged edge divider
                        _JaggedDivider(color: Colors.white),

                        // Receipt body
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Meta info
                              _metaRow('Receipt No', _receiptNo,
                                  color: Colors.black87),
                              _metaRow('Date',
                                  dateTimeFmt.format(sale.paidAt),
                                  color: Colors.black87),
                              if (staffName != null)
                                _metaRow('Staff', staffName!,
                                    color: Colors.black87),
                              if (clientName != null)
                                _metaRow('Client', clientName!,
                                    color: Colors.black87),
                              _metaRow('Payment', sale.paymentMethod,
                                  color: Colors.black87),
                              if (sale.notes != null &&
                                  sale.notes!.isNotEmpty)
                                _metaRow('Notes', sale.notes!,
                                    color: Colors.black54),

                              const SizedBox(height: 14),
                              const Divider(color: Colors.black12),
                              const SizedBox(height: 8),

                              // Column headers
                              Row(children: [
                                const Expanded(
                                    flex: 5,
                                    child: Text('ITEM',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black38,
                                            letterSpacing: 1.2))),
                                const SizedBox(
                                    width: 40,
                                    child: Text('QTY',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black38,
                                            letterSpacing: 1.2),
                                        textAlign: TextAlign.center)),
                                Expanded(
                                    flex: 3,
                                    child: Text('AMOUNT',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black38,
                                            letterSpacing: 1.2),
                                        textAlign: TextAlign.right)),
                              ]),
                              const SizedBox(height: 6),
                              const Divider(color: Colors.black12, height: 1),

                              // Line items
                              ...lines.asMap().entries.map((e) {
                                final i = e.key;
                                final l = e.value;
                                return Container(
                                  color: i.isEven
                                      ? Colors.transparent
                                      : const Color(0x08A855F7),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                  child: Row(children: [
                                    Expanded(
                                      flex: 5,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(l.name,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87)),
                                          Text(
                                            l.refType == 'service'
                                                ? 'Service'
                                                : 'Product',
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.black38),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Text('${l.qty}',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54),
                                          textAlign: TextAlign.center),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(formatPeso(l.lineTotal),
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87),
                                          textAlign: TextAlign.right),
                                    ),
                                  ]),
                                );
                              }),

                              const SizedBox(height: 4),
                              const Divider(color: Colors.black12, height: 1),
                              const SizedBox(height: 12),

                              // Total
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.purple.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppColors.purple.withOpacity(0.2)),
                                ),
                                child: Row(children: [
                                  const Text('TOTAL',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black87,
                                          letterSpacing: 1)),
                                  const Spacer(),
                                  Text(formatPeso(sale.total),
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.purple)),
                                ]),
                              ),

                              const SizedBox(height: 20),
                              const Divider(
                                  color: Colors.black12,
                                  height: 1,
                                  indent: 40,
                                  endIndent: 40),
                              const SizedBox(height: 14),

                              // Footer
                              const Center(
                                child: Text('Thank you for your visit!',
                                    style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic)),
                              ),
                              const SizedBox(height: 4),
                              const Center(
                                child: Text('GenSalon — Your General Salon',
                                    style: TextStyle(
                                        color: Colors.black38, fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _exportPdf(context),
                        icon: const Icon(Icons.picture_as_pdf_outlined,
                            color: AppColors.purple),
                        label: const Text('Export PDF',
                            style: TextStyle(color: AppColors.purple)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.purple),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Done'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Colors.black38, fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 12,
                    color: color ?? Colors.black87,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    await Printing.layoutPdf(
      name: 'GenSalon_Receipt_$_receiptNo',
      onLayout: (_) => _buildPdf(),
    );
  }

  Future<Uint8List> _buildPdf() async {
    final pdf = pw.Document();
    final purpleColor = PdfColor.fromHex('#A855F7');
    final purpleDark = PdfColor.fromHex('#7E22CE');
    final greyLight = PdfColor.fromHex('#F3F4F6');
    final textGrey = PdfColor.fromHex('#6B7280');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(0),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Header band
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 24, vertical: 28),
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [purpleDark, purpleColor],
                  begin: pw.Alignment.topLeft,
                  end: pw.Alignment.bottomRight,
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: 'Gen',
                          style: pw.TextStyle(
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white),
                        ),
                        pw.TextSpan(
                          text: 'Salon',
                          style: pw.TextStyle(
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#E9D5FF')),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('OFFICIAL RECEIPT',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#D8B4FE'),
                          fontSize: 9,
                          letterSpacing: 2.5,
                          fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),

            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(24),
                color: PdfColors.white,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // Meta info
                    _pdfMetaRow('Receipt No', _receiptNo, textGrey),
                    _pdfMetaRow('Date', dateTimeFmt.format(sale.paidAt), textGrey),
                    if (staffName != null)
                      _pdfMetaRow('Staff', staffName!, textGrey),
                    if (clientName != null)
                      _pdfMetaRow('Client', clientName!, textGrey),
                    _pdfMetaRow('Payment', sale.paymentMethod, textGrey),
                    if (sale.notes != null && sale.notes!.isNotEmpty)
                      _pdfMetaRow('Notes', sale.notes!, textGrey),

                    pw.SizedBox(height: 14),
                    pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                    pw.SizedBox(height: 8),

                    // Table header
                    pw.Container(
                      color: greyLight,
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: pw.Row(children: [
                        pw.Expanded(
                          flex: 5,
                          child: pw.Text('ITEM',
                              style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: textGrey,
                                  letterSpacing: 1)),
                        ),
                        pw.SizedBox(
                          width: 32,
                          child: pw.Text('QTY',
                              style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: textGrey,
                                  letterSpacing: 1),
                              textAlign: pw.TextAlign.center),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text('AMOUNT',
                              style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: textGrey,
                                  letterSpacing: 1),
                              textAlign: pw.TextAlign.right),
                        ),
                      ]),
                    ),

                    // Line items
                    ...lines.asMap().entries.map((e) {
                      final i = e.key;
                      final l = e.value;
                      return pw.Container(
                        color: i.isEven ? PdfColors.white : greyLight,
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 7),
                        child: pw.Row(children: [
                          pw.Expanded(
                            flex: 5,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(l.name,
                                    style: pw.TextStyle(
                                        fontSize: 10,
                                        fontWeight: pw.FontWeight.bold)),
                                pw.Text(
                                  l.refType == 'service' ? 'Service' : 'Product',
                                  style: pw.TextStyle(
                                      fontSize: 8, color: textGrey),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(
                            width: 32,
                            child: pw.Text('${l.qty}',
                                style: pw.TextStyle(fontSize: 10),
                                textAlign: pw.TextAlign.center),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(formatPeso(l.lineTotal),
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.right),
                          ),
                        ]),
                      );
                    }),

                    pw.SizedBox(height: 8),
                    pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                    pw.SizedBox(height: 10),

                    // Total box
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#F5F0FF'),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(8)),
                        border: pw.Border.all(
                            color: PdfColor.fromHex('#D8B4FE'), width: 0.8),
                      ),
                      child: pw.Row(children: [
                        pw.Text('TOTAL',
                            style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                letterSpacing: 1)),
                        pw.Spacer(),
                        pw.Text(formatPeso(sale.total),
                            style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: purpleColor)),
                      ]),
                    ),

                    pw.Spacer(),
                    pw.Divider(
                        color: PdfColors.grey300,
                        thickness: 0.5,
                        indent: 40,
                        endIndent: 40),
                    pw.SizedBox(height: 8),
                    pw.Center(
                      child: pw.Text('Thank you for your visit!',
                          style: pw.TextStyle(
                              fontSize: 9,
                              color: textGrey,
                              fontStyle: pw.FontStyle.italic)),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Center(
                      child: pw.Text('GenSalon — Your General Salon',
                          style:
                              pw.TextStyle(fontSize: 8, color: textGrey)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Uint8List.fromList(await pdf.save());
  }

  pw.Widget _pdfMetaRow(String label, String value, PdfColor labelColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(fontSize: 9, color: labelColor)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Jagged (perforated) divider for receipt look
class _JaggedDivider extends StatelessWidget {
  final Color color;
  const _JaggedDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: CustomPaint(
        painter: _JaggedPainter(color: color),
        child: const SizedBox(height: 16),
      ),
    );
  }
}

class _JaggedPainter extends CustomPainter {
  final Color color;
  const _JaggedPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final notchR = 8.0;
    final path = Path();
    path.moveTo(0, 0);
    double x = 0;
    while (x < size.width) {
      path.arcToPoint(Offset(x + notchR * 2, 0),
          radius: Radius.circular(notchR), clockwise: false);
      x += notchR * 2;
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
