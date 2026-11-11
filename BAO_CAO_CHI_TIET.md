# BÁO CÁO BÀI THI GIỮA KỲ
## MÔN: LẬP TRÌNH ĐA NỀN TẢNG
**Đề bài:** Xây dựng ứng dụng nhập, hiển thị, sửa, xóa sản phẩm ở phân hệ admin (Flutter & Firebase Firestore)

---

## 1. THÔNG TIN CHUNG
- **Nền tảng phát triển:** Flutter (Hỗ trợ chạy đồng thời trên Web, Android, iOS, Windows).
- **Cơ sở dữ liệu:** Firebase Cloud Firestore (kèm chế độ Mock Local Database khi chưa gắn cấu hình).
- **Firebase Project ID:** `giuaki-958ed` (Project GiuaKi)
- **Phân hệ:** Quản trị viên (Admin) - Quản lý Sản phẩm.
- **Tập tin cơ sở dữ liệu nộp kèm:** `database_products.json` (Chỉ gồm đúng 4 trường: `name`, `price`, `soluong`, `image`).

---

## 2. THIẾT KẾ CƠ SỞ DỮ LIỆU
Theo đúng quy định đề bài: **"Chỉ chấp nhận cơ sở dữ liệu gồm các trường: name, price, soluong, image (không tự bổ sung thêm trường)"**.

- **Tên Collection trên Firebase Firestore:** `products`
- **Cấu trúc trường dữ liệu (Document Schema):**

| Tên trường | Kiểu dữ liệu | Ý nghĩa | Ví dụ |
| :--- | :--- | :--- | :--- |
| `name` | String | Tên sản phẩm | `Laptop Dell XPS 13` |
| `price` | Number (double/int) | Giá sản phẩm (VNĐ) | `25990000` |
| `soluong` | Number (int) | Số lượng sản phẩm tồn kho | `15` |
| `image` | String | Đường dẫn ảnh URL hoặc chuỗi Data URI Base64 | `https://...` hoặc `data:image/jpeg;base64,...` |

> **Cam kết:** Cơ sở dữ liệu và mã nguồn hoàn toàn không phát sinh bất kỳ trường nào khác ngoài 4 trường trên.

---

## 3. CÁC THƯ VIỆN SỬ DỤNG & LỆNH CÀI ĐẶT

### 3.1. Các gói thư viện (Packages) trong `pubspec.yaml`:
- `firebase_core: ^5.1.0`: Khởi tạo và quản lý kết nối Firebase đa nền tảng.
- `cloud_firestore: ^7.1.0`: Tương tác đọc, ghi, cập nhật, xóa, lắng nghe dữ liệu thời gian thực (Real-time).
- `image_picker: ^1.2.1`: Cho phép người dùng chọn ảnh từ thư viện thiết bị hoặc chụp ảnh từ máy ảnh (Camera) trên cả Web và Di động.

### 3.2. Lệnh cài đặt thư viện:
Mở terminal tại thư mục gốc của dự án và chạy lệnh:
```bash
flutter pub get
```

---

## 4. HƯỚNG DẪN CHI TIẾT TỪNG BƯỚC KẾT NỐI VỚI FIREBASE FIRESTORE

Dự án đã được cấu hình với Firebase Project thật **`testgk-bc0d4`** trong file `lib/firebase_options.dart`:

```dart
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAtA6IIQqvGylHFFyqWp905HYaW-DCISts',
    appId: '1:702548172635:web:7f4acbc4a2de3a802bc47e',
    messagingSenderId: '702548172635',
    projectId: 'giuaki-958ed',
    authDomain: 'giuaki-958ed.firebaseapp.com',
    storageBucket: 'giuaki-958ed.firebasestorage.app',
    measurementId: 'G-GJ7NPEBM0J',
  );
```

