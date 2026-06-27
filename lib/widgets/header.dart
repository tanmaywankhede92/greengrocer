import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../core/utils.dart';

class Header extends ConsumerWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    return Container(
      height: 64,
      color: AppTheme.surfaceCard,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Text(
              DateTime.now().day.toString().padLeft(2, '0') + ' ' +
              ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][DateTime.now().month - 1] + ' ' +
              DateTime.now().year.toString(),
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ),
          if (authState.user != null) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryGreen,
              child: Text(
                AppUtils.initials(authState.user!.fullName),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Text(authState.user!.fullName, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
            const SizedBox(width: 16),
            Container(height: 24, width: 1, color: Colors.grey.shade700),
            const SizedBox(width: 16),
            InkWell(
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              child: const Row(
                children: [
                  Icon(Icons.logout, color: AppTheme.textSecondary, size: 20),
                  SizedBox(width: 6),
                  Text('Logout', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
