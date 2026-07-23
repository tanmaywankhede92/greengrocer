import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../core/utils.dart';

class StatCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color? color;
  final bool isCurrency;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.isCurrency = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primaryRed;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: c.withAlpha(25),
      surfaceTintColor: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(title,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: c.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: c, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                isCurrency ? AppUtils.formatCurrency(value) : value.toStringAsFixed(0),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.bold, height: 1.1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
