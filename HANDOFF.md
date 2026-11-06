# HANDOFF - Spire Cards (repo `halo07-pixel/CARDs`)

> Tài liệu bàn giao cho session/đoạn chat mới. Đọc hết file này + `CLAUDE.md` trước khi làm bất cứ gì.
> Cập nhật lần cuối: sau mốc 3.4b (đã gộp vào `main`, 738 test đạt). Tiếp theo: mốc 3.5.

## 1. TL;DR

- **Dự án:** game thẻ bài roguelike kiểu *Slay the Spire*, **Godot 4.7.2 / GDScript**, 1920x1080, renderer Compatibility.
- **Trạng thái:** Giai đoạn 0, 1, 2.1-2.4 (lõi logic: chiến đấu, thẻ, status, trigger, relic, potion, X-cost, AI quái, bot, mô phỏng) và Giai đoạn 3.1-3.4b (UI chiến đấu: thẻ, quái/status/ý định, tay bài, năng lượng, pile, End Turn, Victory/Defeat, **kéo thả thẻ**, hover, xem trước số) **đã xong và đã gộp vào `main`** (**738 test đạt**, mô phỏng 0 vi phạm). Chơi thử: mở `scenes/battle/battle_demo.tscn` trong Godot rồi bấm F6. **Chưa có:** potion/relic trên màn hình, tooltip, hiệu ứng/animation (3.5-3.6), run/bản đồ/cửa hàng/menu (Giai đoạn 4-5), nhân vật thứ hai, sprite quái (đang là ô chữ cái).
- **Trên `main`:** mọi thứ đến mốc **3.4b** (commit `8611aec`). Không còn nhánh nào chờ gộp. **Repo đúng là `halo07-pixel/CARDs` (có chữ s)**; repo `CARD` và `cad` không dùng.
- **Đã duyệt:** kế hoạch Giai đoạn 3 gồm các mốc 3.1 (thẻ), 3.2 (quái + status + ý định), 3.3 (`BattleScene`, tay bài, năng lượng, kết thúc lượt; gom registry thành `GameData`), 3.4 (kéo thả + mũi tên nhắm), 3.5 (potion/relic/tooltip), 3.6 (hiệu ứng). **Nội dung game bằng tiếng Anh.** Asset: tự vẽ icon/khung bằng SVG (tác phẩm gốc, CC0) + UI/font/âm thanh Kenney CC0 từ mirror `ETdoFresh/kenney.nl` (đã đọc license từng pack) + 0x72 DungeonTileset II (CC0, người dùng tải từ itch.io vì sandbox không tải được). Ghi mọi asset vào `assets/CREDITS.md` khi nhập.
- **Việc đầu tiên của session mới:** dựng môi trường (mục 4), chạy test để xác nhận (kỳ vọng 738), tóm tắt 5 dòng, rồi **trình bày thiết kế mốc 3.5** (mục 13) và chờ người dùng duyệt (đừng tự viết code).

## 2. Mục tiêu và phạm vi

Một game hoàn chỉnh về hình ảnh (asset CC0) với đủ menu, gameplay hoàn thiện ~**70% Slay the Spire**:

| Hạng mục | Mục tiêu |
|---|---|
| Nhân vật | 2 (Warrior làm xong dữ liệu; Rogue chưa), mỗi người ~60 thẻ riêng + ~15 thẻ trung tính |
| Run | 3 act, bản đồ phân nhánh 15 tầng, boss mỗi act |
| Phòng | Quái thường, Elite, Lửa trại (nghỉ/nâng cấp), Cửa hàng, Sự kiện, Kho báu, Boss |
| Thẻ | nâng cấp `+`, Exhaust/Ethereal/Innate/Retain, X-cost, Power |
| Relic / Potion | ~50 relic, ~15 potion, 3 ô potion |
| Quái | ~25 loại, boss nhiều pha |
| Meta | menu chính, chọn nhân vật, lưu/tiếp tục run, cài đặt, lịch sử run, Ascension 1-5 |

Lộ trình 8 giai đoạn: 0 nền móng, 1 lõi chiến đấu, 2 hệ thống mở rộng nội dung, 3 UI chiến đấu, 4 cấu trúc run (map/thưởng/shop/lửa trại/sự kiện), 5 menu và meta, 6 mở rộng nội dung (Act 2-3, nhân vật 2), 7 asset/âm thanh/hiệu ứng, 8 cân bằng bằng bot + đóng gói.

## 3. Người dùng và cách làm việc

- Người dùng nói **tiếng Việt**, dùng Windows + PowerShell, repo public `halo07-pixel/CARDs`. Trả lời tiếng Việt; **comment trong code bằng tiếng Việt**; **nội dung game (tên thẻ, mô tả) bằng tiếng Anh** (được chốt theo "đồng ý" mặc định; hỏi lại nếu họ muốn tiếng Việt - đổi sớm đỡ tốn công hơn).
- **Quy trình 5 bước bắt buộc** (người dùng đặt ngay từ đầu):
  1. Trình bày kiến trúc/ý tưởng - **chưa viết code**.
  2. **Chờ người dùng duyệt.**
  3. Viết code cho tính năng đã duyệt (ngắn gọn, modular).
  4. Chờ người dùng kiểm lỗi.
  5. Refactor hoặc chuyển sang tính năng mới.
