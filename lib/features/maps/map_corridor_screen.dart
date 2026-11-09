import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/utils/data_models.dart';
import '../../core/utils/geo_utils.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/places_api.dart';
import '../../ui/tokens/app_tokens.dart';
import '../restaurants/restaurant_detail_screen.dart';

/// Tab 2: Bản đồ & Tìm nhà hàng trên lộ trình (MapCorridorScreen - Mục 5.1.8 & Mục 9).
/// Thực thi trọn vẹn 6 bước của Mục 9:
/// 1. Chọn Điểm xuất phát và Điểm đến tại TP. Hồ Chí Minh
/// 2. Tính toán tuyến đường di chuyển (Polyline) và chiều dài hành trình
/// 3. Thiết lập hành lang tìm kiếm quanh tuyến đường (Corridor Radius từ 0.5 km đến 5.0 km)
/// 4. Vẽ trực quan Bản đồ tương tác (tuyến đường, vùng đệm hành lang, chốt địa điểm & nhà hàng)
/// 5. Lọc và sắp xếp các nhà hàng nằm dọc tuyến đường kèm độ lệch (distanceFromRouteKm)
/// 6. Cho phép bấm 1 chạm "Chọn làm điểm dừng" để thêm nhà hàng vào Lịch trình hiện tại.
class MapCorridorScreen extends StatefulWidget {
  final TripFlowAppState appState;

  const MapCorridorScreen({super.key, required this.appState});

  @override
  State<MapCorridorScreen> createState() => _MapCorridorScreenState();
}

class _MapCorridorScreenState extends State<MapCorridorScreen> {
  int _originDestId = 1; // Mặc định: Dinh Độc Lập (Quận 1)
  int _targetDestId = 7; // Mặc định: Bảo tàng Chứng tích Chiến tranh (Quận 3)
  double _corridorRadiusKm = AppConfig.defaultCorridorRadiusKm;
  String _selectedCuisine = 'all';
  CorridorSearchResponseModel? _backendResponse;
  List<AlongRouteStop> _alongRouteStops = const [];
  bool _isSearchingBackend = false;

