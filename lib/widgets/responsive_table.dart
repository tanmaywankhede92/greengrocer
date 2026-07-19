import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../core/constants.dart';

class TableColumn<T> {
  final String header;
  final Widget Function(T item, int index) builder;
  final bool numeric;

  const TableColumn({
    required this.header,
    required this.builder,
    this.numeric = false,
  });
}

class ResponsiveTable<T> extends StatelessWidget {
  final List<T> items;
  final List<TableColumn<T>> columns;
  final Widget Function(T item, int index) mobileCard;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final void Function(int page)? onPageChanged;
  final bool isLoading;
  final Widget? emptyWidget;

  const ResponsiveTable({
    super.key,
    required this.items,
    required this.columns,
    required this.mobileCard,
    this.totalCount = 0,
    this.currentPage = 1,
    this.pageSize = 50,
    this.onPageChanged,
    this.isLoading = false,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < AppConstants.tabletBreakpoint;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return emptyWidget ?? const SizedBox.shrink();
    }

    if (isMobile) {
      return _buildMobileView();
    }

    return _buildTabletDesktopView(context);
  }

  Widget _buildMobileView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) => mobileCard(items[index], index),
    );
  }

  Widget _buildTabletDesktopView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.surface),
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                fontSize: 13,
              ),
              dataTextStyle: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
              ),
              border: TableBorder(
                horizontalInside: BorderSide(color: Colors.grey.shade200, width: 0.5),
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              columnSpacing: 24,
              horizontalMargin: 16,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 60,
              columns: columns.map((c) => DataColumn(
                label: Text(c.header),
                numeric: c.numeric,
              )).toList(),
              rows: items.asMap().entries.map((entry) {
                return DataRow(
                  color: WidgetStateProperty.resolveWith((states) {
                    if (entry.key.isOdd) return Colors.grey.shade50;
                    return null;
                  }),
                  cells: columns.map((col) => DataCell(
                    Align(
                      alignment: col.numeric ? Alignment.centerRight : Alignment.centerLeft,
                      child: col.builder(entry.value, entry.key),
                    ),
                  )).toList(),
                );
              }).toList(),
            ),
          ),
        ),
        if (totalCount > pageSize) _buildPagination(),
      ],
    );
  }

  Widget _buildPagination() {
    final totalPages = (totalCount / pageSize).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 1 && onPageChanged != null
                ? () => onPageChanged!(currentPage - 1) : null,
          ),
          Text('Page $currentPage of $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages && onPageChanged != null
                ? () => onPageChanged!(currentPage + 1) : null,
          ),
        ],
      ),
    );
  }
}