- **Chống ngụy biện:** KHÔNG `get_parent().get_parent()` (dùng Signal: call down, signal up); KHÔNG gộp logic dữ liệu thẻ vào UI thẻ; KHÔNG viết `pass`/"sẽ thêm sau" cho hàm cốt lõi; LUÔN xác nhận state của lượt trước khi thực thi hành động.
- **Nhịp làm việc đã quen:** mỗi tính năng = nhánh `claude/phase-X-Y-...` -> test -> phá code cố ý để kiểm test -> đẩy lên GitHub -> báo cáo -> người dùng nhắn **"tiếp tục, merge luôn"** -> gộp vào `main` (fast-forward) -> trình bày thiết kế bước kế tiếp -> chờ "đồng ý".
- Người dùng muốn **báo cáo trung thực**: nêu lỗi đã gặp, kiểm tra nào chưa chạy lại, lần phá code nào không bị test bắt (và vì sao). Họ nói "tôi không vội, càng kỹ càng tốt" nhưng gần đây thấy chậm và hỏi tiến độ -> tóm tắt ngắn gọn, đừng kể lể.
- Từ **Giai đoạn 3 (UI)**: họ yêu cầu **chụp ảnh màn hình mỗi giai đoạn** và gửi (dùng `xvfb-run` + render CPU, mục 4).
- Họ cũng có một dự án khác ("Dungeon Raider", Godot) ở các đoạn chat khác - **không liên quan** repo này.

## 4. Môi trường sandbox (đọc kỹ - dễ vấp)

**Sandbox có thể bị reset bất cứ lúc nào** (đã xảy ra một lần: mất toàn bộ code 2.3 chưa đẩy). => **đẩy lên GitHub sau mỗi mốc**.

Khởi động nhanh:

```bash
mkdir -p ~/bin /home/claude/godot && cd /home/claude/godot
curl -sL -o g.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
unzip -oq g.zip && rm g.zip && chmod +x Godot_v4.7.2-stable_linux.x86_64 && mv Godot_v4.7.2-stable_linux.x86_64 godot && ln -sf $PWD/godot ~/bin/godot
export PATH=$HOME/bin:$PATH
git clone https://github.com/halo07-pixel/CARDs.git /home/claude/cardgame && cd /home/claude/cardgame   # repo public: clone không cần token
bash tools/run_tests.sh          # kỳ vọng: 738 passed
```

Bẫy đã gặp:
- Shell mặc định là `sh`, không phải bash: dùng `bash -c '...'` khi cần `time`, `<(...)`, `${PIPESTATUS}`, brace expansion.
- **Không dùng `pkill -f godot`** (khớp luôn shell đang chạy, tự giết lệnh). Dùng `pgrep -x godot` rồi `kill <pid>`.
- Mỗi lệnh tối đa **300 giây**. `tools/run_tests.sh` luôn chạy `--import` (~10 giây). Khi lặp nhanh: gọi thẳng `godot --headless --path . -s res://tests/run_tests.gd -- --only=test_battle,test_trigger` (lọc theo tên file test).
- Phá code kiểm chứng: làm theo **lô nhỏ (<= 8 lần/lệnh)**, chụp bản sao trước, khôi phục sau mỗi lần, cuối cùng `cmp` byte với bản sao. Nếu lệnh bị ngắt giữa chừng, **khôi phục ngay** từ bản sao trước khi làm gì khác.
- Mạng sandbox: GitHub OK; **itch.io, kenney.nl, opengameart.org bị chặn** (asset phải do người dùng gửi zip hoặc lấy từ repo mirror trên GitHub).
- `xvfb-run` + Mesa có sẵn: `xvfb-run -a godot --rendering-driver opengl3 --path .` render được ảnh thật (đã kiểm chứng ở Giai đoạn 0; **sau reset chưa kiểm tra lại**). Chụp bằng cách lưu `get_viewport().get_texture().get_image()`.
- `load()` trả về **cùng một Resource được cache**: sửa nó là sửa cho mọi nơi (đã gây lỗi test chéo). Code game **không bao giờ sửa dữ liệu lấy từ registry**; test sửa thì `.duplicate()` trước.
- Typed array trong biểu thức điều kiện (`a if c else [] as Array[X]`) có thể trả mảng không định kiểu lúc chạy -> lỗi `Trying to assign an array of type Array...`. Gán tường minh `var x: Array[X] = []`.
- Nhúng chữ `godot` vào tên file tạm của mutation cũng được, nhưng nhớ xóa file tạm (`tools/_*.gd`) trước khi commit.

## 5. Git và GitHub

