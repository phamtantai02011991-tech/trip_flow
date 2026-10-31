import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/models/trip.dart';
import '../../state/trips_provider.dart';
import '../../ui/tokens/app_tokens.dart';
import '../assistant/assistant_screen.dart';
import '../expenses/expenses_screen.dart';
import '../map/trip_flow_map.dart';
import 'trip_list_screen.dart' show money;

/// Module 3 + 6 — tổng quan lộ trình: bản đồ thật + các điểm dừng theo ngày.
class TripOverviewScreen extends ConsumerStatefulWidget {
  const TripOverviewScreen({super.key, required this.tripId});

  final int tripId;

  @override
  ConsumerState<TripOverviewScreen> createState() => _TripOverviewScreenState();
}

class _TripOverviewScreenState extends ConsumerState<TripOverviewScreen> {
  int _selectedDay = 1;
  bool _busy = false;
  List<LatLng> _routePoints = const [];
  int? _routeKey;

  /// Lấy polyline đường đi thật (OSRM) cho ngày đang xem; lỗi thì giữ đường nối điểm.
  void _ensureRoute(Trip trip, List<TripStop> stops) {
    final key = Object.hash(trip.id, _selectedDay, stops.length);
    if (_routeKey == key) return;
    _routeKey = key;

    final destLat = stops.isNotEmpty ? stops.last.lat : (trip.destinationLat ?? trip.originLat);
    final destLng = stops.isNotEmpty ? stops.last.lng : (trip.destinationLng ?? trip.originLng);
    final waypoints = stops.length > 1
        ? [for (var i = 0; i < stops.length - 1; i++) (stops[i].lat, stops[i].lng)]
        : const <(double, double)>[];

    ref
        .read(tripsApiProvider)
        .directions(
          originLat: trip.originLat,
          originLng: trip.originLng,
          destLat: destLat,
          destLng: destLng,
          waypoints: waypoints,
          vehicle: trip.vehicle,
        )
        .then((info) {
      if (!mounted) return;
      setState(() {
        _routePoints = [for (final p in info.points) LatLng(p.$1, p.$2)];
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _routePoints = const []);
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncTrip = ref.watch(tripDetailProvider(widget.tripId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton(
        heroTag: 'assistant_fab',
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AssistantScreen(tripId: widget.tripId),
          ),
        ),
        child: const Icon(Icons.auto_awesome_rounded),
      ),
      body: asyncTrip.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.coral)),
        error: (error, _) => _error(error),
        data: (trip) => _content(trip),
      ),
    );
  }

  Widget _error(Object error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map_outlined, size: 44, color: AppColors.textTertiary),
              const SizedBox(height: 12),
              Text('Không tải được lộ trình', style: AppText.h3),
              const SizedBox(height: 6),
              Text(error.toString(), style: AppText.bodySm, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(tripDetailProvider(widget.tripId)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );

  Widget _content(Trip trip) {
    if (_selectedDay > trip.days.length) _selectedDay = 1;
    final day = trip.days.isEmpty ? null : trip.days[_selectedDay - 1];
    final stops = day?.stops ?? const <TripStop>[];
    _ensureRoute(trip, stops);

    final route = _routePoints.isNotEmpty
        ? _routePoints
        : <LatLng>[
            LatLng(trip.originLat, trip.originLng),
            for (final s in stops) LatLng(s.lat, s.lng),
          ];

    return Stack(
      children: [
        Positioned.fill(
          child: TripFlowMap(
            initialCenter: LatLng(trip.centerPoint.lat, trip.centerPoint.lng),
            initialZoom: 11,
            route: route,
            stops: [
              for (var i = 0; i < stops.length; i++)
                MapStopMarker(
                  point: LatLng(stops[i].lat, stops[i].lng),
                  label: stops[i].name,
                  index: i + 1,
                  kindColor: _kindColor(stops[i].kind),
                ),
            ],
            onStopTap: (index) => _openStop(stops, index),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: _headerBar(trip),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.46,
          minChildSize: 0.32,
          maxChildSize: 0.88,
          builder: (context, controller) => Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
              boxShadow: AppShadow.floating,
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                _dateRow(trip),
                const SizedBox(height: 12),
                _dayPills(trip),
                const SizedBox(height: 12),
                if (stops.isEmpty)
                  _emptyDay()
                else
                  SizedBox(
                    height: 186,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: stops.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => _StopCard(
                        stop: stops[index],
                        index: index,
                        onTap: () => _openStop(stops, index),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _totals(trip),
                const SizedBox(height: 16),
                _actions(trip),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerBar(Trip trip) {
    return Row(
      children: [
        _circleButton(Icons.arrow_back_rounded, () => Navigator.of(context).pop()),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.94),
              borderRadius: AppRadii.pill,
              boxShadow: AppShadow.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tổng quan lộ trình', style: AppText.caption),
                Text(trip.title,
                    style: AppText.h3.copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: AppShadow.card,
          ),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      );

  Widget _dateRow(Trip trip) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Khởi hành', style: AppText.caption),
                Text(trip.startDate ?? 'Chưa chọn', style: AppText.h3.copyWith(fontSize: 15)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thời lượng', style: AppText.caption),
                Text('${trip.totalDays} ngày · ${trip.partySize} người',
                    style: AppText.h3.copyWith(fontSize: 15)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: _busy ? null : _regenerate,
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
            child: Text(_busy ? 'Đang tạo…' : 'Tạo lại AI'),
          ),
        ],
      );

  Widget _dayPills(Trip trip) => SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: trip.days.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final number = trip.days[index].dayNumber;
            final active = number == _selectedDay;
            return GestureDetector(
              onTap: () => setState(() => _selectedDay = number),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.coral : AppColors.surfaceAlt,
                  borderRadius: AppRadii.pill,
                ),
                child: Text(
                  'Ngày $number',
                  style: AppText.label.copyWith(
                    color: active ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          },
        ),
      );

  Widget _emptyDay() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: AppColors.coral),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Ngày này chưa có điểm dừng. Bấm "Tạo lại AI" để lên lịch.',
                  style: AppText.bodySm),
            ),
          ],
        ),
      );

  Widget _totals(Trip trip) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _totalItem('Quãng đường', '${trip.totals.distanceKm.toStringAsFixed(0)} km'),
            _totalItem('Di chuyển', _duration(trip.totals.travelMins)),
            _totalItem('Dự kiến', money(trip.totals.estCost)),
          ],
        ),
      );

  Widget _totalItem(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption.copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: 2),
          Text(value,
              style: AppText.h3.copyWith(color: Colors.white, fontSize: 15)),
        ],
      );

  Widget _actions(Trip trip) => Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _busy ? null : () => _share(trip),
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Chia sẻ'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ExpensesScreen(tripId: widget.tripId, tripTitle: trip.title),
                ),
              ),
              icon: const Icon(Icons.payments_rounded, size: 18),
              label: const Text('Chi phí'),
            ),
          ),
        ],
      );

  /// Chi phí dự kiến theo ngày — tính từ `est_cost` của từng điểm dừng thật.
  void _openCostSheet(Trip trip) {
    final perDay = <int, int>{};
    for (final day in trip.days) {
      perDay[day.dayNumber] =
          day.stops.fold<int>(0, (sum, stop) => sum + (stop.estCost ?? 0));
    }
    final total = perDay.values.fold<int>(0, (a, b) => a + b);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chi phí dự kiến', style: AppText.h2),
              const SizedBox(height: 4),
              Text('Tính từ điểm dừng: xăng xe, ăn uống, vé tham quan.',
                  style: AppText.bodySm),
              const SizedBox(height: 16),
              for (final entry in perDay.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Ngày ${entry.key}', style: AppText.body),
                      ),
                      Text(money(entry.value), style: AppText.h3.copyWith(fontSize: 15)),
                    ],
                  ),
                ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(child: Text('Tổng dự kiến', style: AppText.h3)),
                  Text(money(total),
                      style: AppText.h2.copyWith(color: AppColors.coral)),
                ],
              ),
              const SizedBox(height: 6),
              Text('Chia ${trip.partySize} người: ${money(total ~/ trip.partySize)}/người',
                  style: AppText.bodySm),
            ],
          ),
        ),
      ),
    );
  }

  void _openStop(List<TripStop> stops, int index) {
    final stop = stops[index];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _StopSheet(
        stop: stop,
        canMoveUp: index > 0,
        canMoveDown: index < stops.length - 1,
        onDelete: () => _deleteStop(stop),
        onMove: (delta) => _moveStop(stops, index, delta),
      ),
    );
  }

  /// Module 6 — xoá điểm dừng thật trên server.
  Future<void> _deleteStop(TripStop stop) async {
    Navigator.of(context).pop();
    setState(() => _busy = true);
    try {
      await ref.read(tripsApiProvider).deleteStop(widget.tripId, stop.id);
      ref.invalidate(tripDetailProvider(widget.tripId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Module 6 — đổi thứ tự điểm dừng (gửi mảng id đã sắp xếp).
  Future<void> _moveStop(List<TripStop> stops, int index, int delta) async {
    final target = index + delta;
    if (target < 0 || target >= stops.length) return;
    Navigator.of(context).pop();

    final ids = stops.map((s) => s.id).toList();
    ids.insert(target, ids.removeAt(index));

    setState(() => _busy = true);
    try {
      await ref.read(tripsApiProvider).reorder(widget.tripId, _selectedDay, ids);
      ref.invalidate(tripDetailProvider(widget.tripId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _regenerate() async {
    setState(() => _busy = true);
    try {
      await ref.read(tripsApiProvider).generate(widget.tripId);
      ref.invalidate(tripDetailProvider(widget.tripId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(Trip trip) async {
    setState(() => _busy = true);
    try {
      final updated = await ref.read(tripsApiProvider).share(widget.tripId);
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Link chia sẻ'),
          content: SelectableText('/share/${updated.shareToken ?? ''}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Color _kindColor(String kind) {
    switch (kind) {
      case 'restaurant':
        return AppColors.kindFood;
      case 'cafe':
        return AppColors.kindCafe;
      case 'hotel':
        return AppColors.kindHotel;
      case 'gas':
        return AppColors.kindGas;
      case 'ev':
        return AppColors.kindEv;
      case 'rest':
        return AppColors.kindRest;
      default:
        return AppColors.kindSight;
    }
  }

  String _duration(int minutes) {
    if (minutes <= 0) return '—';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0 ? '${h}h${m.toString().padLeft(2, '0')}' : '${m}p';
  }
}

class _StopCard extends StatelessWidget {
  const _StopCard({required this.stop, required this.index, required this.onTap});

  final TripStop stop;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 196,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.coral, shape: BoxShape.circle),
                  child: Text('${index + 1}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                ),
                const Spacer(),
                if (stop.travelMinsFromPrev != null)
                  Text('${stop.travelMinsFromPrev}p',
                      style: AppText.caption.copyWith(color: AppColors.textTertiary)),
              ],
            ),
            const SizedBox(height: 10),
            Text(stop.name,
                style: AppText.h3.copyWith(fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(stop.address, style: AppText.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(
              children: [
                Icon(_icon(stop.kind), size: 13, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text('${stop.stayMins} phút', style: AppText.caption),
                const Spacer(),
                if (stop.estCost != null)
                  Text(money(stop.estCost!),
                      style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(String kind) {
    switch (kind) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'cafe':
        return Icons.local_cafe_rounded;
      case 'hotel':
        return Icons.hotel_rounded;
      case 'gas':
        return Icons.local_gas_station_rounded;
      case 'ev':
        return Icons.ev_station_rounded;
      case 'rest':
        return Icons.chair_rounded;
      default:
        return Icons.photo_camera_rounded;
    }
  }
}

class _StopSheet extends StatelessWidget {
  const _StopSheet({
    required this.stop,
    this.canMoveUp = false,
    this.canMoveDown = false,
    this.onDelete,
    this.onMove,
  });

  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback? onDelete;
  final void Function(int delta)? onMove;

  final TripStop stop;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(stop.name, style: AppText.h2),
            const SizedBox(height: 4),
            Text(stop.address.isEmpty ? 'Chưa có địa chỉ' : stop.address,
                style: AppText.bodySm),
            const SizedBox(height: 16),
            Row(
              children: [
                _fact(Icons.schedule_rounded, 'Lưu lại ${stop.stayMins} phút'),
                const SizedBox(width: 16),
                if (stop.distanceKmFromPrev != null)
                  _fact(Icons.straighten_rounded,
                      '${stop.distanceKmFromPrev!.toStringAsFixed(1)} km'),
              ],
            ),
            if (stop.note != null && stop.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.coralSoft,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Text('Vì sao chọn: ${stop.note}', style: AppText.bodySm),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                if (onMove != null) ...[
                  IconButton.filledTonal(
                    onPressed: canMoveUp ? () => onMove!(-1) : null,
                    icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: canMoveDown ? () => onMove!(1) : null,
                    icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    label: const Text('Xoá điểm dừng'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Nguồn: ${stop.source == 'ai' ? 'AI chọn từ dữ liệu địa điểm thật' : 'Người dùng thêm'}',
                style: AppText.caption),
          ],
        ),
      ),
    );
  }

  Widget _fact(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textTertiary),
          const SizedBox(width: 6),
          Text(text, style: AppText.bodySm),
        ],
      );
}
