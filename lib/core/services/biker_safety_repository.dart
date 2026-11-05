import '../utils/data_models.dart';

/// Kho dữ liệu & Dịch vụ Thời tiết an toàn cung đèo & Đối tác OTA
class BikerSafetyRepository {
  BikerSafetyRepository._();

  /// Dữ liệu thời tiết & chỉ số an toàn đèo cập nhật liên tục
  static const List<WeatherSafetyModel> passWeathers = [
    WeatherSafetyModel(
      passName: 'Đèo Hải Vân',
      provinceName: 'Đà Nẵng / TT Huế',
      tempCelsius: 25,
      conditionText: 'Nắng ráo, mây thoáng',
      humidityPercent: 68,
      windSpeedKmH: 18,
      visibilityKm: 9.5,
      safetyLevel: 'safe',
      safetyAdvice: 'Điều kiện lý tưởng để săn mây và chạy cung ven biển. Mặt đường khô ráo.',
      lastUpdated: '10 phút trước',
    ),
    WeatherSafetyModel(
      passName: 'Đèo Mã Pí Lèng',
      provinceName: 'Hà Giang',
      tempCelsius: 15,
      conditionText: 'Sương mù sáng sớm & gió lạnh',
      humidityPercent: 88,
      windSpeedKmH: 26,
      visibilityKm: 1.2,
      safetyLevel: 'caution',
      safetyAdvice: 'Bật đèn pha vàng, giảm tốc độ dưới 30km/h khi qua các góc cua tay áo tử thần.',
      lastUpdated: '15 phút trước',
    ),
    WeatherSafetyModel(
      passName: 'Đèo Ô Quy Hồ',
      provinceName: 'Lào Cai / Lai Châu',
      tempCelsius: 11,
      conditionText: 'Gió giật mạnh & sương mù dày',
      humidityPercent: 92,
      windSpeedKmH: 34,
      visibilityKm: 0.5,
      safetyLevel: 'hazard',
      safetyAdvice: 'Tầm nhìn cực hạn chế (< 500m). Đường trơn do rêu ẩm. Khuyến nghị không đổ đèo sau 18h tối.',
      lastUpdated: '5 phút trước',
    ),
    WeatherSafetyModel(
      passName: 'Đèo Prenn Đà Lạt',
      provinceName: 'Lâm Đồng',
      tempCelsius: 18,
      conditionText: 'Mưa phùn rải rác',
      humidityPercent: 85,
      windSpeedKmH: 14,
      visibilityKm: 4.0,
      safetyLevel: 'caution',
      safetyAdvice: 'Đoạn đường vừa nâng cấp đẹp nhưng dốc cua trơn khi trời mưa. Chú ý giữ khoảng cách phanh.',
      lastUpdated: '12 phút trước',
    ),
    WeatherSafetyModel(
      passName: 'Cung Ven Biển Vũng Tàu - Phan Thiết',
      provinceName: 'Bà Rịa - Bình Thuận',
      tempCelsius: 31,
      conditionText: 'Nắng gắt, gió biển',
      humidityPercent: 62,
      windSpeedKmH: 22,
      visibilityKm: 12.0,
      safetyLevel: 'safe',
      safetyAdvice: 'Đường nhựa phẳng đẹp, lưu ý tiếp đủ nước và trang bị chống nắng đầy đủ.',
      lastUpdated: '20 phút trước',
    ),
  ];

  /// Danh sách Đối tác Đặt dịch vụ & OTA chính thức
  static const List<OtaPartnerModel> otaPartners = [
    OtaPartnerModel(
      id: 'vexere',
      partnerName: 'Vexere',
      category: 'transport',
      discountTag: 'Đối tác xe khách #1 • Giảm 15.000đ',
      promoCode: 'VEXERE_TF15',
      affiliateUrl: 'https://vexere.com?ref=tripflow_partner',
      iconEmoji: '🚌',
      description: 'Hơn 1.000 nhà xe giường nằm, Limousine VIP và xe liên tỉnh toàn quốc. Chọn chỗ ngồi trực quan.',
    ),
    OtaPartnerModel(
      id: 'agoda',
      partnerName: 'Agoda',
      category: 'hotel',
      discountTag: 'Khách sạn quốc tế • Giảm thêm 10%',
      promoCode: 'AGODA_TRIPFLOW',
      affiliateUrl: 'https://www.agoda.com?cid=1928472&tag=tripflow',
      iconEmoji: '🏨',
      description: 'Mạng lưới hơn 40.000 khách sạn, resort nghỉ dưỡng và homestay từ bình dân đến 5 sao sang trọng.',
    ),
    OtaPartnerModel(
      id: 'booking',
      partnerName: 'Booking.com',
      category: 'hotel',
      discountTag: 'Không cần thanh toán trước • Hoàn tiền 5%',
      promoCode: 'BOOKING_TF',
      affiliateUrl: 'https://www.booking.com?aid=239841&label=tripflow_app',
      iconEmoji: '🛎️',
      description: 'Miễn phí hủy phòng đến sát ngày đi. Nhận phòng và thanh toán trực tiếp tại quầy lễ tân.',
    ),
    OtaPartnerModel(
      id: 'traveloka',
      partnerName: 'Traveloka',
      category: 'flight',
      discountTag: 'Vé máy bay & Combo • Giảm 50.000đ',
      promoCode: 'TVLK_TRIPFLOW',
      affiliateUrl: 'https://www.traveloka.com?affId=tripflow_vn',
      iconEmoji: '✈️',
      description: 'So sánh giá vé Vietnam Airlines, Vietjet Air, Bamboo Airways trong 1 giây.',
    ),
    OtaPartnerModel(
      id: 'klook',
      partnerName: 'Klook',
      category: 'tour',
      discountTag: 'Vé tham quan & Tour • Giảm 8%',
      promoCode: 'KLOOK_TF20',
      affiliateUrl: 'https://www.klook.com?aid=88231&label=tripflow',
      iconEmoji: '🎟️',
      description: 'Vé cáp treo Fansipan, Sun World Bà Nà Hills, VinWonders Phú Quốc quét mã vào cổng không xếp hàng.',
    ),
  ];
}

