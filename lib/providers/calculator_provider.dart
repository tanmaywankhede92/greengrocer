import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CalculationHistoryItem {
  final String expression;
  final String result;
  final DateTime timestamp;

  const CalculationHistoryItem({
    required this.expression,
    required this.result,
    required this.timestamp,
  });

  String get formattedTime => DateFormat('hh:mm a').format(timestamp);
}

class CalculatorState {
  final String display;
  final String expression;
  final double? operand1;
  final String? operator;
  final bool shouldResetDisplay;
  final List<CalculationHistoryItem> history;
  final bool showHistory;

  const CalculatorState({
    this.display = '0',
    this.expression = '',
    this.operand1,
    this.operator,
    this.shouldResetDisplay = false,
    this.history = const [],
    this.showHistory = false,
  });

  CalculatorState copyWith({
    String? display,
    String? expression,
    double? operand1,
    String? operator,
    bool? shouldResetDisplay,
    List<CalculationHistoryItem>? history,
    bool? showHistory,
    bool clearOperand1 = false,
    bool clearOperator = false,
  }) {
    return CalculatorState(
      display: display ?? this.display,
      expression: expression ?? this.expression,
      operand1: clearOperand1 ? null : (operand1 ?? this.operand1),
      operator: clearOperator ? null : (operator ?? this.operator),
      shouldResetDisplay: shouldResetDisplay ?? this.shouldResetDisplay,
      history: history ?? this.history,
      showHistory: showHistory ?? this.showHistory,
    );
  }
}

class CalculatorNotifier extends StateNotifier<CalculatorState> {
  CalculatorNotifier() : super(const CalculatorState());

  void toggleHistory() {
    state = state.copyWith(showHistory: !state.showHistory);
  }

  void clearHistory() {
    state = state.copyWith(history: const []);
  }

  void restoreHistory(CalculationHistoryItem item) {
    state = state.copyWith(
      display: item.result,
      expression: '',
      clearOperand1: true,
      clearOperator: true,
      shouldResetDisplay: true,
      showHistory: false,
    );
  }

  void inputDigit(String digit) {
    if (state.shouldResetDisplay || state.display == '0' || state.display == 'Error') {
      state = state.copyWith(
        display: digit,
        shouldResetDisplay: false,
      );
    } else {
      if (state.display.length < 15) {
        state = state.copyWith(display: state.display + digit);
      }
    }
  }

  void inputDecimal() {
    if (state.shouldResetDisplay || state.display == 'Error') {
      state = state.copyWith(
        display: '0.',
        shouldResetDisplay: false,
      );
    } else if (!state.display.contains('.')) {
      state = state.copyWith(display: '${state.display}.');
    }
  }

  void toggleSign() {
    if (state.display == '0' || state.display == 'Error') return;
    if (state.display.startsWith('-')) {
      state = state.copyWith(display: state.display.substring(1));
    } else {
      state = state.copyWith(display: '-${state.display}');
    }
  }

  void backspace() {
    if (state.shouldResetDisplay || state.display == 'Error') {
      state = state.copyWith(display: '0', shouldResetDisplay: false);
      return;
    }
    if (state.display.length > 1) {
      final updated = state.display.substring(0, state.display.length - 1);
      if (updated == '-' || updated.isEmpty) {
        state = state.copyWith(display: '0');
      } else {
        state = state.copyWith(display: updated);
      }
    } else {
      state = state.copyWith(display: '0');
    }
  }

  void clear() {
    state = state.copyWith(
      display: '0',
      expression: '',
      clearOperand1: true,
      clearOperator: true,
      shouldResetDisplay: false,
    );
  }

  void percentage() {
    final val = double.tryParse(state.display);
    if (val == null) return;
    final res = val / 100;
    state = state.copyWith(
      display: _formatResult(res),
      shouldResetDisplay: true,
    );
  }

  void setOperator(String op) {
    final currentVal = double.tryParse(state.display);
    if (currentVal == null) return;

    if (state.operand1 != null && state.operator != null && !state.shouldResetDisplay) {
      final evaluated = _compute(state.operand1!, currentVal, state.operator!);
      if (evaluated == null) {
        state = state.copyWith(display: 'Error', shouldResetDisplay: true);
        return;
      }
      state = state.copyWith(
        display: _formatResult(evaluated),
        operand1: evaluated,
        operator: op,
        expression: '${_formatResult(evaluated)} $op',
        shouldResetDisplay: true,
      );
    } else {
      state = state.copyWith(
        operand1: currentVal,
        operator: op,
        expression: '${_formatResult(currentVal)} $op',
        shouldResetDisplay: true,
      );
    }
  }

  void equals() {
    if (state.operand1 == null || state.operator == null) return;
    final currentVal = double.tryParse(state.display);
    if (currentVal == null) return;

    final res = _compute(state.operand1!, currentVal, state.operator!);
    if (res == null) {
      state = state.copyWith(display: 'Error', expression: '', shouldResetDisplay: true);
      return;
    }

    final formattedResult = _formatResult(res);
    final historyItem = CalculationHistoryItem(
      expression: '${_formatResult(state.operand1!)} ${state.operator} ${_formatResult(currentVal)}',
      result: formattedResult,
      timestamp: DateTime.now(),
    );

    final updatedHistory = [historyItem, ...state.history];
    if (updatedHistory.length > 50) {
      updatedHistory.removeLast();
    }

    state = state.copyWith(
      display: formattedResult,
      expression: '${historyItem.expression} =',
      clearOperand1: true,
      clearOperator: true,
      shouldResetDisplay: true,
      history: updatedHistory,
    );
  }

  double? _compute(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '−':
      case '-':
        return a - b;
      case '×':
      case '*':
        return a * b;
      case '÷':
      case '/':
        if (b == 0) return null;
        return a / b;
      default:
        return b;
    }
  }

  String _formatResult(double val) {
    if (val.isNaN || val.isInfinite) return 'Error';
    if (val == val.roundToDouble() && val.abs() < 1e14) {
      return val.toInt().toString();
    }
    String str = val.toStringAsFixed(8);
    if (str.contains('.')) {
      str = str.replaceAll(RegExp(r'0+$'), '');
      str = str.replaceAll(RegExp(r'\.$'), '');
    }
    return str;
  }
}

final calculatorProvider = StateNotifierProvider<CalculatorNotifier, CalculatorState>((ref) {
  return CalculatorNotifier();
});
