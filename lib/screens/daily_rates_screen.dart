import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../core/utils.dart';
import '../providers/rate_provider.dart';
import '../services/api_client.dart';
import '../providers/product_provider.dart';


class DailyRatesScreen extends ConsumerStatefulWidget {
  const DailyRatesScreen({super.key});
  @override
  ConsumerState<DailyRatesScreen> createState() => _DailyRatesScreenState();
}

class _DailyRatesScreenState extends ConsumerState<DailyRatesScreen> {
  DateTime _selectedDate = DateTime.now();
  final Map<String, TextEditingController> _rateControllers = {};
  bool _saving = false;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadRates() {
    setState(() { _rateControllers.clear(); });
  }

  Future<void> _saveRate(String productId, double rate) async {
    await ref.read(rateServiceProvider).upsert(productId, rate, _selectedDate);
  }

  Future<void> _saveAllRates() async {
    setState(() => _saving = true);
    int saved = 0;
    int failed = 0;
    for (final entry in _rateControllers.entries) {
      final rate = double.tryParse(entry.value.text.trim());
      if (rate == null) continue;
      try {
        await _saveRate(entry.key, rate);
        saved++;
      } catch (_) {
        failed++;
      }
    }
    if (mounted) {
      setState(() => _saving = false);
      if (failed == 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$saved rate${saved == 1 ? '' : 's'} saved'), duration: const Duration(seconds: 2)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$saved saved, $failed failed'), backgroundColor: Colors.orange));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);
    final ratesAsync = ref.watch(rateByDateProvider(_selectedDate));

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Rates')),
      body: SingleChildScrollView(
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
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search product...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); })
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
              ),
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
            ),
            const SizedBox(height: 16),
            productsAsync.when(
              loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (e, _) => SizedBox(height: 200, child: Center(child: Text(ApiClient.humanizeError(e)))),
              data: (products) {
                final activeProducts = products.where((p) {
                  if (!p.isActive) return false;
                  if (_search.isEmpty) return true;
                  final display = '${p.name} ${p.nameHindi}'.toLowerCase();
                  return display.contains(_search);
                }).toList();
                if (activeProducts.isEmpty) return const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No products available', style: TextStyle(color: AppTheme.textSecondary))));

                return ratesAsync.when(
                  loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (_, __) => const SizedBox(height: 200),
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
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.nameHindi.isNotEmpty ? '${p.name} (${p.nameHindi})' : p.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(p.unit.value, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                const SizedBox(width: 8),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 80, maxWidth: 120),
                                  child: TextField(
                                    controller: ctrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: existingRate != null ? existingRate.rate.toStringAsFixed(0) : 'Rate',
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                    onSubmitted: (v) async {
                                      final rate = double.tryParse(v);
                                      if (rate != null) {
                                        try {
                                          await _saveRate(p.id, rate);
                                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rate saved'), duration: Duration(seconds: 1)));
                                        } catch (e) {
                                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.humanizeError(e)), backgroundColor: AppTheme.error));
                                        }
                                      }
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
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(left: 24, right: 24, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8, offset: const Offset(0, -2))]),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save, size: 18),
            label: Text(_saving ? 'Saving...' : 'Save All Rates', style: const TextStyle(fontSize: 15)),
            onPressed: _saving ? null : _saveAllRates,
          ),
        ),
      ),
    );
  }
}
