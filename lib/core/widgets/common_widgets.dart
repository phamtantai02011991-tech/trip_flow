import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../utils/app_state.dart';

/// Nhãn hiển thị nội dung đối tác / tài trợ công khai minh bạch (Mục 12).
class SponsoredBadgeWidget extends StatelessWidget {
  final String? label;

  const SponsoredBadgeWidget({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 13, color: Color(0xFFD97706)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label ?? 'Được tài trợ',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF92400E),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ hiển thị Nguồn dữ liệu, Bản quyền hình ảnh và Thời điểm cập nhật lần cuối (Mục 11 & Mục 15).
class SourceAttributionBanner extends StatelessWidget {
  final String dataSource;
  final String attributionText;
  final String lastUpdatedText;
  final String? licenseText;
  final VoidCallback? onReportIssue;

  const SourceAttributionBanner({
    super.key,
    required this.dataSource,
    required this.attributionText,
    required this.lastUpdatedText,
    this.licenseText,
    this.onReportIssue,
  });

  String get _sourceLabel {
    switch (dataSource) {
      case 'partner':
        return 'Đối tác địa phương cung cấp';
      case 'api_provider':
        return 'Đồng bộ từ Cổng dữ liệu mở / Bản đồ';
      default:
        return 'Dữ liệu Nội bộ TripFlow xác thực';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF99F6E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.fact_check_outlined,
                size: 18,
                color: AppTheme.primaryTeal,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nguồn dữ liệu: $_sourceLabel',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF0F766E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ghi công: $attributionText',
            style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
          ),
          if (licenseText != null && licenseText!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              'Giấy phép nội dung/ảnh: $licenseText',
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cập nhật lần cuối: $lastUpdatedText',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              if (onReportIssue != null)
                TextButton.icon(
                  onPressed: onReportIssue,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.flag_outlined, size: 14),
                  label: const Text(
                    'Báo sai thông tin',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Banner thông báo khi người dùng đang ở chế độ Offline / Mất mạng (Mục 2.2, Pitfall 2 & TC-09).
class OfflineModeBanner extends StatelessWidget {
  final VoidCallback onRetryOnline;
  final int pendingSyncCount;

  const OfflineModeBanner({
    super.key,
    required this.onRetryOnline,
    this.pendingSyncCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              pendingSyncCount > 0
                  ? 'Bạn đang offline — Đang hiển thị dữ liệu từ bộ nhớ đệm Hive ($pendingSyncCount lịch trình chờ đồng bộ).'
                  : 'Bạn đang offline — Đang hiển thị dữ liệu đã lưu trong bộ nhớ đệm (Hive).',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF991B1B),
              ),
            ),
          ),
          TextButton(
            onPressed: onRetryOnline,
            child: const Text(
              'Kết nối & Đồng bộ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị hình ảnh tối ưu qua Cloudinary CDN (`c_fill,w_400,h_300,q_auto,f_auto` hoặc `w_1200,q_auto,f_auto`)
class CloudinaryOptimizedImage extends StatelessWidget {
  final String imageUrl;
  final bool isThumbnail;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CloudinaryOptimizedImage({
    super.key,
    required this.imageUrl,
    this.isThumbnail = true,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = isThumbnail
        ? AppConfig.buildThumbnailUrl(imageUrl)
        : AppConfig.buildDetailUrl(imageUrl);

    return Image.network(
      resolvedUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: const Color(0xFFE2E8F0),
          alignment: Alignment.center,
          child: const Icon(
            Icons.photo_camera_back_outlined,
            color: Color(0xFF64748B),
            size: 28,
          ),
        );
      },
    );
  }
}

/// Banner thông báo khi người dùng từ chối quyền vị trí (Mục 5.3 & TC-09).
class LocationPermissionNotice extends StatelessWidget {
  final VoidCallback onGrantPermission;

  const LocationPermissionNotice({super.key, required this.onGrantPermission});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_disabled_rounded,
            color: Color(0xFFD97706),
            size: 20,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Quyền vị trí đang tắt. Bạn vẫn có thể khám phá và chọn điểm đi/đến thủ công tại TP.HCM.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF92400E),
              ),
            ),
          ),
          TextButton(
            onPressed: onGrantPermission,
            child: const Text(
              'Bật vị trí',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/// Giao diện khi danh sách tìm kiếm/lọc bị rỗng (Mục 5.3 & TC-09).
class EmptyStateView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onReset;

  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            if (onReset != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Xóa bộ lọc & Xem tất cả'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// BottomSheet gửi Báo sai thông tin lên Admin/Moderator (Mục 11).
Future<void> showReportIssueBottomSheet({
  required BuildContext context,
  required TripFlowAppState appState,
  required String targetType,
  required int targetId,
  required String targetName,
}) async {
  String selectedIssue = 'wrong_hours';
  final descController = TextEditingController();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag_rounded, color: Color(0xFFDC2626)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Báo sai thông tin: $targetName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Phản hồi của bạn sẽ được gửi trực tiếp tới Kiểm duyệt viên (Moderator) trên Website Admin để xác minh.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedIssue,
                  decoration: const InputDecoration(
                    labelText: 'Loại vấn đề cần báo cáo',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'wrong_hours',
                      child: Text('Sai giờ mở cửa / Khung giờ hoạt động'),
                    ),
                    DropdownMenuItem(
                      value: 'wrong_price',
                      child: Text('Thay đổi giá vé / Khoảng giá món ăn'),
                    ),
                    DropdownMenuItem(
                      value: 'wrong_location',
                      child: Text('Sai địa chỉ hoặc tọa độ bản đồ'),
                    ),
                    DropdownMenuItem(
                      value: 'closed_permanently',
                      child: Text('Địa điểm / Quán đã đóng cửa'),
                    ),
                    DropdownMenuItem(
                      value: 'review_feedback',
                      child: Text('Góp ý bổ sung thông tin trải nghiệm'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setSheetState(() => selectedIssue = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Chi tiết thông tin cần cập nhật',
                    hintText:
                        'VD: Quán hiện mở cửa từ 07:00 - 21:30, nghỉ trưa 14:00 - 16:00...',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final desc = descController.text.trim().isEmpty
                          ? 'Người dùng đề nghị kiểm tra lại giờ hoạt động thực tế.'
                          : descController.text.trim();
                      await appState.submitReport(
                        targetType: targetType,
                        targetId: targetId,
                        targetName: targetName,
                        issueType: selectedIssue,
                        description: desc,
                      );
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã gửi báo cáo cho "$targetName" tới đội ngũ Admin!',
                            ),
                            backgroundColor: AppTheme.primaryTeal,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Gửi báo cáo xác minh'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
