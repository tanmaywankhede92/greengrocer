import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../core/constants.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: AppConstants.sidebarWidth,
      color: AppTheme.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border.withAlpha(100))),
            ),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.store, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rathod', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Enterprises', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                const _MenuItem(icon: Icons.dashboard, label: 'Dashboard', route: '/dashboard'),
                const _MenuItem(icon: Icons.receipt_long, label: 'Bills', route: '/bills'),
                const _MenuItem(icon: Icons.people, label: 'Customers', route: '/customers'),
                const _MenuItem(icon: Icons.inventory, label: 'Products', route: '/products'),
                const _MenuItem(icon: Icons.trending_up, label: 'Daily Rates', route: '/rates'),
                const _MenuItem(icon: Icons.payments, label: 'Payments', route: '/payments'),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Divider(color: AppTheme.border.withAlpha(100)),
                ),
                const SizedBox(height: 16),
                const _MenuItem(icon: Icons.settings, label: 'Settings', route: '/settings'),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border.withAlpha(100))),
            ),
            child: _LogoutButton(),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _MenuItem({required this.icon, required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    final isActive = GoRouterState.of(context).matchedLocation == route ||
        GoRouterState.of(context).matchedLocation.startsWith(route + (route == '/' ? '' : '/'));
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isActive ? AppTheme.primaryRed.withAlpha(15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.go(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: isActive ? AppTheme.primaryRed : AppTheme.textSecondary, size: 22),
                const SizedBox(width: 14),
                Text(label, style: TextStyle(
                  color: isActive ? AppTheme.primaryRed : AppTheme.textSecondary,
                  fontSize: 14, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) context.go('/login');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: const Row(
          children: [
            Icon(Icons.logout, color: AppTheme.textSecondary, size: 20),
            SizedBox(width: 14),
            Text('Logout', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