- **Giao thức git bị chặn** (401) trong sandbox, nhưng REST API `api.github.com` hoạt động. Dùng hai công cụ có sẵn trong repo:
  - Đẩy: `TOKEN=... BRANCH=claude/xxx MESSAGE="feat: ..." python3 tools/gh_push.py` (tạo nhánh mới từ `main`, hoặc thêm commit lên nhánh đã có; `DRY_RUN=1` để xem trước; tự đối chiếu byte với local sau khi đẩy).
  - Gộp: `TOKEN=... BRANCH=claude/xxx python3 tools/gh_merge.py` (fast-forward vào `main`, dừng nếu `main` đã có commit lạ).
- **Token:** fine-grained PAT, *Only select repositories* = **`CARDs`** (có chữ s), *Repository permissions -> Contents: Read and write*, hạn ngắn (7 ngày là đủ). Người dùng dán token vào chat; **tuyệt đối không ghi token vào bất kỳ file/commit/log nào** (repo là PUBLIC: GitHub secret scanning sẽ tự thu hồi token bị lộ, và ai cũng đọc được). Token từng dán trong các đoạn chat cũ **phải được thu hồi**; session mới cần token mới. Nếu thấy `Bad credentials` / `Resource not accessible by personal access token`: token hết hạn/bị thu hồi, hoặc chọn nhầm repo (`CARD` thay vì `CARDs`), hoặc thiếu quyền Contents write (GitHub -> Settings -> Developer settings -> Fine-grained tokens -> Edit).
- Người dùng dùng gói **Free** của Claude -> không dùng được Claude Code trên web; vì vậy mới có cách đẩy bằng API. Không có connector GitHub trong chat.
- Quy ước: nhánh `claude/phase-X-Y-tên`, commit `<type>: <mô tả>` (`feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`), **không force-push**, chỉ gộp `main` khi người dùng nói. Người dùng cập nhật máy bằng `git checkout main` rồi `git pull origin main`.
- Lịch sử `main` (fast-forward, mỗi mốc một commit): `4d7dbd1` nền móng + combat core -> `110046d` 1.3a quái/AI -> `c0c3fc8` 1.3b BattleController -> `27ffbef` 1.3c bot/mô phỏng -> `4d0f64b` 2.1 trigger -> `4218cff` 2.2 relic -> `b519357` 2.3 potion/X-cost/nâng cấp -> `6c07cd7` 2.4 -> `b6b522f` 3.1 -> `8260bf1` 3.2 -> `0bee22d` 3.3a -> `b4e64e9` 3.3b -> `814144e` 3.4a -> `8611aec` 3.4b.

## 6. Kiến trúc

Nguyên tắc: **lõi không phụ thuộc node/UI**, UI chỉ gọi xuống `BattleController` và nghe Signal. Dữ liệu là `Resource` thuần (file `.tres` là nguồn sự thật), logic ở `src/core`.

```
src/data/      Resource dữ liệu thuần (không logic, không hình): CardData, EffectData, StatusData, TriggerData,
               EnemyData, EnemyMove, CharacterData, RelicData, PotionData
src/core/      Lõi chiến đấu (RefCounted, không node):
  thẻ/bài      Deck (5 vùng: draw/hand/discard/exhaust/limbo), CardInstance
  đơn vị       Combatant (máu/giáp/status), EnemyUnit (+EnemyAI, IntentInfo)
  hiệu ứng     EffectResolver (+ResolverContext trừu tượng), DamageCalculator, EffectResult, DamageResult
  trận đấu     BattleState (máy trạng thái), BattleConfig, BattleController, BattleFactory
  trigger      BattleEvent, TriggerSource, TriggerDispatcher, TriggerRunner, ActionQueue, QueuedAction
  tra cứu      ResourceRegistry (lớp gốc trừu tượng) -> Status/Enemy/Card/Relic/PotionRegistry; PotionBelt
src/sim/       Bot và mô phỏng: BattleBot (trừu tượng), RandomBot, GreedyBot, BattleSimulator,
               BattleInvariants, ScenarioStats
src/autoload/  EventBus, SaveSystem, RunState, AudioManager, SceneRouter (Giai đoạn 0)
src/ui/          UI dựng bằng code (Control): view-model thuần (CardView, StatusView, IntentView) + logic thuần không node
               (CardTextFormatter, PlayIntent, DropIntent, DragGesture, ArrowGeometry/ArrowShape, EnemyHitTest, RejectionText, UiUtil)
               + control (CardUI, HandUI, EnemyUI, CombatantUI, StatusIconUI, HealthBarUI, EnergyUI, PileCounterUI,
               TargetArrowUI, PlayZoneUI, ResultOverlayUI, BattleScene = màn chiến đấu, IconLibrary)
src/data/      (thêm) GameData: gom 5 registry; BattleFactory.create_from_game_data(...) là cách dựng trận ngắn gọn
scenes/        boot.tscn, battle/battle_demo.tscn (F6 để chơi thử)
assets/        fonts/kenney_pixel.ttf (CC0), icons/*.svg (tự vẽ, sinh bởi tools/generate_icons.py), CREDITS.md
data/          cards(38) enemies(5) statuses(11) relics(10) potions(8) characters(1)   [.tres]
tests/         72 file test + test_case.gd + factory/recorder/ui_input; runner: tests/run_tests.gd
tools/         run_tests.sh, simulate_battles.gd, generate_starter_*.gd, generate_icons.py (icon SVG), capture_*.gd (chụp ảnh bằng xvfb), gh_push.py, gh_merge.py
```

