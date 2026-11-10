# 🔍 BÁO CÁO KIỂM DUYỆT BẢO MẬT, KIẾN TRÚC & HỢP ĐỒNG API
**Dự án**: TripFlow — Nền tảng Du lịch & Lộ trình Phượt Thông minh  
**Thành phần kiểm toán**: Backend ASP.NET Core (.NET 10 / C#)  
**Tác nhân thực hiện**: 🔍 Reviewer Agent (Model: pro)  
**Tài liệu đối chiếu**: `.agents/workspace/plan.md`, `.agents/workspace/code_report.md`, `backend/swagger.json`  
**Ngày kiểm toán**: 10/11/2026  

---

## 1. KẾT LUẬN CHUNG

- **Trạng thái**: ⚠️ **NEEDS FIXES** (Cần Coder khắc phục 1 lỗi bảo mật P1 trước khi nghiệm thu cuối cùng)
- **Điểm chất lượng (Scale 10)**: **8.8 / 10**
- **Tổng số vấn đề phát hiện**:
  - 🔴 **P0 (Blocker)**: **0**
  - 🟠 **P1 (Critical)**: **1** (Lỗ hổng Auth Bypass tại `AdminController.EnsureAdminAccess`)
  - 🟡 **P2 (Major)**: **2** (Cấu hình `dotnet test` vstest timeout do `OutputType=Exe`; Hardcoded JWT secret fallback trong dev)
  - 🟢 **P3 (Polish)**: **2** (Bổ sung `[Authorize]` filter tường minh; logging phân cấp security events)

---

## 2. THẨM ĐỊNH BẢO MẬT & KIẾN TRÚC (SECURITY & ARCHITECTURE AUDIT)

### 2.1. Kiểm toán Hợp đồng API (Contract Parity) — ĐẠT 100%
- **JSON Serialization**: Cấu hình `JsonNamingPolicy.SnakeCaseLower` trên cả thuộc tính (`PropertyNamingPolicy`) và từ điển (`DictionaryKeyPolicy`) tại [Program.cs](file:///d:/trip_flow/backend-dotnet/Program.cs#L20-L25). Khảo sát toàn bộ model entity và DTO cho thấy 100% trường dữ liệu trả về client Flutter và React Admin dưới dạng `snake_case` (ví dụ `province_id`, `access_token`, `budget_amount`, `total_days`).
- **Enum Serialization**: Sử dụng `JsonStringEnumConverter(JsonNamingPolicy.SnakeCaseLower)`, bảo đảm mọi enum (`motorbike`, `saver`, `balanced`, `destination`, `gas`) serialize thành chuỗi ký tự thường, loại bỏ hoàn toàn nguy cơ client bị lỗi parse số nguyên `0, 1, 2`.
- **Error Envelope Protection**: 
  - Đã triển khai [ErrorEnvelopeMiddleware.cs](file:///d:/trip_flow/backend-dotnet/Middleware/ErrorEnvelopeMiddleware.cs) bọc toàn bộ mã lỗi HTTP 400, 401, 403, 404, 500 vào chuẩn FastAPI `{ "detail": "..." }`.
  - ModelState validation errors được đóng gói qua `options.InvalidModelStateResponseFactory` trong [Program.cs](file:///d:/trip_flow/backend-dotnet/Program.cs#L28-L36) thành `{ "detail": "Thông báo lỗi validation..." }`.
  - Triệt tiêu hoàn toàn ASP.NET Core `ProblemDetails` (`type`, `title`, `traceId`) gây crash parser của Flutter di động và React Admin.

### 2.2. Kiểm toán Bảo mật (Security Hardening) — CÓ CẢNH BÁO P1
| Tiêu chí | Đánh giá | Chi tiết kiểm chứng |
| :--- | :---: | :--- |
| **Password Hashing** | ✅ ĐẠT | Sử dụng thư viện `BCrypt.Net-Next` với muối ngẫu nhiên độ an toàn cao (`BCrypt.HashPassword`). Mật khẩu gốc không bao giờ lưu trữ dạng plaintext. |
| **OTP SMS Rate Limiting** | ✅ ĐẠT | Giới hạn 60 giây giữa 2 lần gửi OTP (`(now - lastOtp.CreatedAt).TotalSeconds < 60`), trả mã HTTP `429 Too Many Requests`. Kiểm tra Regex số di động Việt Nam `^(03\|05\|07\|08\|09)\d{8}$`. |
| **OTP Brute-Force Lockout** | ✅ ĐẠT | Giới hạn tối đa 5 lần nhập sai mã OTP; sau 5 lần mã bị hủy, buộc người dùng yêu cầu mã mới. |
| **Account Lockout (Brute Force)** | ✅ ĐẠT | Theo dõi `failed_login_attempts`. Đăng nhập sai 5 lần liên tiếp sẽ kích hoạt `locked_until = now + 15 phút`, trả HTTP `423 Locked`. |
| **2FA TOTP RFC 6238** | ✅ ĐẠT | Tích hợp chuẩn xác `OtpNet.Totp` với secret Base32 20-bytes, tạo URI `otpauth://totp/...`, hỗ trợ cửa sổ bù trễ `VerificationWindow(1, 1)` (±30s). |
| **Guest Token Data Isolation** | ✅ ĐẠT | Truy vấn chuyến đi qua header `X-Guest-Token`. Ngăn chặn hoàn toàn việc khách vãng lai A truy cập dữ liệu của khách B (trả HTTP 404). |
| **GDPR Account Deletion** | ✅ ĐẠT | `DELETE /api/v1/auth/account?confirm=DELETE` xóa cascade toàn bộ lịch trình, đánh giá, chi phí, yêu thích và lịch sử tìm kiếm. |
| **Admin Access Control** | ❌ **LỖI P1** | Hàm `EnsureAdminAccess()` tại [AdminController.cs](file:///d:/trip_flow/backend-dotnet/Controllers/AdminController.cs#L26-L32) chứa lệnh `if (role == null) return;`. Người dùng ẩn danh không gửi token sẽ vượt qua kiểm tra và có toàn quyền admin! |

---

## 3. THẨM ĐỊNH DỮ LIỆU & THUẬT TOÁN (DATA INTEGRITY & ALGORITHMS)

### 3.1. Tính toàn vẹn Dữ liệu Hạt giống (Seed Data Integrity) — ĐẠT 100%
- **10 Tỉnh/Thành Trọng Điểm**: Khởi tạo đầy đủ 10 tỉnh: TP.HCM (HCM), Đà Nẵng (DN), Hà Nội (HN), Quảng Ninh (QN), Sa Pa (LC), Thừa Thiên Huế (HUE), Quảng Nam (QNA), Khánh Hòa (KH), Lâm Đồng (LD), Kiên Giang (KG).
- **158 Điểm đến (Destinations)**: Nạp thành công 12 điểm hạt giống cốt lõi + 146 điểm mở rộng từ `catalog_extra.json`, giữ nguyên bản quyền ảnh Wikimedia Commons, giấy phép CC BY-SA, và tác giả cấp phép.
- **77 Nhà hàng & Quán ăn (Restaurants)**: Đầy đủ thông số tọa độ, ẩm thực đặc sản vùng miền, phân khúc giá và định mức detour.
- **50 Trạm dừng chân (Rest Stops)**: Đầy đủ trạm xăng Petrolimex/PV Oil, trạm sạc EV VinFast, trạm nghỉ cao tốc.
- **Đồng bộ PostgreSQL Sequences**: File [SeederExtensions.cs](file:///d:/trip_flow/backend-dotnet/Data/SeederExtensions.cs#L7-L37) định nghĩa hàm `ResetPostgresSequencesAsync` chạy lệnh `SELECT setval(pg_get_serial_sequence('{table}', 'id'), COALESCE(MAX(id), 1), MAX(id) IS NOT NULL) FROM {table};` trên cả 23 bảng entity, triệt tiêu lỗi trùng lặp Sequence ID sau khi seed.

### 3.2. Thuật toán Hành lang Tuyến đường & Điểm SFCS — ĐẠT 100%
- **Point-to-Line Projection**:
  - Tại [GeoService.cs](file:///d:/trip_flow/backend-dotnet/Services/GeoService.cs#L50-L134), tọa độ WGS84 được chiếu sang không gian phẳng Cartesian địa phương theo công thức:
    $$X = (\text{lng} - \text{ref\_lng}) \times 111.32 \times \cos(\text{ref\_lat})$$
    $$Y = (\text{lat} - \text{ref\_lat}) \times 111.32$$
  - Đoạn vuông góc được tính bằng vector chiếu clamp $t \in [0.0, 1.0]$, bảo đảm tính toán cực nhanh `O(N)` trong bộ nhớ.
  - Cự ly rẽ nhánh detour: $\text{detourKm} = 2 \times \text{distance}$.
  - Thời gian rẽ nhánh ước tính: $\max(2, \text{round}(\text{detourKm} / 0.4) + 1)$.
  - Tiến độ hành trình `RouteProgressPct` được chuẩn hóa chính xác trên thang $0\% - 100\%$.
- **Thang điểm Smart Food Corridor Score (SFCS) 105 điểm**:
  - Điểm đánh giá (Rating): tối đa 60 điểm ($\text{rating} \times 12$).
  - Mức độ phổ biến (Review count): tối đa 15 điểm ($\min(15, \log_{10}(\text{reviews}) \times 5)$).
  - Độ gần tuyến hành lang (Proximity): tối đa 20 điểm ($\max(0, 20 - \text{dist} \times 8)$).
  - Huy hiệu Michelin/Chất lượng cao: 10 điểm.
  - Tổng điểm cực đại: $60 + 15 + 20 + 10 = 105$ điểm. Công thức phản ánh chính xác 100% theo bản thiết kế của Planner Agent.

---

## 4. KẾT QUẢ KIỂM THỬ XÁC MINH ĐỘC LẬP (VERIFICATION AUDIT)

Reviewer Agent đã trực tiếp kích hoạt kiểm thử độc lập đối với giải pháp Backend:

```text
================================================================
 TRIPFLOW .NET 10 - IN-PROCESS XUNIT PARITY TEST RUNNER
================================================================
[SUITE] AuthParityTests:             8/8 PASS  (0 Fail)
[SUITE] CatalogParityTests:          8/8 PASS  (0 Fail)
[SUITE] PlacesAndCorridorTests:      8/8 PASS  (0 Fail)
[SUITE] TripsAndExpensesTests:       8/8 PASS  (0 Fail)
[SUITE] AdminParityTests:            8/8 PASS  (0 Fail)
[SUITE] SmokeTestRunner (7/7 Smoke): 1/1 PASS  (0 Fail)
================================================================
 KẾT QUẢ KIỂM THỬ TỰ ĐỘNG: 41/41 PASS (0 FAIL) — 100% ĐẠT
================================================================
```

Tất cả 7 mục kiểm tra `smoke_test.py` đều vượt qua:
- `[PASS] GET /health — status=ok`
- `[PASS] GET /health/ready — database=ok`
- `[PASS] GET /destinations (>=100) — total=158, items=100`
- `[PASS] GET /restaurants (>=60) — count=77`
- `[PASS] GET /places/nearby?kinds=gas — gas=3`
- `[PASS] POST /places/along-route — stops=17`
- `[PASS] GET /places/suggest?q=hoi an — items=19`

---

## 5. CHI TIẾT CÁC VẤN ĐỀ CẦN KHẮC PHỤC (THEO THỨ TỰ ƯU TIÊN)

### 🟠 [P1] Lỗ hổng Auth Bypass trên toàn bộ Admin API
- **Vị trí**: [backend-dotnet/Controllers/AdminController.cs#L24-L32](file:///d:/trip_flow/backend-dotnet/Controllers/AdminController.cs#L24-L32)
- **Đoạn mã hiện tại**:
  ```csharp
  private void EnsureAdminAccess()
  {
      var role = _tokenService.GetUserRoleFromPrincipal(User);
      if (role == null) return; // Nếu chưa cấu hình chặt chẽ để dev/test có thể qua, hoặc kiểm tra nếu User gửi claim role == "user"
      if (role == "user")
      {
          throw new BadHttpRequestException("Từ chối truy cập (403 Forbidden): Không có quyền thực hiện.", 403);
      }
  }
  ```
- **Nguyên nhân & Nguy cơ**:
  Khi client không gửi bất kỳ Authorization header nào (người dùng ẩn danh không đăng nhập), `User.Identity?.IsAuthenticated` là `false` và `role` là `null`. Biểu thức `if (role == null) return;` thoát hàm mà không kiểm tra xác thực, dẫn đến **toàn bộ 12 endpoints quản trị admin** (xem KPI dashboard, sửa/tạo điểm đến, thăng quyền người dùng, xem audit logs) đều bị lộ công khai cho bất kỳ ai trên Internet mà không cần đăng nhập! Ngoài ra trong `RecordAuditLog`, thao tác ẩn danh này còn tự động gán là `admin@tripflow.vn` / `super_admin`.
- **Yêu cầu khắc phục cho Coder Agent**:
  Sửa lại hàm `EnsureAdminAccess()` để kiểm tra nghiêm ngặt:
  ```csharp
  private void EnsureAdminAccess()
  {
      var role = _tokenService.GetUserRoleFromPrincipal(User);
      if (string.IsNullOrEmpty(role))
      {
          throw new BadHttpRequestException("Vui lòng đăng nhập để tiếp tục.", StatusCodes.Status401Unauthorized);
      }
      if (role is not ("super_admin" or "content_admin" or "province_editor" or "moderator"))
      {
          throw new BadHttpRequestException("Từ chối truy cập (403 Forbidden): Không có quyền thực hiện.", StatusCodes.Status403Forbidden);
      }
  }
  ```
  Đồng thời cập nhật các bài test trong `AdminParityTests.cs` để thêm một test case xác nhận gọi Admin API không kèm token sẽ nhận mã 401 Unauthorized.

---

### 🟡 [P2] Khả năng tương thích lệnh `dotnet test` tiêu chuẩn
- **Vị trí**: [backend-dotnet/TripFlow.Tests/TripFlow.Tests.csproj](file:///d:/trip_flow/backend-dotnet/TripFlow.Tests/TripFlow.Tests.csproj#L4)
- **Nguyên nhân**:
  Project test được cấu hình `<OutputType>Exe</OutputType>` và sử dụng custom entry point [Program.cs](file:///d:/trip_flow/backend-dotnet/TripFlow.Tests/Program.cs#L8). Khi chạy bằng lệnh tiêu chuẩn `dotnet test`, trình điều khiển `vstest.console` bị treo chờ kết nối testhost (timeout 90s). Mặc dù chạy bằng `dotnet run --project backend-dotnet/TripFlow.Tests/TripFlow.Tests.csproj` hoạt động hoàn hảo và pass 41/41 test, việc này có thể gây khó khăn trong các luồng CI/CD tự động dùng `dotnet test`.
- **Yêu cầu khắc phục cho Coder Agent**:
  Đảm bảo `TripFlow.Tests.csproj` hỗ trợ cả 2 hình thức chạy hoặc bổ sung tài liệu/script `run_tests.cmd` rõ ràng để người dùng và pipeline CI/CD thực thi thuận tiện.

---

### 🟡 [P2] Quản lý JWT Secret trong môi trường Production
- **Vị trí**: [backend-dotnet/Program.cs#L108](file:///d:/trip_flow/backend-dotnet/Program.cs#L108) & [backend-dotnet/Services/TokenService.cs#L24](file:///d:/trip_flow/backend-dotnet/Services/TokenService.cs#L24)
- **Nguyên nhân**:
  Sử dụng chuỗi bí mật fallback hardcoded `"TripFlowSuperSecretKey2026ForAuthenticationJwtBearer1234567890!"`.
- **Yêu cầu khắc phục cho Coder Agent**:
  Trong môi trường Production (khi `!app.Environment.IsDevelopment()`), nếu biến môi trường `JWT__SECRET` hoặc `Jwt:Secret` không được cung cấp hoặc trùng với chuỗi mặc định, hệ thống cần ghi log cảnh báo bảo mật nghiêm ngặt hoặc từ chối khởi động để ngăn ngừa rủi ro lộ secret.

---

### 🟢 [P3] Phân quyền chi tiết theo Tỉnh (Province Scoping)
- **Vị trí**: [backend-dotnet/Controllers/AdminController.cs](file:///d:/trip_flow/backend-dotnet/Controllers/AdminController.cs)
- **Khuyến nghị**:
  Role `province_editor` có trường `AssignedProvinceId` trong bảng `users`. Hiện tại logic cập nhật điểm đến kiểm tra quyền chung `EnsureAdminAccess()`. Khi hoàn thiện giai đoạn tiếp theo, nên bổ sung kiểm tra: nếu user có role `province_editor` thì chỉ được sửa các điểm đến thuộc đúng `AssignedProvinceId` của mình.

---

## 6. DANH SÁCH HÀNH ĐỘNG TIẾP THEO (NEXT ACTIONS)

- [ ] **Coder Agent**: Sửa ngay lỗi bảo mật **P1** trong `AdminController.cs` (`EnsureAdminAccess`), trả 401 khi không có token và 403 khi role là `user`.
- [ ] **Coder Agent**: Bổ sung test case `TC_ADM_Anonymous_AccessAdmin_ShouldReturn401` vào `AdminParityTests.cs`.
- [ ] **Coder Agent**: Chạy lại bộ test `dotnet run --project backend-dotnet/TripFlow.Tests/TripFlow.Tests.csproj` bảo đảm 42/42 tests PASS.
- [ ] **Reviewer Agent**: Thẩm định lại và cấp trạng thái **✅ PASSED** sau khi Coder Agent hoàn tất bản vá.
