# Ca trực đêm — điểm sửa và debug

`MeowShelterGame` giữ mèo/ổ/cá dùng chung. `NightGame` nhận các sự kiện từ
engine và điều phối riêng Ca trực đêm; màn bắt mèo thường không tạo controller này.

## Tìm đúng chỗ

| Cần sửa | File |
| --- | --- |
| Bắt đầu/kết thúc đêm, chọn thẻ, mở shop | `night_game.dart` |
| Trạng thái hiện tại | `NightGame.phase` (`NightPhase`) |
| Tiền, giá mua, số ô, tiến trình | `night_run.dart`, `night_relics.dart` |
| Nội dung/giới hạn thẻ | `night_cards.dart` |
| Cổ vật kích hoạt khi nào, giới hạn combo | `night_relic_effects.dart` |
| Mô tả và hồi chiêu trợ thủ | `night_helpers.dart` |
| Thi triển và thời gian hiệu lực trợ thủ | `night_helper_effects.dart` |
| Đèn, trăng, mây và vùng tác dụng | `maps/moonlit_yard.dart` |
| Vẽ cảnh/đèn/ánh sáng | `maps/moonlit_yard_painter.dart` |
| Gắn bản đồ vào game, nhận thao tác | `maps/moonlit_yard_scene.dart` |

## Luồng lượt chơi

Chọn trợ thủ → hướng dẫn đêm → chơi → chọn thẻ miễn phí →
(shop nếu vừa qua đêm chẵn) → hướng dẫn đêm tiếp theo.
Hết thẻ hợp lệ vẫn có nút tiếp tục; không bỏ qua shop ở đêm chẵn.
Đóng hướng dẫn mới chạy đồng hồ. Chỉ giai đoạn `playing` cập nhật luật đêm.
Ví Ngân quang và cổ vật đặt lại khi chơi lại; xu trại vẫn lưu như trước.

## Mở rộng

- **Thêm bản đồ:** thêm `NightMap`, triển khai `NightScene` trong `maps/`,
  đăng ký ở `createNightScene`, rồi chọn lịch bản đồ trong `NightRun.mapFor`.
  Cảnh tự quản lý component và tài nguyên riêng; controller chỉ hỏi vùng sáng,
  cập nhật cảnh và nhận sự kiện nguồn sáng đầu tiên.
- **Thêm thẻ:** khai báo `NightCard`, áp dụng chỉ số trong `NightRun` hoặc cảnh,
  thêm hình trong `ui/widgets/night_card_icons.dart`.
- **Thêm cổ vật:** khai báo giá/mô tả/combo trong `NightRelic`, triển khai trigger
  trong `NightRelicEffects`, thêm hình ở `ui/widgets/night_relic_icon.dart`.
- **Tái hiện lỗi ngẫu nhiên:** truyền `Random(seed)` vào `MeowShelterGame`.
  Theo dõi `game.night.phase`, `run.night`, `run.silver`, `cardOffer`, `shopOffer`.

Kiểm tra bằng `flutter analyze` và build Android. Không thêm file test/công cụ
vào cây nguồn của dự án.

## Hẻm chợ đêm

Đêm lẻ ở sân sau, đêm chẵn ở hẻm chợ. Lần đầu gặp mỗi bản đồ không có luật phụ
ngẫu nhiên. `night_market.dart` giữ độ ồn, xe đẩy và đèn; `night_market_scene.dart`
nhận thao tác, xử lý báo động; `night_market_painter.dart` vẽ sạp hàng và xe.

- Xe đẩy có báo trước 2s, đi qua trong 4s, tăng 42 độ ồn khi tới giữa đường.
- Mỗi lần làm mèo giật mình/thả nhầm ổ tăng 8 độ ồn; tự giảm 1.5 mỗi giây.
- Tới 100, mèo ngoài vùng sáng né chạy, độ ồn hạ về 25. Mèo đang bế hoặc được
  ánh sáng/kỹ năng mèo đen bảo vệ không chịu tác động. Báo động không bị tính
  thêm thành lỗi thao tác, tránh vòng lặp cộng độ ồn.
- Ba đèn đường bật bằng chạm: sáng 18s, nguội 5s. Than hồng/Chuông đèn/Lăng kính
  và các hiệu ứng ánh trăng vẫn hoạt động. Moonlight và phần vẽ trăng dùng chung
  với sân sau, không nhân đôi logic mây/vệt sáng.
- Thẻ riêng: Đệm chân êm, Bánh xe bọc vải, Điện dự phòng, Góc yên tĩnh; giao kèo
  Chợ đông đổi +50% tiền lấy xe đẩy thường xuyên hơn. Chỉ được chào trước đêm ở hẻm.
