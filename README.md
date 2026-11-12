# Meow Shelter

Game chăm sóc và giải cứu mèo viết bằng **Flutter** và **Flame**. Người chơi câu cá, dụ mèo về đúng ổ, vượt chướng ngại trên đường về nhà và dẫn cả đàn mèo qua nhiều khu vực. Trại mèo là nơi mua mèo, trang trí và tăng độ thân thiết.

Ứng dụng dùng giao diện tiếng Việt, khóa chiều ngang và ẩn thanh trạng thái/điều hướng hệ thống. Tiến trình được lưu cục bộ; hiện không có tài khoản hay máy chủ đồng bộ dữ liệu.

## Công nghệ và môi trường

| Thành phần | Sử dụng |
| --- | --- |
| Flutter / Dart | Giao diện, điều hướng và vòng đời ứng dụng |
| Flame `^1.20.0` | Game loop, sprite animation, camera và component |
| `shared_preferences` `2.3.3` | Lưu tiến trình, bộ sưu tập và thiết lập |
| `flame_audio` `2.10.0` | Nhạc nền và hiệu ứng âm thanh |
| `CustomPainter` / `Canvas` | Phong cảnh, vật cản, icon và hiệu ứng kỹ năng |

Repo có cấu hình **Android** và **iOS**. Môi trường đang dùng Flutter **3.22.3**, Dart **3.4.4**; giới hạn Dart trong `pubspec.yaml` là `>=3.4.4 <4.0.0`. Chưa có cấu hình Web hoặc desktop trong repo.

## Cài đặt và chạy

Cài Flutter SDK, Android SDK và Android Studio. Tạo máy ảo hoặc kết nối điện thoại Android đã bật USB debugging, sau đó chạy từ thư mục gốc dự án:

```sh
flutter doctor -v
flutter pub get
flutter devices
flutter run
```

Nếu có nhiều thiết bị:

```sh
flutter run -d <device-id>
```

Chạy iOS cần macOS, Xcode và môi trường CocoaPods phù hợp. Repo có thư mục `ios/`, nhưng chưa xác nhận bản iOS đã được kiểm thử trên thiết bị.

## Chế độ chơi

### Cứu hộ theo màn

Nút **Bắt đầu** tiếp tục tiến trình; **Chọn màn** mở danh sách chương và số sao đã đạt.

- Hiện có **6 chương, 18 màn**: Sân trước, Vườn hoa, Bếp ăn, Phòng chơi, Góc tối và Đại cứu hộ.
- Kéo cá ra sân để dụ mèo, sau đó bế mèo về đúng ổ trong thời gian cho phép.
- Mỗi loài có luật bắt riêng; các màn có biến thể như giới hạn cá, chia đợt mèo, ổ di chuyển, bóng tối và mèo boss.
- Tiến trình mở màn và số sao tốt nhất được lưu trên máy.

`CatchWindow` mặc định cho 1 giây để bắt đầu bế và 3 giây giữ mèo. Cấu hình màn và hành vi riêng có thể thay đổi thời gian thực tế.

### Cứu hộ vô hạn

Chế độ cứu hộ riêng dùng `infiniteLevel`, dành cho việc tiếp tục cứu mèo thay vì đi theo chuỗi màn của các chương.

### Câu cá

- Chọn điểm thả câu, chờ cá cắn rồi kéo cá vào bờ.
- Theo dõi độ căng dây, giữ nhịp kéo và điều chỉnh hướng khi cá vùng vẫy.
- Các loài cá có độ hiếm và nhịp giằng khác nhau; thời điểm trong ngày ảnh hưởng xác suất gặp cá.
- Có thể câu trúng đồ thất lạc như dép, ủng hoặc lon rỗng.
- Cá được lưu vào bộ sưu tập. Cho mèo ăn **không tiêu hao** số cá đã sưu tập.

### Mèo về nhà

Điều khiển mèo bằng joystick, thu thập cá/tim và vượt các khu vực:

**Đường đất → Vườn sau → Bờ suối → Rừng tre → Cánh đồng → Cầu gỗ → Làng nhỏ → Ngõ về nhà.**

- Vật cản gồm gai, đá lăn, khúc gỗ, lò xo, cua và chim lao xuống.
- Chim nhắm vị trí người chơi trước khi lao xuống; lò xo đẩy mèo lùi về sau.
- Đá qua suối di chuyển và mang mèo theo khi đứng trên đó.
- Có checkpoint, cổng, trận đấu rồng ở đoạn cuối và phần thưởng khi hoàn thành.
- Mỗi loài có **1 kỹ năng chính và 3 kỹ năng phụ**, cùng combo riêng. Chiêu định hướng hỗ trợ chạm để dùng nhanh hoặc kéo để nhắm; chiêu quanh bản thân không cần nhắm.

