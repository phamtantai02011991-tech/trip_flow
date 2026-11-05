import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/app_state.dart';
import '../../core/utils/data_models.dart';
import '../../core/utils/external_launcher.dart';
import 'ota_partner_hub_screen.dart';

/// Màn hình Danh sách Khách sạn, Homestay & Resort (Super App Service 1)
class HotelsScreen extends StatefulWidget {
  final TripFlowAppState appState;

  const HotelsScreen({super.key, required this.appState});

  @override
  State<HotelsScreen> createState() => _HotelsScreenState();
}

class _HotelsScreenState extends State<HotelsScreen> {
  String _selectedType = 'all'; // 'all' | 'resort' | 'homestay' | 'hotel' | 'villa'
  String _priceRange = 'all'; // 'all' | 'under_1m' | '1m_to_3m' | 'above_3m'
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final allHotels = widget.appState.hotelsForDisplay;

    // Lọc theo danh mục, tầm giá và từ khóa
    final filteredHotels = allHotels.where((hotel) {
      if (_selectedType != 'all' && hotel.hotelType != _selectedType) {
        return false;
      }
      if (_priceRange == 'under_1m' && hotel.pricePerNightVnd >= 1000000) {
        return false;
      }
      if (_priceRange == '1m_to_3m' &&
          (hotel.pricePerNightVnd < 1000000 || hotel.pricePerNightVnd > 3000000)) {
        return false;
      }
      if (_priceRange == 'above_3m' && hotel.pricePerNightVnd <= 3000000) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = hotel.name.toLowerCase().contains(q);
        final matchAddress = hotel.address.toLowerCase().contains(q);
        final matchProvince = hotel.provinceName.toLowerCase().contains(q);
        if (!matchName && !matchAddress && !matchProvince) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Khách Sạn & Homestay',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              widget.appState.isNationalMode
                  ? 'Toàn quốc 🇻🇳 • ${filteredHotels.length} nơi lưu trú'
                  : '${widget.appState.selectedProvince.name} • ${filteredHotels.length} nơi lưu trú',
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
            icon: const Icon(Icons.handshake_outlined, color: Color(0xFF10B981)),
            tooltip: 'Đối tác Agoda & Booking',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OtaPartnerHubScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_outline_rounded),
            tooltip: 'Phòng đã đặt',
            onPressed: () => _showMyBookings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm resort, homestay săn mây, villa...',
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // 2. Chips lọc loại hình
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('Tất cả', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('🏖️ Resort cao cấp', 'resort'),
                const SizedBox(width: 8),
                _buildFilterChip('☁️ Homestay săn mây', 'homestay'),
                const SizedBox(width: 8),
                _buildFilterChip('🏨 Khách sạn 4-5★', 'hotel'),
                const SizedBox(width: 8),
                _buildFilterChip('🏡 Villa biệt lập', 'villa'),
              ],
            ),
          ),

          // 3. Chips lọc giá
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildPriceChip('Mọi mức giá', 'all'),
                const SizedBox(width: 8),
                _buildPriceChip('< 1.000.000đ', 'under_1m'),
                const SizedBox(width: 8),
                _buildPriceChip('1 - 3 triệu', '1m_to_3m'),
                const SizedBox(width: 8),
                _buildPriceChip('> 3.000.000đ', 'above_3m'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 4. Danh sách Khách sạn
          Expanded(
            child: filteredHotels.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hotel_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Chưa tìm thấy khách sạn phù hợp',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Hãy thử chọn bộ lọc khác hoặc chuyển sang chế độ "Toàn quốc 🇻🇳"',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filteredHotels.length,
                    itemBuilder: (context, index) {
                      final hotel = filteredHotels[index];
                      return _HotelCard(
                        hotel: hotel,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => HotelDetailScreen(
                                hotel: hotel,
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

  Widget _buildFilterChip(String label, String value) {
    final active = _selectedType == value;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) => setState(() => _selectedType = value),
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

  Widget _buildPriceChip(String label, String value) {
    final active = _priceRange == value;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) => setState(() => _priceRange = value),
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

  void _showMyBookings(BuildContext context) {
    final bookings = widget.appState.hotelBookings;
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
                        'Phòng Đã Đặt Của Bạn',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${bookings.length} phiếu đặt',
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
                          'Bạn chưa có phiếu đặt phòng nào.\nHãy chọn khách sạn và nhấn "Đặt phòng ngay"!',
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        b.hotelName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
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
                                  'Phòng: ${b.roomName} • ${b.guests} khách',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                Text(
                                  'Ngày: ${b.checkInDate} -> ${b.checkOutDate}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Mã Voucher: ${b.voucherCode}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFFF4B55),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      AppConfig.formatVnd(b.totalPrice),
                                      style: const TextStyle(
                                        fontSize: 14,
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

class _HotelCard extends StatelessWidget {
  final HotelModel hotel;
  final VoidCallback onTap;

  const _HotelCard({required this.hotel, required this.onTap});

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
            // Ảnh Hero Khách Sạn
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      hotel.heroImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFE2E8F0),
                        child: const Icon(Icons.landscape_rounded, color: Colors.grey),
                      ),
                    ),
                  ),
                  // Gradient mờ chân ảnh
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
                  // Badge Loại hình
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        hotel.hotelType == 'resort'
                            ? '🏖️ Resort'
                            : hotel.hotelType == 'homestay'
                                ? '☁️ Homestay'
                                : '🏨 Khách Sạn',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Badge Rating sao
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 4),
                          Text(
                            '${hotel.rating} (${hotel.reviewCount})',
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          hotel.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hotel.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Địa chỉ
                  Row(
                    children: [
                      const Icon(Icons.place_rounded, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hotel.address,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Tiện nghi nổi bật
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: hotel.amenities.take(3).map((a) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          a,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Quick Actions: Gọi lễ tân, Chỉ đường, So giá Agoda
                  Row(
                    children: [
                      // Nút Gọi Lễ Tân
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            foregroundColor: const Color(0xFF0F172A),
                          ),
                          icon: const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF10B981)),
                          label: const Text('Gọi lễ tân', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          onPressed: () => ExternalLauncher.makePhoneCall(context, hotel.phone),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Nút Chỉ đường
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          foregroundColor: const Color(0xFF0F172A),
                        ),
                        icon: const Icon(Icons.navigation_outlined, size: 14, color: Color(0xFF2563EB)),
                        label: const Text('Đường đi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        onPressed: () => ExternalLauncher.openMapNavigation(
                          context: context,
                          latitude: hotel.latitude,
                          longitude: hotel.longitude,
                          destinationName: hotel.name,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Nút So giá Agoda
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => ExternalLauncher.openOtaPartner(
                          context: context,
                          partnerName: 'Agoda',
                          affiliateUrl: 'https://www.agoda.com?cid=1928472&tag=tripflow',
                          promoCode: 'AGODA_TRIPFLOW',
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Text(
                            'So giá Agoda',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Giá và nút xem chi tiết
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hotel.originalPriceDisplay.isNotEmpty)
                            Text(
                              hotel.originalPriceDisplay,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF94A3B8),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            hotel.priceDisplay,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFF4B55),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Xem phòng',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
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

/// Màn hình Chi tiết Khách sạn & Đặt phòng E-Voucher
class HotelDetailScreen extends StatelessWidget {
  final HotelModel hotel;
  final TripFlowAppState appState;

  const HotelDetailScreen({
    super.key,
    required this.hotel,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Sliver App Bar với ảnh lớn
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    hotel.heroImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFFCBD5E1)),
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

          // Nội dung chi tiết
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên khách sạn & Rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          hotel.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFD97706)),
                            const SizedBox(width: 4),
                            Text(
                              '${hotel.rating}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Địa chỉ & Hotline
                  Row(
                    children: [
                      const Icon(Icons.place_rounded, size: 16, color: Color(0xFFFF4B55)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hotel.address,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone_in_talk_rounded, size: 15, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        'Hotline đặt bàn / hỗ trợ: ${hotel.hotline}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Giới thiệu
                  const Text(
                    'Giới Thiệu Nơi Nghỉ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hotel.description.isNotEmpty
                        ? hotel.description
                        : 'Không gian nghỉ dưỡng lý tưởng với đầy đủ tiện ích sang trọng, gần các điểm tham quan nổi tiếng.',
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: Color(0xFF334155),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tiện ích & Dịch vụ
                  const Text(
                    'Tiện Ích & Dịch Vụ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: hotel.amenities.map((a) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 14, color: Color(0xFF10B981)),
                            const SizedBox(width: 6),
                            Text(
                              a,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Danh sách phòng
                  const Text(
                    'Danh Sách Phòng Khả Dụng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...hotel.rooms.map((room) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              room.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.bed_rounded, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${room.bedInfo} • Tối đa ${room.maxGuests} người',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  room.priceDisplay,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFFF4B55),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () => _openBookingDialog(context, room),
                            child: const Text('Chọn', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  }),
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
                  const Text('Giá từ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  Text(
                    hotel.priceDisplay,
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  final firstRoom = hotel.rooms.isNotEmpty
                      ? hotel.rooms.first
                      : HotelRoomModel(
                          id: 99,
                          name: 'Phòng Tiêu Chuẩn',
                          priceVnd: hotel.pricePerNightVnd,
                          maxGuests: 2,
                          bedInfo: '1 Giường King',
                          imageUrl: hotel.heroImage,
                        );
                  _openBookingDialog(context, firstRoom);
                },
                icon: const Icon(Icons.flash_on_rounded, size: 18),
                label: const Text(
                  'Đặt Phòng Ngay',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBookingDialog(BuildContext context, HotelRoomModel room) {
    final nameController = TextEditingController(
      text: appState.userName.contains('Guest') ? 'Nguyễn Văn Du Khách' : appState.userName,
    );
    final phoneController = TextEditingController(
      text: appState.userPhone.isNotEmpty ? appState.userPhone : '0987654321',
    );
    int nights = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateModal) {
            final totalAmount = room.priceVnd * nights;
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
                      'Xác Nhận Đặt Phòng • ${hotel.name}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hạng phòng: ${room.name} (${room.bedInfo})',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),

                    // Họ và tên
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Họ và tên người nhận phòng',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Số điện thoại
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại nhận E-Voucher SMS',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Chọn số đêm
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Số đêm lưu trú:',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: nights > 1
                                  ? () => setStateModal(() => nights--)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '$nights đêm',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            IconButton(
                              onPressed: () => setStateModal(() => nights++),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    // Tổng tiền & nút xác nhận
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tổng thanh toán:',
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            final voucherCode =
                                'TF-HTL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                            final booking = HotelBookingRecord(
                              bookingId: 'BK-${DateTime.now().millisecondsSinceEpoch}',
                              hotelId: hotel.id,
                              hotelName: hotel.name,
                              roomName: room.name,
                              checkInDate: '14:00 hôm nay',
                              checkOutDate: '12:00 sau $nights đêm',
                              guests: room.maxGuests,
                              customerName: nameController.text.trim(),
                              customerPhone: phoneController.text.trim(),
                              totalPrice: totalAmount,
                              voucherCode: voucherCode,
                              createdAt: 'Vừa xong',
                            );
                            appState.bookHotel(booking);
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

  void _showSuccessDialog(BuildContext context, HotelBookingRecord booking) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                child: const Icon(Icons.check_rounded, color: Color(0xFF15803D), size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Đặt Phòng Thành Công!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Mã E-Voucher của bạn:\n${booking.voucherCode}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF4B55),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Khách sạn: ${booking.hotelName}\nHạng phòng: ${booking.roomName}\nĐã gửi tin nhắn xác nhận tới ${booking.customerPhone}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
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
