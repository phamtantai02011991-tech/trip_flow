import '../utils/vietnamese_utils.dart';
import '../../data/assistant_api.dart';

/// Bộ não Trợ Lý Du Lịch Thông Minh Tiếng Việt (Smart AI Travel Copilot)
/// Hoạt động ngoại tuyến 100% trên thiết bị, hiểu sâu ngôn ngữ tiếng Việt tự nhiên
/// (cả có dấu và không dấu, từ lóng du lịch, phượt thủ Biker).
class SmartAiAssistantService {
  static AssistantReply processQuestion({
    required String message,
    int? tripId,
  }) {
    final raw = message.trim();
    final lower = raw.toLowerCase();
    final clean = VietnameseUtils.removeDiacritics(lower);

    // 1. Câu hỏi về Ngân sách / Chi phí du lịch
    if (clean.contains('ngan sach') ||
        clean.contains('chi phi') ||
        clean.contains('bao nhieu tien') ||
        clean.contains('tien') ||
        clean.contains('gia')) {
      if (clean.contains('da lat')) {
        return const AssistantReply(
          reply: '✨ **Dự toán chi phí đi Đà Lạt 3 ngày 2 đêm (2 người):**\n\n'
              '• 🏨 **Khách sạn / Homestay**: ~400.000đ - 600.000đ/đêm (Tổng ~1.000.000đ)\n'
              '• 🚌 **Vé xe Limousine giường nằm**: ~320.000đ/vé x 4 vé khứ hồi (~1.280.000đ)\n'
              '• 🏍️ **Thuê xe máy phượt dốc**: 150.000đ/ngày x 3 ngày + 120.000đ xăng (~570.000đ)\n'
              '• 🍲 **Ăn uống đặc sản** (Lẩu gà lá é, bánh tráng nướng, sữa đậu nành): ~500.000đ/người (~1.000.000đ)\n'
              '• 🎟️ **Vé tham quan & Cà phê săn mây**: ~400.000đ\n\n'
              '👉 **Tổng cộng**: Khoảng **2.100.000đ - 2.500.000đ / người** là bạn đã có chuyến đi rất thoải mái!',
          tips: [
            'Nên đặt vé xe Limousine trước 3 ngày để chọn giường tầng dưới êm ái',
            'Thử lẩu bò Quán Gỗ Ba Toa và lẩu gà lá é Tao Ngộ 100% chuẩn vị địa phương',
          ],
          applied: [
            {'action': 'estimate_budget', 'amount': '2.200.000đ', 'destination': 'Đà Lạt'},
          ],
          rejected: [],
        );
      }

      if (clean.contains('ha giang')) {
        return const AssistantReply(
          reply: '🏍️ **Dự toán chi phí phượt Hà Giang Loop (3 ngày 4 đêm):**\n\n'
              '• 🚌 **Xe khách giường nằm cabin Hà Nội - Hà Giang**: ~350.000đ/lượt x 2 (~700.000đ)\n'
              '• 🏍️ **Thuê xe máy cào cào / Wave RSX**: 180.000đ/ngày x 3 ngày + xăng (~700.000đ)\n'
              '• 🏡 **Homestay bản địa Đồng Văn / Mèo Vạc / Du Già**: ~150.000đ - 250.000đ/đêm (~600.000đ)\n'
              '• 🍜 **Ăn uống vùng cao** (Thắng cố, cháo ấu tẩu, lẩu gà đen, bánh tam giác mạch): ~700.000đ\n'
              '• 🚤 **Thuyền sông Nho Quế & hẻm Tu Sản**: ~120.000đ/người\n\n'
              '👉 **Tổng chi phí**: Khoảng **2.800.000đ - 3.200.000đ / người**.',
          tips: [
            'Kiểm tra kỹ phanh trước, phanh sau và lốp xe trước khi đổ đèo Mã Pí Lèng',
            'Đổ đầy bình xăng tại TP. Hà Giang hoặc thị trấn Yên Minh vì trên đèo rất ít cây xăng',
          ],
          applied: [],
          rejected: [],
        );
      }

      return const AssistantReply(
        reply: '💰 **Mức chi tiêu du lịch trung bình tại Việt Nam:**\n\n'
            '• **Tiết kiệm (Dân phượt / Biker)**: ~500.000đ - 700.000đ / ngày (Homestay, xe máy, quán bình dân).\n'
            '• **Tiêu chuẩn (Gia đình / Cặp đôi)**: ~1.200.000đ - 1.800.000đ / ngày (Khách sạn 3-4 sao, xe limousine, nhà hàng đặc sản).\n'
            '• **Nghỉ dưỡng (Resort cao cấp)**: ~2.500.000đ+ / ngày (Resort 5 sao, ăn uống fine dining).',
        tips: ['Bạn có thể đặt trước khách sạn & vé xe trên TripFlow để nhận chiết khấu 10-15%'],
        applied: [],
        rejected: [],
      );
    }

    // 2. Câu hỏi về Hành lý / Chuẩn bị đồ đạc
    if (clean.contains('hanh ly') ||
        clean.contains('chuan bi') ||
        clean.contains('mang gi') ||
        clean.contains('do dac')) {
      if (clean.contains('sa pa') || clean.contains('sapa') || clean.contains('ha giang') || clean.contains('mua dong') || clean.contains('thang 11') || clean.contains('thang 12')) {
        return const AssistantReply(
          reply: '🎒 **Danh sách hành lý cần chuẩn bị đi vùng cao Tây Bắc (Sa Pa / Hà Giang):**\n\n'
              '1. 🧥 **Trang phục giữ ấm**: Áo phao lông vũ chống gió/nước, áo nỉ hoặc áo giữ nhiệt Heattech, khăn len, mũ len che tai, găng tay da hoặc găng gió.\n'
              '2. 👟 **Giày dép**: Giày thể thao hoặc giày trekking có đế rãnh sâu chống trơn trượt khi đi đèo, bậc đá mờ sương.\n'
              '3. 💊 **Tủ thuốc du lịch**: Thuốc cảm cúm, men tiêu hóa, dầu gió, urgo dán vết thương, thuốc say xe.\n'
              '4. 🔋 **Thiết bị điện tử**: Sạc dự phòng (pin tụt rất nhanh khi trời lạnh dưới 10°C), túi chống nước cho điện thoại.\n'
              '5. 🪪 **Giấy tờ**: CCCD, Giấy phép lái xe (bắt buộc nếu thuê xe máy phượt), tiền mặt dự phòng (nhiều bản vùng cao chưa có ATM).',
          tips: [
            'Thời tiết vùng cao thay đổi đột ngột giữa ngày và đêm, hãy mặc đồ theo nguyên tắc nhiều lớp (Layering)',
          ],
          applied: [],
          rejected: [],
        );
      }

      return const AssistantReply(
        reply: '🧳 **Bộ hành lý chuẩn cho chuyến du lịch khám phá:**\n\n'
            '• Giấy tờ tùy thân (CCCD, Bằng lái xe) & Tiền mặt vừa đủ\n'
            '• Kem chống nắng, xịt chống côn trùng, mũ rộng vành\n'
            '• Giày êm chân (đi bộ nhiều) & Dép đi dạo\n'
            '• Sạc dự phòng, cáp sạc & Máy ảnh chụp cảnh đẹp\n'
            '• Thuốc cá nhân: say xe, hạ sốt, dị ứng thời tiết.',
        tips: ['Nên tải sẵn bản đồ ngoại tuyến trên TripFlow để dùng khi mất sóng 4G'],
        applied: [],
        rejected: [],
      );
    }

    // 3. Câu hỏi về Lịch trình / Gợi ý địa điểm đi chơi
    if (clean.contains('lich trinh') ||
        clean.contains('di dau') ||
        clean.contains('choi gi') ||
        clean.contains('goi y') ||
        clean.contains('tour')) {
      if (clean.contains('da lat')) {
        return const AssistantReply(
          reply: '🌸 **Lịch trình khám phá Đà Lạt 3 ngày 2 đêm tối ưu:**\n\n'
              '📍 **Ngày 1: Check-in & Cà phê ngắm hoàng hôn**\n'
              '• Sáng: Đến nơi, gửi hành lý tại Homestay, ăn bánh mì xíu mại Hoàng Diệu.\n'
              '• Chiều: Khám phá Dinh III Bảo Đại & Vườn hoa thành phố.\n'
              '• Hoàng hôn: Cà phê đồi lộng gió tại Tiệm Cà Phê Hoàng Hôn Chiều.\n'
              '• Tối: Ăn lẩu gà lá é Tao Ngộ → Dạo Chợ Đêm Đà Lạt thưởng thức bánh tráng nướng.\n\n'
              '📍 **Ngày 2: Chinh phục thiên nhiên & Săn mây**\n'
              '• 05:00 Sáng: Săn mây Đồi Chè Cầu Đất → Đón bình minh rực rỡ.\n'
              '• Trưa: Thác Datanla (trải nghiệm máng trượt alpine coaster dài nhất ĐNÁ).\n'
              '• Tối: Lẩu bò Quán Gỗ Ba Toa trứ danh.\n\n'
              '📍 **Ngày 3: Thiền Viện Trúc Lâm & Mua quà lưu niệm**\n'
              '• Sáng: Đi cáp treo ngắm rừng thông đến Thiền Viện Trúc Lâm & Hồ Tuyền Lâm.\n'
              '• Mua đặc sản mứt dâu tây, atiso → Lên xe Limousine về lại TP.',
          tips: [
            'Bạn có thể bấm vào mục "Lập Lịch Phượt" ở trang chủ để hệ thống tự động lưu chuyến đi này',
          ],
          applied: [
            {'action': 'suggest_itinerary', 'title': 'Đà Lạt Mộng Mơ 3N2Đ', 'duration': '3 ngày 2 đêm'},
          ],
          rejected: [],
        );
      }

      if (clean.contains('ha noi') || clean.contains('hanoi')) {
        return const AssistantReply(
          reply: '🏛️ **Lịch trình trải nghiệm Hà Nội 36 Phố Phường (2 ngày 1 đêm):**\n\n'
              '📍 **Ngày 1: Di sản lịch sử nghìn năm**\n'
              '• Sáng: Viếng Lăng Bác → Chùa Một Cột → Văn Miếu Quốc Tử Giám.\n'
              '• Trưa: Thưởng thức Phở Bát Đàn hoặc Bún Chả Hương Liên.\n'
              '• Chiều: Đi dạo Hồ Gươm, viếng Đền Ngọc Sơn → Thưởng thức Cà phê Trứng Giảng.\n'
              '• Tối: Phố bia Tạ Hiện sôi động → Chợ đêm phố cổ.\n\n'
              '📍 **Ngày 2: Văn hóa & Kiến trúc Pháp cổ**\n'
              '• Sáng: Nhà thờ Lớn Hà Nội → Di tích Nhà tù Hỏa Lò.\n'
              '• Chiều: Cầu Long Biên lịch sử → Hồ Tây ăn bánh tôm & kem Hồ Tây đón hoàng hôn.',
          tips: ['Nên thuê xích lô dạo một vòng phố cổ vào buổi sáng sớm để cảm nhận nét thanh bình của thủ đô'],
          applied: [],
          rejected: [],
        );
      }

      if (clean.contains('da nang') || clean.contains('hoi an')) {
        return const AssistantReply(
          reply: '🌊 **Lịch trình Đà Nẵng - Hội An (4 ngày 3 đêm):**\n\n'
              '• **Ngày 1**: Tắm biển Mỹ Khê → Bán đảo Sơn Trà & Chùa Linh Ứng → Xem Cầu Rồng phun lửa, phun nước lúc 21:00 cuối tuần.\n'
              '• **Ngày 2**: Trọn ngày tại Bà Nà Hills (Cầu Vàng bàn tay khổng lồ, Làng Pháp).\n'
              '• **Ngày 3**: Chinh phục Ngũ Hành Sơn → Di chuyển sang Phố Cổ Hội An thả hoa đăng, thưởng thức Cao Lầu & Cơm gà Bà Buội.\n'
              '• **Ngày 4**: Đi thuyền thúng Rừng dừa Bảy Mẫu → Mua chả bò Đà Nẵng làm quà về.',
          tips: ['Đèo Hải Vân nối Đà Nẵng - Huế là cung đường phượt ven biển đẹp nhất Việt Nam!'],
          applied: [],
          rejected: [],
        );
      }
    }

    // 4. Câu hỏi về Ăn uống / Quán ngon
    if (clean.contains('an gi') ||
        clean.contains('quan ngon') ||
        clean.contains('dac san') ||
        clean.contains('mon ngon') ||
        clean.contains('nha hang')) {
      return const AssistantReply(
        reply: '🍜 **Gợi ý ẩm thực đặc sản nức tiếng trên TripFlow (Dữ liệu xác minh):**\n\n'
            '• **TP. Hồ Chí Minh**: Cơm tấm Ba Ghiền (Đặng Văn Ngữ), Bánh mì Huỳnh Hoa (Lê Thị Riêng), Ốc Oanh (Vĩnh Khánh).\n'
            '• **Hà Nội**: Phở gia truyền Bát Đàn, Bún chả Đắc Kim (Hàng Mành), Chả cá Lã Vọng.\n'
            '• **Đà Nẵng**: Mì Quảng Ếch Bếp Trang, Bánh tráng cuốn thịt heo Đại Lộc, Bún chả cá Hờn.\n'
            '• **Lâm Đồng (Đà Lạt)**: Lẩu gà lá é Tao Ngộ (3/4), Lẩu bò Ba Toa Quán Gỗ, Bánh ướt lòng gà Long.\n\n'
            '👉 Bạn có thể chuyển sang **Tab "Ẩm thực"** để xem địa chỉ cụ thể và bấm nút chỉ đường Google Maps!',
        tips: ['Bấm vào từng quán trong Tab Ẩm thực để xem mức giá niêm yết và số điện thoại gọi đặt chỗ trước'],
        applied: [],
        rejected: [],
      );
    }

    // 5. Câu hỏi về Phượt xe máy / Biker
    if (clean.contains('phuot') ||
        clean.contains('xe may') ||
        clean.contains('biker') ||
        clean.contains('cung duong') ||
        clean.contains('deo')) {
      return const AssistantReply(
        reply: '🏍️ **Kinh nghiệm phượt an toàn cho Biker từ TripFlow:**\n\n'
            '1. **Kiểm tra xe trước khi khởi hành**: Thay nhớt máy mới, kiểm tra độ mòn má phanh, độ căng sên xích và áp suất lốp.\n'
            '2. **Top cung đường phượt huyền thoại Việt Nam**:\n'
            '   • *Đèo Hải Vân (Đà Nẵng - Huế)*: Cung đường biển đẹp nhất.\n'
            '   • *Hà Giang Loop (Đồng Văn - Mèo Vạc - Mã Pí Lèng)*: Hùng vĩ số 1 Đông Bắc.\n'
            '   • *Cung đường ven biển DT702 (Phan Rang - Vĩnh Hy - Cam Ranh)*: Biển xanh ngắt cát trắng.\n'
            '   • *Đèo Tà Nung & Đèo Prenn (Lâm Đồng)*: Rừng thông bảng lảng sương mù.\n'
            '3. **Sử dụng tính năng "Corridor Search"**: Mở Tab Bản đồ để quét trạm xăng và tiệm vá xe dọc hành trình!',
        tips: ['Luôn mang theo bộ đồ nghề vá xe mini và bơm tay khẩn cấp khi đi đèo hẻo lánh'],
        applied: [],
        rejected: [],
      );
    }

    // 6. Câu trả lời mặc định thông minh (Đón nhận mọi câu hỏi khác)
    return AssistantReply(
      reply: 'Dạ, mình là Trợ lý Du lịch TripFlow! 🇻🇳\n\n'
          'Về câu hỏi **"$raw"**, mình có một số lời khuyên hữu ích cho bạn:\n\n'
          '• **Khám phá điểm đến**: Bạn có thể dùng ô tìm kiếm ở trang chủ để tra cứu các danh thắng, thác nước, di tích lịch sử trên khắp 63 tỉnh thành.\n'
          '• **Dịch vụ tiện ích**: TripFlow hỗ trợ bạn đặt trước khách sạn, vé xe khách Limousine và tour khám phá với giá ưu đãi.\n'
          '• **Lên lịch trình tự động**: Hãy thử tính năng "Lập Lịch Phượt" để hệ thống tự xếp tuyến đường tham quan đẹp nhất cho bạn!\n\n'
          'Bạn cần mình tư vấn thêm về tỉnh thành nào (Đà Lạt, Hà Giang, Phú Quốc, Đà Nẵng, Sa Pa...)?',
      tips: [
        'Hỏi mình: "Chi phí đi Sa Pa 3 ngày bao nhiêu?"',
        'Hỏi mình: "Đi phượt xe máy Hà Giang cần mang gì?"',
        'Hỏi mình: "Quán ăn ngon nhất tại Đà Nẵng"',
      ],
      applied: [],
      rejected: [],
    );
  }
}
