import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../core/utils.dart';

class CustomerSelect extends ConsumerStatefulWidget {
  final ValueChanged<Customer> onSelected;
  final Customer? initial;
  const CustomerSelect({super.key, required this.onSelected, this.initial});

  @override
  ConsumerState<CustomerSelect> createState() => _CustomerSelectState();
}

class _CustomerSelectState extends ConsumerState<CustomerSelect> {
  final _controller = TextEditingController();
  List<Customer> _results = [];
  Customer? _selected;
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _selected = widget.initial;
      _controller.text = widget.initial!.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() { _results = []; _showDropdown = false; });
      return;
    }
    final result = await ref.read(customerSearchProvider(query).future);
    if (mounted) setState(() { _results = result; _showDropdown = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customer', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search customer by name or mobile...',
            suffixIcon: _selected != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _controller.clear();
                      setState(() { _selected = null; _results = []; _showDropdown = false; });
                    },
                  )
                : const Icon(Icons.search, size: 20),
          ),
        ),
        if (_showDropdown && _results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade700),
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final c = _results[index];
                return ListTile(
                  dense: true,
                  title: Text(c.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                  subtitle: Text('${c.mobile}  •  Due: ${AppUtils.formatCurrency(c.currentDue)}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  onTap: () {
                    setState(() {
                      _selected = c;
                      _controller.text = c.name;
                      _showDropdown = false;
                    });
                    widget.onSelected(c);
                  },
                );
              },
            ),
          ),
        if (_selected != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Previous Due: ${AppUtils.formatCurrency(_selected!.currentDue)}',
                style: const TextStyle(color: AppTheme.warning, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}
