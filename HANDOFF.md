# HANDOFF - Spire Cards (repo `halo07-pixel/CARDs`)

> Tài liệu bàn giao cho session/đoạn chat mới. Đọc hết file này + `CLAUDE.md` trước khi làm bất cứ gì.
> Cập nhật lần cuối: sau khi mốc **4.1** (bản đồ) được gộp. `main` có mọi thứ đến mốc 4.1 (commit `6f16f19`). **1148 test đạt.** Tiếp theo: mốc 4.2 (lõi lượt chạy), chưa bắt đầu (cần trình bày thiết kế và chờ người dùng duyệt).

## 1. TL;DR

- **Dự án:** game thẻ bài roguelike kiểu *Slay the Spire*, **Godot 4.7.2 / GDScript**, 1920x1080, renderer Compatibility.
- **Trạng thái:** **Giai đoạn 0-3 xong** (lõi chiến đấu, thẻ, status, trigger, relic, potion, X-cost, AI quái, bot/mô phỏng; UI chiến đấu đầy đủ: thẻ, quái/ý định, tay bài, kéo thả, dây potion, thanh relic, tooltip, xem pile, hiệu ứng chữ nổi/thanh máu mượt/rung/nảy, **lượt quái diễn tuần tự**, âm thanh), refactor `BattleScene` (đã tách `BattleFeedback`, `CardDragHandler`), mốc 4.0 (bộ chạy test nghiêm ngặt, hết rò rỉ). **Mốc 4.1 (sinh bản đồ, `src/run/`) xong và đã gộp.** Mô phỏng 0 vi phạm. Chơi thử: mở `scenes/battle/battle_demo.tscn` trong Godot rồi bấm F6 (có 4 relic, 3 potion, hiệu ứng và âm thanh bật).
- **Chưa có:** `RunController`/phòng/thưởng/cửa hàng/lửa trại/sự kiện/màn hình run (4.2-4.6), nối `RunState` với trận, menu/meta (Giai đoạn 5), nhân vật thứ hai, sprite quái (đang là ô chữ cái), nhạc nền, màn Settings, elite/boss (chưa có quái nào thuộc hai loại này).
- **Đã duyệt (Giai đoạn 4):** 4.0 dọn nền (xong), 4.1 bản đồ (xong, đã gộp), 4.2 lõi run, 4.3 nối trận, 4.4 sự kiện + nội dung tối thiểu (1 elite, 1 boss), 4.5 giao diện run, 4.6 lưu/tiếp tục. **Quyết định đã chốt:** chỉ chơi Act 1 (mã hỗ trợ nhiều act, Act 2-3 để Giai đoạn 6; thắng boss = thắng run); RNG tách luồng theo lĩnh vực từ seed run (`RunRng`); lưu theo phòng, không lưu giữa trận; `RunController` nhận một `RunState` được truyền vào (không gọi thẳng autoload); nội dung game bằng tiếng Anh. Asset: tự vẽ icon SVG (CC0) + font/âm thanh Kenney CC0 từ mirror `ETdoFresh/kenney.nl` (đã đọc license từng pack) + 0x72 DungeonTileset II (CC0, người dùng tải từ itch.io vì sandbox không tải được). Ghi mọi asset vào `assets/CREDITS.md` khi nhập.
- **Repo đúng là `halo07-pixel/CARDs` (có chữ s)**; repo `CARD` và `cad` không dùng.
- **Việc đầu tiên của session mới:** dựng môi trường (mục 4), chạy `bash tools/run_tests.sh` (kỳ vọng 1148) và `bash tools/check_runner.sh`, tóm tắt 5 dòng, rồi **trình bày thiết kế mốc 4.2** (mục 13) và chờ người dùng duyệt (đừng tự viết code).

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

**Sandbox bị reset bất cứ lúc nào** (đã xảy ra HAI lần: mất code 2.3 và mất code 4.0 chưa đẩy). => **đẩy lên GitHub sau mỗi mốc**, kể cả khi chưa xong hẳn nếu việc đã dài.

Khởi động nhanh:

```bash
mkdir -p ~/bin /home/claude/godot && cd /home/claude/godot
curl -sL -o g.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
unzip -oq g.zip && rm g.zip && chmod +x Godot_v4.7.2-stable_linux.x86_64 && mv Godot_v4.7.2-stable_linux.x86_64 godot && ln -sf $PWD/godot ~/bin/godot
export PATH=$HOME/bin:$PATH
git clone https://github.com/halo07-pixel/CARDs.git /home/claude/CARDs && cd /home/claude/CARDs   # repo public: clone không cần token
git config user.name claude && git config user.email noreply@anthropic.com
bash tools/run_tests.sh          # kỳ vọng: 1148 passed (lần đầu import tài sản nên lâu hơn)
bash tools/check_runner.sh       # tự kiểm bộ chạy test (4 ca)
```

