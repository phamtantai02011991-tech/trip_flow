# 06 — Báo cáo dọn dẹp dự án (P0)

> Thực hiện: 31/10/2026 · Không xoá bất kỳ dòng mã nguồn nào.

---

## 1. Kết quả đo được

| Thời điểm | Dung lượng | Số file |
|---|---|---|
| Trước dọn (đầu phiên) | 243,51 MB | 7.673 |
| Trước dọn (sau khi bạn build thêm) | **428,53 MB** | – |
| **Sau dọn** | **4,18 MB** | ~1.500 |
| **Giải phóng** | **424,35 MB (99,0%)** | – |

Mã nguồn thật còn: `lib/` 0,66 MB · `backend/` 0,88 MB · `admin-web/src` 0,29 MB · `.git` 1,23 MB.

---

## 2. Đã xoá

| Mục | Dung lượng | Bản chất | Tái tạo bằng |
|---|---|---|---|
| `build/` | 214,26 MB | Output Flutter (gồm `*.cache.dill.track.dill` 49,84 MB + `build/web` 41,38 MB + canvaskit) | `flutter build …` |
| `.dart_tool/` | 130,06 MB | Cache Dart (`flutter_build`, `hooks_runner` — 3 bản `hook.dill` 10,2 MB trùng nhau) | `flutter pub get` |
| `admin-web/node_modules/` | 78,99 MB | Thư viện npm (6.967 file) | `npm ci` |
| `admin-web/dist/` | 0,44 MB | Bundle Vite cũ | `npm run build` |
| `backend/**/__pycache__/` (10 thư mục) | 469 KB | Bytecode Python | tự sinh khi chạy |
| `.pytest_cache/` | 0 B | Cache pytest (rỗng) | tự sinh |
| `.idea/` | 137 KB | Cấu hình IntelliJ/Android Studio | IDE tự tạo |
| `trip_flow.iml` · `android/trip_flow_android.iml` | 2,1 KB | File module IDE | IDE tự tạo |
| `android/local.properties` | 0,1 KB | Đường dẫn SDK của riêng máy | Flutter tự tạo khi build |
| `.flutter-plugins-dependencies` | 4,5 KB | Danh sách plugin sinh tự động | `flutter pub get` |

Tất cả đều nằm trong `.gitignore` (trừ `.pytest_cache` cũng đã ignore) → `git status` không đổi, lịch sử git không bị ảnh hưởng.

---

## 3. Giữ lại có chủ đích

| Mục | Lý do |
|---|---|
| `android/gradlew`, `gradlew.bat`, `android/gradle/` | Bắt buộc để build Android (dù bị gitignore) |
| `.metadata`, `pubspec.lock`, `analysis_options.yaml` | Flutter cần |
| `admin-web/package-lock.json` | Cần cho `npm ci` tái lập chính xác |
| `.agents/workspace/*.md` | 3 tài liệu tracked của agent (plan/code/review) |
| `lib/core/utils/mock_data.dart` (119 KB) | **Đang được dùng** (4 file import) — là nợ kỹ thuật, xử lý ở P1–P4 chứ không xoá mù |
| `backend/swagger.json` | Đang tracked (quyết định bên dưới) |

---

## 4. Cần bạn quyết định

| Mục | Kích thước | Vấn đề |
|---|---|---|
| `trip_flow.pdf` (thư mục gốc) | 369 KB | Tracked. Nếu không phải tài liệu nộp bài → `git rm trip_flow.pdf` (giữ trong lịch sử) |
| `backend/swagger.json` | 25 KB | Tracked nhưng **bị ghi lại mỗi lần khởi động backend** (`_export_openapi_contract` trong lifespan) → git diff nhiễu. Đề xuất: `git rm --cached backend/swagger.json` + thêm `backend/swagger.json` vào `.gitignore`, dùng `/api/v1/contract/swagger.json` khi cần |
| `devtools_options.yaml` | 0,2 KB | File DevTools sinh tự động — **đã thêm** vào `.gitignore`, hiện đang untracked |

---

## 5. Đã cập nhật `.gitignore`

Thêm mục "Tooling & local agent state":

```gitignore
devtools_options.yaml
.vscode/
.agents/workspace/tmp/
.agents/workspace/*.log
coverage/
lcov.info
admin-web/.vite/
*.tsbuildinfo
.eslintcache
```

---

## 6. Sự cố quyền truy cập đã xử lý

| Thời điểm | Hiện tượng | Xử lý |
|---|---|---|
| Đầu phiên | Mọi lệnh đọc/ghi đều lỗi `SetNamedSecurityInfoW failed (Win32 5): grantWrite(D:\trip_flow)` | Chạy công cụ sửa quyền của DSH (thêm quyền toàn quyền cho tài khoản đang đăng nhập), **đã xác minh** `WRITE_OWNER` từ `false → true`; bản sao lưu quyền cũ ở `D:\dsh-acl-recovery\` |
| Khi xoá file | Sandbox từ chối `Remove-Item` (`Access denied`) dù `Set-Content` thành công | Chạy lệnh dọn ở chế độ toàn quyền có phê duyệt — chỉ xoá thư mục sinh tự động |
| `.pytest_cache` | Ngay cả tài khoản hiện tại cũng không đọc được quyền (`Get-Acl` → Unauthorized) | Đã xoá được sau khi chạy toàn quyền. Nếu tái xuất hiện lỗi này, chạy lại công cụ chẩn đoán quyền |

> Không có file nội dung nào bị thay đổi bởi các thao tác sửa quyền.

---

## 7. Lệnh khôi phục môi trường phát triển

```powershell
cd D:\trip_flow

# Flutter
flutter pub get
flutter analyze
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1

# Backend
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000

# Admin web (cửa sổ khác)
cd admin-web
npm ci
npm run dev
```

> Lưu ý: sau khi xoá `android/local.properties`, lần build Android đầu tiên cần mở lại project trong Android Studio hoặc chạy `flutter build apk` để Flutter sinh lại file này.

---

## 8. Quy tắc chống tái phát (thêm vào quy trình)

1. Trước khi commit, chạy `git status --short` — không commit `build/`, `.dart_tool/`, `node_modules/`, `dist/`.
2. Không commit `swagger.json` (đã là artifact sinh tự động).
3. `.gitignore` phải cập nhật mỗi khi thêm tool mới (devtools, coverage, vite cache…).
4. Chạy `flutter clean` trước khi nén/zip dự án để nộp.
5. Dùng `git clean -ndX` để xem trước những gì sẽ bị xoá (chỉ file ignored) trước khi `-fdx`.
