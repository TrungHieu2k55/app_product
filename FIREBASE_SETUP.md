# Cấu hình Firebase

## 1. Tạo dịch vụ

Trong Firebase Console:

1. Bật **Authentication → Email/Password**.
2. Tạo **Cloud Firestore**.
3. Thêm ứng dụng **Web** và **Android**.

## 2. Firebase đã kết nối

Project hiện tại: `giuaki2-23458`.

Cloudinary đã cấu hình bằng:

- Cloud name: `hieudev`
- Unsigned upload preset: `giua_ki`

Chạy ứng dụng bình thường bằng `flutter run -d chrome` hoặc Android emulator.

## 3. Cấu hình Cloudinary

1. Tạo tài khoản/project trên Cloudinary.
2. Vào **Settings → Upload → Upload presets**.
3. Tạo preset ở chế độ **Unsigned**.
4. Lấy `Cloud name` và tên upload preset để truyền bằng `--dart-define`.

Ảnh được upload trực tiếp lên Cloudinary. Ứng dụng lấy `secure_url` và lưu URL
đó vào trường `image` của Firestore. Không đặt API Secret Cloudinary trong app.

## 4. Triển khai luật bảo mật

```bash
firebase deploy --only firestore:rules
```

Collection Firestore là `products`. Mỗi document chỉ gồm đúng bốn trường:

```json
{
  "name": "Bàn phím cơ",
  "price": 890000,
  "soluong": 12,
  "image": "https://..."
}
```
