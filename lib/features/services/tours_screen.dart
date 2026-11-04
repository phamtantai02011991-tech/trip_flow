import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/app_state.dart';
import '../../core/utils/data_models.dart';

/// Màn hình Danh mục Tour Du Lịch Tuyển Chọn & Phượt Mạo Hiểm (Super App Service 3)
class ToursScreen extends StatefulWidget {
  final TripFlowAppState appState;

  const ToursScreen({super.key, required this.appState});

  @override
  State<ToursScreen> createState() => _ToursScreenState();
}

class _ToursScreenState extends State<ToursScreen> {
  String _selectedCategory = 'all'; // 'all' | 'trekking' | 'motorbike_loop' | 'diving' | 'culture'
  int _selectedDuration = 0; // 0 = all, 1 = 1 day, 2 = 2-3 days, 4 = 4+ days

  @override
  Widget build(BuildContext context) {
    final allTours = widget.appState.toursForDisplay;

    final filteredTours = allTours.where((tour) {
      if (_selectedCategory != 'all' && tour.category != _selectedCategory) {
        return false;
      }
      if (_selectedDuration == 1 && tour.durationDays != 1) return false;
      if (_selectedDuration == 2 &&
          (tour.durationDays < 2 || tour.durationDays > 3)) {
        return false;
      }
      if (_selectedDuration == 4 && tour.durationDays < 4) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tour & Trải Nghiệm Phượt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              widget.appState.isNationalMode
                  ? 'Tuyển chọn Toàn quốc 🇻🇳 • ${filteredTours.length} hành trình'
                  : '${widget.appState.selectedProvince.name} • ${filteredTours.length} hành trình',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.hiking_rounded),
            tooltip: 'Tour đã đăng ký',
            onPressed: () => _showMyTourBookings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Chips Danh mục
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                _buildCategoryChip('Tất cả', 'all'),
                const SizedBox(width: 8),
                _buildCategoryChip('🥾 Trekking leo núi', 'trekking'),
                const SizedBox(width: 8),
                _buildCategoryChip('🏍️ Phượt xe máy Loop', 'motorbike_loop'),
                const SizedBox(width: 8),
                _buildCategoryChip('🤿 Lặn biển san hô', 'diving'),
                const SizedBox(width: 8),
                _buildCategoryChip('🏮 Văn hoá & Ẩm thực', 'culture'),
              ],
            ),
          ),

          // 2. Chips Thời lượng
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _buildDurationChip('Mọi thời lượng', 0),
                const SizedBox(width: 8),
                _buildDurationChip('1 Ngày', 1),
                const SizedBox(width: 8),
                _buildDurationChip('2 - 3 Ngày', 2),
                const SizedBox(width: 8),
                _buildDurationChip('4+ Ngày', 4),
              ],
            ),
          ),

          // 3. Danh sách Tours
          Expanded(
            child: filteredTours.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.explore_off_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Chưa có tour phù hợp với bộ lọc',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Hãy thử chọn "Tất cả" hoặc chuyển sang chế độ Toàn quốc 🇻🇳.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filteredTours.length,
                    itemBuilder: (context, index) {
                      final tour = filteredTours[index];
                      return _TourCard(
                        tour: tour,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TourDetailScreen(
                                tour: tour,
                                appState: widget.appState,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value) {
    final active = _selectedCategory == value;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) => setState(() => _selectedCategory = value),
      selectedColor: const Color(0xFF0F172A),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: active ? Colors.white : const Color(0xFF475569),
      ),
      side: BorderSide(
        color: active ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildDurationChip(String label, int value) {
    final active = _selectedDuration == value;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) => setState(() => _selectedDuration = value),
      selectedColor: const Color(0xFFFF4B55),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: active ? Colors.white : const Color(0xFF475569),
      ),
      side: BorderSide(
        color: active ? const Color(0xFFFF4B55) : const Color(0xFFE2E8F0),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  void _showMyTourBookings(BuildContext context) {
    final bookings = widget.appState.tourBookings;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tour Đã Đăng Ký',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${bookings.length} tour',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (bookings.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Bạn chưa đăng ký tour trải nghiệm nào.\nHãy chọn tour và bấm "Đặt chỗ ngay"!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: bookings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final b = bookings[i];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        b.tourTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Đã xác nhận',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF15803D),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Ngày khởi hành: ${b.startDate} • Đoàn: ${b.partySize} người',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                Text(
                                  'HDV phụ trách: ${b.guideName} (${b.guidePhone})',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Mã Voucher: ${b.voucherCode}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFFF4B55),
                                      ),
                                    ),
                                    Text(
                                      AppConfig.formatVnd(b.totalAmount),
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
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
}

class _TourCard extends StatelessWidget {
  final TourModel tour;
  final VoidCallback onTap;

  const _TourCard({required this.tour, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh Hero phong cách National Geographic
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      tour.heroImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFE2E8F0),
                        child: const Icon(Icons.landscape_rounded,
                            color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x66000000)],
                          stops: [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Badge Thời lượng
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '⏱️ ${tour.durationText}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Badge Độ khó
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: tour.difficulty.contains('Thử thách')
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tour.difficulty,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Badge Rating
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 4),
                          Text(
                            '${tour.rating} (${tour.reviewCount})',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Nội dung chi tiết
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tour.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Highlights checklist
                  ...tour.highlights.take(2).map((h) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              h,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF475569),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // Giá và nút xem chi tiết
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Trọn gói / người:',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF94A3B8))),
                          Text(
                            tour.priceDisplay,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFF4B55),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Chi tiết tour',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded,
                                size: 14, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Màn hình Chi tiết Tour Trải Nghiệm & Đặt Chỗ
class TourDetailScreen extends StatelessWidget {
  final TourModel tour;
  final TripFlowAppState appState;

  const TourDetailScreen({
    super.key,
    required this.tour,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    tour.heroImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFFCBD5E1)),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black38,
                          Colors.transparent,
                          Colors.black87,
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề & Rating
                  Text(
                    tour.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Huy hiệu tóm tắt
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '⏱️ ${tour.durationText}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: tour.difficulty.contains('Thử thách')
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Độ khó: ${tour.difficulty}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: tour.difficulty.contains('Thử thách')
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Điểm nổi bật
                  const Text(
                    'Trải Nghiệm Nổi Bật',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...tour.highlights.map((h) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              h,
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF334155),
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Lịch trình chi tiết từng ngày
                  const Text(
                    'Lịch Trình Chi Tiết Từng Ngày',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...tour.dailySchedule.map((schedule) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        schedule,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Dịch vụ bao gồm
                  const Text(
                    'Dịch Vụ Đã Bao Gồm',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...tour.inclusions.map((inc) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded,
                              size: 15, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              inc,
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Thông tin Hướng dẫn viên
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFF0F172A),
                          child: Icon(Icons.person_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HDV Trưởng Đoàn: ${tour.guideName}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Hotline tư vấn cung đường: ${tour.guidePhone}',
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Giá trọn gói',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  Text(
                    tour.priceDisplay,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF4B55),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4B55),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _openBookingDialog(context),
                icon: const Icon(Icons.confirmation_num_rounded, size: 18),
                label: const Text(
                  'Đặt Chỗ Tour Ngay',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBookingDialog(BuildContext context) {
    final nameController = TextEditingController(
      text: appState.userName.contains('Guest')
          ? 'Nguyễn Văn Du Khách'
          : appState.userName,
    );
    final phoneController = TextEditingController(
      text: appState.userPhone.isNotEmpty ? appState.userPhone : '0987654321',
    );
    int partySize = 1;
    String selectedDate = 'Thứ Bảy tuần này';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateModal) {
            final totalAmount = tour.priceVnd * partySize;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
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
                    const SizedBox(height: 16),
                    Text(
                      'Đăng Ký Tour • ${tour.title}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Thời lượng: ${tour.durationText} • HDV: ${tour.guideName}',
                      style: const TextStyle(
                          fontSize: 12.5, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),

                    // Họ và tên
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Họ và tên người đại diện',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Số điện thoại
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại liên hệ xác nhận',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Chọn ngày khởi hành & số người
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Số lượng thành viên:',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13.5)),
                        Row(
                          children: [
                            IconButton(
                              onPressed: partySize > 1
                                  ? () => setStateModal(() => partySize--)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('$partySize người',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 14)),
                            IconButton(
                              onPressed: () =>
                                  setStateModal(() => partySize++),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    // Tổng tiền & nút đặt
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tổng chi phí tour:',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B))),
                            Text(
                              AppConfig.formatVnd(totalAmount),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFF4B55),
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            final voucherCode =
                                'TF-TOUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                            final booking = TourBookingRecord(
                              bookingId:
                                  'TRBK-${DateTime.now().millisecondsSinceEpoch}',
                              tourId: tour.id,
                              tourTitle: tour.title,
                              startDate: selectedDate,
                              partySize: partySize,
                              contactName: nameController.text.trim(),
                              contactPhone: phoneController.text.trim(),
                              totalAmount: totalAmount,
                              guideName: tour.guideName,
                              guidePhone: tour.guidePhone,
                              voucherCode: voucherCode,
                              createdAt: 'Vừa xong',
                            );
                            appState.bookTour(booking);
                            Navigator.of(ctx).pop();
                            _showSuccessDialog(context, booking);
                          },
                          child: const Text('Xác Nhận Đặt',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context, TourBookingRecord booking) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Color(0xFF15803D), size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Đăng Ký Tour Thành Công!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Mã Voucher: ${booking.voucherCode}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF4B55),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tour: ${booking.tourTitle}\nĐoàn: ${booking.partySize} người • HDV: ${booking.guideName} (${booking.guidePhone})\nTrưởng đoàn sẽ liên hệ xác nhận chi tiết lịch trình.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
}
