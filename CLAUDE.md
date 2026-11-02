# CLAUDE.md - quy tắc làm việc cho repo CARD

Đọc `HANDOFF.md` trước (bối cảnh, trạng thái, môi trường, bẫy đã gặp, bước tiếp theo).

## Quy trình 5 bước (bắt buộc)
1. Trình bày kiến trúc/ý tưởng - **không viết code**. 2. **Chờ người dùng duyệt.** 3. Viết code cho tính năng đã duyệt (ngắn gọn, modular). 4. Chờ người dùng kiểm lỗi. 5. Refactor hoặc sang tính năng mới.

## Chống ngụy biện
- KHÔNG `get_parent().get_parent()`: dùng Signal (call down, signal up).
- KHÔNG gộp logic dữ liệu thẻ (`CardData`) vào UI thẻ (`CardUI`).
- KHÔNG viết `pass` / "sẽ thêm sau" cho hàm cốt lõi.
- LUÔN xác nhận state của lượt trước khi thực thi hành động (hành động sai bị từ chối, không đổi gì).

## Phong cách code
- Bất biến: tạo bản mới, không sửa dữ liệu dùng chung. **Không bao giờ sửa Resource lấy từ registry** (`load()` trả về đối tượng cache).
- KISS / DRY / YAGNI. File 200-400 dòng điển hình (trần mềm 800), hàm < 50 dòng, lồng <= 4 cấp, return sớm, không số "ma thuật" (dùng hằng số).
- Xử lý lỗi tường minh, không nuốt lỗi; kiểm tra dữ liệu ở biên (`validate()` trả danh sách lỗi).
- Comment bằng **tiếng Việt**; nội dung hiển thị của game bằng **tiếng Anh**; trả lời người dùng bằng tiếng Việt.
- Lõi (`src/core`, `src/data`, `src/sim`) không dùng node/UI. Enum lưu số nguyên trong `.tres` -> **chỉ thêm vào cuối enum**.

## Kiểm chứng (mỗi tính năng)
- Viết test headless (`tests/test_*.gd`); `bash tools/run_tests.sh` phải xanh. Dữ liệu mới có test hợp lệ + tham chiếu chéo.
- Chạy `tools/simulate_battles.gd` (nhiều cấu hình): **0 vi phạm bất biến, 0 cảnh báo**.
- Phá code cố ý ở logic quan trọng và xác nhận có test fail; lô nhỏ, khôi phục + `cmp` byte sau mỗi lô. Báo cáo cả những lần phá **không** bị bắt (và vì sao).

## Git
- Nhánh `claude/phase-X-Y-tên`; commit `<type>: <mô tả>` (`feat/fix/refactor/docs/test/chore/perf/ci`); **không force-push**; **đẩy sau mỗi mốc** (sandbox có thể reset); chỉ gộp `main` khi người dùng nói.
- Đẩy/gộp qua API: `tools/gh_push.py`, `tools/gh_merge.py`. **Không ghi token vào file/commit/log.**

## Báo cáo
Trung thực và ngắn gọn: nêu lỗi đã gặp, kiểm tra nào chưa chạy lại, giới hạn đã biết. Không hứa những gì chưa kiểm chứng.
