import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Sale> _filteredSales = [];
  bool _loading = false;

  static const _tabs = ['Daily', 'Weekly', 'Monthly'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) _load();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  DateTimeRange _range() {
    final now = DateTime.now();
    switch (_tab.index) {
      case 0:
        final s = DateTime(now.year, now.month, now.day);
        return DateTimeRange(start: s, end: s.add(const Duration(days: 1)));
      case 1:
        final weekday = now.weekday;
        final s = DateTime(now.year, now.month, now.day - (weekday - 1));
        return DateTimeRange(start: s, end: s.add(const Duration(days: 7)));
      case 2:
      default:
        final s = DateTime(now.year, now.month, 1);
        final e = DateTime(now.year, now.month + 1, 1);
        return DateTimeRange(start: s, end: e);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = _range();
    final sales = await context.read<AppState>().salesInRange(r.start, r.end);
    setState(() {
      _filteredSales = sales;
      _loading = false;
    });
  }

  double get _total => _filteredSales.fold(0.0, (a, s) => a + s.total);

  String get _rangeLbl {
    final r = _range();
    if (_tab.index == 0) return dateFmt.format(r.start);
    return '${dateFmt.format(r.start)} – ${dateFmt.format(r.end.subtract(const Duration(seconds: 1)))}';
  }

  Future<void> _exportPdf() async {
    await Printing.layoutPdf(
      name: 'GenSalon_Report_${_tabs[_tab.index]}',
      onLayout: (_) => _buildPdf(),
    );
  }

  Future<Uint8List> _buildPdf() async {
    final pdf = pw.Document();
    final purple = PdfColor.fromHex('#A855F7');
    final purpleDark = PdfColor.fromHex('#7E22CE');
    final grey = PdfColor.fromHex('#6B7280');
    final greyLight = PdfColor.fromHex('#F3F4F6');

    final Map<String, double> pmTotals = {};
    for (final s in _filteredSales) {
      pmTotals[s.paymentMethod] = (pmTotals[s.paymentMethod] ?? 0) + s.total;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [purpleDark, purple],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
            ),
            borderRadius:
                const pw.BorderRadius.all(pw.Radius.circular(10)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.RichText(
                text: pw.TextSpan(children: [
                  pw.TextSpan(
                      text: 'Gen',
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white)),
                  pw.TextSpan(
                      text: 'Salon',
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#E9D5FF'))),
                ]),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('SALES REPORT — ${_tabs[_tab.index].toUpperCase()}',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9,
                          letterSpacing: 1.5,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text(_rangeLbl,
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#E9D5FF'),
                          fontSize: 8)),
                ],
              ),
            ],
          ),
        ),
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('GenSalon — Your General Salon',
                style: pw.TextStyle(fontSize: 8, color: grey)),
            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: grey)),
          ],
        ),
        build: (ctx) => [
          pw.SizedBox(height: 16),

          // Summary box
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F5F0FF'),
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(
                  color: PdfColor.fromHex('#D8B4FE'), width: 0.8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Period',
                        style:
                            pw.TextStyle(fontSize: 9, color: grey)),
                    pw.Text(_tabs[_tab.index],
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Transactions',
                        style:
                            pw.TextStyle(fontSize: 9, color: grey)),
                    pw.Text('${_filteredSales.length} sales',
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('TOTAL SALES',
                        style:
                            pw.TextStyle(fontSize: 9, color: grey)),
                    pw.Text(formatPeso(_total),
                        style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: purple)),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // Payment method breakdown
          if (pmTotals.isNotEmpty) ...[
            pw.Text('By Payment Method',
                style: pw.TextStyle(
                    fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(
                  color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: purple),
                  children: ['METHOD', 'TRANSACTIONS', 'TOTAL']
                      .map((h) => pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            child: pw.Text(h,
                                style: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold)),
                          ))
                      .toList(),
                ),
                ...pmTotals.entries.map((e) => pw.TableRow(
                      decoration:
                          pw.BoxDecoration(color: PdfColors.white),
                      children: [
                        e.key,
                        '${_filteredSales.where((s) => s.paymentMethod == e.key).length}',
                        formatPeso(e.value),
                      ]
                          .map((t) => pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                child: pw.Text(t,
                                    style: pw.TextStyle(
                                        fontSize: 9,
                                        fontWeight:
                                            t == formatPeso(e.value)
                                                ? pw.FontWeight.bold
                                                : pw.FontWeight.normal)),
                              ))
                          .toList(),
                    )),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // Transactions table
          pw.Text('Transactions',
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          if (_filteredSales.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                  color: greyLight,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8))),
              child: pw.Center(
                child: pw.Text('No transactions for this period.',
                    style: pw.TextStyle(color: grey, fontSize: 10)),
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(
                  color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: purple),
                  children: ['DATE & TIME', 'PAYMENT', 'AMOUNT']
                      .map((h) => pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            child: pw.Text(h,
                                style: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold)),
                          ))
                      .toList(),
                ),
                ..._filteredSales.asMap().entries.map((e) {
                  final i = e.key;
                  final s = e.value;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                        color:
                            i.isEven ? PdfColors.white : greyLight),
                    children: [
                      dateTimeFmt.format(s.paidAt),
                      s.paymentMethod,
                      formatPeso(s.total),
                    ]
                        .map((t) => pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              child: pw.Text(t,
                                  style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight:
                                          t == formatPeso(s.total)
                                              ? pw.FontWeight.bold
                                              : pw.FontWeight.normal,
                                      color: t == formatPeso(s.total)
                                          ? purple
                                          : PdfColors.black)),
                            ))
                        .toList(),
                  );
                }),
              ],
            ),

          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('GRAND TOTAL',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text(formatPeso(_total),
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: purple)),
            ],
          ),
        ],
      ),
    );
    return Uint8List.fromList(await pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Page title
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Reports',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ),
        ),
        // Tab bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tab,
            indicator: BoxDecoration(
              color: AppColors.purple,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textMuted,
            dividerColor: Colors.transparent,
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.purple))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.purple,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Center(
                                  child: Text('GENSALON SALES REPORT',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          letterSpacing: 1)),
                                ),
                                const SizedBox(height: 4),
                                Center(
                                  child: Text(_rangeLbl,
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12)),
                                ),
                                const Divider(height: 24),
                                _row('Period Type', _tabs[_tab.index]),
                                _row('Records', '${_filteredSales.length} sales'),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('TOTAL SALES',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15)),
                                    Text(formatPeso(_total),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                            color: AppColors.purple)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Chart
                        if (_filteredSales.isNotEmpty) ...[
                          const Text('Sales by Payment Method',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: SizedBox(
                                height: 160,
                                child: _PaymentPieChart(sales: _filteredSales),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Transactions
                        const Text('Transactions',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        if (_filteredSales.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                    'No sales for this ${_tabs[_tab.index].toLowerCase()} period.',
                                    style: const TextStyle(
                                        color: AppColors.textMuted),
                                    textAlign: TextAlign.center),
                              ),
                            ),
                          )
                        else
                          ...(_filteredSales.map((s) => _SaleTile(sale: s))),

                        const SizedBox(height: 20),

                        // Export buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _exportPdf,
                                icon: const Icon(
                                    Icons.picture_as_pdf_outlined,
                                    color: AppColors.purple),
                                label: const Text('Export PDF',
                                    style:
                                        TextStyle(color: AppColors.purple)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: AppColors.purple),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13)),
          ],
        ),
      );
}

class _SaleTile extends StatelessWidget {
  final Sale sale;
  const _SaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0x26A855F7),
          child: Icon(Icons.receipt_long_outlined,
              color: AppColors.purple, size: 20),
        ),
        title: Text(formatPeso(sale.total),
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.purple)),
        subtitle: Text(
            '${dateTimeFmt.format(sale.paidAt)} • ${sale.paymentMethod}',
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12)),
      ),
    );
  }
}

class _PaymentPieChart extends StatelessWidget {
  final List<Sale> sales;
  const _PaymentPieChart({required this.sales});

  @override
  Widget build(BuildContext context) {
    final Map<String, double> totals = {};
    for (final s in sales) {
      totals[s.paymentMethod] = (totals[s.paymentMethod] ?? 0) + s.total;
    }
    final colors = [
      AppColors.purple,
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
    ];
    final entries = totals.entries.toList();

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: List.generate(entries.length, (i) {
                final e = entries[i];
                return PieChartSectionData(
                  value: e.value,
                  color: colors[i % colors.length],
                  title: '',
                  radius: 52,
                );
              }),
              sectionsSpace: 2,
              centerSpaceRadius: 32,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(entries.length, (i) {
            final e = entries[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${e.key}\n${formatPeso(e.value)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
