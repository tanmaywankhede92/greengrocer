import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppUtils {
  AppUtils._();

  static final _currencyIntegerFormat = NumberFormat.currency(
    symbol: '\u20B9',
    decimalDigits: 0,
  );

  static final _currencyDecimalFormat = NumberFormat.currency(
    symbol: '\u20B9',
    decimalDigits: 2,
  );

  static String formatCurrency(double amount) {
    if (amount == amount.roundToDouble()) {
      return _currencyIntegerFormat.format(amount);
    }
    return _currencyDecimalFormat.format(amount);
  }

  static String formatQuantity(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toStringAsFixed(0);
    }
    final str = qty.toStringAsFixed(3);
    return str.replaceAll(RegExp(r'\.?0+$'), '');
  }

  static String formatRate(double rate) {
    if (rate == rate.roundToDouble()) {
      return rate.toStringAsFixed(0);
    }
    return rate.toStringAsFixed(2);
  }

  static final dateFormat = DateFormat('dd MMM yyyy');
  static final dateFormatApi = DateFormat('yyyy-MM-dd');
  static final dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

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