### Security Rules trên Firestore (Cho phép đọc/ghi):
```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

---

## 5. HƯỚNG DẪN CHẠY ỨNG DỤNG VÀ THAO TÁC

### 5.1. Chạy trên nền tảng Web (Theo yêu cầu Câu 2: 8.0 điểm):
Chạy lệnh sau trên terminal:
```bash
flutter run -d chrome
```
Hoặc chạy trên Edge:
```bash
flutter run -d edge
```

### 5.2. Chạy trên nền tảng Di động (Theo yêu cầu Câu 4: 0.5 điểm):
1. Mở máy ảo Android Emulator hoặc cắm điện thoại thật qua cáp USB (bật USB Debugging).
2. Kiểm tra thiết bị:
```bash
flutter devices
```
3. Chạy ứng dụng:
```bash
flutter run -d emulator-5554
```
*(Hoặc `flutter run`)*

---

## 6. DANH SÁCH VÀ KỊCH BẢN KIỂM THỬ CÁC CHỨC NĂNG

| STT | Chức năng | Mô tả chi tiết & Thao tác kiểm thử | Điểm yêu cầu |
| :---: | :--- | :--- | :---: |
| 1 | **Đăng nhập Admin** | - Nhập tài khoản admin (Hệ thống có sẵn nút *"Điền tài khoản Admin mẫu"*: `admin@gmail.com` / `admin123`).<br>- Hỗ trợ ẩn/hiện mật khẩu.<br>- Có thông báo lỗi nếu nhập sai. | 1.5 điểm |
| 2 | **Hiển thị danh sách sản phẩm** | - Hiển thị đầy đủ 4 trường: `image`, `name`, `price`, `soluong`.<br>- Trên Web: Dạng Bảng (Table) chuyên nghiệp, hiển thị ảnh thu nhỏ, định dạng tiền tệ VNĐ, badge số lượng, nút thao tác.<br>- Trên Mobile: Dạng Danh sách thẻ (Card) tối ưu cảm ứng. | 8.0 điểm |
| 3 | **Thêm sản phẩm mới** | - Bấm nút **"Thêm sản phẩm"**.<br>- Nhập Tên (`name`), Giá (`price`), Số lượng (`soluong`).<br>- Chọn ảnh từ máy tính/điện thoại hoặc chụp ảnh từ Camera (hoặc dán link ảnh trực tiếp).<br>- Dữ liệu được lưu ngay lên Firestore và cập nhật trực tiếp. | 8.0 điểm |
| 4 | **Sửa sản phẩm** | - Nhấn icon Sửa (bút chì).<br>- Cập nhật lại tên, giá, số lượng hoặc hình ảnh mới.<br>- Bấm "Lưu thay đổi" -> Bảng dữ liệu lập tức cập nhật. | 1.5 điểm |
| 5 | **Xóa sản phẩm** | - Nhấn icon Xóa (thùng rác).<br>- Hộp thoại xác nhận xuất hiện để tránh xóa nhầm.<br>- Bấm "Xác nhận xóa" -> Sản phẩm được gỡ bỏ khỏi Firestore. | 1.5 điểm |
| 6 | **Tìm kiếm sản phẩm** | - Nhập từ khóa vào ô tìm kiếm -> Hệ thống lọc tức thì theo Tên sản phẩm (`name`). | Nâng cao |
| 7 | **Sắp xếp danh sách** | - Hỗ trợ sắp xếp theo Tên (A-Z), Tên (Z-A), Giá tăng dần, Giá giảm dần, Số lượng giảm dần. | Nâng cao |
| 8 | **Xem chi tiết sản phẩm** | - Nhấp vào bất kỳ dòng nào để mở hộp thoại chi tiết: xem ảnh phóng to, sao chép link ảnh, định dạng giá và số lượng tồn kho. | Nâng cao |
| 9 | **Xuất file JSON** | - Nút **"Xuất JSON (Nộp bài)"** cho phép xem trực tiếp toàn bộ dữ liệu database dạng JSON chuẩn 4 trường và sao chép để nộp bài. | Bắt buộc |
| 10 | **Nhập ảnh trên di động** | - Trên di động, tính năng chụp ảnh và chọn ảnh từ bộ sưu tập hoạt động mượt mà bằng thư viện `image_picker`. | 0.5 điểm |

---

## 7. CẤU TRÚC MÃ NGUỒN (SOURCE CODE TREE)

```
TESTGK/
├── lib/
│   ├── firebase_options.dart         # Cấu hình kết nối Firebase Web / Mobile
│   ├── main.dart                     # Điểm khởi chạy ứng dụng & cấu hình Theme
│   ├── models/
│   │   └── product_model.dart        # Model sản phẩm (Chỉ gồm đúng 4 trường: name, price, soluong, image)
│   ├── services/
│   │   ├── firebase_service.dart     # Tương tác Firestore CRUD, Đăng nhập, Stream, JSON Export
│   │   └── image_service.dart        # Xử lý chọn ảnh Camera/Gallery, giải mã Base64/URL
│   └── screens/
│       ├── login_screen.dart         # Màn hình đăng nhập Admin
│       ├── admin_home_screen.dart    # Màn hình quản trị: bảng sản phẩm Web, danh sách Card Mobile, tìm kiếm, sắp xếp
│       ├── product_form_dialog.dart  # Hộp thoại Thêm / Sửa sản phẩm
│       └── product_detail_dialog.dart# Hộp thoại xem chi tiết thông tin sản phẩm
├── database_products.json            # File dữ liệu mẫu JSON nộp kèm bài thi (4 trường: name, price, soluong, image)
├── pubspec.yaml                      # Khai báo các thư viện phụ thuộc
└── BAO_CAO_CHI_TIET.md               # Báo cáo chi tiết này
```

---

## 8. HƯỚNG DẪN NỘP BÀI THI

1. **File cơ sở dữ liệu:** Nộp file `database_products.json` có trong thư mục gốc của dự án.
2. **Link Github Source Code:**
   - Khởi tạo git và push lên GitHub cá nhân:
     ```bash
     git init
     git add .
     git commit -m "Hoàn thiện bài thi giữa kỳ Lập trình đa nền tảng - Quản lý sản phẩm"
     git branch -M main
     git remote add origin https://github.com/<tai-khoan-cua-ban>/<ten-repo>.git
     git push -u origin main
     ```
   - Điền link repo GitHub vào bài nộp.
3. **Link Video Demo:**
   - Sử dụng công cụ quay màn hình (OBS, Xbox Game Bar `Win + G`, hoặc điện thoại).
   - **Kịch bản quay video demo:**
     1. Mở terminal, chạy lệnh `flutter run -d chrome`.
     2. Hiển thị màn hình Đăng nhập Admin, đăng nhập bằng `admin@gmail.com` / `admin123`.
     3. Tại trang Admin: Hiển thị danh sách sản phẩm đầy đủ 4 trường `name`, `price`, `soluong`, `image`.
     4. Thử chức năng Tìm kiếm theo tên sản phẩm và Sắp xếp theo giá / tên / số lượng.
     5. Nhấn **"Thêm sản phẩm"**, chọn ảnh từ máy tính hoặc dán link ảnh, điền tên, giá, số lượng và lưu lại.
     6. Sửa thông tin của một sản phẩm vừa thêm.
     7. Nhấn xem chi tiết sản phẩm, sau đó thực hiện Xóa sản phẩm có hộp thoại xác nhận.
     8. Bấm nút **"Xuất JSON (Nộp bài)"** để chứng minh cấu trúc cơ sở dữ liệu đúng 4 trường.
     9. *(Nếu có máy ảo/thiết bị di động)*: Chạy trên Android (`flutter run -d emulator-5554`), biểu diễn chọn ảnh/chụp ảnh từ camera và hiển thị thông tin sản phẩm dạng Card di động.
     10. Tải video lên Google Drive hoặc YouTube (chế độ Không công khai/Công khai) và dán link vào bài nộp.