`BattleController` (file `src/core/battle_controller.gd`) là **cửa duy nhất cho UI**:

- Tạo: `BattleFactory.create(character, player, deck_ids, enemy_ids, cards, enemies, statuses, seed=1, turn_cap=0, relic_ids=[], relic_registry=null, potion_ids=[], potion_registry=null, potion_slots=3)` (trả `null` + log lỗi nếu dữ liệu sai) hoặc `BattleController.create_from_data(...)`. Người chơi là `Combatant` do nơi gọi tạo (`BattleFactory.create_player(character, current_hp)`), **máu được giữ trên chính đối tượng đó sau trận**.
- Gọi xuống: `start_battle()`, `play_card(card, target=null)`, `use_potion(slot, target=null)`, `end_player_turn()`; truy vấn: `can_play(card)`, `valid_targets(card)`, `living_enemies()`, `trigger_queue_size()`, `trigger_overflowed()`; đọc: `player`, `enemies`, `deck`, `potions` (PotionBelt), `relics`, `energy`, `turn`, `state.phase`, `end_reason`.
- Signal lên: `state.changed(from,to)`, `energy_changed`, `turn_started(turn, is_player)`, `intent_changed(unit)`, `card_played(card,target,results)`, `enemy_acted(unit,move,results)`, `enemy_defeated(unit)`, `triggered(owner,source_key,results)`, `potion_used(slot,potion,target,results)`, `action_rejected(reason)`, `battle_ended(victory)`. Deck cũng có signal riêng (`card_drawn`, `card_discarded`, `card_exhausted`, `reshuffled`, `pile_changed`); `PotionBelt.changed`; `Combatant`: `health_changed`, `block_changed`, `status_changed`, `died`.
- Mã lý do từ chối: `already_started`, `battle_over`, `not_player_turn`, `card_not_in_hand`, `unplayable`, `not_enough_energy`, `invalid_target`, `no_potion`. Lý do kết thúc: `victory`, `defeat`, `turn_cap`.
- Hành động bị từ chối **không đổi gì** và phát `action_rejected` (UI dùng để rung/báo lỗi).

## 7. Luật game và quyết định thiết kế (đã chốt, có test)

| Chủ đề | Quy tắc |
|---|---|
| Sát thương | `floor((base + Strength) x Weak(0.75) x Vulnerable(1.5))`, làm tròn ở bước cuối, tối thiểu 0. Giáp: `floor((base + Dexterity) x Frail(0.75))`. Giáp trừ trước máu. |
| Lượt | Đầu lượt người chơi: năng lượng về tối đa (3, **không cộng dồn**), rút 5. Giáp của mỗi bên xóa ở **đầu lượt của chính bên đó**, trừ khi có Barricade; **lượt 1 của người chơi không xóa giáp** (để giáp từ `BATTLE_START` còn nguyên). Status giảm theo lượt giảm ở cuối lượt của chủ sở hữu. |
| Thắng/thua | Người chơi chết được xét trước (**thua ưu tiên hơn thắng**). `battle_ended` phát đúng một lần. Trận bế tắc kết thúc bằng `turn_cap` (tính là thua). |
| Limbo | Thẻ đang chơi rời tay sang vùng `limbo`, hiệu ứng chạy xong mới vào discard/exhaust -> thẻ rút bài không thể tự rút lại chính nó. Thẻ **Power** sau khi chơi vào exhaust (rời vòng xáo bài). |
| Quái | Chiêu cho trước (`intent`) hiển thị sát thương đã tính đủ Strength/Weak/Vulnerable. Pattern: `SEQUENCE` (cho phép lặp chiêu) hoặc `WEIGHTED` (có `max_consecutive`, không bao giờ kẹt). Chọn chiêu tiếp theo ngay sau khi quái hành động. |
| Trigger | Sự kiện: `BATTLE_START, BATTLE_VICTORY, TURN_START, TURN_END, CARD_PLAYED, ATTACKED, HP_LOST`. Trigger của chủ sở hữu chỉ nổ khi chủ sở hữu là "subject" (trừ `BATTLE_*`). Tìm trigger **không lưu đăng ký**: mỗi lần duyệt status/relic đang có. Thứ tự: người chơi trước (relic rồi status), rồi quái. Effect do trigger sinh ra vào **hàng đợi FIFO**, giới hạn 1000 hành động mỗi lần xử lý; **không sinh `ATTACKED`** (Thorns không kích hoạt Thorns). `BATTLE_VICTORY` chạy **trước** `battle_ended` (máu hồi của Burning Blood kịp tính). Poison nổ ở đầu lượt chủ rồi mới giảm 1. |
| Status | Hệ số (Strength, Dexterity, Vulnerable, Weak, Frail) + trigger (Poison, Metallicize, Thorns, Demon Form) + cờ (`retains_block` Barricade, `negates_debuff` Artifact). Artifact chặn debuff mới, không chặn buff hay việc giảm debuff. |
| X-cost | Tiêu **hết** năng lượng; effect `scales_with_x` lặp `X + x_bonus` lần; X=0 vẫn chơi được nhưng không làm gì. `scales_with_x` chỉ hợp lệ trên thẻ X-cost. |
| Potion | 3 ô, dùng ở lượt người chơi, **không tốn năng lượng**. Sát thương potion dùng công thức chuẩn (Strength có tác dụng) nhưng **không tính là đòn tấn công** (không kích hoạt Thorns). |
| Nâng cấp | Mỗi thẻ gốc có `upgraded_id` trỏ tới thẻ `+` (id kết thúc `+`, file `xxx_plus.tres`). `CardRegistry.upgrade_problems()` là **bài kiểm tra dữ liệu**: bản `+` không được yếu hơn ở bất kỳ điểm nào, không đắt hơn, không đổi loại/độ hiếm/nhân vật/kiểu nhắm, không thêm exhaust/ethereal, và phải tốt hơn ở ít nhất một điểm. |
| Relic | Trigger + bonus tĩnh (`max_energy_bonus`, `draw_per_turn_bonus`) áp vào `BattleConfig`, **không** sửa dữ liệu nhân vật. Relic kiểu "+máu tối đa khi nhặt" là hiệu ứng **tầng run (Giai đoạn 4)**, cố ý không đưa vào đây. |
| Xác định | Cùng seed + cùng chuỗi hành động = cùng kết quả (RNG xáo bài và RNG trận đấu tách riêng, sinh từ seed). |
| Dữ liệu | **Enum lưu dạng số nguyên trong `.tres` -> giá trị enum mới luôn thêm vào CUỐI.** `EVENT_SOURCE` (đích effect) chỉ dùng trong trigger. Mọi `status_id` trong dữ liệu phải tồn tại (có test tham chiếu chéo). Generator **không ghi đè** file `.tres` đã có (ngoại lệ: vá thêm đúng dòng `upgraded_id`). |

