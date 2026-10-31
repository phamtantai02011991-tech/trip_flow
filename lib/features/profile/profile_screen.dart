import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../favorites/favorites_screen.dart';

/// Tab 5: Màn hình Cá nhân, Tài khoản & Thiết lập Trải nghiệm (ProfileScreen - Mục 5.1.11 & Mục 5.3).
/// Hỗ trợ:
/// - Guest Mode không bắt buộc đăng nhập (Mục 5.3) hoặc Đăng nhập tài khoản để đồng bộ
/// - Nút đồng bộ dữ liệu mới nhất từ Admin Backend (TC-08)
/// - Công tắc kiểm thử Quyền vị trí (Location Permission) và Chế độ Offline (TC-06, TC-09)
/// - Lịch sử các báo cáo sai thông tin đã gửi.
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
          appBar: AppBar(
            title: const Text('Cá Nhân & Thiết Lập Ứng Dụng'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Thẻ Hồ sơ Người dùng / Guest Mode (Mục 5.3)
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
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppTheme.primaryTeal,
                          child: Icon(
                            appState.isLoggedIn
                                ? Icons.verified_user_rounded
                                : Icons.person_outline_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appState.userName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                appState.isLoggedIn
                                    ? appState.userEmail
                                    : 'Bạn có thể khám phá đầy đủ nội dung và tạo lịch trình mà không bắt buộc đăng nhập.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (!appState.isLoggedIn)
                          ElevatedButton.icon(
                            onPressed: () {
                              appState.loginUser(
                                email: 'traveler@tripflow.vn',
                                fullName: 'Hoàng Du Khách',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Đã đăng nhập tài khoản traveler@tripflow.vn!',
                                  ),
                                  backgroundColor: AppTheme.primaryTeal,
                                ),
                              );
                            },
                            icon: const Icon(Icons.login_rounded, size: 18),
                            label: const Text('Đăng nhập đồng bộ tài khoản'),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () {
                              appState.logoutUser();
                            },
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text('Chuyển về Chế độ Khách (Guest)'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Truy cập nhanh Yêu thích & Đồng bộ API từ Admin
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FavoritesScreen(appState: appState),
                          ),
                        );
                      },
                      leading: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.redAccent,
                      ),
                      title: const Text(
                        'Danh sách Yêu thích đã lưu',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${appState.totalFavoritesCount} mục đã đánh dấu yêu thích',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      onTap: () async {
                        await appState.syncFromBackend();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Đã đồng bộ dữ liệu mới nhất từ TripFlow Admin Backend!',
                              ),
                              backgroundColor: AppTheme.primaryTeal,
                            ),
                          );
                        }
                      },
                      leading: const Icon(
                        Icons.cloud_sync_rounded,
                        color: AppTheme.primaryTeal,
                      ),
                      title: const Text(
                        'Cập nhật dữ liệu mới nhất từ Admin API',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Nhận ngay địa điểm, món ăn, nhà hàng mới mà không cần cập nhật app',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: appState.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bảng điều khiển Quyền vị trí & Chế độ Offline (Mục 5.3 & Mục 15)
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quyền Riêng Tư & Trạng Thái Mạng (Mục 5.3 & 15)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Cho phép truy cập Vị trí hiện tại (GPS)',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        subtitle: const Text(
                          'Nếu tắt quyền vị trí, ứng dụng vẫn hoạt động bình thường với tâm TP.HCM.',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: isLocationGranted,
                        activeColor: AppTheme.primaryTeal,
                        onChanged: (val) {
                          appState.setLocationPermission(
                            val
                                ? LocationPermissionState.granted
                                : LocationPermissionState.denied,
                          );
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Chế độ Ngoại tuyến (Offline / Mạng yếu)',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        subtitle: const Text(
                          'Xem lại các lịch trình và địa điểm đã lưu ngay cả khi mất kết nối mạng.',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: appState.isOfflineSimulated,
                        activeColor: AppTheme.accentOrange,
                        onChanged: (val) {
                          appState.toggleOfflineSimulation(val);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Lịch sử báo sai thông tin
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (appState.submittedReports.isEmpty)
                        const Text(
                          'Bạn chưa gửi báo cáo nào. Khi phát hiện địa điểm/nhà hàng thay đổi giờ mở cửa hoặc giá vé, hãy bấm "Báo sai thông tin" ở trang chi tiết.',
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
                              color: Colors.redAccent,
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
                                color: Colors.orange,
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
        );
      },
    );
  }
}
