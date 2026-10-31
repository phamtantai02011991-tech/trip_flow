import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_state.dart';
import '../../../core/utils/smart_itinerary_engine.dart';
import '../../maps/map_corridor_screen.dart';
import '../screens/stop_detail_sheet.dart';
import '../screens/trip_planner_wizard_screen.dart';

/// Màn hình Hiển thị Lịch Trình Xây Dựng Thông Minh (Itinerary Overview)
/// Thiết kế 100% chuẩn theo Dribbble Reference (Màn hình 2):
/// - Nửa trên (52%): Bản đồ toàn cảnh tương tác với tuyến polyline màu đỏ san hô #FF4B55
///   kết hợp Marker ảnh tròn (Circular Photo Pins) hiển thị ảnh thật của từng điểm dừng
/// - Nửa dưới (48%): Bottom Sheet trắng bo góc 32px gồm:
///   + Hàng ngày đến / ngày về (Arrival / Depart) & Nút [Thay đổi]
///   + Bộ chọn Ngày (Day 1, Day 2, Day 3) dạng pill san hô
///   + Danh sách các thẻ điểm dừng lướt ngang được nối bằng ĐƯỜNG ĐỨT KHÚC ĐỎ `----`
///   + Chạm vào bất kỳ điểm dừng nào sẽ mở StopDetailSheet (Màn hình 3 chuẩn Dribbble)
class SmartItineraryResultScreen extends StatefulWidget {
  final SmartItineraryPlan plan;
  final TripFlowAppState appState;

  const SmartItineraryResultScreen({
    super.key,
    required this.plan,
    required this.appState,
  });

  @override
  State<SmartItineraryResultScreen> createState() =>
      _SmartItineraryResultScreenState();
}