## 8. Dữ liệu hiện có

- **Warrior** (`data/characters/warrior.tres`): 80 máu, 3 năng lượng, rút 5, 99 vàng; bộ bài 5 Strike + 4 Defend + 1 Bash.
- **38 thẻ** = 19 gốc + 19 bản `+`: strike, defend, bash, cleave, iron_wave, pommel_strike, shrug_it_off, twin_strike, thunderclap, deadly_poison, bandage_up, adrenaline, inflame, metallicize, bloodletting, whirlwind (X), skewer (X), demon_form, barricade.
- **3 quái:** slime (ngẫu nhiên, gắn Weak), goblin (đánh rồi thủ), acolyte (tự tăng Strength). Số liệu máu/sát thương là **placeholder** (Slime chết sau ~2 lượt).
- **11 status:** strength, dexterity, vulnerable, weak, frail, poison, metallicize, thorns, demon_form, artifact, barricade.
- **10 relic:** burning_blood, anchor, vajra, lantern, bag_of_preparation, happy_flower, orichalcum, bronze_scales, energy_crystal, wide_lens.
- **8 potion:** fire, explosive, block, strength, energy, swift, weak, blood.
- Mô tả thẻ dùng chỗ giữ chỗ `{damage}`, `{block}`... **chưa có bộ định dạng** (việc của UI).

## 9. Công cụ và cách kiểm chứng

- **Test:** `bash tools/run_tests.sh [--only=chuoi1,chuoi2]`; thoát mã 1 nếu có lỗi. Test dùng `extends "res://tests/test_case.gd"` (đường dẫn, không `class_name`), hàm `test_*`, hook `before_each/after_each`, `assert_eq/assert_true/...`. Có `tests/combat_factory.gd`, `tests/card_factory.gd`, `tests/battle_recorder.gd`.
- **Mô phỏng:** `godot --headless --path . -s res://tools/simulate_battles.gd -- --battles=300 --seed=1 [--deck=starter|all] [--relics=all] [--potions=N]` in thắng/lượt/máu mất/potion dùng cho từng nhóm quái và từng bot; **thoát mã 1 nếu có vi phạm bất biến** (tổng số thẻ, máu/năng lượng trong giới hạn, `battle_ended` đúng một lần, hàng đợi trigger rỗng khi nghỉ, dây potion...).
- **Phá code kiểm chứng (mutation, làm tay):** sửa một dòng logic -> chạy test liên quan -> phải có test FAIL -> khôi phục. Đã làm cho mọi giai đoạn; trường hợp không bị bắt đều được phân tích (xem mục 11). Giai đoạn 2.3: 23 lần phá đều bị bắt **trước khi sandbox reset**; sau khi dựng lại bằng cách chạy lại từng bước, **chưa chạy lại** các lần phá đó (code giống hệt, 466 test đạt).
- **Sinh dữ liệu:** `godot --headless --path . -s res://tools/generate_starter_{cards,statuses,enemies,relics,potions,character}.gd`.

## 10. Tiến độ chi tiết

