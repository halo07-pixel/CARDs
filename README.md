# Spire Cards

Game thẻ bài roguelike theo lối chơi Slay the Spire, làm bằng **Godot 4.7** (GDScript, renderer Compatibility).
Mục tiêu: bản chơi được đầy đủ vòng lặp (map, chiến đấu, thưởng, cửa hàng, lửa trại, sự kiện, boss) với ~70% nội dung của Slay the Spire.

## Bàn giao

Bối cảnh, quyết định thiết kế, trạng thái và bước tiếp theo: xem [`HANDOFF.md`](HANDOFF.md). Quy tắc làm việc cho Claude: [`CLAUDE.md`](CLAUDE.md).

## Chạy test (headless)

```bash
# cần Godot 4.7.x trong PATH, hoặc đặt GODOT=/duong/dan/toi/godot
bash tools/run_tests.sh
bash tools/run_tests.sh --only=test_battle,test_trigger   # chỉ chạy các file test có tên chứa chuỗi
```

Runner quét `tests/test_*.gd`, thoát mã `1` nếu có test lỗi. Trên máy không có màn hình vẫn chạy được.

## Mô phỏng và cân bằng (headless)

```bash
godot --headless --path . -s res://tools/simulate_battles.gd -- --battles=300 --seed=1
# --deck=all : dùng bộ bài chứa mọi thẻ mẫu (hai bản mỗi thẻ) để kiểm tra các thẻ mới
# --relics=all : người chơi mang mọi relic trong data/relics
# --potions=N : mỗi trận người chơi mang N potion khác nhau (chọn ngẫu nhiên theo seed)
```

Mỗi dòng là một nhóm quái với một loại bot: tỉ lệ thắng, số lượt trung bình, máu mất trung bình.
Sau mỗi bước, các điều kiện bất biến (tổng số thẻ, máu/năng lượng trong giới hạn, `battle_ended` đúng một lần...)
được kiểm tra; vi phạm thì script thoát với mã 1.

## Cấu trúc

| Thư mục | Nội dung |
|---|---|
| `src/data/` | Resource dữ liệu thuần: `CardData`, `EffectData`, `StatusData`, `EnemyData`, `EnemyMove`, `CharacterData`, `TriggerData`, `RelicData`, `PotionData` (không chứa logic, không giữ hình) |
| `src/core/` | Lõi chiến đấu, không dùng node/UI: `Deck`, `Combatant`, `EffectResolver`, `DamageCalculator`, `EnemyAI`, `EnemyUnit`, `BattleController`, `BattleState`, `BattleFactory`, `CardRegistry`, `PotionBelt`, và hệ thống sự kiện/trigger (`TriggerDispatcher`, `TriggerRunner`, `ActionQueue`)... |
| `src/sim/` | Bot tự chơi (`RandomBot`, `GreedyBot`), `BattleSimulator`, `BattleInvariants`: tìm lỗi và đo cân bằng, chạy headless |
| `src/autoload/` | `EventBus`, `RunState`, `SaveSystem`, `AudioManager`, `SceneRouter` |
| `data/` | File `.tres` của thẻ, quái, trạng thái, relic, potion, nhân vật (thêm nội dung = thêm file) |
| `tests/` | Test headless |
| `tools/` | Script chạy test, sinh dữ liệu mẫu |
| `assets/` | Asset bên thứ ba. **Mọi asset phải ghi vào `assets/CREDITS.md`** (tên, tác giả, nguồn, giấy phép) |

## Nguyên tắc code

- Call down, signal up: không dùng `get_parent().get_parent()`; node con báo lên bằng Signal.
- Tách dữ liệu thẻ (`CardData`) khỏi hiển thị (`CardUI`).
- Luôn kiểm tra state của lượt trước khi thực thi hành động.
- Test trước, mỗi tính năng đi qua: thiết kế → duyệt → code → kiểm lỗi → refactor.

## Tiến độ

- [x] **Giai đoạn 0** - Nền móng: autoload, lưu/tải, chuyển cảnh, bộ test headless
- [x] **Giai đoạn 1.1** - Thẻ và bộ bài: `CardData`, `EffectData`, `CardInstance`, `Deck`
- [x] **Giai đoạn 1.2** - Trạng thái, `Combatant`, công thức sát thương, `EffectResolver`
- [x] **Giai đoạn 1.3a** - Dữ liệu quái, AI chọn chiêu, ý định (intent), `ResourceRegistry`, 3 quái mẫu
- [x] **Giai đoạn 1.3b** - `BattleState`, `BattleController` (lượt chơi, thắng/thua, tái lập theo seed), vùng "limbo" của `Deck`
- [x] **Giai đoạn 1.3c** - `CharacterData` (Warrior), `CardRegistry`, `BattleFactory`, 8 thẻ mới, bot tự chơi và trình mô phỏng
- [x] **Giai đoạn 1 hoàn tất** - lõi chiến đấu chơi được hoàn toàn bằng code, chưa có UI
- [x] **Giai đoạn 2.1** - Sự kiện và trigger (Poison, Thorns, Metallicize, Artifact, Barricade, Demon Form), thẻ Power, hiệu ứng `HEAL`/`LOSE_HP`
- [x] **Giai đoạn 2.2** - Relic (`RelicData`, `RelicRegistry`, 10 relic mẫu, bonus tĩnh năng lượng/rút bài)
- [x] **Giai đoạn 2.3** - Potion (3 ô, 8 potion mẫu), X-cost (Whirlwind, Skewer), bản nâng cấp `+` cho mọi thẻ kèm bài kiểm tra dữ liệu
- [ ] **Giai đoạn 2.4** - Nội dung mẫu (quái có trạng thái đầu trận), bot dùng potion, mô phỏng tổng hợp
- [ ] **Giai đoạn 3** - UI chiến đấu (tay bài, kéo thả, ý định quái)
- [ ] **Giai đoạn 4** - Cấu trúc run: map, thưởng, cửa hàng, lửa trại, sự kiện
- [ ] **Giai đoạn 5** - Menu chính, chọn nhân vật, lưu/tiếp tục run, cài đặt
- [ ] **Giai đoạn 6** - Mở rộng nội dung: Act 2-3, nhân vật thứ hai
- [ ] **Giai đoạn 7** - Asset CC0, âm thanh, hiệu ứng
- [ ] **Giai đoạn 8** - Cân bằng bằng bot, đóng gói

Số test hiện tại: 466 (đều đạt).
