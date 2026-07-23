import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../core/utils.dart';
import '../core/constants.dart';

class Header extends ConsumerWidget {
  final VoidCallback? onMenuTap;

  const Header({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDesktop = MediaQuery.of(context).size.width >= AppConstants.desktopBreakpoint;

    return Container(
      height: 64,
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (!isDesktop)
            InkWell(
              onTap: onMenuTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.menu, color: AppTheme.textSecondary, size: 24),
              ),
            ),
          if (!isDesktop) const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${DateTime.now().day.toString().padLeft(2, '0')} '
              '${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][DateTime.now().month - 1]} '
              '${DateTime.now().year}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ),
          if (authState.user != null) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryRed,
              child: Text(
                AppUtils.initials(authState.user!.fullName),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Text(authState.user!.fullName, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
            const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }
}
