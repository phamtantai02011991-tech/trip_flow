# Kế Hoạch Phát Triển & Chuẩn Hóa Hình Ảnh Du Lịch: Đồng Bộ 100% Ảnh Thực Tế Với Từng Địa Danh & Danh Lam Thắng Cảnh Toàn Bộ 10 Tỉnh Thành

## 1. Tổng quan

### 1.1 Vấn đề phát hiện
- Người dùng phản hồi:
  > *"quét lại và tôi thấy ảnh và nội dung không đồng nhất , tôi muốn ảnh và nội dung phải đúng , có thể dùng nội dung sreach để lấy hình ảnh gắn vào cho đúng"*
- Rà soát thực tế mã nguồn:
  1. Trong `lib/core/utils/mock_data.dart`: Các địa điểm thuộc các tỉnh thành ngoài TP.HCM (Hà Nội, Đà Nẵng, Quảng Ninh, Lào Cai, Huế, Hội An, Nha Trang, Đà Lạt, Phú Quốc) chưa được cung cấp mảng `images: [...]` mà dùng giá trị mặc định `const []`. Khi hiển thị, getter `primaryImageUrl` bị fallback về ảnh của Dinh Độc Lập (`photo-1583417319070-4a69db38a482`) khiến Cầu Rồng, Văn Miếu, Vịnh Hạ Long, Chùa Cầu, v.v., đều hiển thị chung một hình ảnh Dinh Độc Lập!
  2. Một số địa điểm tại TP.HCM (Bảo tàng Chứng tích Chiến tranh, Địa đạo Củ Chi) cũng bị gán lặp lại URL ảnh của Dinh Độc Lập hoặc Nhà thờ Đức Bà, gây sai lệch hoàn toàn so với nội dung thực tế.
  3. Cần đồng bộ hình ảnh xác thực chuẩn xác 100% sang cả 3 phân hệ: **Flutter Mobile** (`mock_data.dart`), **Backend Database** (`backend/app/db/seed_db.py`) và **Admin Web** (`admin-web/src/services/api/mockAdminData.js`).

### 1.2 Mục tiêu chuẩn hóa
- Thu thập và gán chính xác 100% URL hình ảnh thực tế từ nguồn lưu trữ mở uy tín **Wikimedia Commons & Unsplash** tương ứng với từng danh thắng lịch sử, công trình kiến trúc, thắng cảnh tự nhiên của 10 tỉnh thành:
  - **TP. Hồ Chí Minh**: Dinh Độc Lập, Chợ Bến Thành, Nhà thờ Đức Bà, Bưu điện Trung tâm, Bến Nhà Rồng, Phố đi bộ Nguyễn Huệ, Bảo tàng Chứng tích Chiến tranh, Địa đạo Củ Chi.
  - **TP. Đà Nẵng**: Cầu Rồng sông Hàn, Ngũ Hành Sơn Non Nước, Chùa Linh Ứng Bán đảo Sơn Trà, Bãi biển Mỹ Khê.
  - **Thủ đô Hà Nội**: Hồ Hoàn Kiếm & Tháp Rùa, Văn Miếu - Quốc Tử Giám, Hoàng thành Thăng Long, Lăng Bác.
  - **Quảng Ninh**: Vịnh Hạ Long (Hòn Trống Mái, Động Thiên Cung), Bảo tàng Quảng Ninh.
  - **Lào Cai (Sa Pa)**: Đỉnh Fansipan Nóc nhà Đông Dương, Bản Cát Cát & Thác Tiên Sa.
  - **Thừa Thiên Huế**: Đại Nội Hoàng Thành Huế (Ngọ Môn), Chùa Thiên Mụ bờ sông Hương.
  - **Quảng Nam**: Chùa Cầu & Phố cổ Hội An, Rừng Dừa Bảy Mẫu Cẩm Thanh.
  - **Khánh Hòa**: Tháp Bà Ponagar Nha Trang, VinWonders Hòn Tre.
  - **Lâm Đồng**: Hồ Xuân Hương & Quảng trường Lâm Viên Đà Lạt, Đỉnh Langbiang.
  - **Kiên Giang**: Dinh Cậu & Chợ đêm Dương Đông, Bãi Sao & Sunset Town Phú Quốc.

---

## 2. Danh mục URL Hình ảnh Du lịch Chuẩn Xác Đối Soát

