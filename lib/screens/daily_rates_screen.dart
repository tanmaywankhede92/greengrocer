import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../providers/rate_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/loading_widget.dart';

class DailyRatesScreen extends ConsumerStatefulWidget {
  const DailyRatesScreen({super.key});
  @override
  ConsumerState<DailyRatesScreen> createState() => _DailyRatesScreenState();
}

class _DailyRatesScreenState extends ConsumerState<DailyRatesScreen> {
  DateTime _selectedDate = DateTime.now();
  final Map<String, TextEditingController> _rateControllers = {};

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  void _loadRates() {
    setState(() { _rateControllers.clear(); });
  }

  Future<void> _saveRate(String productId, double rate) async {
    try {
      await ref.read(rateServiceProvider).upsert(productId, rate, _selectedDate);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rate saved'), duration: Duration(seconds: 1)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);
    final ratesAsync = ref.watch(rateByDateProvider(_selectedDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Rates'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() { _selectedDate = _selectedDate.subtract(const Duration(days: 1)); _loadRates(); }),
                    ),
                    const SizedBox(width: 12),
                    Text(AppUtils.formatDate(_selectedDate), style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setState(() { _selectedDate = _selectedDate.add(const Duration(days: 1)); _loadRates(); }),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () => setState(() { _selectedDate = DateTime.now(); _loadRates(); }),
                      child: const Text('Today'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: productsAsync.when(
                loading: () => const LoadingWidget(),
                error: (e, _) => Center(child: Text('$e')),
                data: (products) {
                  final activeProducts = products.where((p) => p.isActive).toList();
                  if (activeProducts.isEmpty) return const Center(child: Text('No products available', style: TextStyle(color: AppTheme.textSecondary)));

                  return ratesAsync.when(
                    loading: () => const LoadingWidget(),
                    error: (_, __) => const SizedBox(),
                    data: (rates) {
                      for (final p in activeProducts) {
                        if (!_rateControllers.containsKey(p.id)) {
                          final existingRate = rates[p.id];
                          _rateControllers[p.id] = TextEditingController(
                            text: existingRate?.rate.toStringAsFixed(0) ?? '',
                          );
                        }
                      }
                      return Card(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: activeProducts.length,
                          itemBuilder: (context, index) {
                            final p = activeProducts[index];
                            final ctrl = _rateControllers[p.id]!;
                            final existingRate = rates[p.id];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(p.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(p.unit.value, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 100,
                                    child: TextField(
                                      controller: ctrl,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: existingRate != null ? '${existingRate.rate.toStringAsFixed(0)}' : 'Rate',
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                      onSubmitted: (v) {
                                        final rate = double.tryParse(v);
                                        if (rate != null) _saveRate(p.id, rate);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
