import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/utils/mock_data.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/travel_destination_card.dart';
import '../destinations/destination_detail_screen.dart';
import '../destinations/destinations_screen.dart';
import '../favorites/favorites_screen.dart';
import '../provinces/provinces_screen.dart';
import '../restaurants/restaurant_detail_screen.dart';

/// Tab 1: Màn hình Trang chủ Khám phá (HomeScreen - Mục 5.1.1 & Mục 5.2).
/// Gồm:
/// - Chọn tỉnh/thành phố (Mặc định: TP. Hồ Chí Minh) + Nút mở Danh sách Yêu thích
/// - Tìm kiếm nhanh địa điểm
/// - Thanh danh mục địa điểm
/// - Danh sách Địa điểm nổi bật
/// - Thẻ điều hướng nhanh tới Tìm nhà hàng dọc lộ trình (Corridor Search)
/// - Gợi ý Đặc sản & Nhà hàng địa phương
/// - Gợi ý Lịch trình mẫu (Áp dụng 1 chạm).
class HomeScreen extends StatelessWidget {
  final TripFlowAppState appState;

  const HomeScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final currentProv = appState.selectedProvince;
        final featured = appState.featuredDestinations.isNotEmpty
            ? appState.featuredDestinations
            : appState.destinationsForSelectedProvince;
        final foods = appState.localFoodsForSelectedProvince.take(3).toList();
        final templates = appState.sampleItinerariesForSelectedProvince;

        return Scaffold(
          appBar: AppBar(
            title: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProvincesScreen(appState: appState),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppTheme.primaryTeal,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        currentProv.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Tìm kiếm địa điểm',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DestinationsScreen(appState: appState),
                    ),
                  );
                },
                icon: const Icon(Icons.search_rounded),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'Danh sách yêu thích',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FavoritesScreen(appState: appState),
                        ),
                      );
                    },
                    icon: const Icon(Icons.favorite_border_rounded),
                  ),
                  if (appState.totalFavoritesCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${appState.totalFavoritesCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Cảnh báo Offline / Quyền vị trí nếu đang bật giả lập (TC-09)
              if (appState.isOfflineSimulated)
                OfflineModeBanner(
                  onRetryOnline: () {
                    appState.toggleOfflineSimulation(false);
                    appState.syncFromBackend();
                  },
                ),
              if (appState.locationPermission == LocationPermissionState.denied)
                LocationPermissionNotice(
                  onGrantPermission: () {
                    appState.setLocationPermission(
                      LocationPermissionState.granted,
                    );
                  },
                ),

              // Thanh tìm kiếm nhanh
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DestinationsScreen(appState: appState),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tìm địa điểm, món ăn, nhà hàng tại ${currentProv.name}...',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Danh mục nhanh
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: MockDataRepository.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = MockDataRepository.categories[index];
                    return ActionChip(
                      label: Text(cat['name']!),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DestinationsScreen(
                              appState: appState,
                              initialCategory: cat['code']!,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Khu vực 1: Địa điểm nổi bật
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Địa điểm nổi bật • ${currentProv.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DestinationsScreen(appState: appState),
                        ),
                      );
                    },
                    child: const Text('Xem tất cả'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...featured.take(4).map((dest) {
                return TravelDestinationCard(
                  destination: dest,
                  appState: appState,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DestinationDetailScreen(
                          destination: dest,
                          appState: appState,
                        ),
                      ),
                    );
                  },
                );
              }),

              const SizedBox(height: 10),

              // Khu vực 2: CTA Tìm nhà hàng trên lộ trình (Corridor Search - Mục 9)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF115E59)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.route_rounded, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tìm Nhà Hàng Dọc Lộ Trình Di Chuyển',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bạn đang di chuyển tham quan tại ${currentProv.name}? Tìm ngay quán ăn nằm trong hành lang dọc tuyến đường đi mà không cần vòng xa.',
                      style: const TextStyle(color: Color(0xFFCCFBF1), fontSize: 12.5),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryDark,
                      ),
                      onPressed: () {
                        appState.setTabIndex(1); // Chuyển sang Tab 2: Bản đồ
                      },
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Mở Bản Đồ & Tìm Dọc Tuyến Đường'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Khu vực 3: Đặc sản & Ẩm thực địa phương
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Đặc sản & Ẩm thực • ${currentProv.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      appState.setTabIndex(3); // Chuyển sang Tab 4: Ẩm thực
                    },
                    child: const Text('Khám phá Ẩm thực'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...foods.map((food) {
                final recRests = appState.allRestaurants
                    .where((r) => food.recommendedRestaurantIds.contains(r.id))
                    .toList();
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    onTap: () => appState.setTabIndex(3),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFFEF3C7),
                      child: const Icon(
                        Icons.ramen_dining_rounded,
                        color: Color(0xFFD97706),
                      ),
                    ),
                    title: Text(
                      food.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 3),
                        Text(
                          '${food.avgPriceRange} • ${food.bestSeasonOrTime}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB45309),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (recRests.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: recRests.take(2).map((r) {
                              return ActionChip(
                                visualDensity: VisualDensity.compact,
                                label: Text(
                                  r.name,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => RestaurantDetailScreen(
                                        restaurant: r,
                                        appState: appState,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 18),

              // Khu vực 4: Lịch trình mẫu gợi ý
              Text(
                'Lịch trình mẫu gợi ý • ${currentProv.name}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              ...templates.map((tpl) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${tpl.totalDays} Ngày • ${tpl.stops.length} Điểm dừng',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tpl.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tpl.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              appState.applyTemplateToMyItinerary(tpl);
                              appState.setTabIndex(2); // Mở Tab Lịch trình
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Đã áp dụng mẫu "${tpl.title}" vào lịch trình của bạn!',
                                  ),
                                  backgroundColor: AppTheme.primaryTeal,
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_all_rounded, size: 16),
                            label: const Text('Áp dụng Lịch trình mẫu này'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
