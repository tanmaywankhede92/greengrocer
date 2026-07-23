import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils.dart';

class BottomBar extends StatelessWidget {
  final int itemCount;
  final double total;
  final bool allItemsValid;
  final VoidCallback onSave;
  final bool isWide;
  final bool canSave;

  const BottomBar({
    super.key,
    required this.itemCount,
    required this.total,
    required this.allItemsValid,
    required this.onSave,
    required this.isWide,
    this.canSave = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: isWide
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _summary(),
                  _saveButton(),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _summary(),
                  const SizedBox(height: 8),
                  _saveButton(fullWidth: true),
                ],
              ),
      ),
    );
  }

  Widget _summary() {
    return Text(
      '$itemCount item${itemCount == 1 ? '' : 's'}  •  Total ${AppUtils.formatCurrency(total)}',
      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
    );
  }

  Widget _saveButton({bool fullWidth = false}) {
    return SizedBox(
      width: fullWidth ? double.infinity : 140,
      child: ElevatedButton(
        onPressed: canSave ? onSave : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('Save Bill', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
