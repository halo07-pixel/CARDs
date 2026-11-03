# HANDOFF - Spire Cards (repo `halo07-pixel/CARD`)

> Tài liệu bàn giao cho session/đoạn chat mới. Đọc hết file này + `CLAUDE.md` trước khi làm bất cứ gì.
> Cập nhật lần cuối: sau Giai đoạn 2.3 (nhánh `claude/phase-2-3-potions-xcost-upgrades`).

## 1. TL;DR

- **Dự án:** game thẻ bài roguelike kiểu *Slay the Spire*, **Godot 4.7.2 / GDScript**, 1920x1080, renderer Compatibility.
- **Trạng thái:** phần **lõi logic** (chiến đấu, thẻ, trạng thái, trigger, relic, potion, X-cost, AI quái, bot, mô phỏng) đã gần xong và được test rất kỹ (**466 test đạt**, hàng nghìn trận mô phỏng không vi phạm). **Chưa có UI, menu, bản đồ, cửa hàng, nhân vật thứ hai, asset** - tức là **chưa có gì để người dùng nhìn hay bấm**.
- **Trên `main`:** Giai đoạn 0, 1, 2.1, 2.2 (commit `4218cff`). **Giai đoạn 2.3** (potion, X-cost, nâng cấp thẻ) nằm trên nhánh `claude/phase-2-3-potions-xcost-upgrades`, **chưa gộp** (chờ người dùng bảo "merge").
- **Quyết định đang chờ người dùng:** hướng đi tiếp theo (xem mục 13): A = gộp 2.3 + làm nhanh 2.4 rồi UI; B = gộp 2.3 và nhảy thẳng sang UI (Giai đoạn 3); C = giữ cách làm kỹ như cũ.
- **Việc đầu tiên của session mới:** dựng môi trường (mục 4), chạy test để xác nhận, rồi hỏi người dùng chọn A/B/C (đừng tự quyết).

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

- Người dùng nói **tiếng Việt**, dùng Windows + PowerShell, repo public `halo07-pixel/CARD`. Trả lời tiếng Việt; **comment trong code bằng tiếng Việt**; **nội dung game (tên thẻ, mô tả) bằng tiếng Anh** (được chốt theo "đồng ý" mặc định; hỏi lại nếu họ muốn tiếng Việt - đổi sớm đỡ tốn công hơn).
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
git clone https://github.com/halo07-pixel/CARD.git /home/claude/cardgame && cd /home/claude/cardgame   # repo public: clone không cần token
git fetch origin claude/phase-2-3-potions-xcost-upgrades && git checkout claude/phase-2-3-potions-xcost-upgrades   # nếu 2.3 chưa gộp
bash tools/run_tests.sh          # kỳ vọng: 466 passed (nhánh 2.3) hoặc 393 (main khi chưa gộp 2.3)
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
- **Token:** fine-grained PAT, *Only select repositories* = `CARD`, *Repository permissions -> Contents: Read and write*, hạn ngắn. Người dùng dán token vào chat; **tuyệt đối không ghi token vào file/commit/log**. Token từng dán trong đoạn chat cũ **phải được thu hồi**; session mới cần token mới. Nếu thấy `Bad credentials` / `Resource not accessible by personal access token`: token hết hạn/bị thu hồi hoặc thiếu quyền Contents write (sửa ở GitHub -> Settings -> Developer settings -> Fine-grained tokens -> Edit, không cần tạo token mới).
- Người dùng dùng gói **Free** của Claude -> không dùng được Claude Code trên web; vì vậy mới có cách đẩy bằng API. Không có connector GitHub trong chat.
- Quy ước: nhánh `claude/phase-X-Y-tên`, commit `<type>: <mô tả>` (`feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`), **không force-push**, chỉ gộp `main` khi người dùng nói. Người dùng cập nhật máy bằng `git checkout main` rồi `git pull origin main`.
- Lịch sử `main`: `4d7dbd1` nền móng + thẻ/bộ bài/combat core -> `09dfbed`/`1e0c157` README + quyền chạy script -> `110046d` 1.3a quái/AI -> `c0c3fc8` 1.3b BattleController -> `27ffbef` 1.3c bot/mô phỏng/Warrior -> `4d0f64b` 2.1 trigger -> `4218cff` 2.2 relic. Nhánh 2.3: `c51dace` + commit bàn giao này.

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
data/          cards(38) enemies(3) statuses(11) relics(10) potions(8) characters(1)   [.tres]
tests/         43 file test + test_case.gd + factory/recorder; runner: tests/run_tests.gd
tools/         run_tests.sh, simulate_battles.gd, generate_starter_*.gd, gh_push.py, gh_merge.py
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
| **2.3** | Potion, X-cost, nâng cấp thẻ + lint | **Xong, trên nhánh, chưa gộp** | **466** |
| 2.4 | Quái có status đầu trận (Spiker/Toxic Slug), bot dùng potion tốt hơn, mô phỏng tổng hợp | Chưa làm (có thể bỏ/làm gọn) | - |
| 3 | UI chiến đấu | **Chưa làm** | - |
| 4 | Run: map, thưởng, shop, lửa trại, sự kiện | Chưa làm | - |
| 5 | Menu chính, chọn nhân vật, lưu/tiếp tục, cài đặt | Chưa làm | - |
| 6 | Nội dung: Act 2-3, nhân vật thứ hai, đủ thẻ/relic/quái | Chưa làm | - |
| 7 | Asset CC0, âm thanh, hiệu ứng | Chưa làm | - |
| 8 | Cân bằng bằng bot, đóng gói | Chưa làm | - |

