import 'package:flutter/material.dart';
import '../../../core/utils/app_state.dart';
import '../../../core/utils/external_launcher.dart';
import '../../favorites/favorites_screen.dart';
import '../../provinces/provinces_screen.dart';

/// Component Brand Identity Hero Header thay thế hoàn toàn header cũ ("Xin chào, Du khách / Đi Đâu Tiếp Theo?").
/// Thiết kế chuẩn phong cách Editorial Terracotta Brick & Nền Tươi Sáng:
/// - Thẻ màu gạch nung Terracotta Brick (0xFFE05638) kết hợp ánh san hô và rose pink rực rỡ, ấm áp, truyền cảm hứng.
/// - Nhận diện thương hiệu TRIPFLOW SUPER APP kèm huy hiệu ★ Nền Tảng Du Lịch & Phượt #1 Việt Nam.
/// - Tiêu đề truyền cảm hứng: "Hành Trình Bất Tận,\nTrải Nghiệm Đỉnh Cao".
/// - Hotline hỗ trợ khẩn cấp 1900 6868 với kính mờ Frosted Glass.
/// - Location Pill thông minh: Hiển thị "Toàn quốc 🇻🇳 — Khám Phá Việt Nam" hoặc Tỉnh/Thành phố hiện tại.
/// - Dải Trust Badges: 63 Tỉnh/Thành • 1.200+ Điểm đến thực tế • 100% Dữ liệu xác minh.
class BrandIdentityHeader extends StatelessWidget {
  final TripFlowAppState appState;

  const BrandIdentityHeader({
    super.key,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    final currentProv = appState.selectedProvince;
    final isNational = appState.isNationalMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE05638), // Terracotta Brick đậm nét
              Color(0xFFE85D4A), // Coral Brick ấm áp
              Color(0xFFF43F5E), // Ánh Rose Pink rực rỡ
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE05638).withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar: Brand Logo, Super App Tag & Quick Actions (Hotline, Favorites)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo TRIPFLOW (Nền trắng chữ màu gạch nổi bật)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'TRIPFLOW',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: Color(0xFFE05638),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Tag SUPER APP (Kính mờ viền trắng)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'SUPER APP',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Hotline 24/7 Button - 1 Chạm Gọi Ngay
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => ExternalLauncher.makePhoneCall(context, '19006868'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.45),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.phone_in_talk_rounded,
                            size: 13,
                            color: Color(0xFFA7F3D0), // Fresh Mint
                          ),
                          SizedBox(width: 4),
                          Text(
                            '1900 6868',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Nút Yêu thích
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FavoritesScreen(appState: appState),
                        ),
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.45),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        if (appState.totalFavoritesCount > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${appState.totalFavoritesCount}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFE05638),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. Trust Tagline
              Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 14,
                    color: Color(0xFFFEF08A), // Bright star gold
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Nền Tảng Du Lịch & Phượt #1 Việt Nam',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFEF08A),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // 3. Tiêu đề thương hiệu Display Typography
              const Text(
                'Hành Trình Bất Tận,\nTrải Nghiệm Đỉnh Cao',
                style: TextStyle(
                  fontSize: 22,
                  height: 1.22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),

              // 4. Tagline mô tả
              Text(
                'Khám phá 63 tỉnh thành, bản đồ phượt độc quyền & hệ sinh thái dịch vụ toàn diện.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 16),

              // 5. Smart Location Pill (Kính mờ hiện đại & Nút Đổi tỉnh màu trắng)
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProvincesScreen(appState: appState),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isNational
                              ? Icons.public_rounded
                              : Icons.location_on_rounded,
                          size: 16,
                          color: const Color(0xFFE05638),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isNational
                                  ? 'CHẾ ĐỘ HIỂN THỊ'
                                  : 'TỈNH / THÀNH ĐANG XEM',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white.withValues(alpha: 0.85),
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isNational
                                  ? 'Toàn quốc 🇻🇳 — Khám Phá Việt Nam'
                                  : currentProv.name,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Đổi tỉnh',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFE05638),
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: Color(0xFFE05638),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 6. Trust Badges Strip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TrustBadgeItem(
                      icon: Icons.map_outlined,
                      label: '63 Tỉnh/Thành',
                    ),
                    _TrustBadgeDivider(),
                    _TrustBadgeItem(
                      icon: Icons.place_rounded,
                      label: '1.200+ Điểm đến',
                    ),
                    _TrustBadgeDivider(),
                    _TrustBadgeItem(
                      icon: Icons.verified_user_rounded,
                      label: '100% Xác minh',
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

class _TrustBadgeItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadgeItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: const Color(0xFFFEF08A),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _TrustBadgeDivider extends StatelessWidget {
  const _TrustBadgeDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 12,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }
}