| ID | Địa danh | Tỉnh/Thành | URL Ảnh Thực Tế Xác Thực (Wikimedia Commons / Direct CDN) |
|---|---|---|---|
| 1 | Dinh Độc Lập | TP.HCM | `https://upload.wikimedia.org/wikipedia/commons/7/71/Ho_Chi_Minh_City_-_Independence_Palace.jpg` |
| 2 | Chợ Bến Thành | TP.HCM | `https://upload.wikimedia.org/wikipedia/commons/0/02/Ben_Thanh_Market%2C_Saigon.jpg` |
| 3 | Nhà thờ Đức Bà | TP.HCM | `https://upload.wikimedia.org/wikipedia/commons/9/93/Saigon_Notre-Dame_Basilica_%2814695412776%29.jpg` |
| 4 | Bưu điện Trung tâm Sài Gòn | TP.HCM | `https://upload.wikimedia.org/wikipedia/commons/7/78/Ho_Chi_Minh_City%2C_Central_Post_Office%2C_2020-01_CN-01.jpg` |
| 5 | Bến Nhà Rồng | TP.HCM | `https://upload.wikimedia.org/wikipedia/commons/9/95/Ben_Nha_Rong_ve_dem.JPG` |
| 6 | Phố đi bộ Nguyễn Huệ | TP.HCM | `https://upload.wikimedia.org/wikipedia/commons/0/04/Nguyen_Hue_Street1.jpg` |
| 7 | Bảo tàng Chứng tích Chiến tranh | TP.HCM | `https://upload.wikimedia.org/wikipedia/commons/c/ca/War_Remnants_Museum.jpg` |
| 8 | Địa đạo Củ Chi | TP.HCM | `https://upload.wikimedia.org/wikipedia/commons/6/69/Cu_Chi_Tunnel.jpg` |
| 9 | Cầu Rồng Đà Nẵng | Đà Nẵng | `https://upload.wikimedia.org/wikipedia/commons/5/5d/Dragon_Bridge_Da_Nang_1.jpg` |
| 10 | Ngũ Hành Sơn | Đà Nẵng | `https://upload.wikimedia.org/wikipedia/commons/4/44/Marble_Mountains%2C_Vietnam.jpg` |
| 12 | Chùa Linh Ứng Sơn Trà | Đà Nẵng | `https://upload.wikimedia.org/wikipedia/commons/2/28/Lady_Buddha_Da_Nang_5.jpg` |
| 11 | Hồ Hoàn Kiếm & Tháp Rùa | Hà Nội | `https://upload.wikimedia.org/wikipedia/commons/a/a8/Th%C3%A1p_R%C3%B9a.jpg` |
| 13 | Văn Miếu - Quốc Tử Giám | Hà Nội | `https://upload.wikimedia.org/wikipedia/commons/3/31/Hanoi_Temple_of_Literature.jpg` |
| 14 | Hoàng thành Thăng Long | Hà Nội | `https://upload.wikimedia.org/wikipedia/commons/7/70/Main_Gate_-_Citadel_of_Hanoi.jpg` |
| 15 | Vịnh Hạ Long | Quảng Ninh | `https://upload.wikimedia.org/wikipedia/commons/4/4b/Halong_Bay.jpg` |
| 16 | Bảo tàng Quảng Ninh | Quảng Ninh | `https://upload.wikimedia.org/wikipedia/commons/f/f1/Quang_Ninh_Museum_facade_1.jpg` |
| 17 | Đỉnh Fansipan | Sa Pa | `https://upload.wikimedia.org/wikipedia/commons/7/71/Fansipan.jpg` |
| 18 | Bản Cát Cát Sa Pa | Sa Pa | `https://upload.wikimedia.org/wikipedia/commons/4/42/Cat_Cat_waterfall.jpg` |
| 19 | Đại Nội Huế | Cố đô Huế | `https://upload.wikimedia.org/wikipedia/commons/1/13/Ng%E1%BB%8D_m%C3%B4n%2C_Hu%E1%BA%BF.jpg` |
| 20 | Chùa Thiên Mụ | Cố đô Huế | `https://upload.wikimedia.org/wikipedia/commons/2/26/Thi%C3%AAn_M%E1%BB%A5_Pagoda.jpg` |
| 21 | Chùa Cầu Hội An | Hội An | `https://upload.wikimedia.org/wikipedia/commons/9/96/Japanese_Covered_Bridge%2C_Hoi_An%2C_Vietnam_%286944565326%29.jpg` |
| 22 | Rừng Dừa Bảy Mẫu | Hội An | `https://upload.wikimedia.org/wikipedia/commons/8/82/Basket_Boat_and_the_Bamboo_forest_%28Unsplash%29.jpg` |
| 23 | Tháp Bà Ponagar | Nha Trang | `https://upload.wikimedia.org/wikipedia/commons/c/c8/PoNagar.jpg` |
| 24 | VinWonders Nha Trang | Nha Trang | `https://upload.wikimedia.org/wikipedia/commons/d/df/Vinpearl_Nha_Trang_%2849373981551%29.jpg` |
| 25 | Hồ Xuân Hương & Lâm Viên | Đà Lạt | `https://upload.wikimedia.org/wikipedia/commons/a/aa/Da_Lat_-_Xuan_Huong_Lake.jpg` |
| 26 | Đỉnh Langbiang | Đà Lạt | `https://upload.wikimedia.org/wikipedia/commons/c/c9/Lang_Biang_mountain_1.jpg` |
| 27 | Dinh Cậu Phú Quốc | Phú Quốc | `https://upload.wikimedia.org/wikipedia/commons/8/83/Dinh_C%E1%BA%ADu_Ph%C3%BA_Qu%E1%BB%91c.jpg` |
| 28 | Sunset Town & Bãi Sao | Phú Quốc | `https://upload.wikimedia.org/wikipedia/commons/a/ad/Star_Beach_%28B%C3%A3i_Sao%29.jpg` |

---

## 3. Danh sách File Triển khai

1. [`lib/core/utils/mock_data.dart`](file:///d:/trip_flow/lib/core/utils/mock_data.dart): Cung cấp danh sách `images` đầy đủ và chính xác cho 28 địa điểm và 10 tỉnh thành.
2. [`backend/app/db/seed_db.py`](file:///d:/trip_flow/backend/app/db/seed_db.py): Đồng bộ URL ảnh vào database backend.
3. [`admin-web/src/services/api/mockAdminData.js`](file:///d:/trip_flow/admin-web/src/services/api/mockAdminData.js): Cập nhật hình ảnh đồng bộ sang hệ thống Admin Web.
4. Kiểm thử biên dịch Flutter và khởi động lại Hot restart.
