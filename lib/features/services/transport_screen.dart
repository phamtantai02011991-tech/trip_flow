import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/app_state.dart';
import '../../core/utils/data_models.dart';
import '../../core/utils/external_launcher.dart';
import 'ota_partner_hub_screen.dart';

/// Màn hình Đặt vé Giao Thông: Xe khách Limousine, Tàu hỏa Bắc-Nam, Vé máy bay (Super App Service 2)
class TransportScreen extends StatefulWidget {
  final TripFlowAppState appState;

  const TransportScreen({super.key, required this.appState});

  @override
  State<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFromCity = 'all';
  String _selectedToCity = 'all';

  final List<String> _cities = [
    'Tất cả',
    'TP. Hồ Chí Minh',
    'Hà Nội',
    'Đà Nẵng',
    'Đà Lạt (Lâm Đồng)',
    'Sa Pa (Lào Cai)',
    'Phú Quốc',
    'Cố đô Huế',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTickets = widget.appState.transportTicketsForDisplay;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Vé Xe, Tàu & Máy Bay',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.handshake_outlined, color: Color(0xFF10B981)),
            tooltip: 'Đối tác Vexere & Traveloka',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OtaPartnerHubScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.confirmation_number_outlined),
            tooltip: 'Vé điện tử của tôi',
            onPressed: () => _showMyTickets(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF4B55),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFFFF4B55),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          tabs: const [
            Tab(text: '🚌 Xe Limousine'),
            Tab(text: '🚆 Tàu Hoả SE'),
            Tab(text: '✈️ Vé Máy Bay'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Bộ lọc Tuyến đi / Tuyến đến
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedFromCity,
                    decoration: InputDecoration(
                      labelText: 'Điểm đi',
                      prefixIcon: const Icon(Icons.trip_origin_rounded,
                          size: 16, color: Color(0xFF10B981)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    items: _cities.map((c) {
                      return DropdownMenuItem(
                        value: c == 'Tất cả' ? 'all' : c,
                        child: Text(c,
                            style: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedFromCity = val);
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.swap_horiz_rounded,
                      color: Color(0xFF64748B), size: 20),
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedToCity,
                    decoration: InputDecoration(
                      labelText: 'Điểm đến',
                      prefixIcon: const Icon(Icons.location_on_rounded,
                          size: 16, color: Color(0xFFFF4B55)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    items: _cities.map((c) {
                      return DropdownMenuItem(
                        value: c == 'Tất cả' ? 'all' : c,
                        child: Text(c,
                            style: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedToCity = val);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Danh sách chuyến vận chuyển theo Tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTripList(allTickets, 'bus'),
                _buildTripList(allTickets, 'train'),
                _buildTripList(allTickets, 'flight'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripList(List<TransportTicketModel> tickets, String type) {
    final filtered = tickets.where((t) {
      if (t.type != type) return false;
      if (_selectedFromCity != 'all' &&
          !t.fromCity.toLowerCase().contains(_selectedFromCity.toLowerCase())) {
        return false;
      }
      if (_selectedToCity != 'all' &&
          !t.toCity.toLowerCase().contains(_selectedToCity.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type == 'bus'
                    ? Icons.directions_bus_filled_rounded
                    : type == 'train'
                        ? Icons.train_rounded
                        : Icons.flight_takeoff_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Không tìm thấy chuyến đi phù hợp',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hãy thử chọn "Tất cả" tại điểm đi hoặc điểm đến để xem các tuyến khác.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final ticket = filtered[index];
        return _TransportCard(
          ticket: ticket,
          onSelect: () => _openBookingDialog(context, ticket),
        );
      },
    );
  }

  void _openBookingDialog(BuildContext context, TransportTicketModel ticket) {
    final nameController = TextEditingController(
      text: widget.appState.userName.contains('Guest')
          ? 'Nguyễn Văn Du Khách'
          : widget.appState.userName,
    );
    final phoneController = TextEditingController(
      text: widget.appState.userPhone.isNotEmpty
          ? widget.appState.userPhone
          : '0987654321',
    );
    String selectedSeat = 'Phòng 08 (Tầng 1)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
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
                  'Đặt Vé • ${ticket.operatorName}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tuyến: ${ticket.fromCity} ➔ ${ticket.toCity} (${ticket.vehicleCode})',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                Text(
                  'Giờ khởi hành: ${ticket.departureTime} • Hạng ghế: ${ticket.seatClass}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 16),

                // Họ và tên hành khách
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Họ và tên hành khách',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Số điện thoại nhận E-Ticket
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại nhận vé điện tử SMS',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Chọn vị trí ngồi
                DropdownButtonFormField<String>(
                  initialValue: selectedSeat,
                  decoration: InputDecoration(
                    labelText: 'Vị trí ghế / phòng',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    'Phòng 08 (Tầng 1)',
                    'Phòng 10 (Tầng 1)',
                    'Phòng 12 (Tầng 2 View Đẹp)',
                    'Ghế 14A (Gần Cửa Sổ)',
                  ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) selectedSeat = val;
                  },
                ),

                const Divider(height: 24),

                // Giá vé & Nút xuất vé
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Giá vé niêm yết:',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF64748B))),
                        Text(
                          ticket.priceDisplay,
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
                        final ticketCode =
                            'ETKT-${ticket.vehicleCode}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                        final booking = TransportBookingRecord(
                          bookingId: 'TBK-${DateTime.now().millisecondsSinceEpoch}',
                          ticketId: ticket.id,
                          operatorName: ticket.operatorName,
                          fromCity: ticket.fromCity,
                          toCity: ticket.toCity,
                          departureTime: ticket.departureTime,
                          seatClass: ticket.seatClass,
                          passengerName: nameController.text.trim(),
                          passengerPhone: phoneController.text.trim(),
                          totalPrice: ticket.priceVnd,
                          ticketCode: ticketCode,
                          createdAt: 'Vừa xong',
                        );
                        widget.appState.bookTransport(booking);
                        Navigator.of(ctx).pop();
                        _showETicketDialog(context, booking, ticket);
                      },
                      child: const Text('Xác Nhận Xuất Vé',
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
  }

  void _showETicketDialog(
    BuildContext context,
    TransportBookingRecord booking,
    TransportTicketModel ticket,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF15803D), size: 36),
              ),
              const SizedBox(height: 12),
              const Text(
                'Xuất E-Ticket Thành Công!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Mã vé: ${booking.ticketCode}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF4B55),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              // Mock QR Code Representation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_2_rounded,
                        size: 90, color: Color(0xFF0F172A)),
                    const SizedBox(height: 6),
                    Text(
                      'Quét mã khi lên ${ticket.type == 'bus' ? 'xe' : ticket.type == 'train' ? 'tàu' : 'máy bay'}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'Hãng: ${booking.operatorName}\nTuyến: ${booking.fromCity} ➔ ${booking.toCity}\nGiờ khởi hành: ${booking.departureTime}\nHành khách: ${booking.passengerName}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5, color: Color(0xFF334155), height: 1.4),
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

  void _showMyTickets(BuildContext context) {
    final tickets = widget.appState.transportBookings;
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
                        'Vé Điện Tử Của Bạn',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${tickets.length} vé đã mua',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (tickets.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Bạn chưa mua vé xe, tàu hay máy bay nào.\nHãy chọn chuyến đi và nhấn "Chọn vé"!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: tickets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final t = tickets[i];
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
                                        t.operatorName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      t.ticketCode,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFFF4B55),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${t.fromCity} ➔ ${t.toCity}',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Giờ chạy: ${t.departureTime} • Hành khách: ${t.passengerName}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Đã thanh toán E-Ticket',
                                        style: TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xFF10B981),
                                            fontWeight: FontWeight.w700)),
                                    Text(
                                      AppConfig.formatVnd(t.totalPrice),
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

class _TransportCard extends StatelessWidget {
  final TransportTicketModel ticket;
  final VoidCallback onSelect;

  const _TransportCard({required this.ticket, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Logo/Hãng & Mã chuyến
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      ticket.type == 'bus'
                          ? Icons.directions_bus_rounded
                          : ticket.type == 'train'
                              ? Icons.train_rounded
                              : Icons.flight_rounded,
                      size: 16,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ticket.operatorName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ticket.vehicleCode,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Lộ trình & Thời gian di chuyển
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Điểm đi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.departureTime,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ticket.fromCity,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Divider thời gian di chuyển
              Column(
                children: [
                  Text(
                    ticket.durationText,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const SizedBox(
                    width: 70,
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 6, color: Color(0xFF94A3B8)),
                        Expanded(
                            child: Divider(
                                color: Color(0xFFCBD5E1), thickness: 1)),
                        Icon(Icons.arrow_forward_rounded,
                            size: 10, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ),
                ],
              ),

              // Điểm đến
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ticket.arrivalTime,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ticket.toCity,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Hạng ghế & Số ghế trống
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ticket.seatClass,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                Text(
                  'Còn ${ticket.availableSeats} chỗ',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Giá & Nút chọn vé
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ticket.priceDisplay,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF4B55),
                ),
              ),
              Row(
                children: [
                  if (ticket.type == 'bus')
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => ExternalLauncher.openOtaPartner(
                          context: context,
                          partnerName: 'Vexere',
                          affiliateUrl: 'https://vexere.com',
                          promoCode: 'VEXERE_TF15',
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Text(
                            'Qua Vexere',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onSelect,
                child: const Text(
                  'Chọn vé',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