## 11. Nợ kỹ thuật, giới hạn đã biết, chỗ chưa chắc

1. `src/core/battle_controller.gd` dài **407 dòng** (> 400 điển hình của quy chuẩn, < 800 trần mềm). Nếu thêm nữa nên tách (vd. lượt quái ra một lớp riêng).
2. `BattleFactory.create` có **14 tham số** tuần tự -> nên gom registry thành một đối tượng `GameData`/loadout khi bắt đầu làm UI/run.
3. **Cân bằng chỉ là placeholder:** quái đơn quá dễ; mang cả 10 relic thì gần như không mất máu; `GreedyBot` dùng potion rất dè dặt (chỉ khi hạ được quái hoặc nguy hiểm) nên trong mô phỏng gần như không dùng potion (đường dùng potion của nó chỉ được test bằng tình huống dựng sẵn). RandomBot dùng potion nhiều.
4. Sát thương của trigger và của potion dùng công thức chuẩn (Strength có tác dụng) - khác Slay the Spire (Thorns/potion không nhận Strength).
5. Các lần phá code **không bị bắt** đã được phân tích và đều tương đương về hành vi (chỉ khác thông báo/cảnh báo log): bỏ `break` khi người chơi tự chết giữa thẻ (resolver đã tự từ chối nguồn đã chết); bỏ nhánh "thiếu registry" của relic trong `BattleFactory` (chốt kế tiếp bắt cùng kết quả).
6. Chưa có: chiêu quái theo ngưỡng máu, boss nhiều pha, quái triệu hồi, thẻ sinh ra trong bộ bài (Wound/Dazed), hiệu ứng "bỏ thẻ"/"exhaust ngẫu nhiên", `EnemyData.starting_statuses`, i18n. Không lưu giữa trận (thiết kế: chỉ lưu giữa các phòng).
7. **`RunState` (autoload) chưa nối với trận đấu.** Hợp đồng dự kiến: `RunState` giữ id (`deck`, `relics`, `potions` là `Array[String]`, `hp`, `max_hp`, `gold`, `seed`); chuyển sang `Array[StringName]` khi gọi `BattleFactory`; sau trận: `RunState.hp = player.hp`, `RunState.potions = controller.potions.to_ids()`; thưởng/xóa thẻ làm ở tầng run.
8. Pipeline chụp ảnh `xvfb` chưa kiểm tra lại sau reset sandbox.

## 12. Asset (kế hoạch)

Yêu cầu: bản quyền CC0 hoặc ghi rõ; **mọi asset phải ghi vào `assets/CREDITS.md`** (tên, tác giả, nguồn, giấy phép). Người dùng đã có kinh nghiệm với bộ pixel-art 0x72 (CC0) và Kenney (CC0) ở dự án khác và thích itch.io. Sandbox không tải được từ itch.io/Kenney/OpenGameArt -> **nhờ người dùng tải zip và gửi lên chat**, hoặc dùng bản mirror trên GitHub (kiểm tra giấy phép thật kỹ). Chưa có font/asset nào trong `assets/`.

## 13. Bước tiếp theo đề xuất

1. Hỏi người dùng chọn **A / B / C** (mục 1). Khuyến nghị: **gộp 2.3 trước** (`tools/gh_merge.py`), vì nó đã đủ test.
2. Nếu làm **2.4** (gọn): `EnemyData.starting_statuses`, quái Spiker (Thorns) và Toxic Slug (Poison), bot dùng potion chủ động hơn. Trình bày thiết kế -> chờ duyệt như thường lệ.
3. **Giai đoạn 3 (UI chiến đấu)** - gợi ý để trình bày thiết kế: `BattleScene` sở hữu một `BattleController` và nối Signal -> UI; các scene `HandUI`, `CardUI` (nhận `CardData` + `CardInstance.uid`, phát `card_dropped`), `CombatantUI` (máu, giáp, biểu tượng status, ý định), `EnergyOrb`, bộ đếm các pile, `PotionBeltUI`, `RelicBarUI`, nút kết thúc lượt, mũi tên nhắm. UI **không bao giờ sửa lõi**, chỉ gọi `play_card/use_potion/end_player_turn` và đọc trạng thái; viết bộ định dạng mô tả thẻ (`{damage}`...); dùng hình khối/Label làm placeholder rồi thay asset ở Giai đoạn 7; chụp ảnh từng trạng thái (tay bài, kéo thả, ý định quái, nhận sát thương, thắng/thua) cho người dùng.
4. Sau đó Giai đoạn 4 (run), 5 (menu/meta)... theo bảng mục 10.

## 14. Prompt khởi động cho session mới (dán nguyên văn)

> Dự án game thẻ bài roguelike Godot 4.7.2: repo `https://github.com/halo07-pixel/CARD` (public). Hãy clone, đọc `HANDOFF.md` và `CLAUDE.md` ở thư mục gốc (nếu Giai đoạn 2.3 chưa gộp thì nằm ở nhánh `claude/phase-2-3-potions-xcost-upgrades`). Dựng môi trường theo mục 4, chạy `bash tools/run_tests.sh` và báo kết quả. Sau đó tóm tắt tiến độ cho tôi trong 5 dòng và hỏi tôi chọn hướng A/B/C ở mục 13. Tuân thủ quy trình 5 bước: trình bày thiết kế trước, chờ tôi duyệt rồi mới viết code. Khi cần đẩy code lên GitHub tôi sẽ đưa token mới (fine-grained, chỉ repo CARD, Contents: Read and write); dùng `tools/gh_push.py` và `tools/gh_merge.py`, không ghi token vào file.
