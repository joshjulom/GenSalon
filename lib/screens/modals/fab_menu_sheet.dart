import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'items_management_screen.dart';
import 'record_sale_sheet.dart';
import 'services_management_screen.dart';
import 'staff_management_screen.dart';

class FabMenuSheet extends StatelessWidget {
  const FabMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          _MenuTile(
            icon: Icons.receipt_long_outlined,
            iconColor: AppColors.purple,
            title: 'Record Sale',
            subtitle: 'Log a new sale transaction',
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.surface,
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => ChangeNotifierProvider.value(
                  value: context.read<AppState>(),
                  child: const RecordSaleSheet(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.inventory_2_outlined,
            iconColor: const Color(0xFF3B82F6),
            title: 'Items Management',
            subtitle: 'Manage products & inventory',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<AppState>(),
                    child: const ItemsManagementScreen(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.people_outline,
            iconColor: const Color(0xFF10B981),
            title: 'Staff Management',
            subtitle: 'Manage team members & roles',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<AppState>(),
                    child: const StaffManagementScreen(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.spa_outlined,
            iconColor: const Color(0xFFF59E0B),
            title: 'Service List',
            subtitle: 'Manage services & pricing',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<AppState>(),
                    child: const ServicesManagementScreen(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