Bẫy đã gặp:
- **Bộ chạy test nghiêm ngặt (từ 4.0):** `tools/run_tests.sh` thoát mã 1 nếu có test FAIL, hoặc có dòng `SCRIPT ERROR`/`Parse Error`, hoặc Godot báo rò rỉ khi thoát (`ObjectDB instances were leaked`, `resources still in use`). Trước đó một lỗi script giữa chừng làm hàm test chết nhưng test vẫn báo "đạt" nếu đã có assertion trước đó. Tìm nguồn rò rỉ: chạy `godot --headless --verbose ...` rồi chia nhóm file test (`--only=`).
- **Vòng tham chiếu trong test:** lambda bắt `self` hoặc chính đối tượng phát tín hiệu rồi nối vào tín hiệu của nó (`controller.signal.connect(func(): controller...)`) tạo vòng tham chiếu RefCounted -> rò rỉ. Bắt biến cục bộ cần dùng (vd. `var player := controller.player`), và đặt thành viên RefCounted có lambda về `null` trong `after_each`. Test `Node` tạo ra phải `free()`.
- **Git cục bộ `main` bị cũ:** `tools/gh_merge.py` gộp qua API nên nhánh `main` cục bộ KHÔNG tự cập nhật. Luôn `git fetch origin && git checkout -B claude/xxx origin/main` khi bắt đầu nhánh mới (đã từng dựng nhánh trên `main` cũ: nhận ra vì số test chỉ là 738).
- **Tiến trình nền bị dọn:** `nohup ... &` bị hệ thống kill khi lệnh gọi công cụ kết thúc. Chạy foreground với `timeout`, lưu tiến độ ra file nếu việc dài.
- Shell mặc định là `sh`, không phải bash: dùng `bash -c '...'` khi cần `time`, `<(...)`, `${PIPESTATUS}`, brace expansion.
- **Không dùng `pkill -f godot`** (khớp luôn shell đang chạy). Dùng `pgrep -x godot` rồi `kill <pid>`.
- Mỗi lệnh tối đa **300 giây**. `tools/run_tests.sh` luôn chạy `--import`. Khi lặp nhanh: gọi thẳng `godot --headless --path . -s res://tests/run_tests.gd -- --only=test_a.gd,test_b.gd` (lọc theo tên file; dùng đuôi `.gd` để khớp chính xác).
- **Chụp ảnh `xvfb`:** `xvfb-run -a godot --audio-driver Dummy --path . -s res://tools/capture_*.gd --resolution 1920x1080 -- --out=/tmp/x`. **Thiếu `--audio-driver Dummy` Godot có thể treo** (thử mở thiết bị âm thanh thật). Script chạy dạng `-s` biên dịch trước khi autoload tồn tại nên **không được tham chiếu trực tiếp autoload** (vd. `EventBus`) trong script mà công cụ chụp nạp (đã gặp: `BattleScene` giờ phát tín hiệu `sfx_requested`, nơi sở hữu nối vào `EventBus`). `capture_hud.gd`, `capture_interaction.gd`, `capture_map.gd` cho ảnh **tất định** (giống từng byte giữa hai lần chạy); `capture_fx.gd` dùng thời gian thật nên không tất định.
- **Phá code kiểm chứng:** làm theo **lô nhỏ (<= 8-10 lần/lệnh; test fuzz mỗi lần ~15-25 giây)**, chụp bản sao trước, khôi phục sau mỗi lần, cuối cùng chạy lại toàn bộ test. **Nếu lệnh bị `timeout` ngắt giữa chừng, file đang bị phá còn nằm lại: khôi phục ngay** (đã từng làm hỏng nền một lần); công cụ chỉ nên sao lưu SAU khi xác nhận chuỗi cần thay khớp đúng một chỗ.
- Mạng sandbox: GitHub OK (kể cả clone repo mirror Kenney bằng `git clone --filter=blob:none --no-checkout` rồi `git sparse-checkout`); **itch.io, kenney.nl, opengameart.org bị chặn**. API GitHub không xác thực bị giới hạn tần suất.
- `load()` trả về **cùng một Resource được cache**: sửa nó là sửa cho mọi nơi. Code game **không bao giờ sửa dữ liệu lấy từ registry**; test sửa thì `.duplicate()` trước.
- Typed array trong biểu thức điều kiện (`a if c else [] as Array[X]`) có thể trả mảng không định kiểu lúc chạy. Gán tường minh `var x: Array[X] = []`.
- Đừng đặt tên biến/tham số là `floor` (che hàm dựng sẵn `floor()`): dùng `floor_index`. `Array[StringName].sort()` và `sort()` trên StringName so theo con trỏ nội bộ (không tất định giữa các lần chạy): luôn `sort_custom` theo `String(...)`. `CardInstance._next_uid` là biến static toàn cục nên uid tuyệt đối phụ thuộc lịch sử tiến trình.
- Nhớ xóa file tạm (`tools/_*.gd`, `tests/test_zz_*`) trước khi commit.

