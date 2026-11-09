# 🇻🇳 TripFlow — Nền Tảng Khám Phá Du Lịch, Ẩm Thực & Lên Lộ Trình Thông Minh Toàn Quốc

<div align="center">

![TripFlow Banner](https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1400&q=80)

[![Flutter](https://img.shields.io/badge/Flutter-3.x%20%7C%20Dart-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![.NET](https://img.shields.io/badge/.NET%2010-ASP.NET%20Core%20Web%20API-512BD4?logo=dotnet&logoColor=white)](https://dotnet.microsoft.com)
[![C#](https://img.shields.io/badge/Language-C%23-239120?logo=csharp&logoColor=white)](https://dotnet.microsoft.com)
[![React](https://img.shields.io/badge/React%20Admin-18.x-61DAFB?logo=react&logoColor=black)](https://react.dev)
[![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL%2015-336791?logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![FastAPI](https://img.shields.io/badge/Microservice-Python%20FastAPI-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Goong Maps](https://img.shields.io/badge/Maps-Goong.io%20API-FF6F00)](https://goong.io)
[![Cloudinary](https://img.shields.io/badge/CDN-Cloudinary%20Optimization-3448C5?logo=cloudinary&logoColor=white)](https://cloudinary.com)
[![Backend](https://img.shields.io/badge/Backend%20tests-40%2F40%20PASSED-brightgreen)](#-bảng-nghiệm-thu-22-tiêu-chí-tc-01---tc-22)
[![Flutter](https://img.shields.io/badge/Flutter%20tests-14%2F14%20PASSED-brightgreen)](#-bảng-nghiệm-thu-22-tiêu-chí-tc-01---tc-22)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

<p align="center">
  <b>Khám phá du lịch 10 tỉnh thành • Thuật toán tìm quán ăn ngon dọc lộ trình (Corridor Search) • Đánh giá thực tế từ Google Maps • Lịch trình thông minh Offline-First</b>
</p>

[Khám Phá Tính Năng](#-tính-năng-nổi-bật) • [Kiến Trúc Hệ Thống](#-kiến-trúc-hệ-thống) • [Giao Diện Ứng Dụng](#-giao-diện-ứng-dụng--user-flows) • [Thuật Toán SFCS](#-thuật-toán-smart-food-corridor-score-sfcs) • [Hướng Dẫn Cài Đặt](#-hướng-dẫn-cài-đặt--khởi-chạy)

</div>

---

## 📌 Giới Thiệu Dự Án

**TripFlow** là nền tảng số toàn diện hỗ trợ du khách khám phá di tích lịch sử, cảnh quan thiên nhiên và tinh hoa ẩm thực địa phương tại **10 tỉnh/thành phố du lịch trọng điểm thuộc 4 vùng miền Việt Nam**.

Khác với các ứng dụng bản đồ thông thường chỉ tìm điểm theo bán kính tròn xung quanh vị trí đứng, **TripFlow giải quyết bài toán cốt lõi của du khách khi di chuyển**:
> *"Khi đang đi trên tuyến đường từ điểm A đến điểm B, làm sao tìm được quán ăn ngon nhất, đánh giá cao nhất và có nhiều bình luận chân thực nhất nằm ngay trên hành lang đường đi mà không phải rẽ vòng quá xa?"*

---

## ⚠️ Trạng thái triển khai thực tế (kiểm toán 06/11/2026)

> Báo cáo đầy đủ: **[docs/09-KIEM-TOAN-TRIEN-KHAI.md](docs/09-KIEM-TOAN-TRIEN-KHAI.md)**
> Các số liệu marketing bên dưới (1.200+ điểm đến, 63 tỉnh, "22/22 PASSED" của báo cáo cũ) là mục tiêu ban đầu,
> **không phải** trạng thái đã kiểm chứng. Số liệu thật:

| Hạng mục | Trạng thái thật |
|---|---|
| Backend FastAPI khởi động + seed DB | ✅ Chạy được (đã sửa lỗi SQLModel 0.0.48 thời gian timezone) |
| Bộ test backend | ✅ 40/40 pass trên SQLite; 36/36 trên PostgreSQL 16.2 (gồm Alembic + 2FA) |
| Migration | ✅ Alembic baseline, tự chạy `upgrade head` khi container khởi động |
| Smoke test deploy | ✅ `python tools/smoke_test.py --base-url ...` — 7/7 mục |
| Ứng dụng Flutter | ✅ `dart analyze`: 0 error/warning; 14/14 test pass; build web release OK |
| Admin Web React | ✅ `npm run build` OK; 0 test tự động |
| Dữ liệu catalog | ✅ **10 tỉnh**: **168 địa điểm**, **77 quán ăn/cà phê**, **50 điểm nghỉ chân**; 164/220 bản ghi có ảnh thật + giấy phép |
| Đăng nhập OTP SMS | 🟡 Có API + rate limit; mặc định dùng SMS simulator, cần cấu hình eSMS để chạy thật |
| Bảo mật đăng nhập | ✅ Lockout 5 lần/15 phút + **2FA TOTP** + modal setup trong admin + cờ `REQUIRE_ADMIN_2FA` |
| Pháp lý trong app | 🟡 Điều khoản, Chính sách riêng tư, Giấy phép ảnh/bản đồ; cần ĐKKD + luật sư rà soát |
| Đặt khách sạn / tour / vé | 🔴 Demo phía client; **bản release tự ẩn** (`showDemoBooking=false`) |
| Thanh toán, hoàn huỷ, thông báo | 🔴 Chưa có |
| AI lập lộ trình | 🟡 Có code + chống bịa dữ liệu; cần `GEMINI_API_KEY` hợp lệ |
| Bản đồ | 🟡 Routing OSRM; tile mặc định OpenStreetMap, tự dùng Goong khi có key thật |
| Docker Compose | ✅ Đã chạy thật: Postgres 15 + backend healthy + admin web (port 8090 khi 8080 bị Windows chặn) |
| CI/CD & runbook | 🟡 GitHub Actions đã có; backup/giám sát thật vẫn phải bật khi deploy — xem [runbook](docs/11-RUNBOOK-TRIEN-KHAI.md) |
| Xác nhận phát hành | ✅ [docs/12-PHAT-HANH-TRIP-PLANNER.md](docs/12-PHAT-HANH-TRIP-PLANNER.md) — 40/40 test, 7/7 smoke, build OK |

**Kết luận:** hệ thống đã chạy được end-to-end ở mức **MVP kỹ thuật**, nhưng **chưa đủ điều kiện
go-live thương mại** cho tới khi hoàn thành các mục P0/P1 trong báo cáo kiểm toán.

---

## 🌟 Tính Năng Nổi Bật

- 🗺️ **Độ Phủ 10 Tỉnh/Thành Du Lịch Khắp 4 Vùng Miền**: Hà Nội, Quảng Ninh (Hạ Long), Sa Pa (Lào Cai), Đà Nẵng, Huế, Hội An, Nha Trang, Đà Lạt, TP. Hồ Chí Minh và Phú Quốc.
- 📐 **Corridor Search Thông Minh (Goong Maps + Bounding Box + Shapely)**: Tìm nhà hàng nằm trong hành lang cự ly hẹp (< 2km) dọc theo tuyến đường di chuyển.
- 🏆 **Thuật Toán Smart Food Corridor Score (SFCS - 105 điểm)**: Kết hợp thông minh giữa khoảng cách lệch tuyến, điểm đánh giá sao, số lượt review thực tế và danh hiệu quán uy tín để đề xuất quán ăn tối ưu nhất.
- 🤖 **AI Data Ingestion (Google Maps Crawler)**: Module cào dữ liệu Playwright Headless bóc tách rating, số lượt review thực tế (k/k+), món đặc trưng và trích đoạn 2–3 bình luận chân thực của thực khách.
- 🔍 **Tìm Kiếm Đa Trường Xuyên Suốt Review**: Cho phép tìm kiếm cả từ khóa hương vị, không gian quán (ví dụ: *"quẩy giòn"*, *"nước dùng ngọt thanh"*, *"view ngắm hồ"*) nằm trong trích đoạn bình luận thực tế từ Google Maps.
- 🍽️ **Smart Meal Stop Insertion**: Tự động phân tích khoảng trống thời gian giữa các điểm tham quan sáng và chiều để 1-click gợi ý chèn điểm ăn trưa/tối vào lịch trình.
- 💾 **Lưu Trữ Bền Vững Offline-First (Hive Cache)**: Tự động lưu toàn bộ dữ liệu địa phương và lịch trình cá nhân vào máy, xem và tạo lịch trình mượt mà ngay cả khi mất sóng trên đèo núi; tự động đồng bộ lên Server khi có mạng trở lại.
- 🖼️ **Tối Ưu Ảnh Cloudinary CDN**: Tự động chuyển đổi và nén ảnh thumbnail (`w_400,h_300`) và ảnh chi tiết (`w_1200`) siêu tốc.
- 🔐 **Phân Quyền Động RBAC & Quản Trị Đa Tỉnh**: 5 vai trò (Super Admin, Content Admin, Province Manager, Moderator, User) kiểm soát bảo mật chặt chẽ.

---

## 🏛️ Kiến Trúc Hệ Thống

Dự án được cấu trúc theo mô hình **Monorepo chuẩn hóa**, tách biệt rõ ràng giữa Client-side và Server-side:

```
d:\trip_flow\
├── lib/                          # [ROOT] Ứng dụng di động Flutter đa nền tảng (iOS / Android)
│   ├── core/                     # Riverpod, Dio, Hive Cache, Data Models, Theme
│   └── features/                 # Khám phá, Bản đồ, Lịch trình, Ẩm thực, Cá nhân
├── backend-dotnet/               # [CHÍNH THỨC] Backend ASP.NET Core Web API (.NET 10 / C#)
│   ├── Controllers/              # RESTful API (Auth, Tỉnh thành, Điểm đến, Quán ăn, Lịch trình)
│   ├── Models/                   # Data Models & DTOs
│   └── Data/                     # Data Store & Seed Data 10 Tỉnh thành
├── backend/                      # [BỔ TRỢ] Python FastAPI (Microservice AI NLP & GIS)
├── admin-web/                    # Website Quản trị React 18 + Vite + TailwindCSS
└── docker-compose.yml            # PostgreSQL 15 thuần + cấu hình container hóa
```

### Sơ Đồ Luồng Dữ Liệu Tổng Thể

```mermaid
flowchart TD
    subgraph ClientLayer["📱 Phân Hệ Khách Hàng (Client)"]
        FlutterApp["📱 Flutter Mobile App (iOS / Android / Web)\nState: Riverpod | Network: Dio | Cache: Hive\nUI: Material 3 + Responsive Phone Frame"]
        AdminWeb["💻 React 18 Admin Dashboard\nQuản lý 10 Tỉnh thành, Duyệt AI Crawler, RBAC & Audit Logs"]
    end

    subgraph GatewayLayer["🛡️ Bảo Mật & Phân Phối (Gateway)"]
        RateLimiter["Rate Limiter (slowapi)\nGiới hạn 10 req/phút cho Corridor Search"]
        AuthMiddleware["JWT Security Middleware\nPhân quyền RBAC (Role & Permissions)"]
    end

    subgraph ServiceLayer["⚙️ Dịch Vụ Cốt Lõi (FastAPI Backend)"]
        GeoEngine["📐 Geo & Corridor Service\nBounding Box SQL Filter + Shapely Engine"]
        ScoringEngine["🏆 SFCS Engine (Thang 105 điểm)\nCự ly + Rating + Log10 Reviews + Quán uy tín"]
        ItineraryEngine["🍽️ Smart Itinerary Service\nPhân tích khoảng cách sáng-chiều & Gợi ý Meal Stop"]
        CrawlerEngine["🕷️ GoogleMapsCrawler (Playwright Async + BS4)\nBóc tách Rating, Reviews Count & Trích đoạn bình luận"]
    end

    subgraph StorageLayer["🗄️ Lưu Trữ & Đám Mây"]
        Database[("🐘 PostgreSQL 15 / SQLite tripflow.db\nB-Tree Composite Index (latitude, longitude)")]
        GoongAPI["🌍 Goong Maps API (Bản đồ & Lộ trình VN)"]
        CloudinaryCDN["🖼️ Cloudinary CDN (Nén ảnh w_400, w_1200)"]
    end

    FlutterApp <-->|"HTTPS / REST API JSON"| RateLimiter
    AdminWeb <-->|"Bearer JWT Token"| RateLimiter
    RateLimiter --> AuthMiddleware
    AuthMiddleware --> GeoEngine
    AuthMiddleware --> ScoringEngine
    AuthMiddleware --> ItineraryEngine
    AuthMiddleware --> CrawlerEngine
    GeoEngine <--> GoongAPI
    GeoEngine <--> Database
    ScoringEngine <--> Database
    ItineraryEngine <--> Database
    CrawlerEngine <--> Database
    FlutterApp <--> CloudinaryCDN
```

---

## 📱 Giao Diện Ứng Dụng & User Flows

TripFlow sở hữu phong cách thiết kế hiện đại mang cảm hứng du lịch và ẩm thực Việt Nam (màu chủ đạo **Teal Biển `#0D9488`** kết hợp **Cam Hổ Phách `#D97706`**).

```
+---------------------------------------------------------------------------------------------------+
|                                 TRIPFLOW MOBILE APPLICATION FLOW                                  |
+---------------------------------+---------------------------------+-------------------------------+
|  1. KHÁM PHÁ 10 TỈNH THÀNH      |  2. BẢN ĐỒ CORRIDOR SEARCH     |  3. ẨM THỰC & GOOGLE REVIEWS  |
| +-----------------------------+ | +-----------------------------+ | +---------------------------+ |
| | [VN] Bản đồ 10 Tỉnh • 4 Vùng| | | Tuyến: Dinh Độc Lập ➔ Q.Phú | | | [🔍 phở, bún chả, sườn...]| |
| | (Tất cả) (Bắc) (Trung) (Nam)| | | [=== Goong Polyline ===]    | | | (Tất cả) (⭐ 4.5+) (Nhiều)| |
| |                             | | |                             | | |                           | |
| | [Ảnh] TP. Hồ Chí Minh       | | | Quán ăn cách đường < 2km:   | | | [Ảnh] Phở Hòa Pasteur     | |
| | ⭐ 8 Điểm • 6 Đặc sản • 8 Quán| | | 1. Phở Hòa (SFCS: 96.4đ)   | | | ⭐ 4.8 (4.1k+ đánh giá)   | |
| |                             | | |    0.28km • 3 phút rẽ       | | | 🔥 Quán được yêu thích     | |
| | [Ảnh] TP. Đà Nẵng           | | | 2. Cơm Tấm Bụi (SFCS: 92.1đ)| | | 💬 "Nước dùng ngọt thanh  | |
| | ⭐ 3 Điểm • 2 Đặc sản • 2 Quán| | |    0.45km • 4 phút rẽ       | | |    xương hầm, thịt mềm..."| |
| +-----------------------------+ | +-----------------------------+ | +---------------------------+ |
+---------------------------------+---------------------------------+-------------------------------+
|  4. LỊCH TRÌNH & SMART MEAL STOP|  5. CHI TIẾT BÌNH LUẬN THỰC TẾ  |  6. WEBSITE QUẢN TRỊ ADMIN    |
| +-----------------------------+ | +-----------------------------+ | +---------------------------+ |
| | Ngày 1: TP. Hồ Chí Minh     | | | 💬 BÌNH LUẬN GOOGLE MAPS    | | | 💻 React Admin Web 18     | |
| | • 08:30: Dinh Độc Lập       | | | 👤 Lê Nam ⭐⭐⭐⭐⭐ 2 tuần trước | | | • Quản lý 10 Tỉnh thành | |
| |                             | | | "Nước phở ngọt thanh, bánh  | | | • Duyệt AI Crawler Maps   | |
| | [🍽️ Gợi ý quán ăn dọc lộ   | | | phở tươi, phục vụ nhanh!"   | | | • Phân quyền RBAC         | |
| |     trình ngày này] (SFCS)  | | |                             | | | • Báo cáo sai sót & Audit | |
| | ➔ Tự động chèn ăn trưa 12:00| | | 👤 Hà My ⭐⭐⭐⭐☆ 1 tháng trước | | |                           | |
| | • 14:00: Bảo tàng Chứng tích| | | "Quán đông, giá xứng đáng." | | |                           | |
| +-----------------------------+ | +-----------------------------+ | +---------------------------+ |
+---------------------------------------------------------------------------------------------------+
```

---

## 🏆 Thuật Toán Smart Food Corridor Score (SFCS)

Khi du khách di chuyển trên một lộ trình dài (ví dụ: từ trung tâm Đà Lạt đi đỉnh Langbiang hay từ phố cổ Hội An đi Rừng dừa Bảy Mẫu), thuật toán **SFCS** tính điểm đa chiều để đưa ra gợi ý xuất sắc nhất:

$$\text{SFCS} = S_{\text{dist}} + S_{\text{rating}} + S_{\text{reviews}} + S_{\text{bonus}} \quad (\text{Thang điểm tối đa } 105)$$

Trong đó:
1. **Điểm cự ly ($S_{\text{dist}}$ — tối đa 40 điểm)**:
   $$S_{\text{dist}} = 40 \times \left(1.0 - \frac{\text{distance\_km}}{\text{corridor\_radius\_km}}\right)$$
   *Quán nằm càng sát tuyến đường di chuyển thì điểm cự ly càng cao, không làm du khách tốn thời gian rẽ xa.*
2. **Điểm đánh giá sao ($S_{\text{rating}}$ — tối đa 35 điểm)**:
   $$S_{\text{rating}} = 35 \times \frac{\text{rating} - 3.0}{2.0} \quad (\text{chuẩn hóa thang sao từ 3.0 đến 5.0})$$
3. **Điểm độ phổ biến thực tế ($S_{\text{reviews}}$ — tối đa 25 điểm)**:
   $$S_{\text{reviews}} = 25 \times \frac{\log_{10}(\max(10, \text{reviews\_count}))}{4.0}$$
   *Sử dụng hàm logarit cơ số 10 để đánh giá đúng tầm vóc của quán (quán 1.000 - 5.000 reviews chứng minh chất lượng ổn định qua thời gian dài).*
4. **Điểm thưởng quán uy tín ($S_{\text{bonus}}$ — 5 điểm)**:
   Cộng thêm 5 điểm cho các quán được gắn nhãn `is_high_rated` (đạt từ 4.2⭐ trở lên).

---

## 🗺️ Bản Đồ Dữ Liệu 10 Tỉnh/Thành Trọng Điểm

| ID | Mã | Tên Tỉnh / Thành Phố | Vùng miền | Tọa độ Tâm | Địa điểm biểu tượng | Món ngon & Nhà hàng nổi bật |
|:---:|:---:|:---|:---:|:---:|:---|:---|
| **1** | `HCM` | **TP. Hồ Chí Minh** | Nam Bộ | `10.7769, 106.7009` | Dinh Độc Lập, Chợ Bến Thành, Bến Bạch Đằng | Cơm tấm Ba Ghiền, Phở Hòa Pasteur, Bánh mì Huỳnh Hoa |
| **2** | `DN` | **TP. Đà Nẵng** | Trung Bộ | `16.0544, 108.2022` | Cầu Rồng, Ngũ Hành Sơn, Bán đảo Sơn Trà | Mì Quảng Bà Mua, Bánh tráng thịt heo Quán Trần |
| **3** | `HN` | **Thủ đô Hà Nội** | Bắc Bộ | `21.0285, 105.8542` | Hồ Hoàn Kiếm, Văn Miếu, Hoàng thành Thăng Long | Phở Thìn Bờ Hồ, Bún chả Hương Liên, Cà phê trứng |
| **4** | `QN` | **Quảng Ninh (Hạ Long)** | Bắc Bộ | `20.9599, 107.0425` | Vịnh Hạ Long, Bảo tàng Quảng Ninh | Chả mực giã tay Bãi Cháy, Bún bề bề làng chài |
| **5** | `LC` | **Lào Cai (Sa Pa)** | Bắc Bộ | `22.3364, 103.8438` | Đỉnh Fansipan, Bản Cát Cát, Nhà thờ Đá | Lẩu cá hồi Sa Pa, Thắng cố bản Mây, Lợn cắp nách |
| **6** | `HUE` | **Thừa Thiên Huế** | Trung Bộ | `16.4637, 107.5909` | Đại Nội Huế, Chùa Thiên Mụ, Lăng Khải Định | Bún bò Huế Mệ Kéo, Bánh bèo nậm lọc Quán Hạnh |
| **7** | `QNA` | **Quảng Nam (Hội An)** | Trung Bộ | `15.8801, 108.3380` | Phố cổ Hội An, Chùa Cầu, Rừng dừa Bảy Mẫu | Cao lầu Không Gian Xanh, Cơm gà Bà Buội |
| **8** | `KH` | **Khánh Hòa (Nha Trang)** | Trung Bộ | `12.2388, 109.1967` | Tháp Bà Ponagar, Hòn Tre, Chùa Long Sơn | Nem nướng Đặng Văn Quyên, Bún cá sứa Năm Beo |
| **9** | `LD` | **Lâm Đồng (Đà Lạt)** | Tây Nguyên | `11.9404, 108.4583` | Hồ Xuân Hương, Quảng trường Lâm Viên, Langbiang | Lẩu gà lá é Tao Ngộ, Bánh căn Lệ Yersin |
| **10** | `KG` | **Kiên Giang (Phú Quốc)** | Nam Bộ | `10.2899, 103.9840` | Dinh Cậu, Thị trấn Hoàng Hôn, Cầu Hôn | Bún quậy Kiến Xây, Gỏi cá trích nhà hàng Ra Khơi |

---

## ⚡ 5 Tối Ưu Kiến Trúc Cốt Lõi & 6 Bẫy Kỹ Thuật (Pitfalls) Đã Giải Quyết

### 5 Tối Ưu Kiến Trúc Cốt Lõi
1. **PostgreSQL 15 thuần + B-Tree Index (Bỏ PostGIS ở MVP)**: Sử dụng chỉ mục composite B-Tree trên 2 cột `(latitude, longitude)` giúp lọc Bounding Box đạt tốc độ **< 0.5ms**, giảm 80% gánh nặng hạ tầng so với việc cài đặt PostGIS phức tạp.
2. **Thay thế Google Maps bằng Goong Maps (`goong.io`)**: Tối ưu chi phí 5–10 lần, dữ liệu địa chỉ tiếng Việt chính xác và API dẫn đường chuyên biệt cho giao thông Việt Nam.
3. **Thống nhất ORM bằng `SQLModel`**: Kết hợp sức mạnh của SQLAlchemy 2.0 và Pydantic v2, giảm 50% lượng code trùng lặp giữa model DB và schema request/response.
4. **State Management Flutter bằng `Riverpod` + `Dio` + `Hive`**: Quản lý trạng thái tách biệt UI, hỗ trợ Interceptor mạng thông minh và lưu cache cục bộ bền vững Offline-First.
5. **Xử lý ảnh tự động qua `Cloudinary` CDN**: DB chỉ lưu URL định danh, Cloudinary tự động nén, cắt và phân phối ảnh thumbnail `w_400,h_300` và ảnh chi tiết `w_1200`.

### 6 Giải Pháp Phòng Tránh Pitfalls
1. **Corridor Search Bounding Box + `Shapely`**: Không dùng công thức Haversine thô sơ lặp qua từng điểm gây giật lag máy; Backend truy vấn Bounding Box SQL sau đó dùng thư viện hình học chuyên nghiệp `Shapely` tính khoảng cách vuông góc chính xác tuyệt đối.
2. **Phân quyền RBAC chuẩn ngay từ đầu**: Thiết kế bảng `Role`, `Permission`, `RolePermissionLink` giúp dễ dàng mở rộng phân quyền mà không phải sửa code logic kiểm tra quyền.
3. **Idempotent Incremental Data Seeding**: File `seed_db.py` chạy an toàn mọi lúc, tự động bổ sung dữ liệu còn thiếu mà không bị trùng lặp khóa chính hay ghi đè lỗi.
4. **Hợp đồng API OpenAPI 3.1 (`swagger.json`)**: Luôn xuất bản và đồng bộ file hợp đồng để đội ngũ Frontend và Backend phối hợp ăn ý.
5. **Cơ chế lưu trữ Offline-first**: Ứng dụng tự phát hiện mất mạng, đọc dữ liệu từ Hive và tự động đẩy các lịch trình chưa đồng bộ lên server khi có mạng trở lại.
6. **Bảo vệ hạ tầng với Rate Limiter (`slowapi`)**: Khóa chặn tối đa 10 request/phút đối với các API tìm đường để bảo vệ hạn mức gọi dịch vụ bên thứ ba.

---

## 🚀 Hướng Dẫn Cài Đặt & Khởi Chạy

### 1. Yêu Cầu Môi Trường
- **.NET SDK**: 8.0, 9.0 hoặc 10.0
- **Flutter SDK**: 3.19 trở lên
- **Node.js**: 18.x trở lên (cho Admin Web)
- **Python**: 3.10 trở lên (tùy chọn cho module cào dữ liệu AI)
- **Git**

### 2. Khởi Chạy Backend .NET (ASP.NET Core Web API - Chính thức eProject)
```bash
# Di chuyển vào thư mục backend .NET
cd backend-dotnet

# Khởi chạy server ASP.NET Core tại cổng 8000
dotnet run
```
> 🌐 Truy cập tài liệu API tương tác Swagger UI tại: [http://localhost:8000/](http://localhost:8000/) hoặc [http://localhost:8000/swagger](http://localhost:8000/swagger)  
> 💡 *Backend .NET cung cấp đầy đủ 8 cụm API (Auth, Tỉnh thành, Điểm đến, Quán ăn, Khách sạn, Món ngon, Lịch trình, Trợ lý AI) phục vụ đồng thời cả Mobile Flutter và React Admin.*

### 3. Khởi Chạy Backend Python FastAPI (Tùy chọn / Bổ trợ)
```bash
# Di chuyển vào thư mục backend
cd backend

# Cài đặt thư viện phụ thuộc
pip install -r requirements.txt

# Khởi chạy server FastAPI tại cổng 8000
uvicorn app.main:app --reload --port 8000
```
> 🌐 Truy cập tài liệu API tương tác tại: [http://localhost:8000/docs](http://localhost:8000/docs)  
> 🩺 Kiểm tra sức khỏe hệ thống: [http://localhost:8000/health](http://localhost:8000/health)

### 4. Khởi Chạy Ứng Dụng Di Động Flutter (Root)
```bash
# Tại thư mục gốc của dự án (d:\trip_flow)
flutter pub get

# Chạy kiểm thử tự động
flutter test

# Khởi chạy trên trình duyệt Chrome (hoặc máy ảo Android / thiết bị thật)
flutter run -d chrome
```

### 5. Khởi Chạy Website Quản Trị React Admin
```bash
cd admin-web
npm install
npm run dev
```
> 💻 Truy cập trang quản trị Admin: [http://localhost:5173](http://localhost:5173)
> Admin mặc định **bắt buộc đăng nhập**; chỉ khi `VITE_DEMO_MODE=true` mới có nút đăng nhập nhanh bằng tài khoản demo.

### 6. Chạy full stack bằng Docker
```powershell
Copy-Item .env.deploy.example .env   # điền SECRET_KEY, mật khẩu Postgres, eSMS, Goong, Gemini...
docker compose --env-file .env up -d --build

# App Flutter (web):  http://localhost:8081
# Admin CMS:         http://localhost:8090   (8080 thường bị Windows reserve)
# API + Swagger:     http://localhost:8000/docs
# Health:            http://localhost:8000/health/ready
```
> Trên Windows, nếu cổng 8080 bị chặn: đặt `ADMIN_PORT=8090` trong `.env` (file local hiện đã cấu hình).
> `app-web` phục vụ `build/web` tĩnh; trước khi deploy thật hãy build lại với
> `--dart-define=API_BASE_URL=https://api.domain.com/api/v1`.
> Checklist đầy đủ: [docs/09-KIEM-TOAN-TRIEN-KHAI.md](docs/09-KIEM-TOAN-TRIEN-KHAI.md).
> Ở production: `ENVIRONMENT=production`, `SEED_DEMO=0`, `SMS_PROVIDER=esms`, `CORS_ORIGINS` là domain thật.

---

## 🧪 Bảng Nghiệm Thu 22 Tiêu Chí (`TC-01` -> `TC-22`)

Hệ thống đã trải qua quá trình thẩm định nghiêm ngặt từ **Reviewer Agent** và đạt kết quả **100% PASSED**:

> ⚠️ **Lưu ý:** bảng dưới đây là **tiêu chí nghiệm thu ban đầu**, chưa được kiểm chứng lại đầy đủ.
> Kết quả kiểm toán độc lập ngày 06/11/2026 (xem [docs/09-KIEM-TOAN-TRIEN-KHAI.md](docs/09-KIEM-TOAN-TRIEN-KHAI.md))
> cho thấy nhiều tiêu chí chỉ đúng ở mức code/demo, chưa đạt mức vận hành thương mại.

| Mã TC | Hạng mục kiểm duyệt | Trạng thái | Ghi chú nghiệm thu |
|:---:|:---|:---:|:---|
| **TC-01** | Cấu trúc Monorepo & 5 Tab điều hướng Flutter | **PASSED** | Flutter tại Root, Backend tại `backend/`, Admin tại `admin-web/`. |
| **TC-02** | PostgreSQL thuần + B-Tree Composite Index | **PASSED** | Index `(latitude, longitude)` tối ưu truy vấn Bounding Box < 0.5ms. |
| **TC-03** | Tối ưu ảnh Cloudinary CDN | **PASSED** | URL tự động sinh tham số `c_fill,w_400,h_300` và `w_1200`. |
| **TC-04** | Goong Maps & Bounding Box Corridor Search | **PASSED** | Giải mã Polyline, lọc hộp chữ nhật và tính cự ly Shapely < 2km. |
| **TC-05** | Rate Limiting slowapi (10 lần/phút/IP) | **PASSED** | Bảo vệ API tìm đường, chặn request thứ 11 với mã HTTP 429. |
| **TC-06** | Quản lý Giờ mở cửa & Cảnh báo xác thực | **PASSED** | Hiển thị thông báo kiểm tra giờ thực tế minh bạch cho du khách. |
| **TC-07** | Nhãn Tài trợ & Minh bạch nguồn dữ liệu | **PASSED** | Badge "Được tài trợ" và gắn nhãn nguồn dữ liệu biên tập/đối tác. |
| **TC-08** | Lịch trình Offline-first với Hive Cache | **PASSED** | Lưu bền vững local, tự động sync lên server khi có mạng lại. |
| **TC-09** | Bản đồ tương tác & Chọn tuyến đường | **PASSED** | Hiển thị polyline tuyến đường và marker nhà hàng dọc đường. |
| **TC-10** | Hệ thống Báo cáo sai sót cộng đồng | **PASSED** | Người dùng gửi phản hồi, Admin duyệt báo sai thông tin. |
| **TC-11** | Phân quyền RBAC (Role & Permission) | **PASSED** | Phân quyền 5 vai trò động qua bảng liên kết. |
| **TC-12** | Nhật ký thao tác quản trị Audit Logs | **PASSED** | Tự động ghi vết các thao tác CRUD quản trị kèm IP và thời gian. |
| **TC-13** | Quản lý Đối tác & Nhãn tài trợ (Sponsorship) | **PASSED** | Hạn mức tài trợ, ngày bắt đầu và kết thúc linh hoạt. |
| **TC-14** | Mở rộng 10 Tỉnh/Thành thuộc 4 Vùng Miền | **PASSED** | Đủ 10 tỉnh: Bắc Bộ, Trung Bộ, Tây Nguyên, Nam Bộ. |
| **TC-15** | Kiểm duyệt nội dung theo Tỉnh phụ trách | **PASSED** | Quản trị viên theo tỉnh chỉ chỉnh sửa dữ liệu tỉnh được phân công. |
| **TC-16** | Google Maps Crawler & Chống trùng lặp | **PASSED** | Playwright cào dữ liệu, toán tử ILIKE chống trùng lặp thông minh. |
| **TC-17** | Hiệu năng & Tương thích ngược DB | **PASSED** | Zero-downtime migration, chạy tốt trên cả PostgreSQL và SQLite. |
| **TC-18** | Trích xuất Reviews & Đánh giá Google Maps | **PASSED** | Normalizer bóc tách reviews (k/k+), trích xuất 2-3 reviews thực tế. |
| **TC-19** | Migration DB 4 cột mới cho Quán ngon | **PASSED** | `_ensure_ingestion_columns()` tự động thêm cột an toàn. |
| **TC-20** | Tìm kiếm quán thông minh & Quét review | **PASSED** | Lọc `min_rating`, `sort_by=reviews_count`, tìm `q` xuyên qua review JSON. |
| **TC-21** | Thuật toán Smart Food Corridor Score (SFCS) | **PASSED** | Thang điểm 105đ (Cự ly + Sao + Log10 Reviews + Bonus quán uy tín). |
| **TC-22** | Chèn điểm dừng ăn uống thông minh (Meal Stop) | **PASSED** | Phân tích lộ trình sáng-chiều, chèn quán có SFCS cao nhất. |

---

## 🎓 Thông Tin Đồ Án (eProject)

- **Đề tài**: Nền Tảng Khám Phá Du Lịch, Ẩm Thực & Lên Lộ Trình Thông Minh Toàn Quốc (TripFlow)
- **Học kỳ**: **Semester 3**
- **Chuyên ngành**: **eProject (.Net & Mobile App Development)**
- **Sinh viên thực hiện**: **[Phạm Tấn Tài](https://github.com/phamtantai02011991-tech)**
- **Kho lưu trữ mã nguồn**: [https://github.com/phamtantai02011991-tech/trip_flow](https://github.com/phamtantai02011991-tech/trip_flow)

---

## 📄 Bản Quyền & Giấy Phép

Phát triển bởi **[Phạm Tấn Tài](https://github.com/phamtantai02011991-tech)**.  
Dự án được phát hành theo giấy phép **[MIT License](LICENSE)**.
