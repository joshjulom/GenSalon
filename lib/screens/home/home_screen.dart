import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';
import '../../widgets/stat_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cols = Responsive.gridCols(context);

    return RefreshIndicator(
      onRefresh: () => context.read<AppState>().refreshDashboard(),
      color: AppColors.purple,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: MaxWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dashboard',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),

              // Stats grid
              GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  StatCard(
                    label: 'Total Clients',
                    value: '${state.clientCount}',
                    icon: Icons.people_outline,
                    color: const Color(0xFF3B82F6),
                  ),
                  StatCard(
                    label: 'Active Staff',
                    value: '${state.staffCount}',
                    icon: Icons.person_outline,
                    color: const Color(0xFF10B981),
                  ),
                  StatCard(
                    label: "Today's Appts",
                    value: '${state.todayAppointments}',
                    icon: Icons.calendar_today_outlined,
                    color: const Color(0xFFF59E0B),
                  ),
                  StatCard(
                    label: "Today's Sales",
                    value: formatPeso(state.todaySales),
                    icon: Icons.payments_outlined,
                    color: AppColors.purple,
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text('Sales — Last 7 Days',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
                  child: SizedBox(
                    height: 180,
                    child: state.weekSales.isEmpty
                        ? const Center(
                            child: Text('No sales yet',
                                style: TextStyle(color: AppColors.textMuted)))
                        : _SalesBarChart(data: state.weekSales),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text("Today's Appointments",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (state.appointments.isEmpty)
                _emptyCard('No upcoming appointments today.')
              else
                ...state.appointments.take(5).map((a) {
                  final client = state.clients.firstWhere(
                    (c) => c.id == a.clientId,
                    orElse: () => state.clients.isNotEmpty
                        ? state.clients.first
                        : _dummyClient(),
                  );
                  final service = state.services.firstWhere(
                    (s) => s.id == a.serviceId,
                    orElse: () => _dummyService(),
                  );
                  return _ApptTile(
                    clientName: client.name,
                    serviceName: service.name,
                    startAt: a.startAt,
                    status: a.status,
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyCard(String msg) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(msg,
                style: const TextStyle(color: AppColors.textMuted),
                textAlign: TextAlign.center),
          ),
        ),
      );
}

dynamic _dummyClient() => _FakeClient();
dynamic _dummyService() => _FakeService();

class _FakeClient {
  String get name => 'Unknown';
}

class _FakeService {
  String get name => 'Service';
}

class _ApptTile extends StatelessWidget {
  final String clientName;
  final String serviceName;
  final DateTime startAt;
  final dynamic status;

  const _ApptTile({
    required this.clientName,
    required this.serviceName,
    required this.startAt,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = {
      'scheduled': AppColors.purple,
      'completed': const Color(0xFF10B981),
      'cancelled': const Color(0xFFEF4444),
      'noShow': const Color(0xFFF59E0B),
    }[status.name] ?? AppColors.purple;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.purple.withOpacity(0.15),
          child: const Icon(Icons.person, color: AppColors.purple, size: 20),
        ),
        title: Text(clientName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('$serviceName • ${timeFmt.format(startAt)}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status.name,
            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _SalesBarChart extends StatelessWidget {
  final List<MapEntry<DateTime, double>> data;
  const _SalesBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = data.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b);
    final safeMax = maxY == 0 ? 100.0 : maxY * 1.2;

    return BarChart(
      BarChartData(
        maxY: safeMax,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (g, gi, r, ri) => BarTooltipItem(
              formatPeso(r.toY),
              const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              getTitlesWidget: (v, _) => Text(
                v == 0 ? '₱0' : '₱${(v / 1000).toStringAsFixed(0)}k',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textMuted),
              ),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('E').format(data[idx].key),
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Colors.white10, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          data.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i].value,
                color: AppColors.purple,
                width: 18,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
