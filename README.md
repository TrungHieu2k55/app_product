# Product Admin – Flutter + Firebase + Cloudinary

Ứng dụng quản trị sản phẩm theo mô hình MVP, chạy trên Web và Android.

## Chức năng

- Đăng ký, đăng nhập, đăng xuất bằng Firebase Authentication.
- Hiển thị sản phẩm thời gian thực từ Cloud Firestore.
- Thêm, sửa, xóa sản phẩm.
- Chọn ảnh trên web/điện thoại và tải lên Cloudinary.
- Lưu `secure_url` Cloudinary vào trường `image` của Firestore.
- Tìm kiếm, thống kê số sản phẩm, số lượng và giá trị kho.
- Giao diện responsive cho điện thoại, tablet và web.

## Cấu trúc dữ liệu bắt buộc

Collection: `products`

```json
{
  "name": "Bàn phím cơ",
  "price": 890000,
  "soluong": 12,
  "image": "https://res.cloudinary.com/..."
}
```

Document sản phẩm chỉ có đúng bốn trường trên. ID dùng document ID do Firestore
sinh tự động.

## Kiến trúc MVP

- `lib/models`: `Product`, `AppUser`.
- `lib/data`: repository Firebase Auth, Firestore và Cloudinary.
- `lib/presenters`: xử lý nghiệp vụ xác thực và CRUD.
- `lib/screens`: giao diện đăng nhập, danh sách, form sản phẩm.

Xem `FIREBASE_SETUP.md` để kết nối Firebase, Cloudinary và triển khai rules.
