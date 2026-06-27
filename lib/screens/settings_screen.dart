import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../config/theme.dart';
import '../providers/settings_provider.dart';
import '../services/api_client.dart';
import '../widgets/loading_widget.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _taglineCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _prefixCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _taglineCtrl.dispose(); _addrCtrl.dispose();
    _phoneCtrl.dispose(); _gstCtrl.dispose(); _prefixCtrl.dispose(); _footerCtrl.dispose();
    super.dispose();
  }

  void _initFromSettings() {
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings != null && !_initialized) {
      _nameCtrl.text = settings.businessName;
      _taglineCtrl.text = settings.tagline ?? '';
      _addrCtrl.text = settings.address ?? '';
      _phoneCtrl.text = settings.phone ?? '';
      _gstCtrl.text = settings.gstNumber ?? '';
      _prefixCtrl.text = settings.invoicePrefix;
      _footerCtrl.text = settings.footerNote ?? '';
      _initialized = true;
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(settingsServiceProvider).update({
        'businessName': _nameCtrl.text,
        'tagline': _taglineCtrl.text,
        'address': _addrCtrl.text,
        'phone': _phoneCtrl.text,
        'gstNumber': _gstCtrl.text,
        'invoicePrefix': _prefixCtrl.text,
        'footerNote': _footerCtrl.text,
      });
      ref.invalidate(settingsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved'), backgroundColor: AppTheme.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    _initFromSettings();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.error))),
        data: (_) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 600,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Environment', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('API Server', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(ApiConfig.baseUrl, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SegmentedButton<Environment>(
                            segments: const [
                              ButtonSegment(value: Environment.local, label: Text('Local'), icon: Icon(Icons.computer, size: 16)),
                              ButtonSegment(value: Environment.production, label: Text('Production'), icon: Icon(Icons.cloud, size: 16)),
                            ],
                            selected: {ApiConfig.current},
                            onSelectionChanged: (selected) {
                              final env = selected.first;
                              ApiClient().setEnvironment(env);
                              ref.invalidate(settingsProvider);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Switched to ${env.name} server'),
                                backgroundColor: AppTheme.success,
                              ));
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Business Information', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Business Name *')),
                  const SizedBox(height: 16),
                  TextField(controller: _taglineCtrl, decoration: const InputDecoration(labelText: 'Tagline')),
                  const SizedBox(height: 16),
                  TextField(controller: _addrCtrl, decoration: const InputDecoration(labelText: 'Address'), maxLines: 2),
                  const SizedBox(height: 16),
                  TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  TextField(controller: _gstCtrl, decoration: const InputDecoration(labelText: 'GST Number')),
                  const SizedBox(height: 24),
                  const Text('Invoice Settings', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  TextField(controller: _prefixCtrl, decoration: const InputDecoration(labelText: 'Invoice Prefix', hintText: 'RE')),
                  const SizedBox(height: 16),
                  TextField(controller: _footerCtrl, decoration: const InputDecoration(labelText: 'Footer Note'), maxLines: 2),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Settings', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
