import 'package:flutter/material.dart';
import '../../../core/utils/app_state.dart';
import '../../../core/utils/data_models.dart';
import '../../destinations/destination_detail_screen.dart';

/// Thẻ điểm đến thịnh hành lướt ngang (Popular Destination Card)
/// Thiết kế 100% chuẩn theo Dribbble Reference (Màn hình 1):
/// - Tỷ lệ dọc chuẩn (165 x 215px), bo tròn 22px
/// - Ảnh tràn viền nghệ thuật độ phân giải cao
/// - Huy hiệu đánh giá sao nổi góc trên phải (⭐ 4.9)
/// - Gradient đáy tối tinh tế, tiêu đề tên địa danh và tỉnh thành
class PopularDestinationCard extends StatelessWidget {
  final DestinationModel destination;
  final TripFlowAppState appState;
  final VoidCallback? onTap;

  const PopularDestinationCard({
    super.key,
    required this.destination,
    required this.appState,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final heroUrl = destination.images.isNotEmpty
        ? destination.images.first.imageUrl
        : destination.thumbnailUrl;

    return Container(
      width: 165,
      height: 215,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ??
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DestinationDetailScreen(
                        appState: appState,
                        destination: destination,
                      ),
                    ),
                  );
                },
            child: Stack(
              children: [
                // 1. Ảnh tràn viền
                Positioned.fill(
                  child: Image.network(
                    heroUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: const Color(0xFFE2E8F0),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFCBD5E1),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Color(0xFF64748B),
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Gradient lớp phủ bóng tối để tôn chữ và huy hiệu
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.45),
                          Colors.black.withValues(alpha: 0.90),
                        ],
                        stops: const [0.0, 0.35, 0.65, 1.0],
                      ),
                    ),
                  ),
                ),

                // 3. Floating Rating Pill (⭐ 4.9) góc trên phải
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          destination.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Danh mục / Category Tag góc trên trái
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      destination.categoryName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // 5. Thông tin tên địa danh và Tỉnh thành ở đáy
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        destination.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: Color(0xFF5EEAD4),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              destination.provinceName,
                              style: const TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
