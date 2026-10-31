import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_state.dart';
import '../../../core/utils/smart_itinerary_engine.dart';
import '../../maps/map_corridor_screen.dart';
import '../widgets/itinerary_timeline_card.dart';

/// Màn hình Hiển thị Lịch Trình Xây Dựng Thông Minh (Smart Itinerary Result Screen)
/// Áp dụng trải nghiệm người dùng cao cấp từ Ảnh 1, 2, 4:
/// - Bản đồ tương tác trực quan với tuyến đường vẽ Polyline kết nối các điểm dừng
/// - Thẻ tổng quan lộ trình: Tổng quãng đường, tổng thời gian, tổng chi phí dự kiến, dự báo thời tiết
/// - Bộ chọn Ngày trượt ngang (Day 1, Day 2, Day 3)
/// - Dòng thời gian Timeline các điểm tham quan, nghỉ chân và quán ăn đặc sản
class SmartItineraryResultScreen extends StatefulWidget {
  final SmartItineraryPlan plan;
  final TripFlowAppState appState;

  const SmartItineraryResultScreen({
    super.key,
    required this.plan,
    required this.appState,
  });

  @override
  State<SmartItineraryResultScreen> createState() => _SmartItineraryResultScreenState();
}

class _SmartItineraryResultScreenState extends State<SmartItineraryResultScreen> {
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.plan.title),
        actions: [
          IconButton(
            tooltip: _isSaved ? 'Đã lưu lịch trình' : 'Lưu lịch trình',
            onPressed: _saveToPersonalItineraries,
            icon: Icon(
              _isSaved ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
              color: _isSaved ? const Color(0xFF0D9488) : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // 1. Bản đồ Lộ trình Tuyến đường (Visual Route Map Canvas - theo Ảnh 1 & 4)
                _buildRouteMapCanvas(currentDayPlan),
                const SizedBox(height: 16),

                // 2. Thẻ Tổng quan Chuyến đi & Chi phí dự kiến
                _buildTripOverviewCard(),
                const SizedBox(height: 14),

                // 3. Khối Dự báo thời tiết địa phương (theo Ảnh 3)
                _buildWeatherCard(),
                const SizedBox(height: 18),

                // 4. Bộ chọn ngày (Day Selector Tabs - theo Ảnh 1 & 2)
                _buildDaySelectorTabs(),
                const SizedBox(height: 16),

                // 5. Tiêu đề chủ đề ngày & Thống kê ngày
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        currentDayPlan.dayTheme,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${currentDayPlan.stops.length} điểm dừng',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 6. Dòng thời gian Timeline các điểm dừng trong ngày
                ...currentDayPlan.stops.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final stop = entry.value;
                  return ItineraryTimelineCard(
                    stop: stop,
                    isFirst: idx == 0,
                    isLast: idx == currentDayPlan.stops.length - 1,
                  );
                }),
              ],
            ),
          ),

          // Thanh điều hướng và hành động ở chân trang
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  /// Khung hiển thị Bản đồ tuyến đường di chuyển trực quan
  Widget _buildRouteMapCanvas(SmartItineraryDayPlan dayPlan) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Ảnh nền bản đồ phong cách nhạt
            Positioned.fill(
              child: Image.network(
                'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=1000&q=80',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE2E8F0)),
              ),
            ),

            // Lớp phủ tối nhẹ để làm nổi bật tuyến đường
            Positioned.fill(
              child: Container(
                color: const Color(0xFF0F172A).withValues(alpha: 0.35),
              ),
            ),

            // Vẽ sơ đồ kết nối các điểm dừng
            Positioned.fill(
              child: CustomPaint(
                painter: _RoutePolylinePainter(stopCount: dayPlan.stops.length),
              ),
            ),

            // Huy hiệu thông tin tuyến trên bản đồ
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.alt_route_rounded, size: 14, color: Color(0xFF5EEAD4)),
                    const SizedBox(width: 5),
                    Text(
                      'Tuyến đường Ngày $_selectedDay: ${dayPlan.dayDistanceKm} km',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Nút mở toàn màn hình bản đồ
            Positioned(
              bottom: 12,
              right: 12,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MapCorridorScreen(appState: widget.appState),
                    ),
                  );
                },
                icon: const Icon(Icons.map_rounded, size: 16, color: AppTheme.primaryTeal),
                label: const Text(
                  'Xem Bản Đồ Lộ Trình',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thẻ tổng quan lộ trình & Chi phí ước tính
  Widget _buildTripOverviewCard() {
    final plan = widget.plan;
    final totalHours = (plan.totalDurationMins / 60).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      plan.description,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Lưới 3 thông số chính: Quãng đường, Thời gian, Chi phí
          Row(
            children: [
              _buildStatTile(
                icon: Icons.route_rounded,
                iconColor: const Color(0xFF0D9488),
                label: 'Tổng quãng đường',
                value: '${plan.totalDistanceKm} km',
              ),
              _buildStatTile(
                icon: Icons.timer_outlined,
                iconColor: const Color(0xFF2563EB),
                label: 'Tổng thời gian',
                value: '~$totalHours giờ',
              ),
              _buildStatTile(
                icon: Icons.monetization_on_outlined,
                iconColor: const Color(0xFFD97706),
                label: 'Chi phí dự kiến',
                value: _formatVnd(plan.estimatedTotalCostVnd),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Chi tiết các khoản chi phí ước tính
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCostItem('Vé tham quan', _formatVnd(plan.estimatedTicketCostVnd)),
                const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                _buildCostItem('Ăn uống', _formatVnd(plan.estimatedFoodCostVnd)),
                const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                _buildCostItem('Xăng / Di chuyển', _formatVnd(plan.estimatedTransportCostVnd)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCostItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        const SizedBox(height: 1),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
      ],
    );
  }

  /// Khối dự báo thời tiết (theo Ảnh 3)
  Widget _buildWeatherCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny_rounded, color: Color(0xFFD97706), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.plan.weatherForecast,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bộ chọn Ngày (Day 1, Day 2, Day 3 - theo Ảnh 1 & 2)
  Widget _buildDaySelectorTabs() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.plan.dayPlans.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final dayPlan = widget.plan.dayPlans[index];
          final isSelected = dayPlan.dayNumber == _selectedDay;

          return InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => setState(() => _selectedDay = dayPlan.dayNumber),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryTeal : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryTeal : const Color(0xFFCBD5E1),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 13,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ngày ${dayPlan.dayNumber}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
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

  /// Thanh hành động dưới đáy
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: const BorderSide(color: AppTheme.primaryTeal, width: 1.5),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MapCorridorScreen(appState: widget.appState),
                    ),
                  );
                },
                icon: const Icon(Icons.explore_rounded, size: 18, color: AppTheme.primaryTeal),
                label: const Text(
                  'Bản Đồ Lộ Trình',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTheme.primaryTeal),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSaved ? const Color(0xFF047857) : AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _saveToPersonalItineraries,
                icon: Icon(
                  _isSaved ? Icons.check_circle_rounded : Icons.bookmark_add_rounded,
                  size: 18,
                ),
                label: Text(
                  _isSaved ? 'Đã Lưu Lịch Trình' : 'Lưu Lịch Trình',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatVnd(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} tr';
    }
    return '${(amount ~/ 1000)}k';
  }
}

/// Custom painter vẽ đường nối polyline giữa các điểm dừng trên bản đồ
class _RoutePolylinePainter extends CustomPainter {
  final int stopCount;

  _RoutePolylinePainter({required this.stopCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0D9488)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = const Color(0xFF0D9488)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final points = <Offset>[
      Offset(size.width * 0.15, size.height * 0.75),
      Offset(size.width * 0.35, size.height * 0.35),
      Offset(size.width * 0.55, size.height * 0.60),
      Offset(size.width * 0.72, size.height * 0.30),
      Offset(size.width * 0.88, size.height * 0.55),
    ];

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 6, dotPaint);
      canvas.drawCircle(points[i], 6, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
