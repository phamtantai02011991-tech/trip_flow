import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/trip.dart';
import '../../state/trips_provider.dart';
import '../../ui/tokens/app_tokens.dart';
import '../planner/planner_wizard_screen.dart';
import 'trip_overview_screen.dart';

/// Module 6 — danh sách chuyến đi của người dùng.
class TripListScreen extends ConsumerStatefulWidget {
  const TripListScreen({super.key});

  @override
  ConsumerState<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends ConsumerState<TripListScreen> {
  String _filter = 'all';

  static const _filters = <(String, String)>[
    ('all', 'Tất cả'),
    ('planned', 'Đã lên kế hoạch'),
    ('draft', 'Bản nháp'),
    ('completed', 'Đã đi'),
  ];

  @override
  Widget build(BuildContext context) {
    final trips = ref.watch(tripsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.coral,
          onRefresh: () async => ref.invalidate(tripsProvider),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header()),
              SliverToBoxAdapter(child: _filterRow()),
              trips.when(
                loading: () => const SliverToBoxAdapter(child: _LoadingState()),
                error: (error, _) => SliverToBoxAdapter(
                  child: _ErrorState(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(tripsProvider),
                  ),
                ),
                data: (items) {
                  final filtered = _applyFilter(items);
                  if (filtered.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _EmptyState(onCreate: _openPlanner),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _TripCard(
                        trip: filtered[index],
                        onTap: () => _openTrip(filtered[index]),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _openPlanner,
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Chuyến mới'),
      ),
    );
  }

  List<Trip> _applyFilter(List<Trip> items) {
    if (_filter == 'all') return items;
    return items.where((t) => t.status == _filter).toList(growable: false);
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chuyến đi của tôi', style: AppText.display),
          const SizedBox(height: 4),
          Text('Lưu lịch trình, sửa điểm dừng và xem lại các chuyến đã đi.',
              style: AppText.bodySm),
        ],
      ),
    );
  }

  Widget _filterRow() {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (value, label) = _filters[index];
          final active = _filter == value;
          return GestureDetector(
            onTap: () => setState(() => _filter = value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.ink : AppColors.surface,
                borderRadius: AppRadii.pill,
                border: Border.all(color: active ? AppColors.ink : AppColors.line),
              ),
              child: Text(
                label,
                style: AppText.label.copyWith(
                  color: active ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openPlanner() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PlannerWizardScreen()))
        .then((_) => ref.invalidate(tripsProvider));
  }

  void _openTrip(Trip trip) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TripOverviewScreen(tripId: trip.id)),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: AppShadow.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusChip(status: trip.status, aiGenerated: trip.aiGenerated),
                const Spacer(),
                Text(trip.startDate ?? 'Chưa chọn ngày', style: AppText.caption),
              ],
            ),
            const SizedBox(height: 10),
            Text(trip.title, style: AppText.h2, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.trip_origin, size: 14, color: AppColors.coral),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${trip.originName}  →  ${trip.destinationName ?? 'Tự do'}',
                    style: AppText.bodySm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Meta(icon: Icons.calendar_today_rounded, text: '${trip.totalDays} ngày'),
                _Meta(icon: Icons.place_rounded, text: '${trip.stopCount} điểm'),
                _Meta(
                  icon: Icons.straighten_rounded,
                  text: '${trip.totals.distanceKm.toStringAsFixed(0)} km',
                ),
                _Meta(icon: Icons.payments_rounded, text: money(trip.totals.estCost)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.aiGenerated});

  final String status;
  final bool aiGenerated;

  static const _labels = {
    'draft': 'Bản nháp',
    'planned': 'Đã lên kế hoạch',
    'active': 'Đang đi',
    'completed': 'Đã đi',
    'archived': 'Lưu trữ',
  };

  @override
  Widget build(BuildContext context) {
    final color = status == 'completed'
        ? AppColors.success
        : status == 'active'
            ? AppColors.info
            : AppColors.terracotta;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (aiGenerated) ...[
            Icon(Icons.auto_awesome_rounded, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(_labels[status] ?? status,
              style: AppText.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(text, style: AppText.caption),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              height: 132,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text('Không tải được chuyến đi', style: AppText.h3),
          const SizedBox(height: 6),
          Text(message, style: AppText.bodySm, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(color: AppColors.coralSoft, shape: BoxShape.circle),
            child: const Icon(Icons.route_rounded, size: 40, color: AppColors.coral),
          ),
          const SizedBox(height: 16),
          Text('Chưa có chuyến nào', style: AppText.h2),
          const SizedBox(height: 6),
          Text(
            'Nhập điểm đi, điểm đến và sở thích — AI sẽ dựng lộ trình kèm quán ăn trên đường.',
            style: AppText.bodySm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: onCreate, child: const Text('Tạo chuyến đầu tiên')),
        ],
      ),
    );
  }
}

/// Định dạng tiền Việt: 1450000 -> "1.450.000đ"
String money(int value) {
  if (value <= 0) return '0đ';
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${buffer}đ';
}
