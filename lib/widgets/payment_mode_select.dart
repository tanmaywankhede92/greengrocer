import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../core/enums.dart';

class PaymentModeSelect extends StatelessWidget {
  final PaymentMode value;
  final ValueChanged<PaymentMode?> onChanged;

  const PaymentModeSelect({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<PaymentMode>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Payment Mode'),
      dropdownColor: AppTheme.surfaceCard,
      items: PaymentMode.values.map((mode) => DropdownMenuItem(
        value: mode,
        child: Text(mode.displayName, style: const TextStyle(color: AppTheme.textPrimary)),
      )).toList(),
      onChanged: onChanged,
    );
  }
}
