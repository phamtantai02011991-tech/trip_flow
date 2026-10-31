import 'package:flutter/material.dart';
import '../../../core/utils/smart_itinerary_engine.dart';

/// Thẻ điểm dừng trên Dòng thời gian Lịch trình (Timeline Stop Card)
/// Thiết kế lấy cảm hứng trực tiếp từ Ảnh 1, 2 và 4:
/// - Nút số thứ tự điểm dừng dọc theo đường nối timeline
/// - Khối thông tin di chuyển giữa 2 điểm dừng (Khoảng cách km + Số phút lái xe/đi bộ)
/// - Ảnh chụp thực tế sắc nét kèm badge loại điểm dừng
/// - Khung giờ dự kiến, thời lượng và chi phí ước tính
class ItineraryTimelineCard extends StatelessWidget {
  final SmartItineraryStop stop;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  const ItineraryTimelineCard({
    super.key,
    required this.stop,
    this.isFirst = false,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    Color typeBgColor;
    IconData typeIcon;

    switch (stop.stopType) {
      case 'origin':
        typeColor = const Color(0xFF0D9488);
        typeBgColor = const Color(0xFFCCFBF1);
        typeIcon = Icons.trip_origin_rounded;
        break;
      case 'destination':
        typeColor = const Color(0xFFE11D48);
        typeBgColor = const Color(0xFFFFE4E6);
        typeIcon = Icons.flag_rounded;
        break;
      case 'restaurant':
        typeColor = const Color(0xFFD97706);
        typeBgColor = const Color(0xFFFEF3C7);
        typeIcon = Icons.restaurant_rounded;
        break;
      case 'rest_stop':
        typeColor = const Color(0xFF0284C7);
        typeBgColor = const Color(0xFFE0F2FE);
        typeIcon = Icons.local_cafe_rounded;
        break;
      default:
        typeColor = const Color(0xFF7C3AED);
        typeBgColor = const Color(0xFFEDE9FE);
        typeIcon = Icons.place_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Khối hiển thị thông tin di chuyển từ điểm dừng trước (nếu không phải điểm đầu tiên)
        if (!isFirst && stop.distanceFromPrevStopKm > 0)
          Padding(
            padding: const EdgeInsets.only(left: 17, top: 2, bottom: 6),
            child: Row(
              children: [
                // Đường đứt khúc thẳng đứng
                Container(
                  width: 2,
                  height: 28,
                  color: const Color(0xFFCBD5E1),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_car_rounded, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 5),
                      Text(
                        'Di chuyển ${stop.distanceFromPrevStopKm} km • ~${stop.transitMinutesFromPrevStop} phút',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Thẻ nội dung điểm dừng
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cột bên trái: Vòng tròn thứ tự và đường timeline
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: typeColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: typeColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: stop.isOrigin
                        ? const Icon(Icons.navigation_rounded, color: Colors.white, size: 18)
                        : stop.isDestination
                            ? const Icon(Icons.flag_rounded, color: Colors.white, size: 18)
                            : Text(
                                '${stop.stopOrder}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 18,
                    color: const Color(0xFFCBD5E1),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Cột bên phải: Thẻ Card điểm dừng
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hàng 1: Badge loại điểm dừng & Khung giờ
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: typeBgColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(typeIcon, size: 12, color: typeColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      stop.stopTypeLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: typeColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Text(
                                      stop.timeSlot,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Hàng 2: Ảnh thu nhỏ + Tiêu đề & Địa chỉ
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Image.network(
                                    stop.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFFE2E8F0),
                                      child: const Icon(Icons.photo_rounded, color: Color(0xFF94A3B8)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stop.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF94A3B8)),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            stop.address,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF64748B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${stop.rating}',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '⏱️ ${stop.durationMins} phút',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Hàng 3: Ghi chú & Giá vé / Chi phí ước tính
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    stop.notes,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF475569),
                                      height: 1.35,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    stop.ticketPriceInfo,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