## 5. Git và GitHub

- **Giao thức git bị chặn** (401) trong sandbox, nhưng REST API `api.github.com` hoạt động. Dùng hai công cụ có sẵn trong repo:
  - Đẩy: `TOKEN=... BRANCH=claude/xxx MESSAGE="feat: ..." python3 tools/gh_push.py` (tạo nhánh mới từ `main`, hoặc thêm commit lên nhánh đã có; `DRY_RUN=1` để xem trước; tự đối chiếu byte với local sau khi đẩy).
  - Gộp: `TOKEN=... BRANCH=claude/xxx python3 tools/gh_merge.py` (fast-forward vào `main`, dừng nếu `main` đã có commit lạ).
- **Token:** fine-grained PAT, *Only select repositories* = **`CARDs`** (có chữ s), *Repository permissions -> Contents: Read and write*, hạn ngắn (7 ngày là đủ). Người dùng dán token vào chat; **tuyệt đối không ghi token vào bất kỳ file/commit/log nào** (repo là PUBLIC: GitHub secret scanning sẽ tự thu hồi token bị lộ, và ai cũng đọc được). Token từng dán trong các đoạn chat cũ **phải được thu hồi**; session mới cần token mới. Nếu thấy `Bad credentials` / `Resource not accessible by personal access token`: token hết hạn/bị thu hồi, hoặc chọn nhầm repo (`CARD` thay vì `CARDs`), hoặc thiếu quyền Contents write (GitHub -> Settings -> Developer settings -> Fine-grained tokens -> Edit).
- Người dùng dùng gói **Free** của Claude -> không dùng được Claude Code trên web; vì vậy mới có cách đẩy bằng API. Không có connector GitHub trong chat.
- Quy ước: nhánh `claude/phase-X-Y-tên`, commit `<type>: <mô tả>` (`feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`), **không force-push**, chỉ gộp `main` khi người dùng nói. Người dùng cập nhật máy bằng `git checkout main` rồi `git pull origin main`.
- Lịch sử `main` (fast-forward, mỗi mốc một commit): `4d7dbd1` nền móng + combat core -> `110046d` 1.3a -> `c0c3fc8` 1.3b -> `27ffbef` 1.3c -> `4d0f64b` 2.1 -> `4218cff` 2.2 -> `b519357` 2.3 -> `6c07cd7` 2.4 -> `b6b522f` 3.1 -> `8260bf1` 3.2 -> `0bee22d` 3.3a -> `b4e64e9` 3.3b -> `814144e` 3.4a -> `8611aec` 3.4b -> `8dcec0c` 3.5a -> `bbb9de8` 3.5b -> `acd494e` 3.6a -> `8678f7c` 3.6b -> `7d74073` 3.6c -> `111df60` refactor R1 (BattleFeedback) -> `75bcabe` refactor R2 (CardDragHandler) -> `bb6a784` 4.0 -> `6f16f19` 4.1.

## 6. Kiến trúc

Nguyên tắc: **lõi không phụ thuộc node/UI**, UI chỉ gọi xuống `BattleController` và nghe Signal. Dữ liệu là `Resource` thuần (file `.tres` là nguồn sự thật), logic ở `src/core`. Mọi thành phần UI báo lên bằng tín hiệu (call down, signal up); UI không tự tính luật mà hỏi controller trước.

