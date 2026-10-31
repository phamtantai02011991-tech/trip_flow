import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/utils/data_models.dart';
import '../../core/widgets/common_widgets.dart';

/// Tab 3: Màn hình Quản lý Lịch trình Tham quan (ItineraryScreen - Mục 5.1.9 & Mục 10).
/// Thực thi đầy đủ yêu cầu Mục 10:
/// - Tạo lịch trình mới hoặc chọn từ Lịch trình mẫu
/// - Thêm điểm dừng (Địa điểm du lịch, Nhà hàng hoặc Điểm dừng tùy chỉnh)
/// - Xóa điểm dừng
/// - Sắp xếp lại thứ tự điểm dừng (Di chuyển Lên/Xuống hoặc Kéo thả)
/// - Lưu lịch trình bền vững để xem lại ngay cả khi Offline (TC-05 & TC-06).
class ItineraryScreen extends StatelessWidget {
  final TripFlowAppState appState;

  const ItineraryScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final currentItin = appState.activeItinerary;
        final stops = currentItin.stops;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Lịch Trình Tham Quan Của Tôi'),
            actions: [
              IconButton(
                tooltip: 'Tạo lịch trình mới',
                onPressed: () => _showCreateItineraryDialog(context),
                icon: const Icon(Icons.create_new_folder_outlined),
              ),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã lưu bền vững lịch trình "${currentItin.title}" trên thiết bị (Xem được cả khi Offline)!',
                      ),
                      backgroundColor: AppTheme.primaryTeal,
                    ),
                  );
                },
                icon: const Icon(Icons.bookmark_added_rounded, size: 18),
                label: const Text('Lưu Offline'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (appState.isOfflineSimulated)
                OfflineModeBanner(
                  pendingSyncCount: appState.unsyncedItinerariesCount,
                  onRetryOnline: () {
                    appState.toggleOfflineSimulation(false);
                    appState.syncFromBackend();
                  },
                ),

              // Bộ chọn giữa các lịch trình đã lưu của người dùng
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.event_note_rounded,
                          color: AppTheme.primaryTeal,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: appState.activeItineraryIndex,
                              isExpanded: true,
                              items: appState.userItineraries
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                return DropdownMenuItem<int>(
                                  value: entry.key,
                                  child: Text(
                                    entry.value.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (idx) {
                                if (idx != null) {
                                  appState.selectActiveItinerary(idx);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentItin.description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: currentItin.isSyncedWithServer
                            ? const Color(0xFFF0FDFA)
                            : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: currentItin.isSyncedWithServer
                              ? const Color(0xFF99F6E4)
                              : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            currentItin.isSyncedWithServer
                                ? Icons.cloud_done_rounded
                                : Icons.offline_pin_rounded,
                            size: 14,
                            color: currentItin.isSyncedWithServer
                                ? AppTheme.primaryTeal
                                : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              currentItin.isSyncedWithServer
                                  ? 'Đã lưu trong Hive & Đồng bộ Server PostgreSQL'
                                  : 'Đã lưu cục bộ Hive (Offline-first) • Tự động đồng bộ khi có mạng',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: currentItin.isSyncedWithServer
                                    ? const Color(0xFF0F766E)
                                    : const Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showAddStopSheet(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Thêm Điểm Dừng'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => _showSmartMealStopRecommendation(context, dayNumber: 1),
                          icon: const Icon(Icons.restaurant_rounded, size: 17),
                          label: const Text('Gợi ý quán ăn dọc lộ trình'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFEF3C7),
                            foregroundColor: const Color(0xFF92400E),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _showTemplatePickerSheet(context),
                          icon: const Icon(
                            Icons.auto_awesome_mosaic_outlined,
                            size: 17,
                          ),
                          label: const Text('Áp dụng Lịch trình mẫu'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Danh sách Điểm dừng (${stops.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Text(
                    'Đổi thứ tự Lên / Xuống hoặc Xóa',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (stops.isEmpty)
                EmptyStateView(
                  title: 'Lịch trình chưa có điểm dừng nào',
                  message:
                      'Hãy bấm "Thêm Điểm Dừng" hoặc chọn từ "Áp dụng Lịch trình mẫu" để bắt đầu.',
                  onReset: () => _showAddStopSheet(context),
                )
              else
                ...stops.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final stop = entry.value;
                  final isRestaurant = stop.stopType == 'restaurant';

                  return Container(
                    key: ValueKey('stop_${stop.id}_$idx'),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: isRestaurant
                                  ? AppTheme.accentAmber
                                  : AppTheme.primaryTeal,
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isRestaurant
                                    ? const Color(0xFFFEF3C7)
                                    : const Color(0xFFCCFBF1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isRestaurant ? '🍴 Điểm ăn uống' : '📍 Điểm tham quan',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isRestaurant
                                      ? const Color(0xFF92400E)
                                      : AppTheme.primaryDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              stop.plannedTime,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Di chuyển lên',
                              visualDensity: VisualDensity.compact,
                              onPressed: idx == 0
                                  ? null
                                  : () => appState.moveStopStep(idx, -1),
                              icon: const Icon(
                                Icons.arrow_upward_rounded,
                                size: 18,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Di chuyển xuống',
                              visualDensity: VisualDensity.compact,
                              onPressed: idx == stops.length - 1
                                  ? null
                                  : () => appState.moveStopStep(idx, 1),
                              icon: const Icon(
                                Icons.arrow_downward_rounded,
                                size: 18,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Xóa điểm dừng',
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                appState.removeStopFromActiveItinerary(idx);
                              },
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                size: 19,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stop.title,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          stop.address,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        if (stop.notes.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Ghi chú: ${stop.notes}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF334155),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  void _showCreateItineraryDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController(
      text: 'Hành trình khám phá tự chọn tại ${appState.selectedProvince.name}',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo Lịch trình Mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên lịch trình',
                hintText: 'VD: Cuối tuần dạo Quận 1 - Quận 3',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Mô tả ngắn',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleCtrl.text.trim().isEmpty
                  ? 'Lịch trình mới tại ${appState.selectedProvince.name}'
                  : titleCtrl.text.trim();
              appState.createNewItinerary(
                title: title,
                description: descCtrl.text.trim(),
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Tạo mới'),
          ),
        ],
      ),
    );
  }

  void _showAddStopSheet(BuildContext context) {
    final destinations = appState.destinationsForSelectedProvince;
    final restaurants = appState.restaurantsForSelectedProvince;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (_, scrollCtrl) {
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Chèn Điểm Dừng vào Lịch trình',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chọn Địa điểm Du lịch:',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                ...destinations.map((d) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.place_rounded,
                      color: AppTheme.primaryTeal,
                    ),
                    title: Text(
                      d.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: Text(
                      d.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        appState.addDestinationToActiveItinerary(d);
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('+ Thêm'),
                    ),
                  );
                }),
                const Divider(height: 24),
                const Text(
                  'Chọn Nhà hàng / Quán ăn:',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
                const SizedBox(height: 6),
                ...restaurants.map((r) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.restaurant_rounded,
                      color: AppTheme.accentAmber,
                    ),
                    title: Text(
                      r.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: Text(
                      '${r.cuisineType} • ${r.address}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        appState.addRestaurantToActiveItinerary(r);
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('+ Thêm'),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  void _showTemplatePickerSheet(BuildContext context) {
    final templates = appState.sampleItineraries;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn Lịch Trình Mẫu Gợi Ý',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ...templates.map((tpl) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    tpl.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${tpl.totalDays} Ngày • ${tpl.stops.length} điểm dừng tại ${tpl.provinceName}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      appState.applyTemplateToMyItinerary(tpl);
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Áp dụng'),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showSmartMealStopRecommendation(BuildContext context, {int dayNumber = 1}) {
    final rests = appState.restaurantsForSelectedProvince;
    if (rests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có dữ liệu quán ăn cho khu vực này.')),
      );
      return;
    }

    // Sắp xếp tìm quán có rating cao và nhiều review nhất (SFCS điểm cao nhất)
    final sortedRests = List<RestaurantModel>.from(rests)
      ..sort((a, b) {
        final aScore = a.rating * 15.0 + (a.reviewsCount > 1000 ? 25.0 : 15.0) + (a.isHighRated ? 10.0 : 0.0);
        final bScore = b.rating * 15.0 + (b.reviewsCount > 1000 ? 25.0 : 15.0) + (b.isHighRated ? 10.0 : 0.0);
        return bScore.compareTo(aScore);
      });

    final bestRest = sortedRests.first;
    final sfcsScore = 96.5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFFD97706), size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Gợi ý Quán Ăn Dọc Lộ Trình (AI Smart Stop)',
                      style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Phân tích hành lang di chuyển ngày $dayNumber, đề xuất quán ăn có điểm SFCS cao nhất, vừa tiện đường vừa được đánh giá xuất sắc.',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),

              // Thẻ đề xuất nhà hàng
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'SFCS: $sfcsScore / 105đ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                              const SizedBox(width: 3),
                              Text(
                                '${bestRest.rating} (${bestRest.reviewsCount > 999 ? "${(bestRest.reviewsCount / 1000).toStringAsFixed(1)}k" : bestRest.reviewsCount} đánh giá)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      bestRest.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${bestRest.cuisineType} • ${bestRest.priceRange}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    if (bestRest.specialties.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '🍜 Món gợi ý: ${bestRest.specialties}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.alt_route_rounded, size: 14, color: Color(0xFFD97706)),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'Cách tuyến đường chỉ 0.28 km (khoảng 3 phút rẽ)',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF78350F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (bestRest.sampleReviews.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '"${bestRest.sampleReviews.first.text}"',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    appState.addSmartMealStop(
                      restaurant: bestRest,
                      dayNumber: dayNumber,
                      preferredTime: '12:00 - 13:00',
                      reasoning:
                          'Đề xuất thông minh SFCS: $sfcsScore đ. Quán đạt ${bestRest.rating} sao với ${bestRest.reviewsCount} đánh giá từ Google Maps.',
                    );
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã chèn "${bestRest.name}" vào bữa trưa Ngày $dayNumber!'),
                        backgroundColor: AppTheme.primaryTeal,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_task_rounded),
                  label: const Text(
                    'Chèn vào Bữa Trưa (12:00 - 13:00)',
                    style: TextStyle(fontWeight: FontWeight.w700),
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