| Giai đoạn | Nội dung | Trạng thái | Test |
|---|---|---|---|
| 0 | Nền móng: autoload, lưu/tải (JSON + atomic), SceneRouter, runner test | Xong, trên `main` | 31 |
| 1.1 | CardData/EffectData/CardInstance/Deck | Xong | 78 |
| 1.2 | StatusData, Combatant, DamageCalculator, EffectResolver | Xong | 136 |
| 1.3a | EnemyData/AI/IntentInfo/ResourceRegistry | Xong | 170 |
| 1.3b | BattleState, BattleController, limbo | Xong | 218 |
| 1.3c | CharacterData, CardRegistry, BattleFactory, bot, mô phỏng | Xong | 278 |
| 2.1 | Sự kiện/trigger, Poison/Thorns/..., Power, HEAL/LOSE_HP | Xong, trên `main` | 360 |
| 2.2 | Relic | Xong, trên `main` | 393 |
| **2.3** | Potion, X-cost, nâng cấp thẻ + lint | **Xong, đã gộp** | **466** |
| **2.4** | Quái có status đầu trận (`starting_statuses`), Spiker (Thorns), Toxic Slug (Poison) | **Xong, đã gộp** (bỏ phần "bot dùng potion": đo thực tế bot đã dùng ~0,7 potion/trận) | **479** |
| **3.1** | `CardTextFormatter` + `CardView` + `CardUI` (+ `tools/capture_cards.gd` chụp ảnh) | **Xong, đã gộp** | **506** |
| **3.2** | Icon SVG tự vẽ (`tools/generate_icons.py`, 18 icon), font Kenney Pixel, `StatusView`/`IntentView`, `StatusIconUI`/`HealthBarUI`/`CombatantUI`/`EnemyUI` (+ `tools/capture_combatants.gd`) | **Xong, đã gộp** | **556** |
| **3.3a** | `GameData` + `BattleFactory.create_from_game_data`, `BattleController.play_rejection_reason`, `PlayIntent` (click chơi thẻ, tự nhắm khi 1 quái), `RejectionText`, `HandUI` (10 thẻ vừa khung, dựng lại trì hoãn), `EnergyUI`, `PileCounterUI` (+ `tools/capture_hand.gd`) | **Xong, đã gộp** | **616** |
| **3.3b** | `BattleScene` (ghép HandUI/EnemyUI/CombatantUI/EnergyUI/PileCounterUI, End Turn, nhãn lý do từ chối, hủy bằng Esc/chuột phải), `ResultOverlayUI` (Victory/Defeat + Play again), scene demo F6, test tích hợp + test ngẫu nhiên "UI khớp lõi" (10 seed) (+ `tools/capture_battle.gd`) | **Xong, đã gộp** | **648** |
| **3.4a** | Logic kéo thả: `DragGesture` (click vs kéo, ngưỡng 12 px), `DropIntent` (nhả lên quái/vùng thả = 60% phía trên màn hình, tự nhắm khi 1 quái), `ArrowGeometry`/`ArrowShape` (mũi tên cong), `EnemyHitTest`; `HandUI`: hover nhô lên + vẽ trên cùng, `set_preview_target` (số theo Vulnerable); `PlayIntent.make_decision` thành static (+ `tools/capture_hover.gd`) | **Xong, đã gộp** | **694** |
| **3.4b** | Kéo thả thật: `CardUI` (click khi NHẢ chuột; `drag_started/moved/ended/cancelled`), `HandUI` (`begin_drag/move_drag/end_drag/cancel_drag/card_anchor`, dựng lại giữa lúc kéo thì báo huỷ), `TargetArrowUI`, `PlayZoneUI`, `BattleScene` điều phối (`DragGesture`+`DropIntent`+`EnemyHitTest`), Esc/chuột phải huỷ, thẻ không đủ điều kiện không kéo được; test tích hợp + test ngẫu nhiên có kéo thả (+ `tools/capture_drag.gd`) | **Xong, đã gộp** | **738** |
| 3 | UI chiến đấu | **Chưa làm** | - |
| 4 | Run: map, thưởng, shop, lửa trại, sự kiện | Chưa làm | - |
| 5 | Menu chính, chọn nhân vật, lưu/tiếp tục, cài đặt | Chưa làm | - |
| 6 | Nội dung: Act 2-3, nhân vật thứ hai, đủ thẻ/relic/quái | Chưa làm | - |
| 7 | Asset CC0, âm thanh, hiệu ứng | Chưa làm | - |
| 8 | Cân bằng bằng bot, đóng gói | Chưa làm | - |

## 11. Nợ kỹ thuật, giới hạn đã biết, chỗ chưa chắc

