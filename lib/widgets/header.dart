import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../core/utils.dart';
import '../core/constants.dart';
import 'calculator_dialog.dart';

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
          // ── Calculator Button ──
          Tooltip(
            message: 'Calculator',
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => CalculatorDialog.show(context),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Icon(Icons.calculate_outlined, color: AppTheme.textPrimary, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // ── Profile Avatar (Logo only, no name text) ──
          if (authState.user != null)
            Tooltip(
              message: authState.user!.fullName,
              child: CircleAvatar(
                radius: 17,
                backgroundColor: AppTheme.primaryRed,
                child: Text(
                  AppUtils.initials(authState.user!.fullName),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

