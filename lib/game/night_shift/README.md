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

Luân phiên Sân sau → Hẻm chợ → Mái nhà → Kho hàng. Lần đầu gặp mỗi bản đồ không có luật phụ
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
  Kho hàng không chào thẻ bế/ổ/Chăm sóc lan tỏa. Thẻ đã có vẫn dùng khi quay lại
  các map phù hợp. Mọi tiền thưởng mới là Nguyệt quang.

## Biến thể và nhịp mèo

`night_variants.dart` định nghĩa 3 biến thể/map và lịch cấp mèo `NightArrivalPlan`.
Bốn đêm đầu dùng map chuẩn và bù mèo ngay như trước. Từ đêm 5, chọn ngẫu nhiên
biến thể khác lần trước của cùng map và nhịp khác đêm trước; đặt lại khi chơi lại.

- Sân sau: đèn tản sang hai bên/cuối sân, hoặc đèn chéo + trăng hẹp 72%, quét 1.5 lần.
  Thẻ đèn, số đèn và dư sáng vẫn áp dụng trên layout mới. `Moonlight.reset` luôn
  đặt lại tốc độ/độ rộng/pha để không mang biến thể trăng sang map khác.
- Chợ: chuẩn 16s/chuyến; cao điểm 11/17/10/18s; từng cụm 9/9/20s và đổi hướng.
  Chợ đông nhân chu kỳ 0.75, nhưng luôn có tối thiểu 2.5s ngoài thời gian xe qua.
  Vẽ xe, nhặt cá, báo trước, phát ồn và yên tĩnh đều dùng cùng lịch chuyến.
- Mái nhà: chuẩn hai hàng; so le y=0.30/0.56 và 0.40/0.66; sửa chữa khóa một
  cầu 10s đầu đêm, vẫn có cầu còn lại cùng phía. Cầu đôi ghép theo hàng logic,
  không so tọa độ y; cầu đang sửa không được mở bởi Cầu đôi hay thao tác chạm.
  Vẫn sinh mèo ngẫu nhiên cả ba mái, cá chỉ đặt mái giữa.
- Nhịp rải đều: đầu 2, mỗi 3s thêm 1. Từng đợt: đầu 3, mỗi 9s thêm 3,
  trần sân tăng 1. Dồn nhịp: đầu 1, sau 6s thêm 3, sau 3s thêm 1 và lặp lại.
  Mọi đợt đều chịu trần sân và tổng chỉ tiêu. Đợt bị dồn khi sân đầy sẽ chờ chỗ.
  Cứu sạch sân rút thời gian tới đợt chưa được cấp xuống tối đa 2s.
- Lịch không chạy khi xem hướng dẫn, chọn thẻ hay shop. HUD ghi đếm ngược,
  chờ chỗ hoặc đã đủ mèo; hướng dẫn đêm ghi biến thể và nhịp trước khi chạy giờ.
- Biến cố mây/ổ chỉ được rút từ các lựa chọn không bị thẻ miễn nhiễm, thay vì
  rút trúng rồi biến thành đêm trống. Không đổi giá cổ vật hay sức mạnh thẻ.

## Kho hàng

Map thứ tư dùng lồng cho mọi giống mèo, kể cả tam thể. Kéo cá vào một ngăn trống,
chờ mèo vào trọn và tín hiệu xanh rồi chạm lồng/nút CHỐT NGAY. Mèo tự về trại;
không bế và không vẽ ổ. Đóng sớm/chậm làm mèo rút ra, mất mồi; lồng nghỉ 4s.
Trùm nán lại 1.2s thay vì 1.8s. Chỉ thò đầu 0.8s, sau đó vào lồng 1s.

- Logic thời điểm/ngăn: `maps/warehouse_traps.dart`; nhận thao tác, quản lý mèo
  và cá: `maps/warehouse_traps_scene.dart`; nền và lồng: `maps/warehouse_traps_painter.dart`.
- Ba biến thể: ba lồng ngang, lồng so le, lồng giữa bảo trì 8s.
- Cửa êm giảm bán kính hoảng 50% mỗi cấp; Hai ngăn cho 6 ngăn chốt riêng;
  Mồi sâu kéo dài lúc vào 25% và nán thêm 0.6s/cấp; Dây giật chung chốt cả
  ngăn cùng hàng của lồng kế nếu đang có mèo, vẫn phải canh đúng cả hai.
- Cá thơm tăng tốc tới lồng. Chuẩn bị kỹ cho 1 mồi miễn phí. Cá dự trữ hoàn
  mồi đã trả mà chưa có mèo nhận sau 12s. Đêm giới hạn cá có tối thiểu chỉ tiêu
  + 2 mồi trước thưởng Giỏ cá, tránh thiếu mồi bắt buộc ngay từ đầu.
