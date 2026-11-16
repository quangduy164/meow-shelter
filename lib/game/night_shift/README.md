# Ca trực đêm — điểm sửa và debug

`MeowShelterGame` giữ mèo/ổ/cá dùng chung. `NightGame` nhận các sự kiện từ
engine và điều phối riêng chế độ Ca trực đêm; màn bắt mèo thường không tạo controller này.

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
Trong shop có thể bán cổ vật với 50% giá mua để nhận Nguyệt quang và trống ô;
hiệu ứng và combo của món đã bán không còn ở đêm tiếp theo.
Ví Nguyệt quang và cổ vật đặt lại khi chơi lại; xu trại vẫn lưu như trước.

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


## Mái nhà

Bản đồ thứ ba trong vòng luân phiên. Chỉ đặt cá trong vùng đánh dấu trên mái
giữa; mèo xuất hiện ngẫu nhiên trên cả ba mái. Hạ cầu đúng phía để mèo sang ăn. Cá chờ
khi chưa có cầu, không bị tiêu hao vì đường chưa mở. Mèo tự tìm lối qua cầu
đang mở, không đi vòng phía trên/dưới khe. Chạm 4 điểm cầu để hạ ván 16 giây,
sau đó hồi 6 giây. Vẫn có thể bế mèo qua khe như trước.

- Logic: `maps/rooftop_bridges.dart`
- Gắn bản đồ và xử lý chạm: `maps/rooftop_bridges_scene.dart`
- Vẽ mái nhà, cầu ván và vòng chờ: `maps/rooftop_bridges_painter.dart`
- Thẻ riêng: Ván chắc, Thợ mộc nhanh, Ván rộng, Đèn lan can; giao kèo Gió mái.

## Combo và Nguyệt quang

- Cứu mèo: +2 Nguyệt quang; qua đêm: 12 + min(2 × đêm, 20),
  thêm 0–4 nếu nhanh, +3 nếu không có lỗi. Giao kèo tăng thưởng qua đêm:
  Khế ước trăng +40% mỗi cấp, giao kèo khác +25% mỗi cấp; giao kèo bản đồ
  chỉ thưởng ở bản đồ chịu bất lợi. Xu trại là thưởng phụ cố định 5/mèo.
- Nguyệt quang chỉ dùng trong lượt; `earnedMoonlight` đếm tiền kiếm được,
  không tính hoàn tiền bán lại. Mua/bán không tạo tiền mới.
- Than hồng: dư sáng 4s, +2s mỗi cấp Bấc dài/Điện dự phòng/Ván chắc.
- Chuông đèn: lần đầu mở mỗi đèn/cầu, 1 mèo tiến 1 bước; Thêm đèn/Ván rộng
  tăng số mèo (tối đa 3), Đèn sáng/Đèn lan can tăng tầm.
- Túi trăng: lần đầu mở đèn/cầu hồi trợ thủ 2s; mây tới hồi 3s (cách ít nhất
  10s). Trăng tròn +2s nhịp mở đèn; Trợ thủ hăng hái +1s mỗi cấp cho cả hai nhịp.
- Bùa liên hoàn: cứu trong sáng nối trong 8s, từ mèo thứ 2 hỗ trợ 2 mèo.
  Vòng tay ấm +2s cửa sổ mỗi cấp; Cá thơm +35% tầm mỗi cấp; Mèo kiên nhẫn
  cho chuỗi từ 3 hỗ trợ thêm 1 mèo. Cứu trong tối hoặc quá hạn ngắt chuỗi.
- Lăng kính: giao sáng giữ thanh chờ/bế; cứu ở giao sáng +3 Nguyệt quang,
  Trăng tròn thêm 2, Khế ước trăng thêm 1 mỗi cấp. Có cả Bùa liên hoàn:
  mỗi lần cứu từ chuỗi 3 trở đi thêm 2 Nguyệt quang (không cần giao sáng).
- Không cổ vật nào tự đưa mèo vào ổ. Chuỗi và hồi nhịp mây đặt lại mỗi đêm;
  mở lại hướng dẫn không đặt lại hoặc chạy thời gian chuỗi.

## Đặc trưng map và bộ thẻ mở rộng

- Sân sau: Đèn nối tiếp (+2s/cấp cho đèn đang sáng gần nhất, trần 2 lần thời
  lượng gốc), Đốm trăng lưu lại (3/5s, lấy mẫu mỗi 0.5s, tối đa 12 đốm),
  Góc nghỉ (tốc độ hao thanh trong sáng từ 0.5 thành 1/3 hoặc 1/4),
  Đèn ít (bớt 1 đèn, +25% thưởng qua đêm trên sân sau).
  Đốm có vùng sáng xanh nhạt trên đất và hết hạn; không tạo thêm vệt trăng.
- Chợ: sau mỗi chuyến xe có 4s yên tĩnh, mèo được trấn an (không tính là
  ánh sáng cho Lăng kính), ồn giảm thêm 5/s. Sau giờ chợ +2s/cấp.
  Xe lấy tối đa 1 cá chưa ai nhận trong 65px quanh xe; giao ở (0.73,0.65).
  Thùng cá trên xe thêm 1 cá miễn phí/chuyến ở (0.5,0.62). Chuyến xe êm
  tăng thời gian qua sân 4→6s, giảm một nửa ồn xe. Chuông tan chợ giảm 8 ồn/cấp
  mỗi lần cứu trong khoảng yên tĩnh. Cá trên xe ngăn kết luận hết cá sớm.
- Mái nhà: Cầu đôi mở cầu đối diện cùng hàng 6s nếu cầu đó sẵn sàng.
  Nhịp cuối giữ cầu khi có chân mèo trên khe; không giữ vì mèo đang được bế.
  Mâm cá chung có 2 phần được mèo nhận lần lượt, vẫn chỉ đặt trên mái giữa.
  Cầu tự động tự mở lại mỗi cầu 1 lần/đêm khi hồi xong; tự mở kích hoạt
  Chuông đèn/Túi trăng thêm một nhịp, cầu đôi cũng phát nhịp lần mở đầu.
- Chung: Tiếp sức hồi trợ thủ 2s/cấp khi cứu; Cá dự trữ hoàn cá đã trả mà
  chưa ai nhận sau 12s (không hoàn cá miễn phí hoặc phần đã dùng);
  Cứu đúng nhịp nối trong 8s +2s/cấp Vòng tay ấm, thưởng 1/cấp, tối đa 6/đêm;
  Chuẩn bị kỹ đặt 1 cá miễn phí ở giữa sân đầu đêm; Chăm sóc lan tỏa mỗi bữa
  kéo dài chờ bế cho mèo sẵn sàng trong 220px (+35%/cấp Cá thơm), thêm 2s/cấp,
  trần 3 lần thời gian chờ gốc. Hiệu ứng bữa ăn từ cổ vật cũng phát lan tỏa.
- Logic thẻ chung: `night_card_effects.dart`; phần ăn và hoàn cá:
  `../systems/bait_system.dart`. Map không hợp lệ không được chào thẻ riêng;
  thẻ chung có giá trị trên cả ba map. Mọi tiền thưởng mới là Nguyệt quang.