```
src/data/      Resource dữ liệu thuần: CardData, EffectData, StatusData, TriggerData, EnemyData, EnemyMove, CharacterData,
               RelicData, PotionData; GameData (gom 5 registry)
src/core/      Lõi chiến đấu (RefCounted, không node):
  thẻ/bài      Deck (5 vùng: draw/hand/discard/exhaust/limbo), CardInstance
  đơn vị       Combatant (máu/giáp/status), EnemyUnit (+EnemyAI, IntentInfo)
  hiệu ứng     EffectResolver (+ResolverContext), DamageCalculator, EffectResult, DamageResult
  trận đấu     BattleState, BattleConfig, BattleController, BattleFactory
  trigger      BattleEvent, TriggerSource, TriggerDispatcher, TriggerRunner, ActionQueue, QueuedAction
  tra cứu      ResourceRegistry -> Status/Enemy/Card/Relic/PotionRegistry; PotionBelt
src/run/       (mới, 4.1) Cấu trúc lượt chạy, thuần: RoomType, RunRng (seed con theo luồng), MapNode, MapConfig, RunMap (cấu trúc +
               validate + to_dict/from_dict), MapGenerator (sinh bản đồ theo seed), MapAscii (bản in gỡ lỗi)
src/sim/       BattleBot, RandomBot, GreedyBot, BattleSimulator, BattleInvariants, ScenarioStats
src/autoload/  EventBus, SaveSystem, RunState, AudioManager (có stop_all_sfx), SceneRouter
src/ui/        UI dựng bằng code (51 file). Logic thuần: CardTextFormatter, PlayIntent, DropIntent, DragGesture, ArrowGeometry,
               EnemyHitTest, RejectionText, PotionIntent, KeywordGlossary, TooltipBuilder, TooltipPlacement, PileView, EffectCueBuilder,
               SfxMap, UiUtil. View-model: CardView, StatusView, IntentView, PotionView, RelicView, TooltipView, GlossaryEntry, EffectCue.
               Control: CardUI, HandUI, EnemyUI, CombatantUI, StatusIconUI, HealthBarUI (trượt mượt), EnergyUI, PileCounterUI,
               TargetArrowUI, PlayZoneUI, ResultOverlayUI, BadgeUI -> PotionSlotUI/RelicIconUI, PotionBeltUI, RelicBarUI, TooltipUI,
               PileViewerUI, FloatingTextUI, EffectsLayerUI, IconLibrary. Điều phối: BattleScene (màn chiến đấu) cùng ba collaborator:
               BattleFeedback (chữ nổi/nảy/rung/âm thanh), CardDragHandler (máy trạng thái kéo thả), EnemyTurnPlayer (nhịp lượt quái,
               chạy bằng Timer). Hiệu ứng ngắn: UiFx (rung, nảy). Cài đặt hiệu ứng: EffectsConfig (speed 0 = tắt).
scenes/        boot.tscn, battle/battle_demo.tscn (F6 để chơi thử; bật hiệu ứng và nối âm thanh vào EventBus)
assets/        fonts/kenney_pixel.ttf, icons/*.svg (tự vẽ), audio/sfx/*.ogg (11 file Kenney CC0) + audio/licenses, CREDITS.md
data/          cards(38) enemies(5) statuses(11) relics(10) potions(8) characters(1)   [.tres]
tests/         110 file test + test_case.gd + helper (combat_factory, card_factory, hud_factory, battle_recorder, ui_input,
               enemy_turn_fingerprint, fake_context); runner: tests/run_tests.gd
tools/         run_tests.sh (nghiêm ngặt), check_runner.sh (tự kiểm), simulate_battles.gd, generate_*.gd/py, capture_*.gd (chụp ảnh),
               print_map.gd, record_enemy_turn_golden.gd, gh_push.py, gh_merge.py
```

`BattleController` (`src/core/battle_controller.gd`, 498 dòng) là **cửa duy nhất cho UI**:

- Tạo: `BattleFactory.create_from_game_data(character, deck_ids, enemy_ids, game_data, seed, relic_ids, potion_ids, current_hp, turn_cap)` (cách ngắn gọn) hoặc `BattleFactory.create(...)` 14 tham số / `BattleController.create_from_data(...)`. Người chơi là `Combatant` do nơi gọi tạo; **máu được giữ trên chính đối tượng đó sau trận**. `controller.potions` không bao giờ null.
- Gọi xuống: `start_battle()`, `play_card(card, target=null)`, `use_potion(slot, target=null)`, `end_player_turn()` (đường tắt cho bot/mô phỏng/test: chạy trọn lượt quái); **lượt quái từng bước (UI dùng)**: `begin_enemy_turn()` -> lặp `peek_next_enemy()`/`run_next_enemy()` đến khi `is_enemy_turn_in_progress()` false. Truy vấn (không đổi gì): `can_play(card)`, `play_rejection_reason(card)`, `valid_targets(card)`, `potion_rejection_reason(slot, target)`, `valid_potion_targets(slot)`, `living_enemies()`, `get_status_data(id)`.
- Đọc: `player`, `enemies`, `deck`, `potions`, `relics`, `energy`, `turn`, `state.phase`, `end_reason`.
- Signal lên: `state.changed`, `energy_changed`, `turn_started(turn, is_player)`, `intent_changed(unit)`, `card_played`, `enemy_acted`, `enemy_defeated`, `triggered`, `potion_used`, `action_rejected(reason)`, `battle_ended(victory)`. Deck: `card_drawn/discarded/exhausted`, `reshuffled`, `pile_changed`; `PotionBelt.changed`; `Combatant`: `health_changed`, `block_changed`, `status_changed`, `died`.
- Mã lý do từ chối: `already_started`, `battle_over`, `not_player_turn`, `card_not_in_hand`, `unplayable`, `not_enough_energy`, `invalid_target`, `no_potion`. Lý do kết thúc: `victory`, `defeat`, `turn_cap`.
- Hành động bị từ chối **không đổi gì** và phát `action_rejected`.

