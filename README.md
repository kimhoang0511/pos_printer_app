# In Hóa Đơn ESC/POS — Flutter App

Ứng dụng in bill nhiệt ESC/POS đa nền tảng cho quán cafe Trung Nguyên.

## Nền tảng hỗ trợ

| Nền tảng | Mạng TCP/IP | Bluetooth |
|----------|-------------|-----------|
| Android  | ✅           | ✅         |
| iOS      | ✅           | ✅         |
| macOS    | ✅           | 🔧 WIP    |
| Windows  | ✅           | 🔧 WIP    |

## Cài đặt

### Yêu cầu
- Flutter SDK ≥ 3.10 ([flutter.dev](https://flutter.dev))
- Dart ≥ 3.0

### Chạy ứng dụng

```bash
# Clone / mở thư mục
cd pos_printer_app

# Cài dependencies
flutter pub get

# Chạy trên thiết bị/giả lập
flutter run

# Build cho từng nền tảng
flutter build apk          # Android
flutter build ios          # iOS (cần Mac + Xcode)
flutter build macos        # macOS
flutter build windows      # Windows
```

## Cấu hình máy in

### Kết nối mạng (TCP/IP) — khuyến nghị
1. Kết nối máy in vào cùng mạng Wi-Fi / LAN
2. Tra IP máy in (in test page hoặc vào menu máy in)
3. Trong app → **Cài đặt** → nhập IP và Port (mặc định: **9100**)

### Kết nối Bluetooth
- Android / iOS: vào **Cài đặt** → chọn **Bluetooth** → quét thiết bị

## Cấu trúc dự án

```
lib/
├── main.dart                    # Entry point
├── models/
│   ├── bill_model.dart          # Bill, BillItem
│   └── printer_settings.dart   # PrinterSettings
├── services/
│   ├── app_state.dart           # ChangeNotifier state
│   ├── escpos_builder.dart      # Tạo lệnh ESC/POS
│   └── printer_service.dart    # Gửi bytes đến máy in
├── screens/
│   ├── home_screen.dart         # Màn hình chính + preview
│   ├── edit_bill_screen.dart    # Chỉnh sửa hóa đơn
│   └── settings_screen.dart    # Cài đặt máy in
└── widgets/
    └── bill_preview.dart        # Widget hiển thị hóa đơn
```

## Packages sử dụng

| Package | Mục đích |
|---------|----------|
| `esc_pos_utils_plus` | Tạo lệnh ESC/POS |
| `flutter_thermal_printer` | In Bluetooth |
| `provider` | State management |
| `shared_preferences` | Lưu cài đặt |
| `intl` | Format số tiền / ngày giờ |
