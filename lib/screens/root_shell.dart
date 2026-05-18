import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'appointments/appointments_screen.dart';
import 'history/history_screen.dart';
import 'home/home_screen.dart';
import 'modals/fab_menu_sheet.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    AppointmentsScreen(),
    HistoryScreen(),
    ReportsScreen(),
  ];

  final _labels = const ['Home', 'Appointments', 'History', 'Reports'];
  final _icons = const [
    Icons.home_outlined,
    Icons.calendar_month_outlined,
    Icons.history_outlined,
    Icons.bar_chart_outlined,
  ];
  final _activeIcons = const [
    Icons.home,
    Icons.calendar_month,
    Icons.history,
    Icons.bar_chart,
  ];

  void _openFabMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const FabMenuSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.isDesktop(context) || Responsive.isTablet(context);
    return Scaffold(
      appBar: AppBar(
        title: const BrandTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  backgroundColor: AppColors.surface,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (i) =>
                      setState(() => _currentIndex = i),
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme:
                      const IconThemeData(color: AppColors.purple),
                  selectedLabelTextStyle:
                      const TextStyle(color: AppColors.purple),
                  unselectedIconTheme:
                      const IconThemeData(color: AppColors.textMuted),
                  unselectedLabelTextStyle:
                      const TextStyle(color: AppColors.textMuted),
                  destinations: List.generate(
                    4,
                    (i) => NavigationRailDestination(
                      icon: Icon(_icons[i]),
                      selectedIcon: Icon(_activeIcons[i]),
                      label: Text(_labels[i]),
                    ),
                  ),
                  trailing: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: _openFabMenu,
                      child: const Icon(Icons.add),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _screens[_currentIndex]),
              ],
            )
          : _screens[_currentIndex],
      bottomNavigationBar: wide
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              items: List.generate(
                4,
                (i) => BottomNavigationBarItem(
                  icon: Icon(_icons[i]),
                  activeIcon: Icon(_activeIcons[i]),
                  label: _labels[i],
                ),
              ),
            ),
      floatingActionButton: wide
          ? null
          : FloatingActionButton(
              onPressed: _openFabMenu,
              shape: const CircleBorder(),
              child: const Icon(Icons.add),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
