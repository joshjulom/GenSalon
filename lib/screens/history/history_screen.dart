import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'All';
  final _filters = ['All', 'Completed', 'Cancelled', 'No-Show'];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final history = state.historyList.where((a) {
      if (_filter == 'All') return true;
      if (_filter == 'Completed') return a.status == AppointmentStatus.completed;
      if (_filter == 'Cancelled') return a.status == AppointmentStatus.cancelled;
      if (_filter == 'No-Show') return a.status == AppointmentStatus.noShow;
      return true;
    }).toList();

    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((f) {
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: AppColors.purple.withOpacity(0.2),
                    checkmarkColor: AppColors.purple,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.purple : AppColors.textMuted,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    backgroundColor: AppColors.surfaceAlt,
                    side: BorderSide(
                        color: selected ? AppColors.purple : Colors.transparent),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: history.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: AppColors.textMuted),
                      SizedBox(height: 16),
                      Text('No history found',
                          style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<AppState>().loadAll(),
                  color: AppColors.purple,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _HistoryCard(appt: history[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Appointment appt;
  const _HistoryCard({required this.appt});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    String clientName = 'Unknown Client';
    String staffName = 'Unknown Staff';
    String serviceName = 'Unknown Service';

    try { clientName = state.clients.firstWhere((c) => c.id == appt.clientId).name; } catch (_) {}
    try { staffName = state.staffList.firstWhere((s) => s.id == appt.staffId).name; } catch (_) {}
    try { serviceName = state.services.firstWhere((s) => s.id == appt.serviceId).name; } catch (_) {}

    final statusColors = {
      AppointmentStatus.completed: const Color(0xFF10B981),
      AppointmentStatus.cancelled: const Color(0xFFEF4444),
      AppointmentStatus.noShow: const Color(0xFFF59E0B),
      AppointmentStatus.scheduled: AppColors.purple,
    };
    final statusLabels = {
      AppointmentStatus.completed: 'Completed',
      AppointmentStatus.cancelled: 'Cancelled',
      AppointmentStatus.noShow: 'No-Show',
      AppointmentStatus.scheduled: 'Scheduled',
    };
    final c = statusColors[appt.status]!;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: c.withOpacity(0.15),
          child: Icon(Icons.person_outline, color: c, size: 20),
        ),
        title: Text(clientName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$serviceName • $staffName',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            Text(dateTimeFmt.format(appt.startAt),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Text(statusLabels[appt.status]!,
              style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        isThreeLine: true,
      ),
    );
  }
}
