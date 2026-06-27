import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppUtils {
  AppUtils._();

  static final currencyFormat = NumberFormat.currency(
    symbol: '\u20B9',
    decimalDigits: 0,
  );

  static final dateFormat = DateFormat('dd MMM yyyy');
  static final dateFormatApi = DateFormat('yyyy-MM-dd');
  static final dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static String formatCurrency(double amount) => currencyFormat.format(amount);

  static String formatDate(DateTime date) => dateFormat.format(date);

  static String formatDateApi(DateTime date) => dateFormatApi.format(date);

  static String formatDateTime(DateTime date) => dateTimeFormat.format(date);

  static String formatDateShort(DateTime date) => DateFormat('dd/MM/yy').format(date);

  static String initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static Color statusColor(String status) {
    switch (status) {
      case 'active': return const Color(0xFF4CAF50);
      case 'cancelled': return const Color(0xFFEF5350);
      default: return const Color(0xFF9E9E9E);
    }
  }
}
