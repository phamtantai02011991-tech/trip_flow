import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/utils/app_state.dart';
import '../../../core/utils/smart_itinerary_engine.dart';
import '../../itinerary/screens/smart_itinerary_result_screen.dart';
import '../../itinerary/screens/trip_planner_wizard_screen.dart';

/// Dữ liệu cấu hình cho từng thẻ Chuyến đi trong Hero Carousel
class FeaturedTripItem {
  final String id;
  final String title;
  final String subtitle;
  final String durationText;
  final String heroImageUrl;
  final String priceStarting;
  final String travelersText;
  final int provinceId;
  final String provinceName;

  const FeaturedTripItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.durationText,
    required this.heroImageUrl,
    required this.priceStarting,
    required this.travelersText,
    required this.provinceId,
    required this.provinceName,
  });
}

/// Hero Carousel 3D Card Deck (Trang chủ)
/// Thiết kế 100% chuẩn theo Dribbble Reference (Màn hình 1):
/// - Chiều cao 340px, xếp lớp 3D (3D Card Deck Stack)
/// - Ảnh phong cảnh danh thắng chuẩn bản quyền
/// - Nút tròn nổi `↗` góc trên phải chuyển nhanh tới Lộ trình
/// - Pill mờ phong cách Frosted Glass hiển thị thời gian & số điểm dừng
/// - Giá khởi điểm `Chỉ từ 450.000đ` & nhóm avatar `👥 2 người`
/// - Chấm chỉ báo trang (Indicator Dots) với thanh san hô đỏ `#FF4B55` nổi bật
class HeroTripCarousel extends StatefulWidget {
  final TripFlowAppState appState;

  const HeroTripCarousel({super.key, required this.appState});

  @override
  State<HeroTripCarousel> createState() => _HeroTripCarouselState();
}

class _HeroTripCarouselState extends State<HeroTripCarousel> {
  late final PageController _pageController;
  double _currentPage = 0.0;

  // Danh sách các chuyến đi mẫu tiêu biểu trên toàn quốc
  final List<FeaturedTripItem> _trips = const [
    FeaturedTripItem(
      id: 'trip-hcm-heritage',
      title: 'Sài Gòn Di Sản & Lịch Sử',
      subtitle: 'Khởi hành từ 350.000đ',
      durationText: '3 ngày 2 đêm • 12 điểm dừng',
      heroImageUrl:
          'https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1280&q=80',
      priceStarting: '350.000đ',
      travelersText: '2 người',
      provinceId: 1,
      provinceName: 'TP. Hồ Chí Minh',
    ),
    FeaturedTripItem(
      id: 'trip-hanoi-ancient',
      title: 'Hà Nội 36 Phố Phường',
      subtitle: 'Khởi hành từ 480.000đ',
      durationText: '2 ngày 1 đêm • 8 điểm dừng',
      heroImageUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=1280&q=80',
      priceStarting: '480.000đ',
      travelersText: '2-4 người',
      provinceId: 2,
      provinceName: 'Hà Nội',
    ),
    FeaturedTripItem(
      id: 'trip-danang-coastal',
      title: 'Đà Nẵng Biển Xanh Cầu Rồng',
      subtitle: 'Khởi hành từ 520.000đ',
      durationText: '4 ngày 3 đêm • 14 điểm dừng',
      heroImageUrl:
          'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1280&q=80',
      priceStarting: '520.000đ',
      travelersText: '2 người',
      provinceId: 3,
      provinceName: 'Đà Nẵng',
    ),
    FeaturedTripItem(
      id: 'trip-dalat-flowers',
      title: 'Đà Lạt Mộng Mơ & Cà Phê',
      subtitle: 'Khởi hành từ 390.000đ',
      durationText: '3 ngày 2 đêm • 10 điểm dừng',
      heroImageUrl:
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1280&q=80',
      priceStarting: '390.000đ',
      travelersText: '2 người',
      provinceId: 4,
      provinceName: 'Lâm Đồng',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _pageController.addListener(() {
      if (_pageController.hasClients) {
        setState(() {
          _currentPage = _pageController.page ?? 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openTripDetail(FeaturedTripItem trip) {
    // Tìm province tương ứng và tạo lộ trình thông minh mẫu
    final prov = widget.appState.provinces.firstWhere(
      (p) => p.id == trip.provinceId,
      orElse: () => widget.appState.selectedProvince,
    );
    final destinations = widget.appState.allDestinations
        .where((d) => d.provinceId == prov.id)
        .toList();

    if (destinations.length >= 2) {
      final generatedPlan = SmartItineraryEngine.generate(
        province: prov,
        origin: destinations.first,
        destination: destinations.last,
        startDate: DateTime.now(),
        totalDays: 3,
        preferenceIds: {'history', 'architecture'},
        allDestinations: destinations,
        allRestaurants: widget.appState.restaurantsForSelectedProvince,
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SmartItineraryResultScreen(
            plan: generatedPlan,
            appState: widget.appState,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TripPlannerWizardScreen(appState: widget.appState),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Khung PageView Card Deck 3D
        SizedBox(
          height: 340,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _trips.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final trip = _trips[index];
              // Hiệu ứng scale xếp lớp 3D
              final pageDiff = (_currentPage - index).abs();
              final scale = (1.0 - (pageDiff * 0.08)).clamp(0.90, 1.0);
              final opacity = (1.0 - (pageDiff * 0.3)).clamp(0.65, 1.0);

              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: _buildCard(trip),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // Indicator Dots với dot active màu san hô đỏ #FF4B55
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_trips.length, (index) {
            final isActive = (_currentPage.round() == index);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFFF4B55)
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCard(FeaturedTripItem trip) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // 1. Ảnh phong cảnh toàn màn hình của card với loadingBuilder và errorBuilder mượt mà
            Positioned.fill(
              child: Image.network(
                trip.heroImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFFFF4B55).withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.landscape_rounded,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
            ),

            // 2. Lớp gradient phủ tăng tương phản cho chữ và pill
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.40),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    stops: const [0.0, 0.35, 0.65, 1.0],
                  ),
                ),
              ),
            ),

            // 3. Nút tròn nổi trắng với icon chéo ↗ góc trên phải
            Positioned(
              top: 16,
              right: 16,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 4,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _openTripDetail(trip),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.north_east_rounded,
                      color: Color(0xFF0F172A),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            // 4. Nhãn tỉnh thành góc trên trái
            Positioned(
              top: 18,
              left: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.near_me_rounded,
                      color: Color(0xFF5EEAD4),
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trip.provinceName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 5. Nội dung thông tin chính ở đáy Card (Tiêu đề, Giá, Avatar, Frosted Pill)
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tiêu đề chuyến đi đậm nét phong cách Dribbble
                  Text(
                    trip.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Giá và Nhóm Avatar người đồng hành
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        trip.subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // Nhóm Avatar xếp đè + số lượng người
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildOverlappingAvatars(),
                          const SizedBox(width: 6),
                          Text(
                            trip.travelersText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Frosted Glass Pill Tag: "3 ngày 2 đêm • 12 điểm dừng"
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => _openTripDetail(trip),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.38),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.explore_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                trip.durationText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Xây dựng 2 avatar đè nhau chuẩn phong cách thiết kế Dribbble
  Widget _buildOverlappingAvatars() {
    return SizedBox(
      width: 38,
      height: 22,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=120&q=80',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&q=80',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
