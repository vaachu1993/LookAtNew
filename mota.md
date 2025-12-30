---
📋 TỔNG KẾT NHANH
| Controller | Endpoint | Method | Auth | Mô tả |
|------------|----------|--------|------|-------|
| Auth | /api/Auth/register | POST | ❌ | Đăng ký | | | /api/Auth/verify-otp | POST | ❌ | Xác thực OTP | | | /api/Auth/resend-otp | POST | ❌ | Gửi lại OTP | | | /api/Auth/login | POST | ❌ | Đăng nhập | | | /api/Auth/google | POST | ❌ | Đăng nhập Google | | | /api/Auth/forgot-password | POST | ❌ | Quên mật khẩu | | | /api/Auth/reset-password | POST | ❌ | Đặt lại mật khẩu | | | /api/Auth/refresh | POST | ❌ | Refresh token | | | /api/Auth/logout | POST | ✅ | Đăng xuất |
| User | /api/User/me | GET | ✅ | Thông tin cá nhân | | | /api/User/update | PUT | ✅ | Cập nhật profile | | | /api/User/{id} | GET | ✅ | Xem user khác | | | /api/User/change-password | POST | ✅ | Đổi mật khẩu |
| Articles | /api/Articles | GET | ❌ | Lấy tất cả bài viết | | | /api/Articles/{id} | GET | ❌ | Chi tiết bài viết | | | /api/Articles/category/{name} | GET | ❌ | Bài viết theo danh mục |
| Categories | /api/Categories | GET | ❌ | Lấy tất cả danh mục | | | /api/Categories/{id} | GET | ❌ | Chi tiết danh mục | | | /api/Categories | POST | ❌ | Tạo danh mục | | | /api/Categories/{id} | PUT | ❌ | Cập nhật danh mục | | | /api/Categories/{id} | DELETE | ❌ | Xóa danh mục |
| Favorites | /api/Favorites | GET | ✅ | Lấy yêu thích | | | /api/Favorites | POST | ✅ | Thêm yêu thích | | | /api/Favorites/{id} | DELETE | ✅ | Xóa yêu thích | | Feed | /api/Feed | GET | ✅
| Feed cá nhân | | Rss | /api/Rss/fetch | POST | ❌ | Fetch RSS mới |