| Loài mèo | Kỹ năng chính | Ba kỹ năng phụ |
| --- | --- | --- |
| Mèo cam | Bứt tốc lửa | Cầu lửa, Phun lửa, Bom lửa |
| Mèo đen | Hóa bóng | Dịch chuyển bóng, Phân thân, Ngưng thời gian |
| Himalaya | Lăn băng | Mũi băng, Vùng băng giá, Cầu băng |
| Scottish | Khiên phản chấn | Tiếng gầm, Tường đá, Phản đòn |
| Tam thể | Phúc lành | Móng nam châm, Mắt mèo, Sấm sét |

Tên và combo nằm trong `lib/game/cats/cat_breed.dart`. Tầm đánh, hồi chiêu, dạng vùng nhắm và thời gian hiệu lực nằm trong `lib/game/cats/home_attack.dart`; xử lý va chạm và hiệu ứng nằm trong `lib/game/return_home/`.

### Dẫn đàn về nhà

Dùng joystick dẫn mèo đầu đàn đến các nhóm mèo rồi đưa đàn về nhà. Mèo đi sau bám theo đường di chuyển của đầu đàn và tìm đường vòng qua vật cản.

- Có sân tập hướng dẫn; hoàn thành lần đầu sẽ lưu trạng thái đã học.
- Bốn bản đồ chính: **Sân đồ chơi, Phố chợ đêm, Đồi cát, Xứ tuyết**.
- Mỗi bản đồ có luật riêng: bóng nảy, xe tuần tra và đèn giao thông, cát mềm và dốc, băng trơn và cầu tuyết.
- Mỗi lượt có 12 mèo để đón; ở bản đồ chính cần ít nhất 8 mèo để mở nhà. Sân tập yêu cầu đủ 12.
- Va chạm có thể làm đàn tản ra; bóng ở sân đồ chơi chỉ đẩy lệch đàn, không trừ mạng.
- Hiện chế độ này không ghi điểm hoặc thưởng vào tiến trình Trại mèo; trạng thái hoàn thành hướng dẫn được lưu trong dữ liệu chung.

### Trại mèo

- Mèo cam có sẵn; mua thêm các loài trong cửa hàng để chúng xuất hiện tại trại.
- Chạm để vuốt ve, kéo để bế mèo. Độ thân thiết được lưu theo loài.
- Mua đồ trang trí và kéo thả để sắp xếp; vị trí được lưu lại.
- Tiền hiển thị **bên trong Cửa hàng**, không nằm trên homepage hoặc thanh chính của trại.
- Đạt ngưỡng thân thiết giúp giảm thời gian hồi kỹ năng chính trong Mèo về nhà.

## Giao diện và âm thanh

### Bật/tắt Giáng sinh

Đổi biến trong `lib/ui/home_theme.dart`:

```dart
const bool christmasEnabled = true;
```

- `true`: mũ Noel, đồi phủ tuyết, cây thông, quà, dây đèn và nhà mùa đông.
- `false`: logo thường, cảnh hoàng hôn, đường đất và nhà với mái ngói, cửa chớp, bồn hoa.

Sau khi đổi hãy **Hot Restart**. Mũ Noel được vẽ bằng `Canvas/Path` trong `lib/ui/widgets/santa_hat_painter.dart`.

### Co giãn giao diện

`UiScaleBox` trong `lib/ui/responsive.dart` bao toàn ứng dụng. Chiều cao thiết kế tham chiếu là 375; kích thước widget và game được viết theo đơn vị thiết kế rồi co giãn theo màn hình. Màu sắc và kiểu giao diện chung nằm trong `lib/ui/design.dart`. Xem thêm [DESIGN.md](DESIGN.md).

### Âm thanh

Nút âm thanh trên homepage cho phép chỉnh âm lượng và nhạc nền. `GameAudio` dùng chung cho các màn, lưu thiết lập và tạm dừng âm thanh khi ứng dụng ra nền. Tệp âm thanh nằm trong `assets/audio/`.

## Cấu trúc mã nguồn

