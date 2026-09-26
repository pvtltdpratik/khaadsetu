import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/price_format.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../domain/invoice_models.dart';
import 'invoice_providers.dart';

String _iso(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// The operator's end-of-day report: sales, cash in hand, UPI and card received, credit given and recovered.
class DailyClosingScreen extends ConsumerStatefulWidget {
  const DailyClosingScreen({super.key});

  @override
  ConsumerState<DailyClosingScreen> createState() => _DailyClosingScreenState();
}

class _DailyClosingScreenState extends ConsumerState<DailyClosingScreen> {
  String? _date; // null = today, as the server sees it

  Future<void> _pick() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: _date == null ? now : DateTime.parse(_date!), firstDate: DateTime(now.year - 2), lastDate: now);
    if (picked != null) setState(() => _date = _iso(picked));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final day = ref.watch(dailyClosingProvider(_date));
    Widget tile(String key, String label, String value, IconData icon, {Color? color}) => Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Icon(icon, color: color ?? colors.primary),
            Text(value, key: Key(key), style: text.titleLarge),
            Text(label, style: text.labelMedium?.copyWith(color: colors.textMuted)),
          ]),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Day closing'), actions: [IconButton(key: const Key('pick-date'), tooltip: 'Choose a day', onPressed: _pick, icon: const Icon(Icons.calendar_month_outlined))]),
      body: ResponsiveScope(
        child: day.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(dailyClosingProvider(_date))),
          data: (d) => ListView(padding: context.pagePadding, children: [
            Text(d.date, key: const Key('closing-date'), style: text.titleMedium),
            Text('${d.invoices} bill${d.invoices == 1 ? '' : 's'} made', style: text.bodySmall?.copyWith(color: colors.textMuted)),
            AppSpacing.gapMd,
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.5,
              children: [
                tile('sales', 'Sales', formatRupeesExact(d.salesTotal), Icons.receipt_long_outlined),
                tile('cash', 'Cash in hand', formatRupeesExact(d.cashInHand), Icons.payments_outlined, color: colors.success),
                tile('upi', 'UPI received', formatRupeesExact(d.upiReceived), Icons.qr_code_2_rounded),
                tile('card', 'Card received', formatRupeesExact(d.cardReceived), Icons.credit_card_outlined),
                tile('credit-given', 'Credit given', formatRupeesExact(d.creditGiven), Icons.book_outlined, color: colors.warning),
                tile('credit-recovered', 'Credit recovered', formatRupeesExact(d.creditRecovered), Icons.task_alt_outlined, color: colors.success),
              ],
            ),
            if (d.refundedTotal > 0) Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: Text('Refunded today: ${formatRupeesExact(d.refundedTotal)}', key: const Key('refunded'), style: text.bodyMedium)),
          ]),
        ),
      ),
    );
  }
}

const _categories = ['organic', 'fertilizer', 'seed', 'pesticide', 'equipment'];

/// The admin's tax and commission settings. Changes apply to the invoices made from then on.
class PlatformSettingsScreen extends ConsumerStatefulWidget {
  const PlatformSettingsScreen({super.key});

  @override
  ConsumerState<PlatformSettingsScreen> createState() => _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState extends ConsumerState<PlatformSettingsScreen> {
  final _fields = <String, TextEditingController>{};
  bool? _includeTax;
  bool _loaded = false;
  bool _saving = false;
  String? _error;

  TextEditingController _c(String key) => _fields.putIfAbsent(key, TextEditingController.new);

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _n(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  void _load(PlatformSettings s) {
    if (_loaded) return;
    _loaded = true;
    _includeTax = s.pricesIncludeTax;
    _c('default').text = _n(s.defaultGst);
    for (final c in _categories) {
      _c(c).text = _n(s.gstByCategory[c] ?? 0);
    }
    _c('center').text = _n(s.centerSalesPercent);
    _c('farmer').text = _n(s.farmerProductPercent);
  }

  double? _pct(String key) {
    final v = double.tryParse(_c(key).text.trim());
    return v == null || v < 0 || v > 100 ? null : v;
  }

  Future<void> _save() async {
    final rates = {for (final c in _categories) c: _pct(c)};
    if (_pct('default') == null || _pct('center') == null || _pct('farmer') == null || rates.values.any((v) => v == null)) {
      return setState(() => _error = 'Every rate must be a number from 0 to 100');
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(invoiceRepositoryProvider);
      await repo.saveSettings('tax', {'pricesIncludeTax': _includeTax, 'defaultGstPercent': _pct('default'), 'gstPercent': {for (final c in _categories) c: rates[c]}});
      await repo.saveSettings('commission', {'centerSalesPercent': _pct('center'), 'farmerProductPercent': _pct('farmer')});
      ref.invalidate(platformSettingsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved. New bills will use these rates.')));
    } catch (err) {
      if (mounted) setState(() => _error = '$err');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final settings = ref.watch(platformSettingsProvider);
    Widget field(String key, String label) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: TextField(key: Key('rate-$key'), controller: _c(key), keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: label, suffixText: '%')),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Tax and commission')),
      body: ResponsiveScope(
        child: settings.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(platformSettingsProvider)),
          data: (s) {
            _load(s);
            return ListView(padding: context.pagePadding.copyWith(bottom: AppSpacing.xl), children: [
              Text('GST', style: text.titleMedium),
              Text('Rates start at 0 until you set them. Confirm the right rate for each kind of product with your accountant before launch.', style: text.bodySmall?.copyWith(color: colors.textMuted)),
              SwitchListTile(key: const Key('includes-tax'), contentPadding: EdgeInsets.zero, title: const Text('Prices already include GST'), subtitle: const Text('On: the bill total stays the price shown to farmers.'), value: _includeTax ?? true, onChanged: (v) => setState(() => _includeTax = v)),
              field('default', 'Rate for anything not listed below'),
              for (final c in _categories) field(c, '${c[0].toUpperCase()}${c.substring(1)}'),
              AppSpacing.gapMd,
              Text('Commission', style: text.titleMedium),
              AppSpacing.gapSm,
              field('center', 'Center sales'),
              field('farmer', 'Farmer-made product sales'),
              if (_error != null) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: Text(_error!, key: const Key('settings-error'), style: TextStyle(color: colors.danger))),
              FilledButton(key: const Key('save-settings'), onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving...' : 'Save')),
            ]);
          },
        ),
      ),
    );
  }
}