1. `src/core/battle_controller.gd` dài **407 dòng** (> 400 điển hình của quy chuẩn, < 800 trần mềm). Nếu thêm nữa nên tách (vd. lượt quái ra một lớp riêng).
2. `BattleFactory.create` có **14 tham số**: đã có bản rút gọn `BattleFactory.create_from_game_data(character, deck_ids, enemy_ids, game_data, seed, relic_ids, potion_ids, current_hp, turn_cap)` dùng `GameData`; bản cũ giữ cho test.
3. **Cân bằng chỉ là placeholder:** quái đơn quá dễ (bot thắng ~100%); mang cả 10 relic thì gần như không mất máu. Đo ở 2.4: `GreedyBot` dùng khoảng 0,7-0,8 potion/trận khi mang 3 potion (không phải "gần như không dùng" như ghi trước đây).
4. Sát thương của trigger và của potion dùng công thức chuẩn (Strength có tác dụng) - khác Slay the Spire (Thorns/potion không nhận Strength).
5. Các lần phá code **không bị bắt** đã được phân tích và đều tương đương về hành vi (chỉ khác thông báo/cảnh báo log): bỏ `break` khi người chơi tự chết giữa thẻ (resolver đã tự từ chối nguồn đã chết); bỏ nhánh "thiếu registry" của relic trong `BattleFactory` (chốt kế tiếp bắt cùng kết quả).
6. Chưa có: chiêu quái theo ngưỡng máu, boss nhiều pha, quái triệu hồi, thẻ sinh ra trong bộ bài (Wound/Dazed), hiệu ứng "bỏ thẻ"/"exhaust ngẫu nhiên", i18n. Không lưu giữa trận (thiết kế: chỉ lưu giữa các phòng).
7. **`RunState` (autoload) chưa nối với trận đấu.** Hợp đồng dự kiến: `RunState` giữ id (`deck`, `relics`, `potions` là `Array[String]`, `hp`, `max_hp`, `gold`, `seed`); chuyển sang `Array[StringName]` khi gọi `BattleFactory`; sau trận: `RunState.hp = player.hp`, `RunState.potions = controller.potions.to_ids()`; thưởng/xóa thẻ làm ở tầng run.
8. Pipeline chụp ảnh `xvfb` **đã kiểm tra hoạt động** (từ mốc 3.1; mỗi mốc có `tools/capture_*.gd`). Sandbox KHÔNG có chuột/bàn phím thật: kéo thả, hover, phím chỉ kiểm tra bằng sự kiện giả; **cảm giác thao tác thật phải nhờ người dùng thử trên máy** (F6 `battle_demo.tscn`).

## 12. Asset (kế hoạch)

Yêu cầu: bản quyền CC0 hoặc ghi rõ; **mọi asset phải ghi vào `assets/CREDITS.md`**. Hiện có: font Kenney Pixel (CC0, lấy qua mirror GitHub `ETdoFresh/kenney.nl`, đã đọc license từng pack) và 18 icon SVG tự vẽ (chờ người dùng xác nhận CC0). **Nguồn đã khảo sát:** mirror `ETdoFresh/kenney.nl` có 20 pack CC0 dùng được (UI Pack, Pixel UI Pack, âm thanh UI/impact/RPG, font); `game-icons/icons` có icon chiến đấu nhưng chủ yếu CC BY 3.0 (phải ghi tác giả, KHÔNG phải CC0); 0x72 DungeonTileset II là CC0 (xác nhận trên trang tác giả) nhưng chỉ nên lấy từ itch.io: **nhờ người dùng tải zip gửi lên chat** (sandbox bị chặn itch.io/kenney.nl/opengameart). Chưa có sprite quái/nhân vật, nhạc, âm thanh.

## 13. Bước tiếp theo đề xuất

