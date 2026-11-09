import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/utils/data_models.dart';
import '../../core/utils/geo_utils.dart';
import '../../core/widgets/common_widgets.dart';
import '../maps/map_corridor_screen.dart';
import '../restaurants/restaurant_detail_screen.dart';

/// Màn hình Chi tiết Địa điểm Du lịch (Visual-Rich Highlighted Detail Screen - Mục 5.1.4).
/// - Bộ sưu tập hình ảnh thực tế chất lượng cao (Photo Carousel với phân trang và chỉ số ảnh).
/// - 4 Khối thông số nổi bật trực quan (Giờ mở cửa, Giá vé, Thời lượng gợi ý, Tọa độ GPS).
/// - Nút Thêm vào Lịch trình 1-chạm, Lưu Yêu thích và Điều hướng Bản đồ.
/// - Gợi ý Quán ăn ngon tiêu biểu gần địa điểm và Danh lam liên quan.
class DestinationDetailScreen extends StatefulWidget {
  final DestinationModel destination;
  final TripFlowAppState appState;

  const DestinationDetailScreen({
    super.key,
    required this.destination,
    required this.appState,
  });

  @override
  State<DestinationDetailScreen> createState() => _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  late PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destination = widget.destination;
    final appState = widget.appState;

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final isFav = appState.isDestinationFavorite(destination.id);
        final galleryImages = destination.images.isNotEmpty
            ? destination.images
            : [
                DestinationImageModel(
                  id: 1,
                  destinationId: destination.id,
                  imageUrl: destination.primaryImageUrl,
                  caption: destination.name,
                  licenseType: 'owned',
                  creditAuthor: 'TripFlow Studio',
                ),
              ];

        final relatedDestinations = appState.destinationsForSelectedProvince
            .where((d) => d.id != destination.id)
            .take(3)
            .toList();

        final nearbyRestaurants = appState.restaurantsForSelectedProvince
            .where(
              (r) =>
                  GeoUtils.haversineDistanceKm(
                    destination.latitude,
                    destination.longitude,
                    r.latitude,
                    r.longitude,
                  ) <=
                  3.5,
            )
            .take(4)
            .toList();