`BattleScene`: `setup(controller)` / `teardown()`; tín hiệu lên `restart_requested` và **`sfx_requested(name)` (nơi sở hữu nối vào `EventBus.sfx_requested`, như `battle_demo` làm; màn lượt chạy sau này phải tự nối)**; `effects` là `EffectsConfig` **mặc định TẮT** (speed 0): nơi tạo màn chơi thật đặt `effects.speed = EffectsConfig.NORMAL_SPEED`. Với hiệu ứng tắt hoặc cảnh chưa ở trong cây, lượt quái chạy tức thì.

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
| Lượt quái | Chạy từng bước (`begin_enemy_turn`/`run_next_enemy`); `end_player_turn()` giữ NGUYÊN hành vi cũ (được bảo vệ bởi `tests/test_enemy_turn_equivalence.gd`: 40 kịch bản mô phỏng với "dấu vân tay" ghi từ code trước khi tách; **test này gắn với dữ liệu thật nên sẽ FAIL khi cố ý đổi thẻ/quái/relic: khi đó chạy `tools/record_enemy_turn_golden.gd` để ghi lại, hoặc xóa nó nếu không còn cần**). Quái đóng lượt: kiểm tra kết thúc, trần lượt, cập nhật ý định rồi sang lượt người chơi. |
| Bản đồ (4.1) | Lưới 7 cột x 15 tầng + boss tầng 16 (cột giữa). 6 đường đi từ tầng đầu (>= 2 cột xuất phát khác nhau), mỗi bước sang cột kề, không cắt nhau, đường có thể gộp; mọi nút tầng cuối nối vào boss. Tầng 1 toàn quái, tầng 9 toàn kho báu, tầng 15 toàn lửa trại; elite và lửa trại ngẫu nhiên chỉ từ tầng 6, không có lửa trại ngẫu nhiên ở tầng 14; elite/cửa hàng/lửa trại không liền nhau trên một đường và không trùng giữa các nút anh em. Trọng số nút tự do: quái 45, sự kiện 22, lửa trại 12, elite 8, cửa hàng 5. `MapGenerator.generate(run_seed, act)` tất định. |
| RNG theo luồng | `RunRng.derive(run_seed, stream, index)` = 8 byte đầu của SHA-256 của `"seed|luồng|chỉ số"` (ổn định giữa các phiên bản Godot; có test đối chiếu với Python). Mỗi lĩnh vực (map, reward, shop, event, encounter...) một luồng, để làm việc này không đổi kết quả việc kia. |
| Xác định | Cùng seed + cùng chuỗi hành động = cùng kết quả (RNG xáo bài và RNG trận đấu tách riêng, sinh từ seed). |
| Dữ liệu | **Enum lưu dạng số nguyên trong `.tres` -> giá trị enum mới luôn thêm vào CUỐI.** `EVENT_SOURCE` (đích effect) chỉ dùng trong trigger. Mọi `status_id` trong dữ liệu phải tồn tại (có test tham chiếu chéo). Generator **không ghi đè** file `.tres` đã có (ngoại lệ: vá thêm đúng dòng `upgraded_id`). |

## 8. Dữ liệu hiện có

- **Warrior** (`data/characters/warrior.tres`): 80 máu, 3 năng lượng, rút 5, 99 vàng; bộ bài 5 Strike + 4 Defend + 1 Bash.
- **38 thẻ** = 19 gốc + 19 bản `+`: strike, defend, bash (3 thẻ khởi đầu), cleave, iron_wave, pommel_strike, shrug_it_off, twin_strike, thunderclap, deadly_poison, bandage_up, adrenaline, inflame, metallicize, bloodletting, whirlwind (X), skewer (X), demon_form, barricade. Độ hiếm (thẻ gốc): 3 starter, 8 common, 6 uncommon, 2 rare.
- **5 quái:** slime (ngẫu nhiên, gắn Weak), goblin (đánh rồi thủ), acolyte (tự tăng Strength), spiker (Thorns), toxic_slug (Poison). **Chưa có elite/boss.** Số liệu máu/sát thương là **placeholder**.
- **11 status:** strength, dexterity, vulnerable, weak, frail, poison, metallicize, thorns, demon_form, artifact, barricade.
- **10 relic:** burning_blood, anchor, vajra, lantern, bag_of_preparation, happy_flower, orichalcum, bronze_scales, energy_crystal, wide_lens.
- **8 potion:** fire, explosive, block, strength, energy, swift, weak, blood.
- **11 âm thanh** trong `assets/audio/sfx/` (tên khớp `SfxMap.ALL`): card_play, hit, blocked, block_gain, heal, status, potion, end_turn, reject, victory, defeat; có test kiểm tên, độ dài (0.05-3 giây), giấy phép và CREDITS. **Chọn theo tên và độ dài, chưa nghe bằng tai** (sandbox không có thiết bị âm thanh).