1. **Mốc 3.5 (tiếp theo):** potion belt (dùng potion bằng click/kéo, chọn mục tiêu nếu cần) + relic bar trên màn hình, tooltip (hover) cho status/thẻ/relic/potion/từ khóa (Vulnerable, Exhaust...), xem nội dung pile bằng click. Trình bày thiết kế trước, chờ duyệt (quy trình 5 bước). Gợi ý chia 3.5a (logic + view-model + tooltip) và 3.5b (ghép vào BattleScene + test ngẫu nhiên mở rộng).
2. Mốc 3.6: hiệu ứng (số sát thương nổi, rung thẻ khi bị từ chối, animation lượt quái thay vì tức thì, thanh máu mượt, âm thanh Kenney). Sau đó **Giai đoạn 4 (run: bản đồ, phòng, cửa hàng, nối `RunState` với trận)** và **Giai đoạn 5 (menu/meta)**, theo bảng mục 10.
3. **Giai đoạn 3 (UI chiến đấu)** đang làm theo kế hoạch đã duyệt (xem mục Trạng thái): **tiếp theo là mốc 3.5** (potion belt + relic bar trên màn hình, tooltip cho status/thẻ/relic/potion, xem pile bằng click). Người dùng cần kiểm tra cảm giác kéo thả trên máy thật (sandbox chỉ có chuột giả). Sau đó 3.5 (potion/relic/tooltip), 3.6 (hiệu ứng, số nổi, animation lượt quái). UI **không bao giờ sửa lõi**, chỉ gọi `play_card/use_potion/end_player_turn` và đọc trạng thái qua Signal; dữ liệu hiển thị đi qua view-model (như `CardView`), không để UI tự tính luật. Mỗi mốc: test headless + chụp ảnh `xvfb` (`tools/capture_*.gd`) gửi người dùng. **Lưu ý harness:** test không có assertion nào bị tính là FAIL (bắt test chết vì lỗi script giữa chừng); lỗi script TRONG hàm xử lý Signal thì KHÔNG làm test fail, nên test vòng đời Signal phải kiểm tra trực tiếp `get_connections()` và test rò rỉ dùng `Performance.OBJECT_ORPHAN_NODE_COUNT` (đo sau khi trạng thái ổn định).
   **Lưu ý controller:** `intent_changed` phát ngay khi quái chọn chiêu mới (và khi số ý định đổi đầu lượt); phase sang PLAYER_TURN xảy ra SAU `turn_started` nên nút End Turn phải nghe `state.changed`; controller chỉ kiểm tra thắng/thua sau một hành động (đừng hạ quái bằng `take_damage` rồi mong UI báo thắng).
   **Bẫy đã gặp ở UI:** (1) `Array[StringName].sort()` so sánh theo địa chỉ bộ nhớ -> thứ tự không ổn định giữa các lần chạy; luôn `sort_custom` theo `String(...)`. (2) Status Artifact chặn debuff gắn SAU nó (đúng luật): khi dựng ví dụ/test, gắn Artifact CUỐI CÙNG hoặc đừng dùng. (3) Font Kenney Pixel nhỏ: dùng cỡ chữ lớn (thẻ 28-44, nhãn 24-32). (4) Sửa file `.gd` bằng script: thụt lề là TAB. (5) `ProgressBar` tự giới hạn giá trị. (6) Control con mặc định chặn chuột (ColorRect, RichTextLabel): dùng `UiUtil.ignore_mouse_in_children`. (7) Click thẻ -> controller đổi tay bài -> giải phóng ngay sẽ giải phóng CardUI đang phát tín hiệu: luôn `request_refresh()` (trì hoãn), không `refresh()` trong handler. (9) Harness chỉ gọi `before_each` (không có `before_all`). (10) `var x: Array[T] = a if c else []` tạo mảng KHÔNG kiểu -> lỗi script nuốt mất cả hàm: dùng if/else. (11) Test `await` được (harness `await` mỗi test). (12) `Array.sort()` hay so sánh float: dùng ngưỡng sai số (ví dụ hướng mũi tên độ dài 0). (13) Thẻ dựng bằng `tests/combat_factory.gd` KHÔNG có mô tả; test hiển thị chữ phải dùng thẻ thật từ `CardRegistry`. (15) Click trên thẻ tính khi NHẢ chuột (bấm xuống chưa biết là click hay kéo); test cũ dùng `UiInput.click()` (chỉ bấm xuống) phải đổi thành `press` + `release`. (16) Controller giữ chuột cho control đã nhận lúc bấm nên `_gui_input` của CardUI vẫn nhận chuyển động/nhả khi con trỏ ra ngoài thẻ; test headless gọi trực tiếp `_gui_input` với `global_position`. (17) Đặt tọa độ UI theo `DropIntent.DESIGN_SCREEN` (1920x1080), không dùng `size` của node. (18) Test cần toạ độ thật phải thêm node vào `Engine.get_main_loop().root` và `await process_frame`. (14) `Deck.add_to_hand` từ chối thẻ đã nằm trong một pile; muốn đưa cùng thẻ về tay phải đi qua xáo bài (`end_turn_discard` rồi `draw`). (8) Test headless gọi trực tiếp `ui._gui_input(tests/ui_input.gd click())` để mô phỏng chuột. Ảnh chụp: `xvfb-run -a godot --rendering-driver opengl3 --path . -s res://tools/capture_*.gd --resolution 1920x1080 -- --out=/tmp/x.png` (project stretch canvas_items 1920x1080 nên phải truyền --resolution đúng).
4. Sau đó Giai đoạn 4 (run), 5 (menu/meta)... theo bảng mục 10.

## 14. Prompt khởi động cho session mới (dán nguyên văn)

> Dự án game thẻ bài roguelike Godot 4.7.2 (GDScript): repo `https://github.com/halo07-pixel/CARDs` (public, nhánh `main`). Việc đầu tiên: clone, đọc `HANDOFF.md` và `CLAUDE.md` ở thư mục gốc, dựng môi trường theo mục 4, chạy `bash tools/run_tests.sh` (kỳ vọng 738 test đạt) và báo kết quả. Sau đó tóm tắt tiến độ trong 5 dòng. Giai đoạn 0 đến 3.4b đã xong và đã gộp; mốc tiếp theo là 3.5 (potion belt, relic bar, tooltip). Tuân thủ quy trình 5 bước (trình bày thiết kế trước, chờ tôi duyệt rồi mới viết code), nội dung game bằng tiếng Anh, trả lời tiếng Việt, báo cáo trung thực (kể cả lần phá code không bị test bắt), chụp ảnh màn hình mỗi mốc. Khi cần đẩy code lên GitHub tôi sẽ đưa token mới (fine-grained, chỉ repo CARDs, Contents: Read and write); dùng `tools/gh_push.py` và `tools/gh_merge.py`, **không ghi token vào file/commit/log**, chỉ gộp `main` khi tôi nói.