- Trợ thủ: cam giữ cửa sổ chốt 6s; tai cụp làm cửa sổ hao chậm một nửa 6s;
  đen giữ mèo bình tĩnh 8s; tam thể cho chốt từ 70% lúc vào trong 10s;
  Himalaya làm 2 mèo tin mồi, lần vào lồng kế nán thêm 2s.
- Chuông đèn/Túi trăng kích hoạt lần đặt mồi đầu mỗi ngăn; Chuông/Bùa làm mèo
  gần tin mồi. Lăng kính giữ cửa sổ chốt khi lồng giao ánh trăng, thưởng giao
  sáng như cũ. Tiếp sức/Cứu đúng nhịp và thưởng Nguyệt quang/xu vẫn áp dụng.
- `trapCapture` vô hiệu thao tác bế/chơi trên mèo Kho hàng; `trapManaged` chỉ
  dừng AI khi cảnh đang dẫn mèo vào lồng. Map khác giữ luật giống mèo cũ.

## Vườn lau

Mèo trốn trong sáu bụi lau, không hiện và không bế được. Mèo tự đổi sang bụi
kề sau vài giây, để lại vết chân vàng. Chạm một bụi để tạo tiếng động: mèo ở
bụi kề chạy sang nơi xa bụi đó hơn. Nếu mèo ở bụi biên bị lùa về phía giỏ,
mèo chạy vào lối ra và được cứu ngay. Chạm trúng bụi đang có mèo làm mèo chạy
loạn và tính lỗi. Kéo cá vào bụi trống để dụ mèo ở bụi kề vào đó.

- Logic bụi, lối ra và hướng chạy: `maps/reed_garden.dart`.
- Gắn mèo, chạm, cá và mèo chạy về giỏ: `maps/reed_garden_scene.dart`.
- Vẽ nền, bụi, vết và giỏ lối ra: `maps/reed_garden_painter.dart`.
- Thẻ riêng: Dấu chân sương, Lau lặng gió, Rẽ lau nhẹ, Chuông lau.
## Bến thuyền

Mèo chờ ở bến trái, mỗi con lên một bè có cờ màu giống mèo. Bến phải có đèn
màu giống mèo: bè chỉ được cứu khi vào đúng bến cùng màu. Khi mèo giống mới tới,
một bến không còn bè cần dùng sẽ đổi màu. Vào nhầm bến, ra thác hoặc đâm đá
thì bè quay lại bến trái và tính lỗi. Kéo cá lên bè để neo bè 2.5 giây.

- Lần đầu gặp map: cửa nước đổi riêng từng luồng.
- Lần thứ hai: một cửa đổi hướng cả cột, có thanh nối giữa các cửa cùng cột.
- Lần thứ ba trở đi: hai bè đi sát nhau sẽ va và cùng quay lại.
- Logic luồng, bến, cửa, va chạm: `maps/harbor_flow.dart`; gắn mèo và cá:
  `maps/harbor_flow_scene.dart`; vẽ: `maps/harbor_flow_painter.dart`.
- Thẻ riêng: Bè chắc, Dòng chậm, Bến chung, Dây kéo bến.
## Nhà ga đêm

Mèo vào sân ngồi chờ trên ghế sân ga, có vòng màu dưới chân theo giống mèo.
Mỗi vạch toa có cột biển màu báo toa của chuyến tàu sắp tới. Chạm mèo rồi chạm
vạch để mèo ra đứng chờ; chạm mèo trên vạch rồi chạm vạch khác để đổi chỗ. Khi tàu
dừng, mèo đúng màu lên tàu và được cứu, mèo sai màu về ghế và tính lỗi. Kéo cá
vào vạch trống để gọi một mèo đang chờ, ưu tiên mèo hợp biển toa đó.

- Lịch tàu và biển toa: `maps/night_station.dart`; ghế, vạch, cá và lên tàu:
  `maps/night_station_scene.dart`; vẽ ga, tàu, biển, vạch: `maps/night_station_painter.dart`.
- Biển chuyến sau có mọi giống đang chờ (tối đa bằng số toa), toa thừa là biển
  ngẫu nhiên. Mèo mới tới chỉ thay biển thừa, không đổi biển đã xếp.
- Biến thể: Ga nhỏ (3 toa), Tàu dài (4 toa), Đổi biển (biển chỉ hiện khi tàu vào).
- Lần gặp thứ hai: tàu dừng ngắn hơn. Lần thứ ba: tàu tới dày hơn.
- Thẻ riêng: Còi báo sớm, Dừng lâu, Toa chung, Nhân viên ga.
