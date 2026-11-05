# 🌊 TRIPFLOW — MASTER DOCUMENTATION & HỆ THỐNG TOÀN DIỆN

> **Phiên bản hệ thống**: 1.1.0  
> **Định vị sản phẩm**: Super App Du Lịch, Đặt Dịch Vụ, Lập Lịch Trình & Khám Phá Ẩm Thực Toàn Diện Việt Nam  
> **Nền tảng hỗ trợ**: Android (Pixel 8 Pro API 36+), iOS, Web Dashboard, Backend API  
> **Trạng thái kiểm thử**: ✅ 14/14 Automated Tests Passed (100%)

---

## 📌 PHẦN 1: TỔNG QUAN DỰ ÁN & KIẾN TRÚC HỆ THỐNG

**TripFlow** là nền tảng du lịch thông minh thế hệ mới dành riêng cho thị trường Việt Nam. Ứng dụng giải quyết triệt để sự phân mảnh giữa việc **tìm kiếm thông tin điểm đến**, **lên kế hoạch lịch trình di chuyển**, **khám phá ẩm thực quán ngon thực tế** và **đặt dịch vụ lưu trú / vé xe / tour du lịch**.

```
                           ┌─────────────────────────────────────────┐
                           │      TRIPFLOW TRAVEL ECOSYSTEM          │
                           └────────────────────┬────────────────────┘
                                                │
         ┌──────────────────────────────────────┼──────────────────────────────────────┐
         ▼                                      ▼                                      ▼
┌──────────────────┐                  ┌──────────────────┐                  ┌──────────────────┐
│  📱 MOBILE APP   │                  │  🚀 FASTAPI API  │                  │  💻 ADMIN WEB    │
│  (Flutter Client)│                  │   (Core Backend) │                  │   (React + Vite) │
├──────────────────┤                  ├──────────────────┤                  ├──────────────────┤
│• Riverpod State  │◄── REST API / ──►│• Geo-Filtering   │◄── Management ──►│• Quản lý POI     │
│• Material 3 UI   │    JSON Cache    │• AI Itinerary    │    Dashboard     │• Duyệt bài viết  │
│• Flutter Map GIS │                  │• Data Normalizer │                  │• Thống kê doanh  │
│• Hive Offline DB │                  │• Crawler Ingest  │                  │  thu đối tác     │
└──────────────────┘                  └──────────────────┘                  └──────────────────┘
```

### Kiến Trúc Kỹ Thuật (Tech Stack)

| Phân hệ | Công nghệ cốt lõi | Vai trò & Trách nhiệm |
| :--- | :--- | :--- |
| **Mobile Client** | **Flutter 3.x / Dart 3** | Ứng dụng di động đa nền tảng, thiết kế Editorial chuẩn Anti-AI-Slop, độ phân giải cao, tối ưu 60fps trên Android Pixel 8 Pro. |
| **State Management** | **Flutter Riverpod + ChangeNotifier** | Quản trị trạng thái toàn cục reactive: Bộ lọc toàn quốc / 63 tỉnh thành, giỏ đặt phòng, vé xe, danh sách yêu thích và lịch trình. |
| **Bản đồ & Định vị** | **Flutter Map + Goong Maps / OSM** | Bản đồ tương tác ngoại tuyến, vẽ polyline tuyến đường, tính toán hành lang (Corridor Bounding Box). |
| **Lưu trữ cục bộ** | **Hive NoSQL + SharedPreferences** | Lưu trữ bộ đệm offline (Offline-First), khôi phục phiên đăng nhập và dữ liệu đã tải khi mất mạng. |
| **Backend Server** | **Python FastAPI + SQLModel (PostgreSQL)** | Cung cấp RESTful API hiệu năng cao, thuật toán chuẩn hóa dữ liệu địa lý lãnh thổ Việt Nam. |
| **Web Dashboard** | **React 18 + Vite + Tailwind CSS** | Bảng điều hành dành cho quản trị viên và đối tác quản lý điểm đến, voucher và đối soát giao dịch. |

---

## 🚀 PHẦN 2: NHỮNG GÌ DỰ ÁN ĐÃ LÀM VÀ ĐANG CÓ (FEATURES IMPLEMENTED)

