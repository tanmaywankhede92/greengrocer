import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool compact;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: compact ? 16 : 18, color: AppTheme.primaryRed),
        SizedBox(width: compact ? 6 : 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.w600,
            )),
            if (subtitle != null)
              Text(subtitle!, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}
