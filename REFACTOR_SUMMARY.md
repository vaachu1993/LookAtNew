# Refactor Summary - Bottom Navigation Bar

## Mục đích
Refactor code để sử dụng `GlobalKey<NavigatorState>` và centralized state management cho Bottom Navigation Bar, theo mẫu trong `vidu.md`.

## Các thay đổi chính

### 1. **Utils/Utils.dart**
- ✅ Thêm `GlobalKey<NavigatorState> navigatorKey` để quản lý navigation toàn cục
- ✅ Thêm `int selectIndex = 0` để lưu trạng thái tab hiện tại

```dart
static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
static int selectIndex = 0;
```

### 2. **main.dart**
- ✅ Thêm import `Utils/Utils.dart`
- ✅ Thêm `navigatorKey: Utils.navigatorKey` vào MaterialApp

```dart
MaterialApp(
  navigatorKey: Utils.navigatorKey,
  // ...
)
```

### 3. **widgets/common_bottom_nav_bar.dart**
- ✅ Loại bỏ parameters `currentIndex` và `onTap`
- ✅ Sử dụng `Utils.selectIndex` thay vì truyền currentIndex
- ✅ Sử dụng `Utils.navigatorKey.currentContext` để lấy context
- ✅ Đơn giản hóa navigation logic trong `_tabItemClick()`

```dart
class CommonBottomNavBar extends StatelessWidget {
  const CommonBottomNavBar({super.key});
  
  void _tabItemClick(int index) async {
    Utils.selectIndex = index;
    BuildContext context = Utils.navigatorKey.currentContext!;
    // Navigation logic...
  }
}
```

### 4. **Tất cả các screens (Home, Explore, Bookmark, Notifications, Profile)**

#### Thay đổi chung cho mỗi screen:
- ✅ Thêm import `../../Utils/Utils.dart`
- ✅ Set `Utils.selectIndex` trong `initState()`:
  - HomeScreen: `Utils.selectIndex = 0`
  - ExploreScreen: `Utils.selectIndex = 1`
  - BookmarkScreen: `Utils.selectIndex = 2`
  - NotificationsScreen: `Utils.selectIndex = 3`
  - ProfileScreen: `Utils.selectIndex = 4`
- ✅ Đơn giản hóa bottomNavigationBar:
  ```dart
  // Trước:
  bottomNavigationBar: CommonBottomNavBar(currentIndex: X)
  
  // Sau:
  bottomNavigationBar: const CommonBottomNavBar()
  ```

## Lợi ích của refactor

1. **Code gọn gàng hơn**: Không cần truyền `currentIndex` qua props
2. **Quản lý state tập trung**: State được quản lý ở một nơi duy nhất (Utils.dart)
3. **Navigation linh hoạt hơn**: Có thể navigate từ bất kỳ đâu trong app qua `Utils.navigatorKey`
4. **Dễ maintain**: Thay đổi logic navigation chỉ cần sửa ở một chỗ
5. **Theo best practice**: Sử dụng GlobalKey pattern cho navigation

## Kiểm tra

- ✅ Không có lỗi compile
- ✅ Flutter analyze passed (153 issues chỉ là style warnings)
- ✅ Logic navigation được giữ nguyên
- ✅ Auth checking vẫn hoạt động đúng

## Files đã thay đổi

1. `lib/Utils/Utils.dart` - Thêm navigatorKey và selectIndex
2. `lib/main.dart` - Thêm navigatorKey vào MaterialApp
3. `lib/widgets/common_bottom_nav_bar.dart` - Refactor logic
4. `lib/screens/home/home_screen.dart` - Set selectIndex = 0
5. `lib/screens/explore/explore_screen.dart` - Set selectIndex = 1
6. `lib/screens/bookmark/bookmark_screen.dart` - Set selectIndex = 2
7. `lib/screens/notifications/notifications_screen.dart` - Set selectIndex = 3
8. `lib/screens/profile/profile_screen.dart` - Set selectIndex = 4

---
**Refactored on**: December 31, 2025
**Pattern**: GlobalKey Navigation Pattern (theo vidu.md)