### 1. Chế Độ Toàn Quốc 🇻🇳 & Bộ Lọc 63 Tỉnh Thành Linh Hoạt
- **Bỏ mặc định TP. Hồ Chí Minh**: Ứng dụng khởi động mặc định ở chế độ **`Toàn quốc 🇻🇳 — Khám Phá Việt Nam`**, tập hợp các điểm đến, món ngon và tour tiêu biểu trên khắp cả nước.
- **Bộ chọn tỉnh thành thông minh**: Tích hợp Modal Bottom Sheet cho phép người dùng chuyển đổi ngay lập tức sang bất kỳ tỉnh thành nào (Hà Nội, Đà Nẵng, Lâm Đồng, Hà Giang, Phú Quốc...) với độ trễ 0ms.

### 2. Bộ Nhận Diện Thương Hiệu Cao Cấp (Brand Identity Hero Header)
- Thiết kế nền **Slate 900 (`#0F172A`)** sang trọng, độ tương phản cao, chống lóa khi dùng ngoài trời.
- Huy hiệu **TRIPFLOW** (Coral `#FF4B55`) & tag **SUPER APP** (`#38BDF8`).
- **Hotline CSKH 24/7 (`1900 6868`)**: Tích hợp trình quay số 1 chạm (`ExternalLauncher.makePhoneCall`).
- **Dải Trust Badges xác minh**: `63 Tỉnh/Thành` • `1.200+ Điểm đến` • `100% Xác minh`.

