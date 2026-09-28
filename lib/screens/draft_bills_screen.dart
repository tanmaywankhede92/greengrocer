import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../models/draft_bill.dart';
import '../providers/bill_provider.dart';
import '../services/api_client.dart';
import '../widgets/breadcrumb.dart';
import '../widgets/empty_state.dart';

class DraftBillsScreen extends ConsumerStatefulWidget {
  const DraftBillsScreen({super.key});

  @override
  ConsumerState<DraftBillsScreen> createState() => _DraftBillsScreenState();
}

class _DraftBillsScreenState extends ConsumerState<DraftBillsScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String? _discardingId;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _discardDraft(DraftBill draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: AppTheme.error, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Discard Draft?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to discard draft ${draft.draftId}? All entered items will be permanently removed.',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _discardingId = draft.id);
    try {
      final billService = ref.read(billServiceProvider);
      await billService.discardDraft(draft.id.isNotEmpty ? draft.id : draft.draftId);
      ref.invalidate(draftListProvider);
      ref.invalidate(draftCountProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Draft ${draft.draftId} discarded'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to discard draft: ${ApiClient.humanizeError(e)}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _discardingId = null);
    }
  }

  void _openDraft(DraftBill draft) {
    context.go('/bills/new', extra: draft);
  }

  @override
  Widget build(BuildContext context) {
    final draftsAsync = ref.watch(draftListProvider(_search.isEmpty ? null : _search));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Draft Bills'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Bill'),
              onPressed: () => context.go('/bills/new'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(draftListProvider);
          ref.invalidate(draftCountProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Breadcrumb(crumbs: [
                Crumb('Home', route: '/dashboard'),
                Crumb('Bills', route: '/bills'),
                Crumb('Draft Bills'),
              ]),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by draft ID, customer name or mobile...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _search = '');
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v.trim()),
                ),
              ),
              draftsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.error, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load drafts: ${ApiClient.humanizeError(e)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.error),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => ref.invalidate(draftListProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (drafts) {
                  if (drafts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
                      child: EmptyState(
                        icon: Icons.drafts_outlined,
                        title: _search.isEmpty ? 'No Saved Drafts' : 'No matching drafts found',
                        subtitle: _search.isEmpty
                            ? 'Partially completed bills will appear here so you can continue them at any time.'
                            : 'Try adjusting your search query.',
                        actionLabel: _search.isEmpty ? 'Create Bill' : null,
                        onAction: _search.isEmpty ? () => context.go('/bills/new') : null,
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: drafts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final draft = drafts[index];
                      return _buildDraftCard(draft);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraftCard(DraftBill draft) {
    final customerDisplayName = draft.customerName.isNotEmpty
        ? draft.customerName
        : (draft.customer?.name ?? 'Walk-in / Unassigned');
    final hasCustomer = draft.customerName.isNotEmpty || draft.customer != null;
    final isDiscarding = _discardingId == draft.id;

    final dateToDisplay = draft.updatedAt ?? draft.createdAt ?? draft.billDate;
    final formattedTime = AppUtils.formatDateTime(dateToDisplay.toLocal());

    return Material(
      color: Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isDiscarding ? null : () => _openDraft(draft),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border.withAlpha(80)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withAlpha(15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      draft.draftId,
                      style: const TextStyle(
                        color: AppTheme.primaryRed,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade400, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_note, size: 14, color: Colors.amber.shade900),
                        const SizedBox(width: 4),
                        Text(
                          'Draft',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Customer & Items info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              hasCustomer ? Icons.person_outline : Icons.person_off_outlined,
                              size: 16,
                              color: hasCustomer ? AppTheme.textPrimary : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                customerDisplayName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: hasCustomer ? AppTheme.textPrimary : AppTheme.textSecondary,
                                  fontStyle: hasCustomer ? FontStyle.normal : FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (draft.customerMobile.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.only(left: 22),
                            child: Text(
                              draft.customerMobile,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppUtils.formatCurrency(draft.total),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryRed,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${draft.items.length} ${draft.items.length == 1 ? 'item' : 'items'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (draft.items.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: draft.items.take(4).map((i) {
                    final qtyStr = i.quantity % 1 == 0 ? i.quantity.toInt().toString() : i.quantity.toString();
                    final itemText = '${i.productName} ($qtyStr ${i.unit})';
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300, width: 0.5),
                      ),
                      child: Text(
                        itemText,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                      ),
                    );
                  }).toList()
                    ..addAll(
                      draft.items.length > 4
                          ? [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '+${draft.items.length - 4} more',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ]
                          : [],
                    ),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: isDiscarding
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.error),
                          )
                        : const Icon(Icons.delete_outline, size: 16),
                    label: Text(isDiscarding ? 'Discarding...' : 'Discard'),
                    onPressed: isDiscarding ? null : () => _discardDraft(draft),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Continue Draft'),
                    onPressed: isDiscarding ? null : () => _openDraft(draft),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
