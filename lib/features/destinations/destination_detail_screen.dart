import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/utils/data_models.dart';
import '../../core/utils/geo_utils.dart';
import '../../core/widgets/common_widgets.dart';
import '../restaurants/restaurant_detail_screen.dart';

/// Màn hình Chi tiết Địa điểm Du lịch (Mục 5.1.4).
/// Hiển thị:
/// - Mô tả chi tiết, giờ mở cửa, giá vé tham khảo, tọa độ GPS
/// - Bộ sưu tập ảnh kèm giấy phép bản quyền ảnh
/// - Nguồn dữ liệu & Thời điểm cập nhật lần cuối + Nút Báo sai thông tin
/// - Nút Thêm vào lịch trình & Lưu yêu thích
/// - Gợi ý địa điểm liên quan và nhà hàng gần đó.
class DestinationDetailScreen extends StatelessWidget {
  final DestinationModel destination;
  final TripFlowAppState appState;

  const DestinationDetailScreen({
    super.key,
    required this.destination,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final isFav = appState.isDestinationFavorite(destination.id);
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
            : 'owned (TripFlow Studio)';

        return Scaffold(
          appBar: AppBar(
            title: Text(destination.name),
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
            padding: const EdgeInsets.all(16),
            children: [
              // Banner Hình ảnh & Bản quyền
              Container(
                height: 210,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade600,
                            borderRadius: BorderRadius.circular(999),
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
                                '${destination.rating} (${destination.reviewCount} đánh giá)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (destination.isSponsored) ...[
                          SponsoredBadgeWidget(label: destination.sponsorLabel),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          destination.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: Color(0xFF99F6E4),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                destination.address,
                                style: const TextStyle(
                                  color: Color(0xFFCCFBF1),
                                  fontSize: 12.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Nút hành động chính: Thêm vào lịch trình & Lưu yêu thích
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        appState.addDestinationToActiveItinerary(destination);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã thêm "${destination.name}" vào ${appState.activeItinerary.title}',
                            ),
                            backgroundColor: AppTheme.primaryTeal,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                      label: const Text('Thêm vào Lịch trình'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      appState.toggleDestinationFavorite(destination.id);
                    },
                    icon: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? Colors.redAccent : AppTheme.primaryTeal,
                      size: 18,
                    ),
                    label: Text(isFav ? 'Đã lưu' : 'Yêu thích'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Thông tin Giờ mở cửa, Giá vé, Tọa độ GPS
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.access_time_rounded,
                      title: 'Giờ mở cửa tham khảo',
                      value: destination.openingHours,
                    ),
                    const Divider(height: 20),
                    _DetailRow(
                      icon: Icons.confirmation_number_outlined,
                      title: 'Giá vé tham khảo',
                      value: destination.ticketPriceInfo,
                    ),
                    const Divider(height: 20),
                    _DetailRow(
                      icon: Icons.timelapse_rounded,
                      title: 'Thời gian tham quan gợi ý',
                      value: 'Khoảng ${destination.recommendedDurationMins} phút',
                    ),
                    const Divider(height: 20),
                    _DetailRow(
                      icon: Icons.my_location_rounded,
                      title: 'Tọa độ Bản đồ (GPS)',
                      value:
                          '${destination.latitude.toStringAsFixed(4)}, ${destination.longitude.toStringAsFixed(4)} (${destination.provinceName})',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Mô tả chi tiết
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
                    const Text(
                      'Giới thiệu địa điểm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      destination.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF334155),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Nguồn dữ liệu & Bản quyền ảnh (Mục 11)
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

              // Gợi ý Nhà hàng gần địa điểm
              if (nearbyRestaurants.isNotEmpty) ...[
                const Text(
                  'Nhà hàng & Quán ăn gần địa điểm này',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                ...nearbyRestaurants.map((rest) {
                  final distKm = GeoUtils.haversineDistanceKm(
                    destination.latitude,
                    destination.longitude,
                    rest.latitude,
                    rest.longitude,
                  );
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
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
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFFEF3C7),
                        child: const Icon(
                          Icons.restaurant_rounded,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      title: Text(
                        rest.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Cách ${distKm.toStringAsFixed(2)} km • ${rest.cuisineType} • ${rest.priceRange}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],

              // Địa điểm liên quan cùng tỉnh
              if (relatedDestinations.isNotEmpty) ...[
                const Text(
                  'Địa điểm liên quan tại cùng Tỉnh / Thành',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                ...relatedDestinations.map(
                  (rel) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
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
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFCCFBF1),
                        child: const Icon(
                          Icons.place_rounded,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                      title: Text(
                        rel.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${rel.categoryName} • ⭐ ${rel.rating}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryTeal),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
