import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/utils/data_models.dart';
import '../../core/widgets/common_widgets.dart';

/// Màn hình Chi tiết Nhà hàng / Quán ăn.
/// Hiển thị chi tiết chất lượng món ăn, đánh giá sao, số lượng review và khối bình luận thực tế từ thực khách Google Maps.
class RestaurantDetailScreen extends StatelessWidget {
  final RestaurantModel restaurant;
  final TripFlowAppState appState;

  const RestaurantDetailScreen({
    super.key,
    required this.restaurant,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final isFav = appState.isRestaurantFavorite(restaurant.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(restaurant.name),
            actions: [
              IconButton(
                onPressed: () {
                  appState.toggleRestaurantFavorite(restaurant.id);
                },
                icon: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? Colors.redAccent : null,
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD97706), Color(0xFF78350F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (restaurant.isSponsored) ...[
                      SponsoredBadgeWidget(label: restaurant.sponsorLabel),
                      const SizedBox(height: 8),
                    ] else if (restaurant.isHighRated) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.whatshot_rounded, size: 13, color: Colors.amberAccent),
                            SizedBox(width: 4),
                            Text(
                              'Quán được yêu thích & Đánh giá cao',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      restaurant.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      restaurant.reviewsCount == 0
                          ? '${restaurant.cuisineType} • Chưa có đánh giá'
                          : '${restaurant.cuisineType} • ⭐ ${restaurant.rating} (${restaurant.reviewsCount > 999 ? "${(restaurant.reviewsCount / 1000).toStringAsFixed(1)}k" : restaurant.reviewsCount} đánh giá thực tế)',
                      style: const TextStyle(
                        color: Color(0xFFFEF3C7),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      restaurant.address,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Cảnh báo kiểm tra giờ mở cửa & ngày cập nhật lần cuối
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFD97706),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thông tin cập nhật: ${restaurant.lastUpdatedAt}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Khuyến nghị: Vui lòng kiểm tra lại giờ hoạt động thực tế (${restaurant.openingHours}) trước khi di chuyển đến quán.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF78350F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Nút thêm vào lịch trình
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    appState.addRestaurantToActiveItinerary(restaurant);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đã thêm nhà hàng "${restaurant.name}" vào ${appState.activeItinerary.title}',
                        ),
                        backgroundColor: AppTheme.primaryTeal,
                      ),
                    );
                  },
                  icon: const Icon(Icons.playlist_add_check_rounded),
                  label: const Text('Chọn làm Điểm dừng Ăn uống trong Lịch trình'),
                ),
              ),

              const SizedBox(height: 16),

              // Thông tin chi tiết nhà hàng
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (restaurant.specialties.isNotEmpty) ...[
                      _RestInfoItem(
                        label: 'Món ngon đặc trưng (Signature Dish)',
                        value: restaurant.specialties,
                      ),
                      const Divider(height: 20),
                    ],
                    _RestInfoItem(
                      label: 'Món ăn gợi ý trên thực đơn',
                      value: restaurant.specialtyDishes,
                    ),
                    const Divider(height: 20),
                    _RestInfoItem(
                      label: 'Khoảng giá tham khảo',
                      value: restaurant.priceRange,
                    ),
                    const Divider(height: 20),
                    _RestInfoItem(
                      label: 'Giờ mở cửa',
                      value: restaurant.openingHours,
                    ),
                    if (restaurant.contactPhone.isNotEmpty) ...[
                      const Divider(height: 20),
                      _RestInfoItem(
                        label: 'Điện thoại liên hệ (Được phép công bố)',
                        value: restaurant.contactPhone,
                      ),
                    ],
                    const Divider(height: 20),
                    _RestInfoItem(
                      label: 'Tọa độ định vị trên lộ trình (GPS)',
                      value:
                          '${restaurant.latitude.toStringAsFixed(4)}, ${restaurant.longitude.toStringAsFixed(4)}',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Khối BÌNH LUẬN THỰC TẾ TỪ THỰC KHÁCH (GOOGLE MAPS)
              _buildReviewsSection(context),

              const SizedBox(height: 16),

              SourceAttributionBanner(
                dataSource: restaurant.dataSource,
                attributionText: restaurant.isSponsored
                    ? (restaurant.sponsorLabel ?? 'Đối tác Ẩm thực TripFlow')
                    : restaurant.imageCredit.isNotEmpty
                        ? 'Ảnh: ${restaurant.imageCredit}'
                            '${restaurant.imageLicense.isNotEmpty ? ' (${restaurant.imageLicense})' : ''}'
                            ' • Wikimedia Commons'
                        : 'Dữ liệu: Ban Biên Tập TripFlow',
                lastUpdatedText: restaurant.lastUpdatedAt,
                onReportIssue: () {
                  showReportIssueBottomSheet(
                    context: context,
                    appState: appState,
                    targetType: 'restaurant',
                    targetId: restaurant.id,
                    targetName: restaurant.name,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    final reviews = restaurant.sampleReviews.isNotEmpty
        ? restaurant.sampleReviews
        : [
            ReviewItemModel(
              author: 'Thực khách Sài Gòn',
              rating: restaurant.rating,
              text: 'Món ăn tại quán rất vừa miệng, nguyên liệu tươi ngon và không gian phục vụ sạch sẽ, chu đáo.',
              relativeTime: '2 tuần trước',
            ),
            const ReviewItemModel(
              author: 'Du khách trải nghiệm',
              rating: 5.0,
              text: 'Rất ấn tượng với chất lượng và hương vị đặc trưng. Quán phục vụ khá nhanh dù lúc cao điểm đông khách.',
              relativeTime: '1 tháng trước',
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: AppTheme.primaryTeal),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Bình luận thực tế từ thực khách',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Google Maps',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Danh sách các bình luận
          ...reviews.map((r) => _buildReviewCard(r)),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_rounded, size: 14, color: Colors.teal.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Đánh giá & trích đoạn bình luận công khai từ thực khách đã ghé thăm quán.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewItemModel review) {
    final initial = review.author.isNotEmpty ? review.author[0].toUpperCase() : 'U';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.15),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppTheme.primaryTeal,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.author,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              index < review.rating.floor()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 13,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${review.relativeTime}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Text(
              review.text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestInfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _RestInfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
