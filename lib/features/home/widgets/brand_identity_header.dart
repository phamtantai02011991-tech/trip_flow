import 'package:flutter/material.dart';
import '../../../core/utils/app_state.dart';
import '../../../core/utils/external_launcher.dart';
import '../../favorites/favorites_screen.dart';
import '../../provinces/provinces_screen.dart';
import '../../sos/biker_sos_screen.dart';

/// Component Brand Identity Hero Header thay thế hoàn toàn header cũ ("Xin chào, Du khách / Đi Đâu Tiếp Theo?").
/// Thiết kế chuẩn Anti-AI-Slop phong cách Editorial cao cấp:
/// - Thẻ màu sẫm Slate 900 (0xFF0F172A) tương phản cao, sang trọng.
/// - Nhận diện thương hiệu TRIPFLOW SUPER APP kèm huy hiệu ★ Nền Tảng Du Lịch & Phượt #1 Việt Nam.
/// - Tiêu đề truyền cảm hứng: "Hành Trình Bất Tận, Trải Nghiệm Đỉnh Cao".
/// - Hotline hỗ trợ khẩn cấp 1900 6868.
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF334155).withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar: Brand Logo, Star Badge & Quick Actions (Hotline, Favorites)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo TRIPFLOW
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4B55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'TRIPFLOW',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Tag SUPER APP
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF475569),
                        width: 0.8,
                      ),
                    ),
                    child: const Text(
                      'SUPER APP',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Nút Cứu Hộ Biker SOS 24/7 (Phase 1 Killer Feature)
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BikerSosScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emergency_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: 2),
                          Text(
                            'SOS',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),

                  // Hotline 24/7 Button - 1 Chạm Gọi Ngay
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => ExternalLauncher.makePhoneCall(context, '19006868'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF334155),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.phone_in_talk_rounded,
                            size: 12,
                            color: Color(0xFF10B981),
                          ),
                          SizedBox(width: 3),
                          Text(
                            '1900 6868',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF1F5F9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),

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
                            color: const Color(0xFF1E293B),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF334155),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 16,
                            color: Color(0xFFFF4B55),
                          ),
                        ),
                        if (appState.totalFavoritesCount > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF4B55),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${appState.totalFavoritesCount}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
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
                    color: Color(0xFFFBBF24),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Nền Tảng Du Lịch & Phượt #1 Việt Nam',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.95),
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
                  color: Color(0xFFF8FAFC),
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),

              // 4. Tagline mô tả
              const Text(
                'Khám phá 63 tỉnh thành, bản đồ phượt độc quyền & hệ sinh thái dịch vụ toàn diện.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 16),

              // 5. Smart Location Pill
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
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isNational
                          ? const Color(0xFFFF4B55).withValues(alpha: 0.5)
                          : const Color(0xFF38BDF8).withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isNational
                              ? const Color(0xFFFF4B55).withValues(alpha: 0.15)
                              : const Color(0xFF38BDF8).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isNational
                              ? Icons.public_rounded
                              : Icons.location_on_rounded,
                          size: 16,
                          color: isNational
                              ? const Color(0xFFFF4B55)
                              : const Color(0xFF38BDF8),
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
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF64748B),
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
                                color: Color(0xFFF8FAFC),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Đổi tỉnh',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: Color(0xFFE2E8F0),
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
                  color: const Color(0xFF020617).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
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
          color: const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFFCBD5E1),
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
      color: const Color(0xFF334155),
    );
  }
}

