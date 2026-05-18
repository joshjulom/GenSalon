import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'book_appointment_sheet.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

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
      floatingActionButton: FloatingActionButton.extended(
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

    final statusColor = _statusColor(appt.status);

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

  Color _statusColor(AppointmentStatus s) => {
        AppointmentStatus.scheduled: AppColors.purple,
        AppointmentStatus.completed: const Color(0xFF10B981),
        AppointmentStatus.cancelled: const Color(0xFFEF4444),
        AppointmentStatus.noShow: const Color(0xFFF59E0B),
      }[s]!;
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
