import 'package:flutter/material.dart';
import '../../core/utils/app_state.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../favorites/favorites_screen.dart';
import '../services/hotels_screen.dart';
import '../services/transport_screen.dart';

/// Tab 5: Màn hình Cá nhân, Tài khoản & Thiết lập Trải nghiệm (ProfileScreen)
/// Thiết kế 100% chuẩn theo phong cách Editorial Terracotta Brick từ ảnh tham chiếu:
/// - Header màu gạch nung cong mềm mại (Curved Terracotta Header) với Avatar tròn nổi bật
/// - Tên người dùng và huy hiệu Hội Viên "( Thành Viên Du Lịch TripFlow )"
/// - Nền tươi sáng màu kem ấm (#FAF8F5)
/// - Danh mục menu thẻ trắng bo góc 18px thanh lịch, biểu tượng tinh tế
class ProfileScreen extends StatelessWidget {
  final TripFlowAppState appState;

  const ProfileScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final isLocationGranted =
            appState.locationPermission == LocationPermissionState.granted;

        return Scaffold(
          backgroundColor: const Color(0xFFFAF8F5),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              // 1. CURVED TERRACOTTA BRICK HERO HEADER (Chuẩn theo ảnh tham chiếu)
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFE05638), // Terracotta Brick
                      Color(0xFFE85D4A), // Coral Brick
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33E05638),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
                    child: Column(
                      children: [
                        // Top Bar: Branding & Notification
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TripFlow',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Avatar với vòng tròn hào quang trắng nổi bật
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.7),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.white,
                            child: Icon(
                              appState.isLoggedIn
                                  ? Icons.verified_user_rounded
                                  : Icons.person_rounded,
                              size: 40,
                              color: const Color(0xFFE05638),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Tên người dùng
                        Text(
                          appState.userName,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Huy hiệu hội viên
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            appState.isLoggedIn
                                ? '( Thành Viên Xác Thực OTP )'
                                : '( Thành Viên Du Lịch TripFlow )',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (appState.isLoggedIn &&
                            (appState.isOtpVerified ||
                                appState.userPhone.isNotEmpty)) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 13,
                                  color: Color(0xFF059669),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Đã xác thực OTP qua tin nhắn SMS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // Nút Đăng nhập / Đăng xuất
                        if (!appState.isLoggedIn)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFFE05638),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          RegisterScreen(appState: appState),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.sms_rounded, size: 15),
                                label: const Text(
                                  'Đăng ký tài khoản (Nhận OTP)',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          LoginScreen(appState: appState),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.login_rounded, size: 15),
                                label: const Text(
                                  'Đăng nhập',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          )
                        else
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => appState.logoutUser(),
                            icon: const Icon(Icons.logout_rounded, size: 16),
                            label: const Text(
                              'Đăng xuất (Về chế độ Khách)',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 2. DANH MỤC TÍNH NĂNG CHÍNH (Card Menu phong cách Editorial)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFFEAE3D9)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _ProfileMenuItem(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        title: 'Quản lý tài khoản & Thông tin',
                        subtitle: appState.isLoggedIn
                            ? (appState.userPhone.isNotEmpty
                                ? appState.userPhone
                                : appState.userEmail)
                            : 'Chế độ Khách (Đầy đủ tính năng)',
                        onTap: () {
                          if (!appState.isLoggedIn) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    RegisterScreen(appState: appState),
                              ),
                            );
                          }
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFF0EAE1)),
                      _ProfileMenuItem(
                        icon: Icons.confirmation_number_rounded,
                        iconColor: const Color(0xFF0284C7), // Ocean Blue
                        title: 'Lịch sử đặt vé & Đặt phòng',
                        subtitle: 'E-Voucher khách sạn & E-Ticket vé xe tàu',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => HotelsScreen(appState: appState),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFF0EAE1)),
                      _ProfileMenuItem(
                        icon: Icons.favorite_rounded,
                        iconColor: const Color(0xFFE11D48), // Rose Pink
                        title: 'Địa điểm & Quán ăn yêu thích',
                        subtitle:
                            '${appState.totalFavoritesCount} mục đã lưu vào danh sách',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  FavoritesScreen(appState: appState),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFF0EAE1)),
                      _ProfileMenuItem(
                        icon: Icons.cloud_sync_rounded,
                        iconColor: const Color(0xFF10B981), // Fresh Mint
                        title: 'Đồng bộ dữ liệu mới nhất (Admin API)',
                        subtitle: 'Cập nhật địa điểm, món ngon & khách sạn mới',
                        trailing: appState.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh_rounded, size: 20),
                        onTap: () async {
                          await appState.syncFromBackend();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Đã đồng bộ dữ liệu mới nhất từ TripFlow Admin Backend!',
                                ),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. THIẾT LẬP GPS & NGOẠI TUYẾN OFFLINE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFFEAE3D9)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thiết Lập Quyền Riêng Tư & Mạng',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Cho phép truy cập Vị trí (GPS)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          subtitle: const Text(
                            'Tự động quét quán ngon và điểm đến quanh bạn',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: isLocationGranted,
                          activeColor: const Color(0xFF0284C7),
                          onChanged: (val) {
                            appState.setLocationPermission(
                              val
                                  ? LocationPermissionState.granted
                                  : LocationPermissionState.denied,
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFFF0EAE1)),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Chế độ Ngoại tuyến (Offline)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          subtitle: const Text(
                            'Duyệt lịch trình và dữ liệu đã lưu khi mất mạng',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: appState.isOfflineSimulated,
                          activeColor: const Color(0xFFE05638),
                          onChanged: (val) {
                            appState.toggleOfflineSimulation(val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 4. LỊCH SỬ BÁO CÁO SAI THÔNG TIN
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFFEAE3D9)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Báo cáo sai thông tin đã gửi (${appState.submittedReports.length})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (appState.submittedReports.isEmpty)
                          const Text(
                            'Bạn chưa gửi báo cáo nào. Khi phát hiện thông tin thay đổi, hãy bấm "Báo sai thông tin" tại trang chi tiết để nhận điểm thưởng.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          )
                        else
                          ...appState.submittedReports.map(
                            (rep) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.flag_rounded,
                                color: Color(0xFFE11D48),
                              ),
                              title: Text(
                                rep.targetName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                              subtitle: Text(
                                rep.description,
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: const Text(
                                'Chờ duyệt',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE05638),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF64748B),
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
    );
  }
}
