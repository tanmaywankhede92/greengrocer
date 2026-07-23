import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../core/utils.dart';
import '../services/customer_service.dart';

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
    final q = query.trim();
    if (q.isEmpty) {
      setState(() { _results = []; _showDropdown = false; });
      return;
    }
    final result = await ref.read(customerSearchProvider(q).future);
    if (mounted) setState(() { _results = result; _showDropdown = true; });
  }

  Future<void> _showAddCustomerDialog() async {
    final nameCtrl = TextEditingController(text: _controller.text);
    final mobileCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    String? createdId;
    final saved = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *')),
              const SizedBox(height: 12),
              TextField(controller: mobileCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile *')),
              const SizedBox(height: 12),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || mobileCtrl.text.isEmpty) return;
              try {
                final service = CustomerService();
                createdId = await service.create({'name': nameCtrl.text, 'mobile': mobileCtrl.text, 'address': addrCtrl.text});
                if (ctx.mounted) Navigator.pop(ctx, {'id': createdId!, 'name': nameCtrl.text, 'mobile': mobileCtrl.text, 'address': addrCtrl.text});
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != null && mounted) {
      final newCustomer = Customer(id: saved['id']!, name: saved['name']!, mobile: saved['mobile']!, address: saved['address']);
      setState(() {
        _selected = newCustomer;
        _controller.text = newCustomer.name;
        _showDropdown = false;
      });
      widget.onSelected(newCustomer);
    }
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
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _selected != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _controller.clear();
                      setState(() { _selected = null; _results = []; _showDropdown = false; });
                    },
                  )
                : null,
          ),
        ),
        if (_showDropdown)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            constraints: const BoxConstraints(maxHeight: 240),
            child: _results.isNotEmpty
                ? ListView.builder(
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
                  )
                : ListTile(
                    dense: true,
                    leading: const Icon(Icons.person_add, color: AppTheme.primaryRed),
                    title: const Text('Add new customer', style: TextStyle(color: AppTheme.primaryRed, fontSize: 14)),
                    subtitle: Text('"${_controller.text}"', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    onTap: () => _showAddCustomerDialog(),
                  ),
          ),
        if (_selected != null && _selected!.currentDue > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.warning.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Previous Due: ${AppUtils.formatCurrency(_selected!.currentDue)}',
                  style: const TextStyle(color: AppTheme.warning, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
      ],
    );
  }
}
