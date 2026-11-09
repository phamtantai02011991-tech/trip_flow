import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config/app_config.dart';
import '../../ui/tokens/app_tokens.dart';

/// Một điểm dừng hiển thị trên bản đồ.
class MapStopMarker {
  const MapStopMarker({
    required this.point,
    required this.label,
    this.imageUrl,
    this.index,
    this.kindColor,
  });

  final LatLng point;
  final String label;
  final String? imageUrl;
  final int? index;
  final Color? kindColor;
}

/// Bản đồ thật (flutter_map) — thay cho `CustomPainter` giả trước đây.
///
/// - Nền: tile Goong (`AppConfig.goongMapTileUrlTemplate`), phủ hợp đường phố Việt Nam.
/// - Marker: ảnh tròn hoặc chấm số thứ tự, có viền trắng + bóng (ảnh 2, 3).
/// - Tuyến: polyline dày 4px, viền trắng 7px phía dưới để nổi trên nền bản đồ.
class TripFlowMap extends StatefulWidget {
  const TripFlowMap({
    super.key,
    required this.initialCenter,
    this.initialZoom = 13,
    this.stops = const [],
    this.route = const [],
    this.onStopTap,
    this.dark = false,
    this.controller,
    this.interactive = true,
  });

  final LatLng initialCenter;
  final double initialZoom;
  final List<MapStopMarker> stops;
  final List<LatLng> route;
  final void Function(int index)? onStopTap;
  final bool dark;
  final MapController? controller;
  final bool interactive;

  @override
  State<TripFlowMap> createState() => _TripFlowMapState();
}

class _TripFlowMapState extends State<TripFlowMap> {
  MapController? _fallbackController;

  MapController get _controller => widget.controller ?? (_fallbackController ??= MapController());

  @override
  void didUpdateWidget(covariant TripFlowMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route.length != widget.route.length && widget.route.length > 1) {
      _fitRoute();
    }
  }

  void _fitRoute() {
    final points = widget.route;
    if (points.length < 2) return;
    try {
      _controller.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(48),
        ),
      );
    } catch (_) {
      // Bản đồ chưa sẵn sàng (chưa build xong) — lần build sau sẽ fit lại.
    }
  }

  @override
  Widget build(BuildContext context) {
    final map = FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: widget.initialCenter,
        initialZoom: widget.initialZoom,
        interactionOptions: InteractionOptions(
          flags: widget.interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
        backgroundColor: widget.dark ? AppColors.mapDarkBg : AppColors.surfaceAlt,
      ),
      children: [
        TileLayer(
          urlTemplate: AppConfig.mapTileUrlTemplateFor(dark: widget.dark),
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'vn.tripflow.app',
          maxNativeZoom: 19,
          tileProvider: NetworkTileProvider(),
        ),
        if (widget.route.length > 1)
          PolylineLayer(
            polylines: [
              // Viền trắng dưới tuyến giúp tuyến nổi bật trên mọi nền bản đồ
              Polyline(
                points: widget.route,
                color: Colors.white,
                strokeWidth: 7,
                borderStrokeWidth: 0,
              ),
              Polyline(
                points: widget.route,
                color: AppColors.coral,
                strokeWidth: 4,
                borderStrokeWidth: 0,
              ),
            ],
          ),
        MarkerLayer(markers: _buildMarkers()),
        if (widget.stops.isNotEmpty)
          RichAttributionWidget(
            alignment: AttributionAlignment.bottomLeft,
            attributions: [
              TextSourceAttribution('Goong Maps'),
              TextSourceAttribution('OpenStreetMap contributors'),
            ],
          ),
      ],
    );

    if (!widget.dark) return map;

    // Chế độ tối: đảo sáng + giảm bão hoà cho tile sáng (ảnh 4).
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        -0.9, 0, 0, 0, 255, //
        0, -0.9, 0, 0, 255, //
        0, 0, -0.9, 0, 255, //
        0, 0, 0, 1, 0,
      ]),
      child: map,
    );
  }

  List<Marker> _buildMarkers() {
    return [
      for (var i = 0; i < widget.stops.length; i++)
        Marker(
          point: widget.stops[i].point,
          width: 62,
          height: 72,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: widget.onStopTap == null ? null : () => widget.onStopTap!(i),
            child: _PhotoPin(
              label: widget.stops[i].label,
              imageUrl: widget.stops[i].imageUrl,
              index: widget.stops[i].index ?? i + 1,
              color: widget.stops[i].kindColor ?? AppColors.coral,
            ),
          ),
        ),
    ];
  }
}

class _PhotoPin extends StatelessWidget {
  const _PhotoPin({
    required this.label,
    required this.index,
    required this.color,
    this.imageUrl,
  });

  final String label;
  final int index;
  final Color color;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: AppShadow.marker,
          ),
          clipBehavior: Clip.antiAlias,
          child: (imageUrl != null && imageUrl!.isNotEmpty)
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(),
                )
              : _fallback(),
        ),
        // Đuôi nhọn chỉ xuống điểm thật trên bản đồ
        CustomPaint(size: const Size(12, 8), painter: _PinTailPainter(color)),
        Semantics(label: label, child: const SizedBox.shrink()),
      ],
    );
  }

  Widget _fallback() => Center(
        child: Text(
          '$index',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      );
}

class _PinTailPainter extends CustomPainter {
  const _PinTailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // `Path` phải chỉ rõ `ui.Path`: flutter_map cũng export một lớp tên `Path`.
    final paint = Paint()..color = Colors.white;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);

    final inner = Paint()..color = color;
    final innerPath = ui.Path()
      ..moveTo(2, 0)
      ..lineTo(size.width - 2, 0)
      ..lineTo(size.width / 2, size.height - 2)
      ..close();
    canvas.drawPath(innerPath, inner);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter oldDelegate) => oldDelegate.color != color;
}
