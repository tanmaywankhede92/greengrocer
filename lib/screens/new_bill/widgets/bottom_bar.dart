import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils.dart';

class BottomBar extends StatelessWidget {
  final int itemCount;
  final double total;
  final bool allItemsValid;
  final VoidCallback onSave;
  final VoidCallback? onEstimate;
  final bool isWide;
  final bool canSave;
  final String label;

  const BottomBar({
    super.key,
    required this.itemCount,
    required this.total,
    required this.allItemsValid,
    required this.onSave,
    this.onEstimate,
    required this.isWide,
    this.canSave = true,
    this.label = 'Save Bill',
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEstimate != null) ...[
                        OutlinedButton.icon(
                          onPressed: canSave ? onEstimate : null,
                          icon: const Icon(Icons.receipt_long_outlined, size: 16),
                          label: const Text(
                            'Estimate (कच्चा पर्चा)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            side: BorderSide(color: Colors.grey.shade400),
                            foregroundColor: Colors.grey.shade800,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      _saveButton(),
                    ],
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _summary(),
                  const SizedBox(height: 8),
                  if (onEstimate != null)
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: OutlinedButton.icon(
                            onPressed: canSave ? onEstimate : null,
                            icon: const Icon(Icons.receipt_long_outlined, size: 16),
                            label: const Text(
                              'Estimate (कच्चा)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey.shade400),
                              foregroundColor: Colors.grey.shade800,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 5,
                          child: _saveButton(fullWidth: false),
                        ),
                      ],
                    )
                  else
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
        child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
