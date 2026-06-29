import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: AppConstants.sidebarWidth,
      color: AppTheme.surfaceNav,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.store, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 8),
                Text('Greengrocer', style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18, fontWeight: FontWeight.bold,
                )),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _MenuItem(icon: Icons.dashboard, label: 'Dashboard', route: '/dashboard'),
                _MenuItem(icon: Icons.receipt_long, label: 'Bills', route: '/bills'),
                _MenuItem(icon: Icons.people, label: 'Customers', route: '/customers'),
                _MenuItem(icon: Icons.inventory, label: 'Products', route: '/products'),
                _MenuItem(icon: Icons.trending_up, label: 'Daily Rates', route: '/rates'),
                _MenuItem(icon: Icons.payments, label: 'Payments', route: '/payments'),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _MenuItem(icon: Icons.settings, label: 'Settings', route: '/settings'),
              ],
            ),
          ),
          const Divider(height: 1),
          _LogoutButton(),
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
        color: isActive ? AppTheme.primaryGreen.withAlpha(40) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.go(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: isActive ? AppTheme.primaryGreenLight : AppTheme.textSecondary, size: 22),
                const SizedBox(width: 14),
                Text(label, style: TextStyle(
                  color: isActive ? AppTheme.primaryGreenLight : AppTheme.textSecondary,
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
        child: Row(
          children: [
            const Icon(Icons.logout, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 14),
            Text('Logout', style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            )),
          ],
        ),
      ),
    );
  }
}
