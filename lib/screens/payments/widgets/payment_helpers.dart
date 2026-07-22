import 'package:flutter/material.dart';
import '../../../config/theme.dart';

Widget th(String label, double width, {TextAlign align = TextAlign.left, bool compact = false}) {
  return SizedBox(
    width: width,
    child: Text(label, style: TextStyle(
      fontSize: compact ? 10 : 11,
      fontWeight: FontWeight.w700,
      color: Colors.grey.shade600,
      letterSpacing: 0.5,
    ), textAlign: align),
  );
}

Widget actionIconBtn(IconData icon, String tooltip, Color color, VoidCallback? onPressed, {bool compact = false}) {
  return Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: EdgeInsets.all(compact ? 4 : 6),
        child: Icon(icon, size: compact ? 16 : 18, color: onPressed == null ? Colors.grey.shade300 : color),
      ),
    ),
  );
}

Widget dialogRow(String label, String value, {Color? valueColor}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Flexible(child: Text(value, style: TextStyle(
          color: valueColor ?? AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ), overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}