### 3. Hệ Sinh Thái 5 Trụ Cột Dịch Vụ Du Lịch & Phượt

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                             5 DỊCH VỤ CỐT LÕI TRIPFLOW                           │
├────────────────────┬────────────────────┬───────────────────┬────────────────────┤
│   🏨 KHÁCH SẠN     │   🎫 VÉ XE & TÀU   │   🗺️ TOUR TUYỂN    │  🏍️ LẬP LỊCH PHƯỢT │
│   Resort & Stay    │   Limousine & Bay  │   Trekking mạo    │  Xuyên Việt & Biker│
│   E-Voucher QR     │   E-Ticket QR      │   hiểm có HDV     │  Corridor POIs     │
├────────────────────┴────────────────────┴───────────────────┴────────────────────┤
│                       🍜 ẨM THỰC QUÁN NGON THỰC TẾ                               │
│       Dữ liệu cào Google Maps, giá niêm yết, món phải thử & gọi đặt bàn          │
└──────────────────────────────────────────────────────────────────────────────────┘
```

1. **Khách Sạn & Homestay (`HotelsScreen`)**:
   - Tìm kiếm và lọc theo loại hình: Resort nghỉ dưỡng, Homestay săn mây, Khách sạn 4-5 sao, Villa biệt lập.
   - Lọc theo mức giá: Dưới 1 triệu, 1 - 3 triệu, Trên 3 triệu.
   - Thẻ thông tin trực quan: Ảnh Hero, đánh giá sao, địa chỉ, tiện nghi nổi bật (Hồ bơi vô cực, BBQ, Wifi tốc độ cao).
   - Nút **"Gọi lễ tân"** 1 chạm + Nút **"Chỉ đường"** Google Maps + Nút **"So giá Agoda"**.
   - Quy trình đặt phòng & sinh mã **E-Voucher** lưu vào sổ tay cá nhân.
2. **Vé Xe, Tàu & Máy Bay (`TransportScreen`)**:
   - Đặt vé Limousine 24-34 phòng VIP (Phương Trang FUTA, Thành Bưởi, Hoa Mai).
   - Đặt vé Tàu hỏa Bắc - Nam SE1 (Khoang 4 giường nằm mềm).
   - Đặt vé Máy bay nội địa (Vietnam Airlines, Vietjet Air).
   - Lọc theo điểm đi / điểm đến và hạng ghế.
   - Quy trình xuất vé điện tử **E-Ticket có mã QR** mô phỏng để quét lên xe.
3. **Tour & Trải Nghiệm Tuyển Chọn (`ToursScreen`)**:
   - Các tour mạo hiểm và văn hóa: Trekking Fansipan Sa Pa, Chinh phục Tà Năng - Phan Dũng, Vòng cung Hà Giang Loop, Lặn ngắm san hô Nam Đảo Phú Quốc.
   - Hiển thị chi tiết độ khó (Dễ / Vừa phải / Thử thách), lịch trình từng ngày và thông tin trưởng đoàn / hotline hướng dẫn viên.
4. **Lập Lịch Trình Phượt Biker Corridor (`PlannerWizardScreen`)**:
   - Chọn số ngày đi: 1 ngày trong phố, 2 ngày 1 đêm, 3 ngày 2 đêm, Chuyến đi Xuyên Việt.
   - Chọn phương tiện: Xe máy phượt đường dài, Ô tô tự lái, Xe khách liên tỉnh.
   - Thuật toán Corridor Search: Tự động quét và hiển thị các trạm xăng Petrolimex, tiệm sửa xe máy, trạm dừng chân và điểm ngắm cảnh đèo dọc theo cung đường.
5. **Ẩm Thực & Món Ngon Thực Tế (`RestaurantsScreen` & `LocalFoodsScreen`)**:
   - Dữ liệu thực tế chuẩn hóa từ internet: Tên quán, địa chỉ chính xác, tọa độ GPS, số hotline, giờ mở cửa, phân khúc giá (bình dân đến cao cấp).
   - Đánh giá chân thực trích dẫn từ Google Maps Reviews.
   - Nút **"Gọi đặt bàn"** và **"Chỉ đường"** trực tiếp.

### 4. Trung Tâm Liên Kết Đối Tác OTA Toàn Cầu (`OtaPartnerHubScreen`)
TripFlow đóng vai trò là Hub liên kết đối tác, giúp khách hàng nhận được giá tốt nhất và hưởng trọn vẹn ưu đãi độc quyền:
- **Vexere**: Đối tác đặt vé xe khách liên tỉnh #1 Việt Nam — Mã ưu đãi: `VEXERE_TF15` (Giảm 15.000đ/vé).
- **Agoda**: Mạng lưới 40.000+ khách sạn & resort quốc tế — Mã: `AGODA_TRIPFLOW` (Giảm thêm 10%).
- **Booking.com**: Đặt phòng thanh toán tại quầy không cần cọc — Mã: `BOOKING_TF` (Hoàn tiền 5%).
- **Traveloka**: Vé máy bay nội địa & quốc tế — Mã: `TVLK_TRIPFLOW` (Giảm 50.000đ/chặng).
- **Klook**: Vé tham quan Sun World Bà Nà Hills, Fansipan Legend, VinWonders — Mã: `KLOOK_TF20` (Giảm 8%).
- **Cơ chế 1 chạm**: Bấm mở đối tác -> Ứng dụng tự động sao chép mã ưu đãi vào clipboard và mở trang đặt chỗ với tracking ID của TripFlow.

### 5. Tiện Ích Trợ Lý AI & Quản Lý Chi Tiêu
- **Trợ lý TripFlow (`AssistantScreen`)**: Chatbot tư vấn lịch trình, gợi ý trang phục theo thời tiết và mẹo tiết kiệm chi phí.
- **Sổ tay Chi tiêu (`ExpensesScreen`)**: Theo dõi thu chi từng ngày trong chuyến đi, phân bổ ngân sách ăn uống, vé xe, lưu trú.
- **Bản đồ Tương tác (`MapCorridorScreen`)**: Hiển thị vị trí người dùng, bán kính tìm kiếm địa điểm lân cận.

---

## 🛠️ PHẦN 3: CÁC VIỆC CẦN LÀM SAU (NEXT STEPS & ROADMAP)

Để đưa TripFlow từ phiên bản hoàn thiện tính năng lên quy mô **Sản phẩm Thương Mại Hóa (Production Commercial Grade)**, dưới đây là lộ trình các hạng mục cần triển khai tiếp theo:

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                          LỘ TRÌNH PHÁT TRIỂN TIẾP THEO                         │
├────────────────────┬────────────────────┬──────────────────────────────────────┤
│  PHASE 2 (Ưu tiên) │  PHASE 3 (Mở rộng) │  PHASE 4 (Quy mô lớn)                │
│  Thanh Toán & Mã   │  Đối Tác B2B &     │  Cộng Đồng, GPX &                    │
│  Giảm Giá Thật     │  Quét Mã QR        │  Định Vị Nhóm Realtime               │
└────────────────────┴────────────────────┴──────────────────────────────────────┘
```

### 1. Giai Đoạn 2: Tích Hợp Cổng Thanh Toán Thực Tế (Payment Engine)
- [ ] **Tích hợp SDK Thanh toán nội địa**:
  - Cổng **VNPay QR** (Quét mã thanh toán trên 35+ ứng dụng ngân hàng Việt Nam).
  - Ví điện tử **MoMo** và **ZaloPay** (App-to-App payment flow).
  - Cổng quốc tế Stripe / PayOS cho thẻ Visa, Mastercard, JCB.
- [ ] **Bộ đếm thời gian giữ chỗ (Holding Timer - 15 phút)**:
  - Khi người dùng bấm "Đặt phòng" hoặc "Chọn ghế xe", hệ thống tạm khóa ghế trong 15 phút để chờ giao dịch hoàn tất, tự động nhả ghế nếu hết thời gian thanh toán.
