import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'book_appointment_sheet.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  Future<void> _exportPdf(BuildContext context) async {
    final state = context.read<AppState>();
    final appts = state.appointments;
    await Printing.layoutPdf(
      name: 'GenSalon_Appointments',
      onLayout: (_) => _buildPdf(appts, state),
    );
  }

  Future<Uint8List> _buildPdf(
      List<Appointment> appts, AppState state) async {
    final pdf = pw.Document();
    final purple = PdfColor.fromHex('#A855F7');
    final purpleDark = PdfColor.fromHex('#7E22CE');
    final grey = PdfColor.fromHex('#6B7280');
    final greyLight = PdfColor.fromHex('#F3F4F6');

    String clientName(int id) {
      try { return state.clients.firstWhere((c) => c.id == id).name; } catch (_) { return 'Unknown'; }
    }
    String staffName(int id) {
      try { return state.staffList.firstWhere((s) => s.id == id).name; } catch (_) { return 'Unknown'; }
    }
    String serviceName(int id) {
      try { return state.services.firstWhere((s) => s.id == id).name; } catch (_) { return 'Unknown'; }
    }
    String statusLabel(AppointmentStatus s) {
      switch (s) {
        case AppointmentStatus.scheduled: return 'Scheduled';
        case AppointmentStatus.completed: return 'Completed';
        case AppointmentStatus.cancelled: return 'Cancelled';
        case AppointmentStatus.noShow: return 'No-Show';
      }
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
                end: pw.Alignment.bottomRight),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
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
                  pw.Text('APPOINTMENTS LIST',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9,
                          letterSpacing: 1.5,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text('Generated: ${dateFmt.format(DateTime.now())}',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#E9D5FF'), fontSize: 8)),
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
          pw.Text('Total: ${appts.length} appointment${appts.length == 1 ? '' : 's'}',
              style: pw.TextStyle(fontSize: 10, color: grey)),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(3),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: purple),
                children: [
                  'CLIENT', 'SERVICE', 'STAFF', 'DATE & TIME', 'STATUS'
                ].map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: pw.Text(h,
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.8)),
                )).toList(),
              ),
              // Data rows
              ...appts.asMap().entries.map((e) {
                final i = e.key;
                final a = e.value;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: i.isEven ? PdfColors.white : greyLight),
                  children: [
                    clientName(a.clientId),
                    serviceName(a.serviceId),
                    staffName(a.staffId),
                    '${dateFmt.format(a.startAt)}\n${timeFmt.format(a.startAt)}',
                    statusLabel(a.status),
                  ].map((t) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    child: pw.Text(t,
                        style: pw.TextStyle(fontSize: 9, color: PdfColors.black)),
                  )).toList(),
                );
              }),
            ],
          ),
        ],
      ),
    );
    return Uint8List.fromList(await pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final appts = state.appointments;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => context.read<AppState>().loadAll(),
        color: AppColors.purple,
        child: appts.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.calendar_month_outlined,
                            size: 64, color: AppColors.textMuted),
                        SizedBox(height: 16),
                        Text('No upcoming appointments',
                            style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: appts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _ApptCard(appt: appts[i]),
              ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'export_appts',
            onPressed: () => _exportPdf(context),
            backgroundColor: AppColors.surfaceAlt,
            foregroundColor: AppColors.purple,
            mini: true,
            tooltip: 'Export PDF',
            child: const Icon(Icons.picture_as_pdf_outlined),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'book_appt',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: AppColors.surface,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => ChangeNotifierProvider.value(
                value: context.read<AppState>(),
                child: const BookAppointmentSheet(),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Book Appointment'),
            backgroundColor: AppColors.purple,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _ApptCard extends StatelessWidget {
  final Appointment appt;
  const _ApptCard({required this.appt});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    String clientName = 'Unknown Client';
    String staffName = 'Unknown Staff';
    String serviceName = 'Unknown Service';

    try {
      clientName = state.clients.firstWhere((c) => c.id == appt.clientId).name;
    } catch (_) {}
    try {
      staffName = state.staffList.firstWhere((s) => s.id == appt.staffId).name;
    } catch (_) {}
    try {
      serviceName =
          state.services.firstWhere((s) => s.id == appt.serviceId).name;
    } catch (_) {}

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(clientName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                _StatusChip(status: appt.status),
              ],
            ),
            const SizedBox(height: 6),
            _row(Icons.spa_outlined, serviceName),
            const SizedBox(height: 4),
            _row(Icons.person_outline, staffName),
            const SizedBox(height: 4),
            _row(Icons.access_time_outlined,
                '${dateTimeFmt.format(appt.startAt)} — ${timeFmt.format(appt.endAt)}'),
            if (appt.notes != null && appt.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              _row(Icons.notes_outlined, appt.notes!),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (appt.status == AppointmentStatus.scheduled) ...[
                  _actionBtn(context, 'Complete', const Color(0xFF10B981),
                      () => _updateStatus(context, appt, AppointmentStatus.completed)),
                  const SizedBox(width: 8),
                  _actionBtn(context, 'No-Show', const Color(0xFFF59E0B),
                      () => _updateStatus(context, appt, AppointmentStatus.noShow)),
                  const SizedBox(width: 8),
                  _actionBtn(context, 'Cancel', const Color(0xFFEF4444),
                      () => _updateStatus(context, appt, AppointmentStatus.cancelled)),
                ],
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 20),
                  onPressed: () => _delete(context, appt),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted))),
        ],
      );

  Widget _actionBtn(BuildContext context, String label, Color color, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      );

  Future<void> _updateStatus(BuildContext context, Appointment a, AppointmentStatus s) async {
    final updated = Appointment(
      id: a.id,
      clientId: a.clientId,
      staffId: a.staffId,
      serviceId: a.serviceId,
      startAt: a.startAt,
      endAt: a.endAt,
      status: s,
      notes: a.notes,
    );
    await context.read<AppState>().updateAppointment(updated);
  }

  Future<void> _delete(BuildContext context, Appointment a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Appointment?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) await context.read<AppState>().deleteAppointment(a.id!);
  }

}

class _StatusChip extends StatelessWidget {
  final AppointmentStatus status;
  const _StatusChip({required this.status});

  static const _labels = {
    AppointmentStatus.scheduled: 'Scheduled',
    AppointmentStatus.completed: 'Completed',
    AppointmentStatus.cancelled: 'Cancelled',
    AppointmentStatus.noShow: 'No-Show',
  };
  static const _colors = {
    AppointmentStatus.scheduled: AppColors.purple,
    AppointmentStatus.completed: Color(0xFF10B981),
    AppointmentStatus.cancelled: Color(0xFFEF4444),
    AppointmentStatus.noShow: Color(0xFFF59E0B),
  };

  @override
  Widget build(BuildContext context) {
    final c = _colors[status]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(_labels[status]!,
          style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