## 9. Công cụ và cách kiểm chứng

- **Test:** `bash tools/run_tests.sh [--only=chuoi1,chuoi2]` (nghiêm ngặt: xem mục 4); `bash tools/check_runner.sh` tự kiểm bộ chạy. Test dùng `extends "res://tests/test_case.gd"`, hàm `test_*`, hook `before_each/after_each`, `assert_eq/assert_true/...`; test được `await`. Helper: `tests/combat_factory.gd`, `card_factory.gd`, `hud_factory.gd` (trận có potion/relic), `battle_recorder.gd`, `ui_input.gd`.
- **Mô phỏng:** `godot --headless --path . -s res://tools/simulate_battles.gd -- --battles=300 --seed=1 [--deck=starter|all] [--relics=all] [--potions=N]`; thoát mã 1 nếu có vi phạm bất biến. Kỳ vọng: 0 vi phạm, 0 cảnh báo.
- **Phá code kiểm chứng (mutation, làm tay):** sửa một dòng logic -> chạy test liên quan -> phải có test FAIL -> khôi phục. Làm cho mọi mốc từ 3.5; các lần không bị bắt đều được phân tích và vá bằng test (hoặc xóa code thừa). Báo cáo cả những lần không bị bắt.
- **Ảnh chụp:** `tools/capture_*.gd` (mục 4); `capture_interaction.gd` (kéo thả + hiệu ứng, tất định) và `capture_hud.gd` là mốc so ảnh trước/sau khi refactor (17 ảnh phải giống từng byte). `tools/capture_map.gd` vẽ bản đồ ra PNG, `tools/print_map.gd` in ASCII.
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
| **3.5a** | `PotionIntent`, `PotionView`, `RelicView`, `KeywordGlossary`, `TooltipBuilder`, `TooltipPlacement`, `PileView`; lõi: `potion_rejection_reason`, `valid_potion_targets` | **Xong, đã gộp** | **811** |
| **3.5b** | `PotionBeltUI`, `RelicBarUI`, `TooltipUI`, `PileViewerUI`, ghép vào `BattleScene` (potion bằng click, tooltip, xem pile) (+ `tools/capture_hud.gd`) | **Xong, đã gộp** | **921** |
| **3.6a** | Hiệu ứng trình diễn: `EffectsConfig`, `EffectCueBuilder`, `EffectsLayerUI`/`FloatingTextUI`, `UiFx`, thanh máu mượt, rung khi bị từ chối (+ `tools/capture_fx.gd`) | **Xong, đã gộp** | **990** |
| **3.6b** | Lượt quái tuần tự: lõi `begin_enemy_turn/run_next_enemy`, `EnemyTurnPlayer`; golden hành vi 40 kịch bản | **Xong, đã gộp** | **1035** |
| **3.6c** | Âm thanh: `SfxMap`, 11 SFX Kenney CC0, `BattleScene` phát qua tín hiệu | **Xong, đã gộp** | **1063** |
| **R1, R2** | Refactor `BattleScene`: tách `BattleFeedback` và `CardDragHandler`; sửa lỗi biên dịch của công cụ `-s` (tín hiệu `sfx_requested`); `tools/capture_interaction.gd` | **Xong, đã gộp** | **1106** |
| **4.0** | Bộ chạy test nghiêm ngặt (`SCRIPT ERROR`/rò rỉ = FAIL), `tools/check_runner.sh`, sửa mọi rò rỉ trong test, `AudioManager.stop_all_sfx` | **Xong, đã gộp** | **1107** |
| **4.1** | Bản đồ: `RoomType`, `RunRng`, `MapNode`, `MapConfig`, `RunMap`, `MapGenerator`, `MapAscii` (+ `tools/print_map.gd`, `tools/capture_map.gd`); fuzz 2000 seed | **Xong, đã gộp** | **1148** |
| 3 | UI chiến đấu | **Xong** | - |
| 4 | Run: map, thưởng, shop, lửa trại, sự kiện | **Đang làm** (4.0, 4.1 xong; 4.2-4.6 chưa) | - |
| 5 | Menu chính, chọn nhân vật, lưu/tiếp tục, cài đặt | Chưa làm | - |
| 6 | Nội dung: Act 2-3, nhân vật thứ hai, đủ thẻ/relic/quái | Chưa làm | - |
| 7 | Asset CC0, âm thanh, hiệu ứng | Chưa làm | - |
| 8 | Cân bằng bằng bot, đóng gói | Chưa làm | - |

## 11. Nợ kỹ thuật, giới hạn đã biết, chỗ chưa chắc

