import 'package:flutter/material.dart';
import '../../../core/utils/app_state.dart';
import '../../../core/utils/data_models.dart';
import '../../../core/utils/smart_itinerary_engine.dart';
import '../../destinations/destination_detail_screen.dart';
import '../../maps/map_corridor_screen.dart';

/// Màn hình Chi tiết Điểm Dừng (Stop Detail Screen)
/// Thiết kế 100% chuẩn theo Dribbble Reference (Màn hình 3):
/// - Ảnh toàn màn hình độ phân giải cao của danh thắng
/// - Nút quay lại tròn trong suốt + Nhãn Ngày (Day 1 / Ngày 1)
/// - Tiêu đề điểm dừng lớn, phân loại (2nd Stop • Tham quan) & Đánh giá sao ⭐ 4.9 (127 đánh giá)
/// - Thẻ Card nổi bo góc tròn màu trắng ở chân màn hình:
///   + Khoảng cách (400 m từ vị trí của bạn)
///   + Địa chỉ chi tiết
///   + Nút dẫn đường tròn màu đỏ san hô #FF4B55
///   + Dải thumbnail ảnh thực tế với badge +25 ảnh
class StopDetailSheet extends StatelessWidget {
  final SmartItineraryStop stop;
  final int dayNumber;
  final TripFlowAppState appState;

  const StopDetailSheet({
    super.key,
    required this.stop,
    required this.dayNumber,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    // Trích xuất danh sách ảnh thực tế từ DestinationModel nếu có
    final DestinationModel? dest =
        stop.rawEntity is DestinationModel ? stop.rawEntity as DestinationModel : null;

    final List<String> galleryUrls = dest?.images.map((img) => img.imageUrl).toList() ?? [
      stop.imageUrl,
      'https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1080&q=80',
      'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=1080&q=80',
      'https://images.unsplash.com/photo-1569154941061-e231b4725ef1?auto=format&fit=crop&w=1080&q=80',
    ];

    // Khoảng cách định dạng chuẩn
    final distanceText = stop.distanceFromPrevStopKm > 0
        ? '${(stop.distanceFromPrevStopKm * 1000).toInt()} m từ điểm trước'
        : 'Điểm khởi hành';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Ảnh danh thắng nền toàn màn hình
          Positioned.fill(
            child: Image.network(
              stop.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  ),
                ),
              ),
            ),
          ),

          // 2. Lớp gradient phủ toàn cảnh để chữ nổi bật
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.40),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.25, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // 3. Top Navigation Bar (Nút Back tròn và nhãn "Ngày 1")
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Material(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: const CircleBorder(),
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
                Text(
                  'Ngày $dayNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 40), // Cân bằng với nút Back
              ],
            ),
          ),

          // 4. Thông tin Tiêu đề, Thứ tự điểm dừng & Đánh giá sao (Nằm phía trên thẻ nổi)
          Positioned(
            left: 20,
            right: 20,
            bottom: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4B55).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Điểm dừng thứ ${stop.stopOrder} • ${stop.stopTypeLabel}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  stop.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF59E0B),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${stop.rating.toStringAsFixed(1)} (127 đánh giá)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFF5EEAD4),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stop.timeSlot,
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 5. Thẻ Trắng Nổi ở đáy màn hình (Floating White Bottom Card - theo Ảnh 1 Màn 3)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hàng: Khoảng cách & Nút Dẫn Đường màu Đỏ San Hô tròn
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              distanceText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stop.address,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF64748B),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Nút Dẫn đường tròn màu san hô đỏ #FF4B55
                      Material(
                        color: const Color(0xFFFF4B55),
                        shape: const CircleBorder(),
                        elevation: 3,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    MapCorridorScreen(appState: appState),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(
                              Icons.near_me_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Dải Thumbnail ảnh thực tế với Badge +25 ảnh
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: galleryUrls.length > 5 ? 5 : galleryUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final isLast = idx == 4 && galleryUrls.length > 5;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Image.network(
                                galleryUrls[idx],
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 52,
                                  height: 52,
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                              if (isLast)
                                Container(
                                  width: 52,
                                  height: 52,
                                  color: Colors.black.withValues(alpha: 0.65),
                                  child: const Center(
                                    child: Text(
                                      '+25',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  if (dest != null) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
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
                              builder: (_) => DestinationDetailScreen(
                                appState: appState,
                                destination: dest,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Xem Thông Tin Chi Tiết & Giá Vé',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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
}