```text
lib/
├── main.dart                 # Khởi tạo lưu trữ, âm thanh và ứng dụng
├── audio/                    # Nhạc nền, hiệu ứng và thiết lập
├── camp/                     # Dữ liệu trại, hành vi mèo, đồ trang trí
├── collection/               # Loài cá và bộ sưu tập
├── fishing/                  # Luật câu cá, trạng thái và ánh sáng
├── levels/                   # Chương, màn, nhiệm vụ, sao và mở khóa
├── game/
│   ├── meow_shelter_game.dart # Luồng chơi cứu hộ
│   ├── cats/                 # Loài mèo, hoạt ảnh, luật bắt và kỹ năng
│   ├── components/           # Mèo, cá, ổ, HUD và hướng dẫn cứu hộ
│   ├── systems/              # Hệ thống mồi cá
│   ├── world/                # Bố cục sân và phong cảnh bản đồ
│   ├── return_home/          # Đường về nhà, bẫy, kỹ năng và boss
│   └── cat_herd/             # Dẫn đàn, tìm đường, bản đồ và mô phỏng
└── ui/
    ├── screens/              # Màn Flutter chứa giao diện/game
    ├── widgets/              # Nút, icon, painter và overlay
    ├── home_theme.dart       # Công tắc Giáng sinh
    ├── responsive.dart       # Co giãn giao diện
    └── design.dart           # Quy chuẩn giao diện chung
```

Ảnh/sprite nằm trong `assets/images/`; thư mục tài nguyên phải được khai báo trong `pubspec.yaml`. Xem [lib/ARCHITECTURE.md](lib/ARCHITECTURE.md) để biết cách phân chia trách nhiệm và mở rộng các chế độ.

## Các điểm cấu hình thường sửa

| Nhu cầu | File/thư mục |
| --- | --- |
| Bố cục và nút homepage | `lib/ui/screens/home_screen.dart` |
| Đường và nhà thường | `lib/ui/widgets/home_background_painter.dart` |
| Phong cảnh Giáng sinh | `lib/ui/widgets/home_christmas_art.dart` |
| Logo và mũ Noel | `lib/ui/widgets/game_logo.dart`, `lib/ui/widgets/santa_hat_painter.dart` |
| Thông tin mèo, kỹ năng chính, combo | `lib/game/cats/cat_breed.dart` |
| Tầm đánh, hồi chiêu, loại vùng nhắm | `lib/game/cats/home_attack.dart` |
| Hiệu ứng kỹ năng | `lib/game/return_home/return_home_skills.dart` |
| Khu vực và rải bẫy | `lib/game/return_home/return_home_road.dart`, `lib/game/return_home/return_home_spawner.dart` |
| Thêm/sửa màn cứu hộ | `lib/levels/` |
| Bản đồ và luật Dẫn đàn | `lib/game/cat_herd/herd_map.dart`, `lib/game/cat_herd/herd_round.dart` |
| Giá mèo, đồ trang trí, ngưỡng thân thiết | `lib/camp/camp_state.dart` |
| Loài cá và tỉ lệ gặp | `lib/collection/fish_species.dart` |

## Dữ liệu lưu trên máy

| Khóa lưu | Nội dung |
| --- | --- |
| `camp_state_v1` | Xu, mèo đã mua, số lần cứu, thân thiết, đồ trang trí và vị trí, sao từng màn, hướng dẫn đã xem |
| `fish_collection_species_v1` | Số lượng đã câu theo từng loài cá/đồ thất lạc |
| `audio_volume`, `audio_music_enabled` | Âm lượng và trạng thái bật nhạc nền |

Dữ liệu JSON không đọc được được giữ lại dưới khóa có hậu tố `_broken`, sau đó phần dữ liệu tương ứng khởi tạo lại. Gỡ ứng dụng hoặc xóa dữ liệu ứng dụng có thể làm mất tiến trình; hiện chưa có chức năng xuất/nhập bản lưu hoặc đồng bộ đám mây.

## Kiểm tra và build Android

```sh
flutter analyze
flutter build apk --debug
```

APK debug nằm tại `build/app/outputs/flutter-apk/app-debug.apk`.

Tạo APK release hoặc Android App Bundle:

```sh
flutter build apk --release
flutter build appbundle --release
```

- APK: `build/app/outputs/flutter-apk/app-release.apk`.
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`.
- Cấu hình Android hiện dùng application ID `com.example.meow_shelter` và **release vẫn ký bằng debug key**. Cần đặt application ID và signing riêng trước khi phát hành.
- Repo hiện dùng Android Gradle Plugin 7.3.0, Kotlin 1.7.10 và Gradle 7.6.3. Khi đổi Flutter/JDK, kiểm tra tương thích của bộ công cụ này.

Hiện repo chưa có bộ kiểm thử tự động được lưu sẵn. Ngoài phân tích tĩnh và build, nên chơi thử thao tác kéo/bế mèo, kỹ năng và vùng va chạm, qua suối, tìm đường của đàn, mua/lưu đồ trong trại, âm thanh và giao diện ở nhiều tỉ lệ màn hình.
