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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (color ?? AppTheme.primaryRed).withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color ?? AppTheme.primaryRed, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isCurrency ? AppUtils.formatCurrency(value) : value.toStringAsFixed(0),
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