1. `src/core/battle_controller.gd` dài **498 dòng** và `src/ui/battle_scene.gd` **520 dòng** (> 400 điển hình, < 800 trần mềm). Cân nhắc tách thêm (vd. phần lượt quái của controller) nếu phình tiếp.
2. `BattleFactory.create` có **14 tham số**: dùng `create_from_game_data`.
3. **Cân bằng chỉ là placeholder:** quái đơn quá dễ (bot thắng ~100%); mang cả 10 relic thì gần như không mất máu. Bot dùng ~0,7-0,8 potion/trận.
4. Sát thương của trigger và của potion dùng công thức chuẩn (Strength có tác dụng) - khác Slay the Spire.
5. `tests/test_enemy_turn_equivalence.gd` (golden) **gắn với dữ liệu thật**: FAIL khi cố ý đổi thẻ/quái/relic (xem mục 7). Giữ hoặc xóa là quyết định còn mở.
6. Chưa có: chiêu quái theo ngưỡng máu, boss nhiều pha, quái triệu hồi, thẻ sinh ra trong bộ bài (Wound/Dazed), hiệu ứng "bỏ thẻ"/"exhaust ngẫu nhiên", i18n, nhạc nền, màn Settings (thanh trượt âm lượng chưa thử được).
7. **`RunState` (autoload) chưa nối với trận đấu** (mốc 4.3). Hợp đồng dự kiến: `RunState` giữ id (`deck`, `relics`, `potions` là `Array[String]`, `hp`, `max_hp`, `gold`, `seed`); chuyển sang `Array[StringName]` khi gọi `BattleFactory`; sau trận: `RunState.hp = player.hp`, `RunState.potions = controller.potions.to_ids()`. Mốc 4.2 dự kiến đổi `SAVE_KEYS` của `RunState` (thêm trạng thái các luồng RNG và bản đồ); hiện chưa có bản lưu nào nên không cần tương thích ngược.
8. Sandbox KHÔNG có chuột/bàn phím/âm thanh thật: kéo thả, hover, phím, **âm thanh và độ mượt/thời lượng hiệu ứng** chỉ kiểm bằng sự kiện giả và ảnh tĩnh; **cảm giác thật phải nhờ người dùng thử trên máy** (F6 `battle_demo.tscn`).
9. Tooltip hiện bên phải vùng neo nên che các ô/thẻ kế bên (đúng thiết kế đã duyệt, hơi vướng); chữ nổi của cả ba quái dồn lên hero khi lượt quái tức thì (đã giải quyết bằng lượt quái tuần tự khi bật hiệu ứng).
10. Bản đồ 4.1 mới là dữ liệu: **chưa có giao diện vẽ bản đồ** (4.5); `tools/capture_map.gd` chỉ là ảnh gỡ lỗi (không có chữ, chỉ màu theo loại phòng).
11. **Cảnh báo ObjectDB rò rỉ khi thoát đã được xử lý (4.0)**: nguồn gốc nằm hoàn toàn trong test (vòng tham chiếu lambda, node không giải phóng, tiếng còn đang phát); game và lõi không rò rỉ. Bộ chạy test giờ fail nếu tái phát.

## 12. Asset (kế hoạch)

Yêu cầu: bản quyền CC0 hoặc ghi rõ; **mọi asset phải ghi vào `assets/CREDITS.md`**. Hiện có: font Kenney Pixel (CC0, lấy qua mirror GitHub `ETdoFresh/kenney.nl`, đã đọc license từng pack) và 18 icon SVG tự vẽ (chờ người dùng xác nhận CC0). **Nguồn đã khảo sát:** mirror `ETdoFresh/kenney.nl` có 20 pack CC0 dùng được (UI Pack, Pixel UI Pack, âm thanh UI/impact/RPG, font); `game-icons/icons` có icon chiến đấu nhưng chủ yếu CC BY 3.0 (phải ghi tác giả, KHÔNG phải CC0); 0x72 DungeonTileset II là CC0 (xác nhận trên trang tác giả) nhưng chỉ nên lấy từ itch.io: **nhờ người dùng tải zip gửi lên chat** (sandbox bị chặn itch.io/kenney.nl/opengameart). Đã có 11 SFX Kenney CC0 (nhập ở 3.6c, ghi trong CREDITS). Chưa có sprite quái/nhân vật, nhạc nền.

## 13. Bước tiếp theo đề xuất

