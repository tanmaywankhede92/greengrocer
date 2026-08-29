import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/customer.dart';
import '../services/api_client.dart';
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
  final _fieldKey = GlobalKey();
  final _layerLink = LayerLink();
  List<Customer> _results = [];
  Customer? _selected;
  OverlayEntry? _dropdownOverlay;

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
    _removeDropdown();
    _controller.dispose();
    super.dispose();
  }

  void _showDropdown() {
    _removeDropdown();
    final RenderBox? renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;
    final size = renderBox.size;

    _dropdownOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeDropdown,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            showWhenUnlinked: false,
            child: SizedBox(
              width: size.width,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                constraints: const BoxConstraints(maxHeight: 240),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: _results.isNotEmpty
                    ? ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final c = _results[index];
                          return ListTile(
                            dense: true,
                            title: Text(c.name,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary, fontSize: 14)),
                            subtitle: Text(
                                '${c.mobile}  \u2022  Due: ${AppUtils.formatCurrency(c.currentDue)}',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                            onTap: () {
                              setState(() {
                                _selected = c;
                                _controller.text = c.name;
                              });
                              widget.onSelected(c);
                              _removeDropdown();
                            },
                          );
                        },
                      )
                    : ListTile(
                        dense: true,
                        leading: const Icon(Icons.person_add,
                            color: AppTheme.primaryRed),
                        title: const Text('Add new customer',
                            style: TextStyle(
                                color: AppTheme.primaryRed, fontSize: 14)),
                        subtitle: Text('"${_controller.text}"',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                        onTap: () {
                          _removeDropdown();
                          _showAddCustomerDialog();
                        },
                      ),
              ),
            ),
          ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_dropdownOverlay!);
  }

  void _removeDropdown() {
    _dropdownOverlay?.remove();
    _dropdownOverlay = null;
  }

  void _onSearchChanged(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
      });
      _removeDropdown();
      return;
    }
    final result = await ref.read(customerSearchProvider(q).future);
    if (mounted) {
      setState(() {
        _results = result;
      });
      _showDropdown();
    }
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
              TextField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Name *')),
              const SizedBox(height: 12),
              TextField(
                  controller: mobileCtrl,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(labelText: 'Mobile *')),
              const SizedBox(height: 12),
              TextField(
                  controller: addrCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Address'),
                  maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || mobileCtrl.text.isEmpty) {
                return;
              }
              try {
                final service = CustomerService();
                createdId = await service.create({
                  'name': nameCtrl.text,
                  'mobile': mobileCtrl.text,
                  'address': addrCtrl.text
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx, {
                    'id': createdId!,
                    'name': nameCtrl.text,
                    'mobile': mobileCtrl.text,
                    'address': addrCtrl.text
                  });
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text(ApiClient.humanizeError(e)),
                      backgroundColor: AppTheme.error));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != null && mounted) {
      final newCustomer = Customer(
          id: saved['id']!,
          name: saved['name']!,
          mobile: saved['mobile']!,
          address: saved['address']);
      setState(() {
        _selected = newCustomer;
        _controller.text = newCustomer.name;
      });
      widget.onSelected(newCustomer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customer',
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        CompositedTransformTarget(
          link: _layerLink,
          child: TextField(
            key: _fieldKey,
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
                        setState(() {
                          _selected = null;
                          _results = [];
                        });
                        _removeDropdown();
                      },
                    )
                  : null,
            ),
          ),
        ),
        if (_selected != null && _selected!.currentDue > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.warning.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                  'Previous Due: ${AppUtils.formatCurrency(_selected!.currentDue)}',
                  style: const TextStyle(
                      color: AppTheme.warning,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),
      ],
    );
  }
}