- [ ] **Bảo hiểm Du lịch Tích Hợp (Micro-Insurance)**:
  - Tích hợp API bảo hiểm du lịch (Bảo Việt, PVI) bán kèm gói bảo hiểm tai nạn cá nhân / trễ chuyến giá chỉ từ 15.000đ - 30.000đ/người khi thanh toán vé.
- [ ] **Hệ thống Điểm thưởng Tích lũy (TripCoins Loyalty)**:
  - Tích lũy 2% - 5% giá trị đơn hàng vào ví điểm TripCoins để trừ tiền trực tiếp cho các chuyến đi tiếp theo.

### 2. Giai Đoạn 3: Cổng Dành Cho Đối Tác & Quét Mã QR Check-in (Merchant Portal)
- [ ] **Ứng dụng / Trang Web Đối Tác (Merchant Validator)**:
  - Nhân viên khách sạn hoặc phụ xe dùng camera điện thoại quét mã QR trên E-Voucher / E-Ticket của khách hàng để chuyển trạng thái thành *"Đã sử dụng (Redeemed)"*.
- [ ] **Đồng bộ API B2B thời gian thực (Direct API Sync)**:
  - Kết nối trực tiếp với **Vexere Open API** (`api.vexere.com`) để lấy số ghế trống và sơ đồ giường nằm thời gian thực.
  - Kết nối **Agoda Supply API / Hotelbeds API** để đồng bộ giá phòng theo mùa cao điểm/thấp điểm.
- [ ] **Bảng điều khiển Đối soát Doanh thu (Vendor Settlement Dashboard)**:
  - Tự động thống kê doanh thu, hoa hồng đại lý và tạo phiếu thanh toán định kỳ hàng tuần cho các nhà xe và homestay.

### 3. Giai Đoạn 4: Tính Năng Mạng Xã Hội, GPX & Bản Đồ Phượt Nâng Cao
- [ ] **Định vị Đoàn Phượt Thời Gian Thực (Live Group Tracking)**:
  - Trưởng đoàn tạo phòng (Group Ride Code), các thành viên gia nhập sẽ thấy chấm vị trí GPS của nhau trên bản đồ: nắm rõ ai dẫn đầu, ai dừng nghỉ, ai bị tụt lại phía sau.
- [ ] **Hỗ trợ Tải File GPX / KML Ngoại Tuyến**:
  - Cho phép xuất file tọa độ hành trình `.GPX` nạp vào các thiết bị định vị Garmin, đồng hồ thể thao Suunto/Coros hoặc app dẫn đường ngoại tuyến.
- [ ] **Thị Trường Lịch Trình Mẫu Từ Cộng Đồng (Community Itinerary Hub)**:
  - Người dùng có thể chia sẻ lịch trình 3N2Đ Hà Giang, 2N1Đ Đà Lạt của mình lên cộng đồng; người khác chỉ cần bấm 1 nút *"Áp dụng lịch trình này"* là tự động điền toàn bộ điểm đến vào chuyến đi của họ.
- [ ] **Đánh giá Đã Xác Thực (Verified Traveler Reviews)**:
  - Cho phép người dùng đăng ảnh, video ngắn và đánh giá chất lượng; gắn nhãn tích xanh *"Đã trải nghiệm thực tế qua TripFlow"* để chống đánh giá ảo.

---

## 💻 PHẦN 4: HƯỚNG DẪN CÀI ĐẶT & CHẠY DỰ ÁN

### 1. Ứng Dụng Di Động (Flutter Mobile App)
```bash
# Kiểm tra dependencies
flutter pub get

# Chạy toàn bộ bộ kiểm thử tự động
flutter test

# Khởi chạy ứng dụng lên thiết bị ảo (hoặc máy thật)
flutter run -d emulator-5554

# Đóng gói APK cài đặt
flutter build apk --debug
# File xuất xưởng tại: build/app/outputs/flutter-apk/app-debug.apk
```

### 2. Máy Chủ Backend (FastAPI API)
```bash
cd backend

# Kích hoạt môi trường ảo Python
.\venv\Scripts\activate

# Cài đặt thư viện
pip install -r requirements.txt

# Khởi chạy server FastAPI tại cổng 8000
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
# API Docs Swagger UI: http://localhost:8000/docs
```

### 3. Bảng Điều Hành Quản Trị (Admin Web)
```bash
cd admin-web

# Cài đặt packages
npm install

# Khởi chạy môi trường phát triển Vite
npm run dev
# Dashboard mở tại: http://localhost:5173
```

---

*Tài liệu được cập nhật tự động và đồng bộ trực tiếp cùng mã nguồn dự án TripFlow.*