class _SmartItineraryResultScreenState
    extends State<SmartItineraryResultScreen> {
  int _selectedDay = 1;
  bool _isSaved = false;

  void _saveToPersonalItineraries() {
    final itineraryModel = widget.plan.toItineraryModel();
    widget.appState.saveNewItinerary(itineraryModel);
    setState(() => _isSaved = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã lưu thành công "${widget.plan.title}" vào Lịch trình cá nhân (Xem được cả khi Offline)!',
        ),
        backgroundColor: AppTheme.primaryTeal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentDayPlan = widget.plan.dayPlans.firstWhere(
      (d) => d.dayNumber == _selectedDay,
      orElse: () => widget.plan.dayPlans.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // ==========================================
          // 1. NỬA TRÊN: BẢN ĐỒ VÀ CÁC MARKER ẢNH TRÒN
          // ==========================================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: _buildInteractiveMap(currentDayPlan),
          ),

          // Header Overlay nổi trên bản đồ (Nút Back, Tiêu đề, Lưu)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF0F172A),
                        size: 20,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Tổng Quan Lộ Trình',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '${widget.plan.title} • ${widget.plan.totalDays}N${widget.plan.totalDays - 1 > 0 ? widget.plan.totalDays - 1 : 1}Đ',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _saveToPersonalItineraries,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        _isSaved
                            ? Icons.bookmark_added_rounded
                            : Icons.bookmark_border_rounded,
                        color: _isSaved
                            ? const Color(0xFFFF4B55)
                            : const Color(0xFF0F172A),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // 2. NỬA DƯỚI: BOTTOM SHEET TRẮNG BO GÓC 32PX
          // ==========================================
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height * 0.49,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Drag handle nhỏ
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header: Khởi hành, Kết thúc, Nút Thay đổi
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Khởi hành',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(widget.plan.startDate),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kết thúc',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(widget.plan.endDate),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        // Nút [Thay đổi] bo viền đỏ san hô
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFFF4B55),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TripPlannerWizardScreen(
                                  appState: widget.appState,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Thay đổi',
                            style: TextStyle(
                              color: Color(0xFFFF4B55),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Bộ chọn Ngày (Day Selector Pills)
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.plan.dayPlans.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final dayPlan = widget.plan.dayPlans[index];
                        final isSelected = dayPlan.dayNumber == _selectedDay;
                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            setState(() => _selectedDay = dayPlan.dayNumber);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFF4B55)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                'Ngày ${dayPlan.dayNumber}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Danh sách thẻ điểm dừng trượt ngang nối bằng ĐƯỜNG ĐỨT KHÚC ĐỎ `----`
                  Expanded(
                    child: _buildHorizontalStopsList(currentDayPlan),
                  ),

                  const SizedBox(height: 8),

                  // Nút Điều hướng toàn màn hình / Chân trang
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  MapCorridorScreen(appState: widget.appState),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.navigation_rounded,
                          size: 18,
                          color: Color(0xFF5EEAD4),
                        ),
                        label: Text(
                          'Mở Dẫn Đường Toàn Bộ Ngày $_selectedDay (${currentDayPlan.stops.length} điểm)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Khung hiển thị Bản đồ với Tuyến polyline màu San Hô & Marker Ảnh Tròn
  Widget _buildInteractiveMap(SmartItineraryDayPlan dayPlan) {
    // Tọa độ tương đối trên màn hình cho các điểm dừng (để vẽ Marker ảnh tròn)
    final stops = dayPlan.stops;
    final pinOffsets = [
      const Offset(0.25, 0.32),
      const Offset(0.70, 0.40),
      const Offset(0.42, 0.58),
      const Offset(0.80, 0.72),
      const Offset(0.30, 0.80),
    ];

    return Stack(
      children: [
        // Ảnh nền bản đồ kiến trúc sạch, phong cách Apple Maps
        Positioned.fill(
          child: Image.network(
            'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=1200&q=80',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: const Color(0xFFE2E8F0)),
          ),
        ),

        // Lớp phủ màu sáng nhẹ tạo hiệu ứng bản đồ vector tối giản
        Positioned.fill(
          child: Container(
            color: Colors.white.withValues(alpha: 0.35),
          ),
        ),

        // Tuyến đường màu Đỏ San Hô #FF4B55 nối các điểm dừng
        Positioned.fill(
          child: CustomPaint(
            painter: _DribbbleRoutePainter(stopCount: stops.length),
          ),
        ),

        // Các Marker Ảnh Tròn (Circular Photo Pins) trên bản đồ
        ...stops.asMap().entries.map((entry) {
          final idx = entry.key;
          final stop = entry.value;
          final offsetRatio = pinOffsets[idx % pinOffsets.length];

          return LayoutBuilder(
            builder: (context, constraints) {
              final x = constraints.maxWidth * offsetRatio.dx - 22;
              final y = constraints.maxHeight * offsetRatio.dy - 22;

              return Positioned(
                left: x,
                top: y,
                child: GestureDetector(
                  onTap: () => _openStopDetail(stop),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        stop.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFFF4B55),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  /// Danh sách điểm dừng lướt ngang nối bằng ĐƯỜNG ĐỨT KHÚC ĐỎ
  Widget _buildHorizontalStopsList(SmartItineraryDayPlan dayPlan) {
    final stops = dayPlan.stops;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      itemCount: stops.length,
      itemBuilder: (context, index) {
        final stop = stops[index];
        final isLast = index == stops.length - 1;

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thẻ Điểm Dừng
            GestureDetector(
              onTap: () => _openStopDetail(stop),
              child: Container(
                width: 145,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ảnh đại diện điểm dừng
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 145,
                        height: 96,
                        child: Image.network(
                          stop.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFCBD5E1),
                            child: const Icon(Icons.image_outlined),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Thời gian hoạt động: 07.00 - 10.00
                    Text(
                      stop.timeSlot,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Tên điểm dừng
                    Text(
                      stop.title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // ĐƯỜNG ĐỨT KHÚC ĐỎ `----` KẾT NỐI GIỮA CÁC THẺ
            if (!isLast) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 32,
                child: CustomPaint(
                  painter: _DottedLinePainter(),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
        );
      },
    );
  }

  void _openStopDetail(SmartItineraryStop stop) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StopDetailSheet(
          stop: stop,
          dayNumber: _selectedDay,
          appState: widget.appState,
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final weekdays = [
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ nhật'
    ];
    final dayOfWeek = weekdays[date.weekday - 1];
    return '$dayOfWeek, ${date.day} thg ${date.month}';
  }
}

/// CustomPainter vẽ đường polyline màu Đỏ San Hô #FF4B55 theo góc cạnh Dribbble
class _DribbbleRoutePainter extends CustomPainter {
  final int stopCount;

  _DribbbleRoutePainter({required this.stopCount});

  @override
  void paint(Canvas canvas, Size size) {
    final routePaint = Paint()
      ..color = const Color(0xFFFF4B55)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final p1 = Offset(size.width * 0.25, size.height * 0.32);
    final p2 = Offset(size.width * 0.70, size.height * 0.40);
    final p3 = Offset(size.width * 0.42, size.height * 0.58);
    final p4 = Offset(size.width * 0.80, size.height * 0.72);

    final path = Path();
    path.moveTo(p1.dx, p1.dy);
    // Vẽ đường đi theo phong cách zic-zac đường phố
    path.lineTo(size.width * 0.45, size.height * 0.32);
    path.lineTo(size.width * 0.45, size.height * 0.40);
    path.lineTo(p2.dx, p2.dy);

    path.lineTo(size.width * 0.60, size.height * 0.48);
    path.lineTo(p3.dx, p3.dy);

    path.lineTo(size.width * 0.65, size.height * 0.65);
    path.lineTo(p4.dx, p4.dy);

    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// CustomPainter vẽ đường đứt khúc đỏ nối giữa các card điểm dừng
class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF4B55)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;
    final y = size.height * 0.4;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset((startX + dashWidth).clamp(0, size.width), y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
