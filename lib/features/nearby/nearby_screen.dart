import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../data/places_api.dart';
import '../../ui/tokens/app_tokens.dart';
import '../map/trip_flow_map.dart';
import '../reviews/reviews_sheet.dart';

/// Module 5 — tìm địa điểm quanh đây (bản đồ tối + danh sách + lọc).
class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  // TODO(P2): thay bằng GPS khi có geolocator. Hiện mặc định trung tâm TP.HCM.
  static const _center = LatLng(10.7769, 106.7009);

  static const _kinds = <(String, String, IconData)>[
    ('food', 'Quán ăn', Icons.restaurant_rounded),
    ('cafe', 'Cà phê', Icons.local_cafe_rounded),
    ('sight', 'Tham quan', Icons.photo_camera_rounded),
    ('hotel', 'Khách sạn', Icons.hotel_rounded),
    ('gas', 'Xăng', Icons.local_gas_station_rounded),
    ('ev', 'Sạc điện', Icons.ev_station_rounded),
  ];

  String _kind = 'food';
  double _radius = 3;
  bool _loading = true;
  String? _error;
  NearbyResult? _result;

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
      final data = await PlacesApi().nearby(
        lat: _center.latitude,
        lng: _center.longitude,
        radiusKm: _radius,
        kinds: [_kind],
      );
      if (!mounted) return;
      setState(() {
        _result = data;
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
    final places = _result?.items ?? const <Place>[];

    return Scaffold(
      backgroundColor: AppColors.mapDarkBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: TripFlowMap(
              initialCenter: _center,
              initialZoom: 13,
              dark: true,
              stops: [
                for (var i = 0; i < places.length; i++)
                  MapStopMarker(
                    point: LatLng(places[i].lat, places[i].lng),
                    label: places[i].name,
                    index: i + 1,
                    kindColor: AppColors.kindFood,
                  ),
              ],
              onStopTap: (i) => _openPlace(places[i]),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: _searchBar(),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            left: 0,
            right: 0,
            child: _kindRow(),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.42,
            minChildSize: 0.3,
            maxChildSize: 0.88,
            builder: (context, controller) => Container(
              decoration: const BoxDecoration(
                color: AppColors.mapDarkCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.mapDarkLine,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _labelFor(_kind),
                        style: AppText.h3.copyWith(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text('· ${_radius.toStringAsFixed(0)} km',
                          style: AppText.caption.copyWith(color: AppColors.textTertiary)),
                      if ((_result?.hiddenGemCount ?? 0) > 0) ...[
                        const SizedBox(width: 6),
                        Text('· ${_result!.hiddenGemCount} quán ruột',
                            style: AppText.caption.copyWith(color: AppColors.coral)),
                      ],
                      const Spacer(),
                      _radiusChips(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.coral),
                      ),
                    )
                  else if (_error != null)
                    _errorView()
                  else if (places.isEmpty)
                    _emptyView()
                  else ...[
                    for (final place in places) _placeTile(place),
                    if ((_result?.note ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _result!.note,
                          style: AppText.caption.copyWith(color: AppColors.textTertiary),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.mapDarkCard,
          borderRadius: AppRadii.pill,
          border: Border.all(color: AppColors.mapDarkLine),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 20, color: AppColors.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tìm quanh đây · TP. Hồ Chí Minh',
                style: AppText.bodySm.copyWith(color: AppColors.textOnDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: _load,
              child: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.coral),
            ),
          ],
        ),
      );

  Widget _kindRow() => SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _kinds.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final (code, label, icon) = _kinds[index];
            final active = code == _kind;
            return GestureDetector(
              onTap: () {
                setState(() => _kind = code);
                _load();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.coral : AppColors.mapDarkCard,
                  borderRadius: AppRadii.pill,
                  border: Border.all(
                      color: active ? AppColors.coral : AppColors.mapDarkLine),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 15, color: active ? Colors.white : AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Text(label,
                        style: AppText.label.copyWith(
                            color: active ? Colors.white : AppColors.textSecondary)),
                  ],
                ),
              ),
            );
          },
        ),
      );

  Widget _radiusChips() => Row(
        children: [
          for (final value in const [1.0, 3.0, 5.0, 10.0])
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() => _radius = value);
                  _load();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _radius == value ? AppColors.coral : Colors.transparent,
                    borderRadius: AppRadii.pill,
                    border: Border.all(
                        color: _radius == value ? AppColors.coral : AppColors.mapDarkLine),
                  ),
                  child: Text('${value.toStringAsFixed(0)}km',
                      style: AppText.caption.copyWith(
                          color: _radius == value ? Colors.white : AppColors.textTertiary)),
                ),
              ),
            ),
        ],
      );

  Widget _placeTile(Place place) => GestureDetector(
        onTap: () => _openPlace(place),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.mapDarkBg,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.kindFood.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.restaurant_rounded, color: AppColors.kindFood),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name,
                        style: AppText.h3.copyWith(color: Colors.white, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(place.address,
                        style: AppText.caption.copyWith(color: AppColors.textTertiary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF5B301)),
                        const SizedBox(width: 3),
                        Text(
                          '${place.rating.toStringAsFixed(1)} (${place.reviewCount})'
                          '${place.isHiddenGem ? ' · Quán ruột' : place.isTopRated ? ' · Nổi tiếng' : ''}',
                          style: AppText.caption.copyWith(
                            color: place.isHiddenGem ? AppColors.coral : Colors.white,
                            fontWeight: place.isHiddenGem ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${place.distanceKm.toStringAsFixed(1)} km · ${place.etaMin}p',
                            style: AppText.caption.copyWith(color: AppColors.textTertiary)),
                        if (place.openHours.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(place.openHours,
                                style: AppText.caption
                                    .copyWith(color: AppColors.textTertiary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _emptyView() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            const Icon(Icons.place_outlined, size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 10),
            Text(
              _kind == 'food' || _kind == 'cafe' || _kind == 'sight'
                  ? 'Không có địa điểm trong bán kính này.'
                  : 'Loại này cần Goong/Google Places — chưa cấu hình API key.',
              style: AppText.bodySm.copyWith(color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _errorView() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.textTertiary),
            const SizedBox(height: 8),
            Text(_error!, style: AppText.bodySm.copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );

  void _openPlace(Place place) {
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
              Text(place.name, style: AppText.h2),
              const SizedBox(height: 4),
              Text(place.address, style: AppText.bodySm),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF5B301)),
                  Text(' ${place.rating.toStringAsFixed(1)} '
                      '(${place.reviewCount})', style: AppText.bodySm),
                  const SizedBox(width: 12),
                  Text('${place.distanceKm.toStringAsFixed(1)} km', style: AppText.bodySm),
                  if (place.priceHint.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Flexible(child: Text(place.priceHint, style: AppText.bodySm)),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.directions_rounded, size: 18),
                      label: const Text('Chỉ đường'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                      label: const Text('Thêm vào chuyến'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppColors.surface,
                  builder: (_) => ReviewsSheet(placeKey: place.id, placeName: place.name),
                ),
                icon: const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF5B301)),
                label: const Text('Đánh giá & nhận xét'),
              ),
              const SizedBox(height: 8),
              Text('Nguồn: ${place.source == 'catalog' ? 'dữ liệu TripFlow' : place.source}',
                  style: AppText.caption),
            ],
          ),
        ),
      ),
    );
  }

  String _labelFor(String code) {
    for (final (c, label, _) in _kinds) {
      if (c == code) return label;
    }
    return 'Gần đây';
  }
}
