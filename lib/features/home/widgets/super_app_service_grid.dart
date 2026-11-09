import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/app_state.dart';
import '../../planner/planner_wizard_screen.dart';
import '../../restaurants/restaurants_screen.dart';
import '../../services/hotels_screen.dart';
import '../../services/tours_screen.dart';
import '../../services/transport_screen.dart';
import '../../services/ota_partner_hub_screen.dart';

/// Hub 5 Dịch vụ cốt lõi của TripFlow Super App (Anti-AI-Slop Standard)
/// Phối màu tươi sáng: Màu Gạch Terracotta, Hồng đậm nhạt, Xanh biển & Mint tươi mát
/// Gồm:
/// 1. 🏨 Khách Sạn & Homestay (Đặt phòng & E-Voucher) - Tông Hồng Đậm Nhạt
/// 2. 🎫 Vé Xe, Tàu & Bay (Đặt vé Limousine, Tàu SE, Máy bay & E-Ticket) - Tông Xanh Biển Tươi
/// 3. 🗺️ Tour & Trải Nghiệm (Trekking Tà Năng, Fansipan, Hà Giang Loop, Lặn Phú Quốc) - Tông Xanh Mint Tươi
/// 4. 🏍️ Lập Lịch Phượt (Road-trip Wizard đa ngày, xe máy phượt & ô tô tự lái) - Tông Màu Gạch Nung Terracotta
/// 5. 🍜 Ẩm Thực Quán Ngon (Dữ liệu cào Google Maps / mạng xã hội thực tế) - Tông Cam Đất Ấm Áp
class SuperAppServiceGrid extends StatelessWidget {
  final TripFlowAppState appState;

  const SuperAppServiceGrid({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Heading
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dịch Vụ Du Lịch & Phượt',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Hệ sinh thái đặt dịch vụ & tiện ích toàn diện',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF2F8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCE7F3)),
                ),
                child: const Text(
                  AppConfig.showDemoBooking ? '5 Tiện Ích' : 'Trip Planner',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE11D48),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Hàng 1: 3 dịch vụ du lịch (Khách sạn [Hồng], Vé xe tàu [Xanh biển], Tour [Mint])
          // Chỉ hiển thị ở bản demo/dev; bản release ẩn để không phát hành booking giả.
          if (AppConfig.showDemoBooking)
            Row(
            children: [
              Expanded(
                child: _ServiceTile(
                  icon: Icons.hotel_rounded,
                  iconColor: const Color(0xFFE11D48),
                  bgColor: const Color(0xFFFFF1F2),
                  borderColor: const Color(0xFFFECDD3),
                  title: 'Khách Sạn',
                  subtitle: 'Resort & Stay',
                  demo: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HotelsScreen(appState: appState),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ServiceTile(
                  icon: Icons.directions_bus_filled_rounded,
                  iconColor: const Color(0xFF0284C7),
                  bgColor: const Color(0xFFF0F9FF),
                  borderColor: const Color(0xFFBAE6FD),
                  title: 'Vé Xe & Tàu',
                  subtitle: 'Limousine, Bay',
                  demo: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TransportScreen(appState: appState),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ServiceTile(
                  icon: Icons.terrain_rounded,
                  iconColor: const Color(0xFF059669),
                  bgColor: const Color(0xFFECFDF5),
                  borderColor: const Color(0xFFA7F3D0),
                  title: 'Tour Tuyển',
                  subtitle: 'Trekking & Phượt',
                  demo: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ToursScreen(appState: appState),
                      ),
                    );
                  },
                ),
              ),
            ],
          )
          else
            _comingSoonBanner(),

          const SizedBox(height: 10),

          // Hàng 2: 2 dịch vụ mũi nhọn mở rộng (Lập Lịch Phượt Biker [Terracotta Brick] & Ẩm Thực Quán Ngon [Cam Đất])
          Row(
            children: [
              // Lập Lịch Phượt Biker (Màu Gạch Terracotta)
              Expanded(
                flex: 6,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PlannerWizardScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFE05638), // Terracotta Brick
                          Color(0xFFEA580C),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE05638).withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.two_wheeler_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Lập Lịch Phượt',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text('🏍️', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Xuyên Việt • Biker POI',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
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

              const SizedBox(width: 10),

              // Ẩm Thực Quán Ngon
              Expanded(
                flex: 5,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RestaurantsScreen(appState: appState),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.restaurant_menu_rounded,
                            color: Color(0xFFEA580C),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ẩm Thực',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF9A3412),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Quán ngon thực tế',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFFC2410C),
                                  fontWeight: FontWeight.w600,
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
            ],
          ),

          const SizedBox(height: 10),

          // Đối Tác Đặt Chỗ OTA (Vexere, Agoda, Booking, Traveloka, Klook)
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const OtaPartnerHubScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.handshake_outlined, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đối Tác Đặt Chỗ & Ưu Đãi Độc Quyền',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF166534),
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Vexere • Agoda • Booking.com • Traveloka • Klook (Giảm tới 15%)',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF15803D),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF15803D)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _comingSoonBanner() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            const Icon(Icons.construction_rounded,
                color: Color(0xFFD97706), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đặt phòng / vé / tour đang hoàn thiện',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bản phát hành này tập trung vào lập lộ trình, tìm quán ăn và điểm nghỉ chân. '
                    'Bạn vẫn có thể đặt qua đối tác bên dưới.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: const Color(0xFF92400E).withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final String title;
  final String subtitle;
  final bool demo;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.title,
    required this.subtitle,
    this.demo = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
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
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (demo) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'DEMO',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFBE123C),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
