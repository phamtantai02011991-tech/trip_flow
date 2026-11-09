import 'package:flutter/material.dart';
import '../../core/utils/app_state.dart';
import '../../core/utils/mock_data.dart';
import '../../core/widgets/common_widgets.dart';
import '../destinations/destinations_screen.dart';
import '../maps/map_corridor_screen.dart';
import '../restaurants/restaurant_detail_screen.dart';
import '../search/global_search_screen.dart';
import 'widgets/brand_identity_header.dart';
import 'widgets/hero_trip_carousel.dart';
import 'widgets/popular_destination_card.dart';
import 'widgets/super_app_service_grid.dart';

/// Tab 1: Màn hình Trang Chủ Khám Phá (HomeScreen)
/// Thiết kế 100% chuẩn theo Dribbble Reference:
/// - Nền tươi sáng màu kem ấm (#FAF8F5), hài hòa giữa Terracotta Brick, Hồng đậm nhạt và Xanh biển/Mint
/// - Header Brand Identity Terracotta Brick sang trọng, lượn cong mềm mại
/// - 5 Dịch vụ Super App phân loại màu sắc tươi mát, nổi bật
/// - Thanh tìm kiếm tinh tế + Chips danh mục lướt ngang
/// - 3D Card Deck Carousel hiển thị Chuyến đi nổi bật với nút ↗ và Pill kính mờ
/// - Danh sách lướt ngang "Điểm Đến Thịnh Hành" với ảnh tràn viền nghệ thuật & huy hiệu ⭐
/// - Khu vực "Ẩm Thực Đặc Sản Địa Phương" dạng thẻ ảnh ngang bắt mắt
/// - Thẻ gọi nhanh "Lập Cung Đường Phượt Dọc Tuyến" phong cách Xanh Biển Tươi Mát
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
          backgroundColor: const Color(0xFFFAF8F5),
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

                // 2. BRAND IDENTITY HERO HEADER (Terracotta Brick lượn sóng)
                BrandIdentityHeader(appState: appState),

                // 3. SUPER APP SERVICE GRID (Khách Sạn, Vé Tàu Xe, Tour, Lập Lịch Phượt, Ẩm Thực)
                SuperAppServiceGrid(appState: appState),

                const SizedBox(height: 12),

                // 4. THANH TÌM KIẾM NHANH TINH TẾ
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              GlobalSearchScreen(appState: appState),
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
                          color: const Color(0xFFEAE3D9),
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
                            color: Color(0xFF0284C7), // Fresh Ocean Blue
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              appState.isNationalMode
                                  ? 'Tìm điểm đến, khách sạn, tour, quán ngon toàn quốc...'
                                  : 'Tìm địa điểm, danh thắng, món ngon tại ${currentProv.name}...',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2), // Soft Pink
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: Color(0xFFE11D48), // Deep Rose
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 5. DANH MỤC NHANH TRƯỢT NGANG
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
                          color: Color(0xFFEAE3D9),
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

                // 6. HERO 3D CARD DECK CAROUSEL
                HeroTripCarousel(appState: appState),

                const SizedBox(height: 26),

                // 7. PHẦN "ĐIỂM ĐẾN THỊNH HÀNH" (POPULAR DESTINATION)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          appState.isNationalMode
                              ? 'Danh Thắng Thịnh Hành 3 Miền'
                              : 'Điểm Đến Thịnh Hành Tại ${currentProv.name}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
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
                          foregroundColor: const Color(0xFFE05638), // Terracotta Brick
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

                // 8. PHẦN "ẨM THỰC ĐẶC SẢN NỔI TIẾNG"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          appState.isNationalMode
                              ? 'Đặc Sản Trứ Danh Bắc - Trung - Nam'
                              : 'Ẩm Thực Đặc Sản ${currentProv.name}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          appState.setTabIndex(4); // Chuyển sang Tab Ẩm thực
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFE05638), // Terracotta Brick
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
                            appState.setTabIndex(4);
                          }
                        },
                        child: Container(
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFEAE3D9),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
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
                                  top: Radius.circular(17),
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
                                        color: Color(0xFF1E293B),
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
                                        color: Color(0xFFE05638), // Terracotta Brick
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

                // 9. CARD TÍNH NĂNG "LẬP CUNG ĐƯỜNG PHƯỢT DỌC TUYẾN (CORRIDOR SEARCH)"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0284C7), // Ocean Blue
                          Color(0xFF0EA5E9), // Sky Blue
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.28),
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
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 0.8,
                                  ),
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
                                'Lập Cung Đường Phượt Dọc Tuyến',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Quét trạm xăng, quán sửa xe, quán cà phê săn mây & trạm dừng ven đường',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 11.5,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Material(
                          color: Colors.white,
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
                                color: Color(0xFF0284C7),
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
