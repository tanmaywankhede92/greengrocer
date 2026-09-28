import 'package:flutter/material.dart';

/// Fixed height of every action slot so all rows share one baseline.
const double kTableActionSlotHeight = 28;

/// Min / max width of a single action slot. The slot width is derived from the
/// space the Actions column actually got, so the icons never overflow and always
/// land in the exact same horizontal position on every row.
const double kTableActionSlotMin = 24;
const double kTableActionSlotMax = 34;

/// Header cell for the Actions column. Must be paired with [TableActions] so the
/// label sits exactly above the icons.
class TableActionsHeader extends StatelessWidget {
  final String label;
  const TableActionsHeader({super.key, this.label = 'Actions'});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      textAlign: TextAlign.center,
    );
  }
}

class TableAction {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;
  final bool isLoading;

  /// When false an empty slot is still reserved, keeping the icons of the
  /// remaining actions aligned with the other rows.
  final bool visible;

  const TableAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
    this.isLoading = false,
    this.visible = true,
  });
}

/// Renders the action icons of a table row in evenly sized, vertically centred
/// slots so that every row lines up perfectly.
class TableActions extends StatelessWidget {
  final List<TableAction> actions;

  const TableActions({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = actions.length;
        final available = constraints.maxWidth.isFinite ? constraints.maxWidth - 8 : count * kTableActionSlotMax;
        final slot = (available / count).clamp(kTableActionSlotMin, kTableActionSlotMax).toDouble();
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final action in actions)
              SizedBox(
                width: slot,
                height: kTableActionSlotHeight,
                child: action.visible ? _ActionButton(action: action) : null,
              ),
          ],
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final TableAction action;
  const _ActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: action.tooltip,
      child: InkWell(
        onTap: action.onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: action.isLoading
              ? SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: action.color),
                )
              : Icon(action.icon, size: 16, color: action.color),
        ),
      ),
    );
  }
}