  Future<void> _runBackendCorridorSearch(
    DestinationModel origin,
    DestinationModel target,
  ) async {
    setState(() => _isSearchingBackend = true);
    final resp = await widget.appState.apiClient.searchCorridorOnBackend(
      provinceId: widget.appState.selectedProvince.id,
      originLat: origin.latitude,
      originLng: origin.longitude,
      destinationLat: target.latitude,
      destinationLng: target.longitude,
      corridorRadiusKm: _corridorRadiusKm,
      cuisineFilter: _selectedCuisine,
      fallbackRestaurants: widget.appState.allRestaurants
          .where((r) => r.provinceId == widget.appState.selectedProvince.id)
          .toList(),
    );
    List<AlongRouteStop> stops = const [];
    try {
      stops = await PlacesApi().alongRoute(
        originLat: origin.latitude,
        originLng: origin.longitude,
        destLat: target.latitude,
        destLng: target.longitude,
        corridorRadiusKm: _corridorRadiusKm,
      );
    } catch (_) {
      stops = const [];
    }
    if (mounted) {
      setState(() {
        _backendResponse = resp;
        _alongRouteStops = stops;
        _isSearchingBackend = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final selectedProvId = widget.appState.selectedProvince.id;
        final destinations = widget.appState.allDestinations
            .where((d) => d.provinceId == selectedProvId)
            .toList();
        final safeDestinations = destinations.isNotEmpty
            ? destinations
            : widget.appState.allDestinations;
        final origin = safeDestinations.firstWhere(
          (d) => d.id == _originDestId,
          orElse: () => safeDestinations.first,
        );
        final target = safeDestinations.firstWhere(
          (d) => d.id == _targetDestId,
          orElse: () => safeDestinations.last,
        );

        final polyline = _backendResponse?.polyline.isNotEmpty == true
            ? _backendResponse!.polyline
            : GeoUtils.buildRoutePolyline(
                originLat: origin.latitude,
                originLng: origin.longitude,
                destLat: target.latitude,
                destLng: target.longitude,
              );
        final boundingBox = _backendResponse?.boundingBox ??
            GeoUtils.computeBoundingBox(polyline, _corridorRadiusKm);
        final routeLengthKm = _backendResponse?.totalRouteKm ??
            GeoUtils.calculateRouteLengthKm(polyline);

        final corridorResults = _backendResponse?.results ??
            GeoUtils.findRestaurantsOnCorridor(
              restaurants: widget.appState.allRestaurants
                  .where((r) => r.provinceId == origin.provinceId)
                  .toList(),
              polyline: polyline,
              corridorRadiusKm: _corridorRadiusKm,
              cuisineFilter: _selectedCuisine,
            );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Bản Đồ & Nhà Hàng Trên Lộ Trình'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.appState.locationPermission ==
                  LocationPermissionState.denied)
                LocationPermissionNotice(
                  onGrantPermission: () {
                    widget.appState.setLocationPermission(
                      LocationPermissionState.granted,
                    );
                  },
                ),

              // Bộ chọn Điểm xuất phát & Điểm đến + Bán kính Hành lang (Corridor Radius)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.alt_route_rounded,
                          color: AppTheme.primaryTeal,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Thiết lập Lộ trình & Hành lang tìm kiếm (Mục 9)',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: origin.id,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Điểm xuất phát (Origin)',
                        prefixIcon: Icon(
                          Icons.trip_origin_rounded,
                          color: Colors.teal,
                          size: 18,
                        ),
                      ),
                      items: safeDestinations.map((d) {
                        return DropdownMenuItem<int>(
                          value: d.id,
                          child: Text(
                            d.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _originDestId = val;
                            _backendResponse = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: target.id,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Điểm đến (Destination)',
                        prefixIcon: Icon(
                          Icons.flag_rounded,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                      ),
                      items: safeDestinations.map((d) {
                        return DropdownMenuItem<int>(
                          value: d.id,
                          child: Text(
                            d.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _targetDestId = val;
                            _backendResponse = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bán kính hành lang quanh tuyến đường:',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCCFBF1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${_corridorRadiusKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _corridorRadiusKm,
                      min: AppConfig.minCorridorRadiusKm,
                      max: AppConfig.maxCorridorRadiusKm,
                      divisions: 9,
                      activeColor: AppTheme.primaryTeal,
                      label: '${_corridorRadiusKm.toStringAsFixed(1)} km',
                      onChanged: (val) {
                        setState(() {
                          _corridorRadiusKm = val;
                          _backendResponse = null;
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF99F6E4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.map_outlined,
                                size: 15,
                                color: AppTheme.primaryTeal,
                              ),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'Goong Maps Polyline • PostgreSQL B-Tree Bounding Box + Shapely',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _isSearchingBackend
                                    ? null
                                    : () => _runBackendCorridorSearch(
                                          origin,
                                          target,
                                        ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.sync_rounded, size: 14),
                                label: Text(
                                  _isSearchingBackend
                                      ? 'Đang gọi API...'
                                      : 'Đồng bộ Goong API',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Bounding Box SQL: Lat [${boundingBox['min_lat']} .. ${boundingBox['max_lat']}], Lng [${boundingBox['min_lng']} .. ${boundingBox['max_lng']}] • Rate Limit: ${AppConfig.corridorRateLimitPerMinute} req/min/IP',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Bản đồ tương tác trực quan (CustomPaint Map Canvas)
              Container(
                height: 225,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CorridorMapPainter(
                          polyline: polyline,
                          matchedRestaurants: corridorResults,
                          corridorRadiusKm: _corridorRadiusKm,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 12,
                      right: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Quãng đường: $routeLengthKm km • Hành lang: ${_corridorRadiusKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentAmber,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${corridorResults.length} quán dọc tuyến',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '🟢 ${origin.name}  ➔  🔴 ${target.name}',
                          style: const TextStyle(
                            color: Color(0xFFCCFBF1),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tiêu đề danh sách kết quả Corridor Search
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Nhà hàng nằm dọc lộ trình (${corridorResults.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Sắp xếp ưu tiên theo khoảng cách lệch khỏi tuyến đường nhỏ nhất.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),

              if (corridorResults.isEmpty)
                EmptyStateView(
                  title: 'Chưa có nhà hàng trong bán kính này',
                  message:
                      'Hãy tăng bán kính hành lang (Corridor Radius) lên 2.0 km – 3.5 km để mở rộng phạm vi tìm kiếm dọc đường đi.',
                  onReset: () {
                    setState(() => _corridorRadiusKm = 2.5);
                  },
                )
              else
                ...corridorResults.map((item) {
                  final rest = item.restaurant;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFCCFBF1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Cách tuyến: ${item.distanceFromRouteKm} km (+${item.estimatedDetourMins} phút)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (rest.isSponsored)
                              SponsoredBadgeWidget(label: rest.sponsorLabel),
                            const Spacer(),
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${rest.rating}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          rest.name,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${rest.cuisineType} • ${rest.priceRange}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          rest.address,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: Color(0xFFD97706),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Giờ mở cửa: ${rest.openingHours} • Cập nhật: ${rest.lastUpdatedAt} (Kiểm tra giờ trước khi đi)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF92400E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => RestaurantDetailScreen(
                                      restaurant: rest,
                                      appState: widget.appState,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Xem chi tiết'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                widget.appState.addRestaurantToActiveItinerary(
                                  rest,
                                  notes:
                                      'Điểm dừng ăn uống dọc lộ trình (Cách tuyến ${item.distanceFromRouteKm} km)',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Đã thêm "${rest.name}" làm điểm dừng vào Lịch trình!',
                                    ),
                                    backgroundColor: AppTheme.primaryTeal,
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.add_location_alt_rounded,
                                size: 16,
                              ),
                              label: const Text('Chọn làm Điểm dừng'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              if (_alongRouteStops.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Điểm nghỉ chân dọc tuyến (${_alongRouteStops.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cây xăng, sạc EV và quán cà phê nằm trong hành lang tuyến đường.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                ..._alongRouteStops.map(
                  (stop) => _buildAlongRouteStopCard(context, stop),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlongRouteStopCard(BuildContext context, AlongRouteStop stop) {
    final color = switch (stop.kind) {
      'gas' => AppColors.kindGas,
      'ev' => AppColors.kindEv,
      'cafe' => AppColors.kindCafe,
      _ => AppColors.kindRest,
    };
    final icon = switch (stop.kind) {
      'gas' => Icons.local_gas_station_rounded,
      'ev' => Icons.ev_station_rounded,
      'cafe' => Icons.local_cafe_rounded,
      _ => Icons.chair_alt_rounded,
    };
    final label = switch (stop.kind) {
      'gas' => 'Cây xăng',
      'ev' => 'Sạc EV',
      'cafe' => 'Quán cà phê',
      _ => 'Điểm nghỉ',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: stop.thumbnailUrl.isNotEmpty
                ? Image.network(
                    stop.thumbnailUrl,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 46,
                      height: 46,
                      color: color.withValues(alpha: 0.14),
                      child: Icon(icon, color: color),
                    ),
                  )
                : Container(
                    width: 46,
                    height: 46,
                    color: color.withValues(alpha: 0.14),
                    child: Icon(icon, color: color),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$label • Cách tuyến ${stop.distanceFromRouteKm} km '
                  '(+${stop.estimatedDetourMins} phút)',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (stop.address.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    stop.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              widget.appState.addCustomStopToActiveItinerary(
                title: stop.name,
                address: stop.address,
                plannedTime: '15:00 - 15:20',
                stopType: stop.kind,
                notes: 'Điểm nghỉ chân dọc tuyến '
                    '(cách tuyến ${stop.distanceFromRouteKm} km).',
                latitude: stop.latitude,
                longitude: stop.longitude,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã thêm "${stop.name}" vào Lịch trình!'),
                  backgroundColor: AppTheme.primaryTeal,
                ),
              );
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}

class _CorridorMapPainter extends CustomPainter {
  final List<List<double>> polyline;
  final List<CorridorRestaurantResult> matchedRestaurants;
  final double corridorRadiusKm;

  _CorridorMapPainter({
    required this.polyline,
    required this.matchedRestaurants,
    required this.corridorRadiusKm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Vẽ lưới tọa độ nền bản đồ
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (polyline.length < 2) return;

    final startOffset = Offset(size.width * 0.16, size.height * 0.68);
    final midOffset1 = Offset(size.width * 0.42, size.height * 0.44);
    final midOffset2 = Offset(size.width * 0.66, size.height * 0.52);
    final endOffset = Offset(size.width * 0.85, size.height * 0.28);

    final routePath = Path()
      ..moveTo(startOffset.dx, startOffset.dy)
      ..lineTo(midOffset1.dx, midOffset1.dy)
      ..lineTo(midOffset2.dx, midOffset2.dy)
      ..lineTo(endOffset.dx, endOffset.dy);

    // Vẽ vùng đệm Hành lang (Corridor Buffer)
    final corridorWidth = (corridorRadiusKm * 18.0).clamp(18.0, 68.0);
    final bufferPaint = Paint()
      ..color = const Color(0xFF14B8A6).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = corridorWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(routePath, bufferPaint);

    // Vẽ đường Polyline lộ trình chính
    final linePaint = Paint()
      ..color = const Color(0xFF2DD4BF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(routePath, linePaint);

    // Vẽ các chấm nhà hàng dọc lộ trình
    final restPaint = Paint()..color = const Color(0xFFF59E0B);
    for (int i = 0; i < matchedRestaurants.length; i++) {
      final frac = (i + 1) / (matchedRestaurants.length + 1);
      final rx =
          startOffset.dx + (endOffset.dx - startOffset.dx) * frac;
      final ry = startOffset.dy +
          (endOffset.dy - startOffset.dy) * frac +
          (i.isEven ? -12.0 : 12.0);
      canvas.drawCircle(Offset(rx, ry), 6.5, restPaint);
    }

    // Chốt xuất phát (Xanh lá) & Điểm đến (Đỏ)
    canvas.drawCircle(
      startOffset,
      8.5,
      Paint()..color = const Color(0xFF10B981),
    );
    canvas.drawCircle(
      endOffset,
      8.5,
      Paint()..color = const Color(0xFFEF4444),
    );
  }

  @override
  bool shouldRepaint(covariant _CorridorMapPainter oldDelegate) {
    return oldDelegate.corridorRadiusKm != corridorRadiusKm ||
        oldDelegate.matchedRestaurants.length != matchedRestaurants.length;
  }
}