1. **Mốc 4.2 - lõi lượt chạy (thuần, tiếp theo):** `RunController` (nhận một `RunState` được truyền vào) điều khiển luồng MAP -> PHÒNG -> THƯỞNG -> về MAP, tiến trên `RunMap`, chọn nhóm quái theo loại phòng, sinh thưởng (vàng, chọn 1 trong 3 thẻ theo độ hiếm, potion, relic của elite), lửa trại (nghỉ hồi 30% hoặc nâng cấp thẻ qua `upgraded_id`), cửa hàng (giá, mua, xóa thẻ); RNG tách luồng bằng `RunRng`. **Trình bày thiết kế trước, chờ duyệt (quy trình 5 bước).**
2. Mốc 4.3 nối trận (dựng trận từ `RunState`, ghi hp/potion về, thua thì kết thúc run, relic "+máu tối đa khi nhặt" ở tầng run). Mốc 4.4 sự kiện dữ liệu hóa (~4) + **1 elite và 1 boss cho Act 1** (hiện không có). Mốc 4.5 giao diện run (màn bản đồ, thưởng, lửa trại, cửa hàng, sự kiện, xem deck; `RunScene` thay các màn con bằng tín hiệu; nhớ nối `sfx_requested` vào `EventBus`). Mốc 4.6 lưu/tiếp tục (tự lưu khi vào bản đồ và sau thưởng; thoát giữa trận thì quay lại đầu phòng).
3. Sau đó Giai đoạn 5 (menu/meta), 6 (nội dung Act 2-3, nhân vật 2), 7 (asset, nhạc, sprite), 8 (cân bằng bằng bot, đóng gói), theo bảng mục 10.
4. **Quy tắc UI (giữ nguyên):** UI **không bao giờ sửa lõi**, chỉ gọi `play_card/use_potion/begin_enemy_turn/run_next_enemy` và đọc trạng thái qua Signal; dữ liệu hiển thị đi qua view-model; mỗi mốc UI: test headless + ảnh `xvfb` gửi người dùng. Controller chỉ kiểm tra thắng/thua sau một hành động (đừng hạ quái bằng `take_damage` rồi mong UI báo thắng). `intent_changed` phát ngay khi quái chọn chiêu mới; phase sang PLAYER_TURN xảy ra SAU `turn_started` nên nút End Turn phải nghe `state.changed`.
5. **Bẫy UI/test đã gặp (rút gọn):** Control con mặc định chặn chuột (dùng `UiUtil.ignore_mouse_in_children`; control cần nhận hover mà vẫn để click đi lên dùng `MOUSE_FILTER_PASS`); click thẻ -> controller đổi tay bài -> không giải phóng CardUI trong handler của chính nó (dùng `request_refresh()`); click thẻ tính khi NHẢ chuột; tọa độ UI theo `DropIntent.DESIGN_SCREEN`; test cần toạ độ thật phải thêm node vào `Engine.get_main_loop().root` và `await process_frame`; container ghi đè `position` nên hiệu ứng ngắn chỉ đụng `rotation/scale/modulate` (`UiFx`); tween test bằng `pause()` + `custom_step()` cho tất định; `Timer.start()` cần node ở trong cây; font Kenney Pixel nhỏ nên dùng cỡ chữ lớn; sửa `.gd` bằng script thì thụt lề là TAB; `ProgressBar` tự giới hạn giá trị; `Deck.add_to_hand` từ chối thẻ đã nằm trong pile; thẻ dựng bằng `combat_factory` không có mô tả (test hiển thị chữ dùng thẻ thật từ `CardRegistry`); thứ tự phát tín hiệu: handler lỗi script trong tín hiệu KHÔNG làm test fail (nhưng bộ chạy mới đã coi `SCRIPT ERROR` là FAIL).

## 14. Prompt khởi động cho session mới (dán nguyên văn)

> Dự án game thẻ bài roguelike Godot 4.7.2 (GDScript): repo `https://github.com/halo07-pixel/CARDs` (public, nhánh `main`). Việc đầu tiên: clone, đọc `HANDOFF.md` và `CLAUDE.md` ở thư mục gốc, dựng môi trường theo mục 4, chạy `bash tools/run_tests.sh` (kỳ vọng 1148 test đạt) và `bash tools/check_runner.sh`, rồi báo kết quả. Sau đó tóm tắt tiến độ trong 5 dòng. Giai đoạn 0 đến 3 (UI chiến đấu) đã xong và đã gộp, mốc 4.0 (dọn nền) xong, mốc 4.1 (sinh bản đồ) xong và đã gộp; mốc tiếp theo là 4.2 (lõi lượt chạy: RunController, thưởng, lửa trại, cửa hàng). Tuân thủ quy trình 5 bước (trình bày thiết kế trước, chờ tôi duyệt rồi mới viết code), nội dung game bằng tiếng Anh, trả lời tiếng Việt, báo cáo trung thực (kể cả lần phá code không bị test bắt), chụp ảnh màn hình mỗi mốc có giao diện. Khi cần đẩy code lên GitHub tôi sẽ đưa token mới (fine-grained, chỉ repo CARDs, Contents: Read and write); dùng `tools/gh_push.py` và `tools/gh_merge.py`, **không ghi token vào file/commit/log**, chỉ gộp `main` khi tôi nói. Nhánh mới luôn tạo từ `origin/main` (`git fetch origin && git checkout -B claude/xxx origin/main`).
