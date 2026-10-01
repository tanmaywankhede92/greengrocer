import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/calculator_provider.dart';

class CalculatorDialog extends ConsumerStatefulWidget {
  const CalculatorDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const CalculatorDialog(),
    );
  }

  @override
  ConsumerState<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends ConsumerState<CalculatorDialog> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final notifier = ref.read(calculatorProvider.notifier);

    final key = event.logicalKey;
    final char = event.character;

    if (char != null && RegExp(r'^[0-9]$').hasMatch(char)) {
      notifier.inputDigit(char);
    } else if (char == '.') {
      notifier.inputDecimal();
    } else if (char == '+' || key == LogicalKeyboardKey.numpadAdd) {
      notifier.setOperator('+');
    } else if (char == '-' || key == LogicalKeyboardKey.numpadSubtract) {
      notifier.setOperator('−');
    } else if (char == '*' || key == LogicalKeyboardKey.numpadMultiply) {
      notifier.setOperator('×');
    } else if (char == '/' || key == LogicalKeyboardKey.numpadDivide) {
      notifier.setOperator('÷');
    } else if (char == '%' || (char == '%' && event.synthesized)) {
      notifier.percentage();
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter || char == '=') {
      notifier.equals();
    } else if (key == LogicalKeyboardKey.backspace) {
      notifier.backspace();
    } else if (key == LogicalKeyboardKey.escape || char?.toLowerCase() == 'c') {
      notifier.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calculatorProvider);
    final notifier = ref.read(calculatorProvider.notifier);
    final isMobile = MediaQuery.of(context).size.width < 500;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 40,
          vertical: 24,
        ),
        backgroundColor: Colors.white,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 360,
            maxHeight: 560,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header Bar ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E2330),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withAlpha(50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calculate, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Calculator',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // History Toggle Button
                    IconButton(
                      tooltip: state.showHistory ? 'Back to Keypad' : 'Calculation History',
                      icon: Badge(
                        isLabelVisible: state.history.isNotEmpty && !state.showHistory,
                        label: Text('${state.history.length}'),
                        backgroundColor: AppTheme.primaryRed,
                        child: Icon(
                          state.showHistory ? Icons.dialpad : Icons.history,
                          color: state.showHistory ? AppTheme.primaryRed : Colors.white70,
                          size: 22,
                        ),
                      ),
                      onPressed: () => notifier.toggleHistory(),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // ── Content Area: History OR Keypad ──
              Expanded(
                child: state.showHistory
                    ? _buildHistoryView(state, notifier)
                    : _buildKeypadView(state, notifier),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadView(CalculatorState state, CalculatorNotifier notifier) {
    return Column(
      children: [
        // ── Calculator Screen / Display ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          color: const Color(0xFF161922),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Expression preview (e.g. 250 × 40 =)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Text(
                  state.expression.isEmpty ? ' ' : state.expression,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Current Result / Input Number
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Text(
                  _formatDisplay(state.display),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Buttons Grid ──
        Expanded(
          child: Container(
            color: const Color(0xFFF3F4F6),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildButtonRow([
                  _calcBtn('AC', textColor: AppTheme.error, isAction: true, onTap: notifier.clear),
                  _calcBtn('⌫', textColor: AppTheme.textPrimary, isAction: true, onTap: notifier.backspace),
                  _calcBtn('%', textColor: const Color(0xFF4B5563), isAction: true, onTap: notifier.percentage),
                  _calcBtn('÷', isOperator: true, onTap: () => notifier.setOperator('÷')),
                ]),
                const SizedBox(height: 8),
                _buildButtonRow([
                  _calcBtn('7', onTap: () => notifier.inputDigit('7')),
                  _calcBtn('8', onTap: () => notifier.inputDigit('8')),
                  _calcBtn('9', onTap: () => notifier.inputDigit('9')),
                  _calcBtn('×', isOperator: true, onTap: () => notifier.setOperator('×')),
                ]),
                const SizedBox(height: 8),
                _buildButtonRow([
                  _calcBtn('4', onTap: () => notifier.inputDigit('4')),
                  _calcBtn('5', onTap: () => notifier.inputDigit('5')),
                  _calcBtn('6', onTap: () => notifier.inputDigit('6')),
                  _calcBtn('−', isOperator: true, onTap: () => notifier.setOperator('−')),
                ]),
                const SizedBox(height: 8),
                _buildButtonRow([
                  _calcBtn('1', onTap: () => notifier.inputDigit('1')),
                  _calcBtn('2', onTap: () => notifier.inputDigit('2')),
                  _calcBtn('3', onTap: () => notifier.inputDigit('3')),
                  _calcBtn('+', isOperator: true, onTap: () => notifier.setOperator('+')),
                ]),
                const SizedBox(height: 8),
                _buildButtonRow([
                  _calcBtn('±', textColor: const Color(0xFF4B5563), onTap: notifier.toggleSign),
                  _calcBtn('0', onTap: () => notifier.inputDigit('0')),
                  _calcBtn('.', onTap: notifier.inputDecimal),
                  _calcBtn('=', isEquals: true, onTap: notifier.equals),
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtonRow(List<Widget> buttons) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons.map((btn) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: btn,
          ),
        )).toList(),
      ),
    );
  }

  Widget _calcBtn(
    String label, {
    required VoidCallback onTap,
    bool isOperator = false,
    bool isEquals = false,
    bool isAction = false,
    Color? textColor,
  }) {
    Color bg = Colors.white;
    Color fg = textColor ?? const Color(0xFF1F2937);

    if (isEquals) {
      bg = AppTheme.primaryRed;
      fg = Colors.white;
    } else if (isOperator) {
      bg = const Color(0xFFE5E7EB);
      fg = const Color(0xFF111827);
    } else if (isAction) {
      bg = const Color(0xFFE5E7EB);
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      elevation: isEquals ? 2 : 0.5,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isEquals ? 24 : 18,
              fontWeight: (isOperator || isEquals || isAction) ? FontWeight.bold : FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryView(CalculatorState state, CalculatorNotifier notifier) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFFF9FAFB),
          child: Row(
            children: [
              const Icon(Icons.history, size: 18, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              const Text(
                'Calculation History',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (state.history.isNotEmpty)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 32),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Clear', style: TextStyle(fontSize: 12)),
                  onPressed: notifier.clearHistory,
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.border),
        Expanded(
          child: state.history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_toggle_off, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'No history yet',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Calculations will appear here.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final item = state.history[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => notifier.restoreHistory(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.expression,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '= ${item.result}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  item.formattedTime,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Icon(Icons.touch_app, size: 14, color: AppTheme.textSecondary),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.border)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E2330),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.dialpad, size: 16),
              label: const Text('Back to Keypad', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              onPressed: () => notifier.toggleHistory(),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDisplay(String val) {
    if (val == 'Error' || val.isEmpty) return val;
    // Format commas for the integer part
    if (val.contains('.')) {
      final parts = val.split('.');
      final intPart = double.tryParse(parts[0]);
      if (intPart != null) {
        final formattedInt = parts[0].replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
        return '$formattedInt.${parts[1]}';
      }
    } else {
      final intPart = double.tryParse(val);
      if (intPart != null) {
        return val.replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
      }
    }
    return val;
  }
}
