import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/biker_safety_repository.dart';
import '../../core/utils/data_models.dart';
import '../../core/utils/external_launcher.dart';

/// Màn hình Cứu Hộ Khẩn Cấp Biker SOS 24/7 (Phase 1 Killer Feature)
class BikerSosScreen extends StatefulWidget {
  final String? initialPassName;

  const BikerSosScreen({super.key, this.initialPassName});

  @override
  State<BikerSosScreen> createState() => _BikerSosScreenState();
}

class _BikerSosScreenState extends State<BikerSosScreen> {
  String _selectedFilter = 'Tất cả';
  final double _mockLat = 16.1925;
  final double _mockLng = 108.1317;

  @override
  void initState() {
    super.initState();
    if (widget.initialPassName != null) {
      _selectedFilter = widget.initialPassName!;
    }
  }

  List<BikerEmergencyRescueModel> get _filteredRescues {
    final list = BikerSafetyRepository.emergencyRescues;
    if (_selectedFilter == 'Tất cả') return list;
    return list
        .where((r) =>
            r.passName.toLowerCase().contains(_selectedFilter.toLowerCase()) ||
            r.name.toLowerCase().contains(_selectedFilter.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19), // Nền Dark chuyên dụng giảm chói mắt
      appBar: AppBar(
        backgroundColor: const Color(0xFFDC2626), // Màu đỏ cảnh báo khẩn cấp
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'CỨU HỘ BIKER 24/7',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Gọi Cứu Nạn 112',
            icon: const Icon(Icons.phone_in_talk, color: Colors.white),
            onPressed: () => ExternalLauncher.makePhoneCall(context, '112'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Khung cảnh báo GPS & Trạng thái xe
          _buildGpsStatusCard(),
          const SizedBox(height: 16),

          // 2. Hai nút cứu hộ 1 chạm khẩn cấp nhất
          _buildPrimaryActionRow(),
          const SizedBox(height: 20),

          // 3. Dự báo thời tiết an toàn cung đèo
          _buildWeatherSafetySummary(),
          const SizedBox(height: 20),

          // 4. Tiêu đề danh bạ cứu hộ & Bộ lọc khu vực
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trạm Cứu Hộ Dọc Tuyến',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    dropdownColor: const Color(0xFF1E293B),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả cung đèo')),
                      DropdownMenuItem(value: 'Hải Vân', child: Text('Đèo Hải Vân')),
                      DropdownMenuItem(value: 'Mã Pí Lèng', child: Text('Đèo Mã Pí Lèng')),
                      DropdownMenuItem(value: 'Ô Quy Hồ', child: Text('Đèo Ô Quy Hồ')),
                      DropdownMenuItem(value: 'Prenn', child: Text('Đèo Prenn Đà Lạt')),
                      DropdownMenuItem(value: 'Khau Phạ', child: Text('Đèo Khau Phạ')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedFilter = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 5. Danh sách các trạm cứu hộ
          ..._filteredRescues.map((rescue) => _buildRescueCard(rescue)),
          const SizedBox(height: 24),

          // 6. Cẩm nang an toàn tự xử lý sự cố đèo
          _buildSafetyGuideCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildGpsStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.my_location, color: Color(0xFFEF4444), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TỌA ĐỘ GPS CỨU HỘ HIỆN TẠI',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '16.1925° N, 108.1317° E (Khu vực Đèo Hải Vân)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF334155),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('Sao chép', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: '$_mockLat, $_mockLng (Khu vực Đèo Hải Vân)'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã sao chép tọa độ GPS vào bộ nhớ tạm!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Lưu ý: Bật đèn khẩn cấp Hazard & dắt xe vào sát lề đường để đảm bảo tầm nhìn các phương tiện khác.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionRow() {
    return Row(
      children: [
        // Nút Gọi 1900 6868
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            icon: const Icon(Icons.call, size: 22),
            label: const Text(
              'GỌI 1900 6868\n(Hotline Khẩn Cấp)',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, height: 1.2),
            ),
            onPressed: () => ExternalLauncher.makePhoneCall(context, '19006868'),
          ),
        ),
        const SizedBox(width: 12),
        // Nút Gửi SMS SOS kèm GPS
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706), // Màu vàng hổ phách
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            icon: const Icon(Icons.sms_failed_outlined, size: 22),
            label: const Text(
              'GỬI SMS SOS\n(Kèm GPS vị trí)',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, height: 1.2),
            ),
            onPressed: () {
              const msg =
                  'CỨU HỘ KHẨN CẤP: Tôi đang gặp sự cố xe máy tại khu vực Đèo Hải Vân. Tọa độ GPS: 16.1925, 108.1317. Vui lòng hỗ trợ!';
              ExternalLauncher.sendEmergencySms(
                context: context,
                phone: '19006868',
                message: msg,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherSafetySummary() {
    final weather = BikerSafetyRepository.passWeathers.first;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.wb_sunny_outlined, color: Color(0xFF10B981), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${weather.passName}: ${weather.tempCelsius}°C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'AN TOÀN',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  weather.safetyAdvice,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRescueCard(BikerEmergencyRescueModel rescue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            rescue.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (rescue.is24_7)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '24/7',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rescue.passName,
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rescue.serviceType.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rescue.description,
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.place_outlined, color: Color(0xFF94A3B8), size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  rescue.address,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Nút Gọi ngay
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981), // Màu xanh lá uy tín
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.phone, size: 16),
                  label: Text(
                    'Gọi ${rescue.hotline}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  onPressed: () => ExternalLauncher.makePhoneCall(context, rescue.hotline),
                ),
              ),
              const SizedBox(width: 8),
              // Nút Dẫn đường
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF334155),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.navigation_outlined, size: 16),
                label: const Text('Dẫn đường', style: TextStyle(fontSize: 12)),
                onPressed: () => ExternalLauncher.openMapNavigation(
                  context: context,
                  latitude: rescue.latitude,
                  longitude: rescue.longitude,
                  destinationName: rescue.name,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyGuideCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF475569)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFFF59E0B), size: 18),
              SizedBox(width: 8),
              Text(
                'Quy Tắc An Toàn Khi Gặp Sự Cố Trên Đèo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '1. Đưa xe vào sát lề bên taluy dương (phía vách núi), tuyệt đối không dừng ở taluy âm (vực).\n'
            '2. Bật đèn khẩn cấp Hazard hoặc đặt cành cây/áo phản quang cách đuôi xe 15m để cảnh báo xe đổ đèo.\n'
            '3. Khi đứt xích hoặc cháy phanh: bình tĩnh về số thấp (số 2 hoặc số 1) để hãm động cơ trước khi dừng hẳn.\n'
            '4. Giữ ấm cơ thể và gửi ngay tọa độ GPS qua SMS cho đội cứu hộ.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

