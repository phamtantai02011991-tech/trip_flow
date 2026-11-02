import 'package:flutter/material.dart';

import '../../data/trips_api.dart';
import '../../ui/tokens/app_tokens.dart';
import '../trip/trip_list_screen.dart' show money;

/// Module 7 — chi phí thực tế của chuyến: thêm, xoá, so sánh với dự kiến.
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key, required this.tripId, this.tripTitle = ''});

  final int tripId;
  final String tripTitle;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _api = TripsApi();
  TripBudget? _budget;
  List<TripExpense> _items = const [];
  bool _loading = true;
  String? _error;

  static const _categories = <(String, String, IconData, Color)>[
    ('fuel', 'Xăng xe', Icons.local_gas_station_rounded, AppColors.kindGas),
    ('food', 'Ăn uống', Icons.restaurant_rounded, AppColors.kindFood),
    ('hotel', 'Khách sạn', Icons.hotel_rounded, AppColors.kindHotel),
    ('ticket', 'Vé tham quan', Icons.confirmation_number_rounded, AppColors.kindSight),
    ('other', 'Phát sinh', Icons.more_horiz_rounded, AppColors.textSecondary),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.budgetSummary(widget.tripId),
        _api.listExpenses(widget.tripId),
      ]);
      if (!mounted) return;
      setState(() {
        _budget = results[0] as TripBudget;
        _items = results[1] as List<TripExpense>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Chi phí chuyến đi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.coral))
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  color: AppColors.coral,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    children: [
                      _summaryCard(),
                      const SizedBox(height: 16),
                      if (_categories.any((c) => (_budget?.byCategory[c.$1] ?? 0) > 0))
                        _categoryBreakdown(),
                      const SizedBox(height: 16),
                      Text('Khoản chi', style: AppText.h2),
                      const SizedBox(height: 8),
                      if (_items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text('Chưa ghi khoản chi nào.',
                                style: AppText.bodySm),
                          ),
                        )
                      else
                        for (final item in _items) _expenseTile(item),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _openAddSheet,
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm chi phí'),
      ),
    );
  }

  Widget _summaryCard() {
    final budget = _budget;
    final total = budget?.actualTotal ?? 0;
    final estimate = budget?.totalEstimate ?? 0;
    final limit = budget?.budgetAmount ?? 0;
    final ratio = limit > 0 ? (total / limit).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Đã chi', style: AppText.caption.copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: 4),
          Text(money(total),
              style: AppText.display.copyWith(color: Colors.white, fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            budget == null || budget.budgetAmount == 0
                ? 'Dự kiến: ${money(estimate)} · ${money(budget?.perPerson ?? 0)}/người'
                : 'Ngân sách ${money(limit)} · ${money(budget.perPerson)}/người',
            style: AppText.caption.copyWith(color: AppColors.textTertiary),
          ),
          if (limit > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: AppColors.mapDarkCard,
                valueColor: AlwaysStoppedAnimation(
                    budget!.overBudget ? AppColors.danger : AppColors.coral),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              budget.overBudget
                  ? 'Đã vượt ngân sách ${money((budget.actualTotal - limit).abs())}'
                  : 'Còn lại ${money(budget.remaining ?? (limit - total))}',
              style: AppText.caption.copyWith(
                  color: budget.overBudget ? AppColors.danger : AppColors.success),
            ),
          ],
        ],
      ),
    );
  }

  Widget _categoryBreakdown() {
    final byCategory = _budget?.byCategory ?? const <String, int>{};
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (code, label, icon, color) in _categories)
          if ((byCategory[code] ?? 0) > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.pill,
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 6),
                  Text('$label ${money(byCategory[code] ?? 0)}', style: AppText.caption),
                ],
              ),
            ),
      ],
    );
  }

  Widget _expenseTile(TripExpense item) {
    final meta = _categories.firstWhere(
      (c) => c.$1 == item.category,
      orElse: () => _categories[4],
    );
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) async {
        try {
          await _api.deleteExpense(widget.tripId, item.id);
          _load();
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Không xoá được: $e')));
          _load();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: meta.$4.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(meta.$3, size: 20, color: meta.$4),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: AppText.h3.copyWith(fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('${meta.$2} · ${item.planned ? 'dự kiến' : 'thực tế'}',
                      style: AppText.caption),
                ],
              ),
            ),
            Text(money(item.amount), style: AppText.h3.copyWith(fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Không tải được chi phí', style: AppText.h3),
              const SizedBox(height: 6),
              Text(_error!, style: AppText.bodySm, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );

  void _openAddSheet() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String category = 'food';
    bool planned = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Thêm khoản chi', style: AppText.h2),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'Tên khoản chi (VD: Ăn sáng)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Số tiền (VND)'),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (code, label, icon, color) in _categories)
                    GestureDetector(
                      onTap: () => setSheet(() => category = code),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: category == code
                              ? color.withValues(alpha: 0.16)
                              : AppColors.surfaceAlt,
                          borderRadius: AppRadii.pill,
                          border: Border.all(
                              color: category == code ? color : AppColors.line),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 14, color: color),
                            const SizedBox(width: 6),
                            Text(label, style: AppText.caption),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: planned,
                activeThumbColor: AppColors.coral,
                title: Text('Đây là chi phí dự kiến', style: AppText.bodySm),
                onChanged: (v) => setSheet(() => planned = v),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () async {
                  final amount = int.tryParse(
                      amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                      0;
                  if (titleController.text.trim().isEmpty || amount <= 0) return;
                  Navigator.pop(context);
                  try {
                    await _api.addExpense(
                      widget.tripId,
                      title: titleController.text.trim(),
                      amount: amount,
                      category: category,
                      planned: planned,
                    );
                    _load();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Không thêm được: $e')));
                  }
                },
                child: const Text('Lưu khoản chi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