        final firstLicense = destination.images.isNotEmpty
            ? '${destination.images.first.licenseType} (${destination.images.first.creditAuthor})'
            : 'owned (TripFlow Editorial)';

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text(
              destination.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            actions: [
              IconButton(
                tooltip: isFav ? 'Bỏ yêu thích' : 'Lưu yêu thích',
                onPressed: () {
                  appState.toggleDestinationFavorite(destination.id);
                },
                icon: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? Colors.redAccent : null,
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              // 1. Photo Gallery Carousel sắc nét với chỉ số ảnh và caption bản quyền
              Container(
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: galleryImages.length,
                        onPageChanged: (idx) {
                          setState(() => _currentImageIndex = idx);
                        },
                        itemBuilder: (context, index) {
                          final img = galleryImages[index];
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                img.imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    color: const Color(0xFFE2E8F0),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: AppTheme.primaryTeal,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF0F766E), Color(0xFF1E293B)],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported_rounded,
                                      color: Colors.white60,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                              // Lớp gradient nhẹ phủ lên ảnh để chữ nổi bật
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.35),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.75),
                                    ],
                                    stops: const [0.0, 0.4, 1.0],
                                  ),
                                ),
                              ),
                              // Caption ảnh ở góc dưới
                              Positioned(
                                bottom: 12,
                                left: 14,
                                right: 65,
                                child: Text(
                                  img.caption.isNotEmpty ? img.caption : destination.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      // Floating Category Tag & Rating Badge ở góc trên
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            destination.categoryName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade600,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
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
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                destination.reviewCount == 0
                                    ? 'Chưa có đánh giá'
                                    : '${destination.rating} (${destination.reviewCount} đánh giá)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Chỉ số ảnh (Ví dụ: 1/2) ở góc dưới phải
                      if (galleryImages.length > 1)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.photo_library_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_currentImageIndex + 1}/${galleryImages.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. Khối Tiêu Đề và Địa Chỉ
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (destination.isSponsored) ...[
                      SponsoredBadgeWidget(label: destination.sponsorLabel),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      destination.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: AppTheme.primaryTeal,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            destination.address,
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 3. Khối 4 Thẻ Thông Số Nổi Bật (Highlighted Metrics Grid)
              Row(
                children: [
                  Expanded(
                    child: _HighlightTile(
                      icon: Icons.access_time_rounded,
                      iconColor: const Color(0xFF0D9488),
                      bgColor: const Color(0xFFF0FDFA),
                      title: 'Giờ mở cửa',
                      value: destination.openingHours,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HighlightTile(
                      icon: Icons.confirmation_number_outlined,
                      iconColor: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFFFBEB),
                      title: 'Giá vé tham quan',
                      value: destination.ticketPriceInfo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _HighlightTile(
                      icon: Icons.timelapse_rounded,
                      iconColor: const Color(0xFF0284C7),
                      bgColor: const Color(0xFFF0F9FF),
                      title: 'Thời gian gợi ý',
                      value: 'Khoảng ${destination.recommendedDurationMins} phút',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HighlightTile(
                      icon: Icons.explore_rounded,
                      iconColor: const Color(0xFF059669),
                      bgColor: const Color(0xFFECFDF5),
                      title: 'Tọa độ GPS',
                      value:
                          '${destination.latitude.toStringAsFixed(3)}, ${destination.longitude.toStringAsFixed(3)}',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 4. Hàng Nút Hành Động Trọng Tâm (Thêm Lịch Trình, Yêu Thích, Mở Bản Đồ)
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                      onPressed: () {
                        appState.addDestinationToActiveItinerary(destination);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã thêm "${destination.name}" vào ${appState.activeItinerary.title}!',
                            ),
                            backgroundColor: AppTheme.primaryTeal,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_location_alt_rounded, size: 19),
                      label: const Text(
                        'Thêm vào Lịch trình',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryTeal,
                        side: const BorderSide(color: AppTheme.primaryTeal, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MapCorridorScreen(appState: appState),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map_rounded, size: 18),
                      label: const Text(
                        'Bản đồ',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 5. Thẻ Giới Thiệu Địa Điểm Chi Tiết
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCCFBF1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            size: 16,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Giới thiệu & Lịch sử hình thành',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      destination.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF334155),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 6. Nguồn Dữ Liệu & Bản Quyền Ảnh (Mục 11)
              SourceAttributionBanner(
                dataSource: destination.dataSource,
                attributionText: destination.sourceAttribution,
                lastUpdatedText: destination.updatedAt,
                licenseText: firstLicense,
                onReportIssue: () {
                  showReportIssueBottomSheet(
                    context: context,
                    appState: appState,
                    targetType: 'destination',
                    targetId: destination.id,
                    targetName: destination.name,
                  );
                },
              ),

              const SizedBox(height: 20),

              // 7. Gợi ý Quán Ăn Đánh Giá Cao Gần Địa Điểm
              if (nearbyRestaurants.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Quán ăn ngon gần địa điểm này',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Bán kính 3.5 km',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...nearbyRestaurants.map((rest) {
                  final distKm = GeoUtils.haversineDistanceKm(
                    destination.latitude,
                    destination.longitude,
                    rest.latitude,
                    rest.longitude,
                  );
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RestaurantDetailScreen(
                              restaurant: rest,
                              appState: appState,
                            ),
                          ),
                        );
                      },
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: Image.network(
                            rest.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFFEF3C7),
                              child: const Icon(
                                Icons.restaurant_rounded,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        rest.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                rest.reviewsCount == 0
                                    ? 'Chưa có đánh giá'
                                    : '${rest.rating} (${rest.reviewsCount}+ đánh giá)',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '• Cách ${distKm.toStringAsFixed(1)} km',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rest.specialties.isNotEmpty
                                ? rest.specialties
                                : rest.specialtyDishes,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],

              // 8. Địa Điểm Liên Quan Cùng Tỉnh / Thành
              if (relatedDestinations.isNotEmpty) ...[
                const Text(
                  'Địa điểm du lịch cùng Tỉnh / Thành',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                ...relatedDestinations.map(
                  (rel) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => DestinationDetailScreen(
                              destination: rel,
                              appState: appState,
                            ),
                          ),
                        );
                      },
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: Image.network(
                            rel.primaryImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFCCFBF1),
                              child: const Icon(
                                Icons.place_rounded,
                                color: AppTheme.primaryTeal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        rel.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            rel.categoryName,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${rel.rating}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Khối thẻ thông số nổi bật (Highlighted Info Tile)
class _HighlightTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String value;

  const _HighlightTile({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
