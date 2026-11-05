import 'package:flutter/material.dart';
import '../../core/services/biker_safety_repository.dart';
import '../../core/utils/data_models.dart';
import '../../core/utils/external_launcher.dart';

/// Màn hình Trung Tâm Đối Tác OTA & Đặt Dịch Vụ (Agoda, Booking, Vexere, Traveloka, Klook)
class OtaPartnerHubScreen extends StatelessWidget {
  const OtaPartnerHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final partners = BikerSafetyRepository.otaPartners;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Liên Kết Đối Tác Đặt Chỗ',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner cam kết giá tốt & tích hợp đối tác
          _buildHeroPartnerBanner(),
          const SizedBox(height: 16),

          const Text(
            'Đối Tác Chính Thức Của TripFlow',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Chọn đối tác bạn tin dùng để hưởng trọn vẹn ưu đãi độc quyền dành riêng cho thành viên TripFlow.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          // Danh sách các thẻ đối tác OTA
          ...partners.map((partner) => _buildPartnerCard(context, partner)),
          const SizedBox(height: 20),

          // Lợi ích khi đặt qua liên kết TripFlow
          _buildBenefitSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeroPartnerBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'TIẾT KIỆM ĐẾN 15%',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'Mạng Lưới Đối Tác Toàn Diện',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Đặt Dịch Vụ Nhanh Chóng\nQua Các Nền Tảng Hàng Đầu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'TripFlow liên kết trực tiếp với Vexere, Agoda, Booking.com, Traveloka và Klook để mang lại sự tiện lợi, an tâm và giá ưu đãi nhất cho mỗi chuyến đi của bạn.',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerCard(BuildContext context, OtaPartnerModel partner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(partner.iconEmoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner.partnerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      partner.discountTag,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            partner.description,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number_outlined, size: 16, color: Color(0xFFFF4B55)),
                const SizedBox(width: 8),
                Text(
                  'Mã ưu đãi: ${partner.promoCode}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Tự động sao chép',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(
                'Mở ${partner.partnerName} & Áp Mã',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              onPressed: () => ExternalLauncher.openOtaPartner(
                context: context,
                partnerName: partner.partnerName,
                affiliateUrl: partner.affiliateUrl,
                promoCode: partner.promoCode,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, color: Color(0xFF2563EB), size: 18),
              SizedBox(width: 8),
              Text(
                'Quyền Lợi Độc Quyền Khi Đặt Qua TripFlow',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• Giữ nguyên mọi quyền lợi hội viên và tích điểm của các ứng dụng đối tác.\n'
            '• Hoàn tiền bổ sung vào ví điểm TripCoins cho chuyến đi sau.\n'
            '• Đồng bộ tự động mã xác nhận và thời gian khởi hành vào Lịch Trình TripFlow.',
            style: TextStyle(color: Color(0xFF1E40AF), fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

