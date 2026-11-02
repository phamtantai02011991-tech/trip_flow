import 'package:flutter/material.dart';
import '../../core/utils/app_state.dart';
import '../../core/utils/mock_data.dart';
import '../../core/widgets/common_widgets.dart';
import '../destinations/destinations_screen.dart';
import '../favorites/favorites_screen.dart';
import '../maps/map_corridor_screen.dart';
import '../provinces/provinces_screen.dart';
import '../restaurants/restaurant_detail_screen.dart';
import 'widgets/hero_trip_carousel.dart';
import 'widgets/popular_destination_card.dart';

/// Tab 1: Màn hình Trang Chủ Khám Phá (HomeScreen)
/// Thiết kế 100% chuẩn theo Dribbble Reference (Màn hình 1):
/// - Header lớn phong cách Editorial: "Xin chào, Du khách 👋" + Tiêu đề đậm "Đi Đâu Tiếp Theo?"
/// - Huy hiệu chọn Tỉnh/Thành phố thông minh + Nút Tìm kiếm & Yêu thích
/// - Thanh tìm kiếm tinh tế + Chips danh mục lướt ngang
/// - 3D Card Deck Carousel hiển thị Chuyến đi nổi bật với nút ↗ và Pill kính mờ
/// - Danh sách lướt ngang "Điểm Đến Thịnh Hành" với ảnh tràn viền nghệ thuật & huy hiệu ⭐
/// - Khu vực "Ẩm Thực Đặc Sản Địa Phương" dạng thẻ ảnh ngang bắt mắt
/// - Thẻ gọi nhanh "Lập Lịch Trình Dọc Tuyến (Corridor Search)"
class HomeScreen extends StatelessWidget {
  final TripFlowAppState appState;

  const HomeScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final currentProv = appState.selectedProvince;
        final featuredDestinations = appState.featuredDestinations.isNotEmpty
            ? appState.featuredDestinations
            : appState.destinationsForSelectedProvince;
        final foods = appState.localFoodsForSelectedProvince;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 130),
              children: [
                // 1. Cảnh báo Offline / Vị trí nếu có
                if (appState.isOfflineSimulated)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: OfflineModeBanner(
                      onRetryOnline: () {
                        appState.toggleOfflineSimulation(false);
                        appState.syncFromBackend();
                      },
                    ),
                  ),
                if (appState.locationPermission ==
                    LocationPermissionState.denied)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: LocationPermissionNotice(
                      onGrantPermission: () {
                        appState.setLocationPermission(
                          LocationPermissionState.granted,
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 12),

                // 2. HEADER EDITORIAL (Theo chuẩn Dribbble Ảnh 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Lời chào & Tiêu đề lớn
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Xin chào, Du khách 👋',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Đi Đâu Tiếp Theo?',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Pill Chọn Tỉnh/Thành phố
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProvincesScreen(appState: appState),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      size: 14,
                                      color: Color(0xFFFF4B55),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      currentProv.name,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: Color(0xFF475569),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Nhóm Nút Tác vụ (Yêu thích & Chuông Thông báo)
                      Row(
                        children: [
                          // Nút Danh sách Yêu thích
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                tooltip: 'Yêu thích',
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  elevation: 1,
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          FavoritesScreen(appState: appState),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.favorite_rounded,
                                  color: Color(0xFFFF4B55),
                                  size: 20,
                                ),
                              ),
                              if (appState.totalFavoritesCount > 0)
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF4B55),
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
                          const SizedBox(width: 8),

                          // Nút Chuông thông báo
                          IconButton(
                            tooltip: 'Thông báo',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 1,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Bạn có 3 gợi ý địa điểm mới nhất từ ban biên tập!',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              color: Color(0xFF0F172A),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 3. THANH TÌM KIẾM NHANH TINH TẾ
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              DestinationsScreen(appState: appState),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF64748B),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tìm địa điểm, danh thắng, món ngon tại ${currentProv.name}...',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: Color(0xFF475569),
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 4. DANH MỤC NHANH TRƯỢT NGANG
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: MockDataRepository.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = MockDataRepository.categories[index];
                      return ActionChip(
                        elevation: 0,
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        label: Text(
                          cat['name']!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
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

                // 5. HERO 3D CARD DECK CAROUSEL (Chuẩn theo Ảnh 1 Dribbble)
                HeroTripCarousel(appState: appState),

                const SizedBox(height: 26),

                // 6. PHẦN "ĐIỂM ĐẾN THỊNH HÀNH" (POPULAR DESTINATION)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Điểm Đến Thịnh Hành',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  DestinationsScreen(appState: appState),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFF4B55),
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Xem tất cả',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // DANH SÁCH THẺ ĐIỂM ĐẾN TRƯỢT NGANG (165 x 215px, bo góc 22px)
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: featuredDestinations.length,
                    itemBuilder: (context, index) {
                      final dest = featuredDestinations[index];
                      return PopularDestinationCard(
                        destination: dest,
                        appState: appState,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 26),

                // 7. PHẦN "ẨM THỰC ĐẶC SẢN NỔI TIẾNG"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Ẩm Thực & Món Ngon',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          appState.setTabIndex(3); // Chuyển sang Tab Ẩm thực
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFF4B55),
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Xem tất cả',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // DANH SÁCH THẺ ẨM THỰC TRƯỢT NGANG
                SizedBox(
                  height: 175,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: foods.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final food = foods[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          final restaurants = appState
                              .restaurantsForSelectedProvince
                              .where((r) =>
                                  food.recommendedRestaurantIds.contains(r.id))
                              .toList();
                          if (restaurants.isNotEmpty) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RestaurantDetailScreen(
                                  restaurant: restaurants.first,
                                  appState: appState,
                                ),
                              ),
                            );
                          } else {
                            appState.setTabIndex(3);
                          }
                        },
                        child: Container(
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(18),
                                ),
                                child: Image.network(
                                  food.imageUrl,
                                  width: 140,
                                  height: 95,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 140,
                                    height: 95,
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      food.name,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      food.avgPriceRange,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFFF4B55),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // 8. CARD TÍNH NĂNG "TÌM NHÀ HÀNG DỌC TUYẾN (CORRIDOR SEARCH)"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF4B55),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Tính năng Độc quyền',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tìm Quán Ăn Dọc Tuyến',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tự động quét bán kính 500m quanh lộ trình bạn đang đi',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11.5,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Material(
                          color: const Color(0xFFFF4B55),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MapCorridorScreen(
                                    appState: appState,
                                  ),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(14),
                              child: Icon(
                                Icons.near_me_rounded,
                                color: Colors.white,
                                size: 22,
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
          ),
        );
      },
    );
  }
}
