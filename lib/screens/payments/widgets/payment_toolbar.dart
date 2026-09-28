import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// Top row of the payments page: search, filters toggle and page actions.
///
/// The toolbar stays pinned at the top of the page. Anything expandable (the
/// filter panel) is passed in through [filtersPanel] so this widget stays
/// unaware of what is being filtered.
class PaymentToolbar extends StatefulWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final bool hasActiveFilters;
  final Widget? filtersPanel;
  final VoidCallback onRefresh;
  final VoidCallback onAddPayment;
  final VoidCallback onExport;
  final bool isMobile;

  const PaymentToolbar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.hasActiveFilters,
    required this.filtersPanel,
    required this.onRefresh,
    required this.onAddPayment,
    required this.onExport,
    this.isMobile = false,
  });

  @override
  State<PaymentToolbar> createState() => _PaymentToolbarState();
}

class _PaymentToolbarState extends State<PaymentToolbar> {
  final _searchCtrl = TextEditingController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.searchQuery;
  }

  @override
  void didUpdateWidget(covariant PaymentToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery && _searchCtrl.text != widget.searchQuery) {
      _searchCtrl.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search customer, mobile, receipt...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              widget.onSearchChanged('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  ),
                  onChanged: widget.onSearchChanged,
                ),
              ),
            ),
            if (!widget.isMobile) ...[
              const SizedBox(width: 8),
              _filterChip(() => setState(() => _showFilters = !_showFilters)),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh',
                onPressed: widget.onRefresh,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.table_chart_outlined, size: 20),
                tooltip: 'Export Excel',
                onPressed: widget.onExport,
              ),
              const SizedBox(width: 4),
            ],
            if (widget.isMobile) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.filter_list, size: 20, color: widget.hasActiveFilters ? AppTheme.primaryRed : null),
                tooltip: 'Filters',
                onPressed: () => setState(() => _showFilters = !_showFilters),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh',
                onPressed: widget.onRefresh,
              ),
              IconButton(
                icon: const Icon(Icons.table_chart_outlined, size: 20),
                tooltip: 'Export Excel',
                onPressed: widget.onExport,
              ),
            ],
            FilledButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: widget.isMobile ? const Text('Add') : const Text('Add Payment'),
              onPressed: widget.onAddPayment,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 12 : 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        if (_showFilters && widget.filtersPanel != null) ...[
          const SizedBox(height: 10),
          widget.filtersPanel!,
        ],
      ],
    );
  }

  Widget _filterChip(VoidCallback onTap) {
    final active = widget.hasActiveFilters;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryRed.withAlpha(20) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? AppTheme.primaryRed.withAlpha(80) : AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list, size: 16, color: active ? AppTheme.primaryRed : AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text('Filters', style: TextStyle(fontSize: 12, color: active ? AppTheme.primaryRed : AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
