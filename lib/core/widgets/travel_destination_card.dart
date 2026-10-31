import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/app_state.dart';
import '../utils/data_models.dart';
import 'common_widgets.dart';

/// Thẻ Địa điểm Du lịch Trực quan (Visual-First Travel Destination Card):
/// - Ảnh bìa sắc nét kích thước lớn (175px) với hiệu ứng bo tròn 18px và bóng mờ hiện đại.
/// - Huy hiệu Danh mục, Đánh giá Sao (⭐ Rating) và Nút Lưu Yêu Thích 1-chạm đặt trực tiếp trên ảnh.
/// - Nhãn thời lượng tham quan (⏱️) và Thông tin giá vé (🎟️) hiển thị rõ ràng.
/// - Thiết kế Responsive 100% không bao giờ gặp lỗi tràn màn hình (RenderFlex Overflow).
class TravelDestinationCard extends StatelessWidget {
  final DestinationModel destination;
  final TripFlowAppState appState;
  final VoidCallback? onTap;

  const TravelDestinationCard({
    super.key,
    required this.destination,
    required this.appState,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFav = appState.isDestinationFavorite(destination.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Khối Ảnh Bìa Danh Thắng với các Floating Badges
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  children: [
                    // Hình ảnh chính (Image.network với fallback an toàn)
                    SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Image.network(
                        destination.primaryImageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppTheme.primaryTeal,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF0F766E), Color(0xFF1E293B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.photo_camera_back_rounded,
                                    size: 38,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    destination.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Lớp chuyển màu mờ nhẹ ở đáy ảnh để làm nổi bật thông tin
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.25),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.65),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Badge góc trên bên trái: Danh mục địa điểm
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          destination.categoryName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    // Badge góc trên bên phải: Rating & Nút Lưu Yêu Thích 1-chạm
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 15,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  destination.rating.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Material(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                appState.toggleDestinationFavorite(destination.id);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  isFav
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 18,
                                  color: isFav ? Colors.redAccent : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Nhãn thông số ở đáy ảnh: Thời lượng & Giá vé
                    Positioned(
                      bottom: 10,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 12,
                                  color: Color(0xFF5EEAD4),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${destination.recommendedDurationMins} phút',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.confirmation_number_outlined,
                                  size: 12,
                                  color: Color(0xFFFDE047),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  destination.ticketPriceInfo,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (destination.isSponsored) ...[
                            const SizedBox(width: 6),
                            SponsoredBadgeWidget(label: destination.sponsorLabel),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Nội dung Chi Tiết Thẻ
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên địa danh du lịch
                    Text(
                      destination.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),

                    // Địa chỉ có icon ghim
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: AppTheme.primaryTeal,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            destination.address,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Mô tả súc tích
                    Text(
                      destination.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. Chân thẻ Responsive: Nguồn xác thực & Nút thêm vào lịch trình (KHÔNG BAO GIỜ BỊ OVERFLOW)
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_user_rounded,
                                size: 13,
                                color: Color(0xFF0D9488),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  destination.dataSource == 'partner'
                                      ? 'Đối tác xác thực'
                                      : 'Nội bộ TripFlow xác thực',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            appState.addDestinationToActiveItinerary(destination);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Đã thêm "${destination.name}" vào lịch trình!',
                                ),
                                backgroundColor: AppTheme.primaryTeal,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.add_rounded,
                            size: 16,
                          ),
                          label: const Text(
                            'Lịch trình',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
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
    );
  }
}

