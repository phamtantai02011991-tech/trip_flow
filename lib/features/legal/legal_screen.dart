import 'package:flutter/material.dart';

import '../../ui/tokens/app_tokens.dart';

/// Điều khoản sử dụng, chính sách riêng tư và giấy phép dữ liệu/ảnh.
class LegalScreen extends StatelessWidget {
  final int initialTab;

  const LegalScreen({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab.clamp(0, 2),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF8F5),
        appBar: AppBar(
          title: const Text('Pháp lý & Quyền riêng tư'),
          backgroundColor: const Color(0xFFFAF8F5),
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          bottom: const TabBar(
            labelColor: AppColors.coral,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.coral,
            tabs: [
              Tab(text: 'Điều khoản'),
              Tab(text: 'Riêng tư'),
              Tab(text: 'Giấy phép'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LegalPage(
              title: 'Điều khoản sử dụng',
              updated: 'Cập nhật: 07/11/2026',
              sections: [
                _LegalSection(
                  '1. TripFlow là gì?',
                  'TripFlow là công cụ giúp bạn lập lộ trình, tìm quán ăn và điểm nghỉ chân '
                      'dọc đường tại Việt Nam. TripFlow không phải đơn vị lữ hành, không trực tiếp '
                      'tổ chức tour, vận chuyển hay lưu trú.',
                ),
                _LegalSection(
                  '2. Thông tin chỉ mang tính tham khảo',
                  'Giờ mở cửa, giá, toạ độ và tình trạng địa điểm có thể thay đổi. Vui lòng xác '
                      'nhận lại với địa điểm trước khi khởi hành. TripFlow không chịu trách nhiệm '
                      'cho thiệt hại phát sinh từ việc sử dụng thông tin tham khảo.',
                ),
                _LegalSection(
                  '3. Đặt dịch vụ',
                  'Bản phát hành này không cung cấp chức năng đặt phòng, vé hay tour. Các liên kết '
                      'đối tác (Agoda, Booking.com, Traveloka, Klook, Vexere) mở sang website bên '
                      'thứ ba và tuân theo điều khoản của đối tác đó.',
                ),
                _LegalSection(
                  '4. Tài khoản & hành vi',
                  'Bạn chịu trách nhiệm bảo mật tài khoản. Không được spam, thu thập dữ liệu tự '
                      'động, đăng nội dung sai lệch hoặc xâm phạm quyền của người khác. TripFlow có '
                      'thể tạm khoá tài khoản vi phạm.',
                ),
                _LegalSection(
                  '5. Giới hạn trách nhiệm',
                  'TripFlow cung cấp dịch vụ "nguyên trạng". Trong phạm vi pháp luật cho phép, '
                      'TripFlow không chịu trách nhiệm cho mất mát dữ liệu, gián đoạn dịch vụ hoặc '
                      'thiệt hại gián tiếp.',
                ),
              ],
            ),
            _LegalPage(
              title: 'Chính sách riêng tư',
              updated: 'Cập nhật: 07/11/2026',
              sections: [
                _LegalSection(
                  '1. Dữ liệu chúng tôi thu thập',
                  '• Số điện thoại/email và họ tên khi đăng nhập hoặc đăng ký.\n'
                      '• Lịch trình, điểm dừng, yêu thích và đánh giá do bạn tạo.\n'
                      '• Vị trí gần đúng khi bạn cấp quyền, để tìm quán ăn/điểm nghỉ gần bạn.\n'
                      '• Mã khách ẩn danh (guest token) cho chuyến chưa đăng nhập.\n'
                      '• Nhật ký kỹ thuật tối thiểu để vận hành và chống lạm dụng.',
                ),
                _LegalSection(
                  '2. Mục đích sử dụng',
                  'Hiển thị lộ trình và gợi ý địa điểm; lưu dữ liệu bạn tạo; xác thực tài khoản; '
                      'cải thiện chất lượng dữ liệu; bảo vệ hệ thống khỏi spam và tấn công.',
                ),
                _LegalSection(
                  '3. Lưu trữ & bảo mật',
                  'Token đăng nhập được lưu trong Keychain/Keystore của thiết bị. Dữ liệu máy chủ '
                      'lưu trên PostgreSQL, phân quyền theo vai trò. Chúng tôi không bán dữ liệu cá nhân.',
                ),
                _LegalSection(
                  '4. Chia sẻ với bên thứ ba',
                  'Dịch vụ bản đồ (Goong/OpenStreetMap), SMS (eSMS), lưu trữ ảnh (Cloudinary) và '
                      'nhà cung cấp hạ tầng chỉ nhận dữ liệu tối thiểu để thực hiện chức năng. '
                      'Liên kết đối tác đặt dịch vụ do bạn chủ động mở.',
                ),
                _LegalSection(
                  '5. Quyền của bạn',
                  'Bạn có thể xuất toàn bộ dữ liệu và xoá tài khoản ngay trong mục Cá nhân → '
                      'Xuất dữ liệu / Xoá tài khoản. Yêu cầu khác gửi tới privacy@tripflow.vn.',
                ),
                _LegalSection(
                  '6. Thời gian lưu',
                  'Dữ liệu tài khoản được giữ cho tới khi bạn xoá. Nhật ký kỹ thuật và audit được '
                      'giữ tối đa 12 tháng để bảo mật, sau đó xoá hoặc ẩn danh.',
                ),
                _LegalSection(
                  '7. Trẻ em',
                  'TripFlow không hướng tới người dùng dưới 13 tuổi. Nếu phát hiện dữ liệu trẻ em '
                      'được gửi lên, chúng tôi sẽ xoá.',
                ),
              ],
            ),
            _LegalPage(
              title: 'Giấy phép dữ liệu & ảnh',
              updated: 'Cập nhật: 07/11/2026',
              sections: [
                _LegalSection(
                  '1. Ảnh địa điểm',
                  'Phần lớn ảnh đến từ Wikimedia Commons với giấy phép CC BY, CC BY-SA hoặc CC0. '
                      'Tên tác giả, giấy phép và liên kết nguồn được hiển thị ở trang chi tiết địa '
                      'điểm. Khi tái sử dụng, bạn phải giữ ghi công và chia sẻ tương tự theo giấy phép.',
                ),
                _LegalSection(
                  '2. Bản đồ',
                  'Bản đồ mặc định dùng dữ liệu OpenStreetMap (ODbL) và tile OpenStreetMap. Khi cấu '
                      'hình Goong Maps, dữ liệu bản đồ tuân theo điều khoản của Goong.',
                ),
                _LegalSection(
                  '3. Dữ liệu địa điểm',
                  'Toạ độ, tên đường và một phần thông tin lấy từ OpenStreetMap (ODbL) và Wikipedia '
                      '(CC BY-SA). Dữ liệu biên tập của TripFlow được tổng hợp từ nguồn công khai.',
                ),
                _LegalSection(
                  '4. Biểu tượng & giao diện',
                  'Biểu tượng Material Icons (Apache 2.0), font hệ thống và thiết kế giao diện do '
                      'TripFlow thực hiện.',
                ),
                _LegalSection(
                  '5. Báo lỗi bản quyền',
                  'Nếu bạn là chủ sở hữu và cho rằng nội dung/ảnh được dùng sai, gửi thông tin tới '
                      'legal@tripflow.vn. Chúng tôi sẽ kiểm tra và gỡ trong thời gian hợp lý.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalPage extends StatelessWidget {
  final String title;
  final String updated;
  final List<_LegalSection> sections;

  const _LegalPage({
    required this.title,
    required this.updated,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          updated,
          style: const TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 16),
        for (final section in sections) ...[
          Text(
            section.heading,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            section.body,
            style: const TextStyle(
              fontSize: 12.8,
              height: 1.55,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.coral.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.coral.withValues(alpha: 0.25)),
          ),
          child: const Text(
            'Liên hệ: privacy@tripflow.vn · legal@tripflow.vn\n'
            'TripFlow — công cụ lập lộ trình, tìm quán ăn và điểm nghỉ chân.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _LegalSection {
  final String heading;
  final String body;

  const _LegalSection(this.heading, this.body);
}
