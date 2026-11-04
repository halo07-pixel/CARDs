#!/usr/bin/env python3
"""Sinh toàn bộ icon SVG của game vào assets/icons/ (tác phẩm gốc của dự án, CC0).

Chạy: python3 tools/generate_icons.py [--sheet /đường/dẫn/xem_thử.png]
Cần `pip install cairosvg pillow` (chỉ khi dùng --sheet). Tên file = icon_id của dữ liệu
(status) hoặc tên cố định (heart, block, intent_*). Sửa màu/hình ở bảng ICONS rồi chạy lại.
"""
import os
import sys

OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "icons")
SIZE = 128   # kích thước raster mặc định khi Godot nhập (viewBox gốc 64)
STROKE = 3

SWORD = ('<path d="M32 5 L39 14 V41 H25 V14 Z"/><rect x="14" y="41" width="36" height="7" rx="2"/>'
         '<rect x="28" y="48" width="8" height="10" rx="2"/><circle cx="32" cy="60" r="3"/>')
SHIELD = '<path d="M32 5 L54 13 V31 C54 46 44 55 32 60 C20 55 10 46 10 31 V13 Z"/>'
HEART = '<path d="M32 57 C8 41 4 24 15 14 C23 8 30 12 32 19 C34 12 41 8 49 14 C60 24 56 41 32 57 Z"/>'

# tên -> (màu nền, màu viền, thân svg)
ICONS = {
    # --- status (khớp icon_id trong data/statuses) ---
    "strength": ("#ff7b4a", "#5a1d0a",
                 '<rect x="4" y="26" width="9" height="12" rx="2"/><rect x="13" y="20" width="9" height="24" rx="2"/>'
                 '<rect x="22" y="29" width="20" height="6"/><rect x="42" y="20" width="9" height="24" rx="2"/>'
                 '<rect x="51" y="26" width="9" height="12" rx="2"/>'),
    "dexterity": ("#4fd1c5", "#0f4a45",
                  '<path d="M50 6 C30 8 14 22 12 44 L10 58 L16 56 C20 52 24 50 28 50 C44 48 54 30 50 6 Z"/>'
                  '<path d="M14 54 L44 18" fill="none"/>'),
    "weak": ("#9aa6b8", "#2b3140",
             '<path d="M26 22 L30 15 L33 24 L38 13 L38 42 L26 42 Z"/><rect x="14" y="42" width="36" height="7" rx="2"/>'
             '<rect x="28" y="49" width="8" height="10" rx="2"/>'),
    "vulnerable": ("#c7a6ff", "#32205c",
                   SHIELD + '<path d="M34 8 L28 24 L38 30 L27 44 L33 58" stroke="#32205c" stroke-width="4" fill="none"/>'),
    "frail": ("#efe6d2", "#4a3f26",
              '<g transform="rotate(-45 32 32)"><rect x="14" y="28" width="36" height="8" rx="3"/>'
              '<circle cx="12" cy="26" r="6"/><circle cx="12" cy="38" r="6"/>'
              '<circle cx="52" cy="26" r="6"/><circle cx="52" cy="38" r="6"/></g>'),
    "poison": ("#7bd84a", "#1f4a14",
               '<path d="M32 5 C32 5 13 28 13 40 A19 19 0 0 0 51 40 C51 28 32 5 32 5 Z"/>'
               '<circle cx="25" cy="42" r="4" fill="#1f4a14" stroke="none"/><circle cx="38" cy="47" r="3" fill="#1f4a14" stroke="none"/>'),
    "thorns": ("#b9c36a", "#3b4214",
               '<path d="M32 3 L38 22 L56 16 L44 31 L60 39 L41 41 L40 60 L32 46 L24 60 L23 41 L4 39 L20 31 L8 16 L26 22 Z"/>'),
    "artifact": ("#ffe9a3", "#5a4308",
                 '<circle cx="32" cy="32" r="26" fill="none"/><path d="M32 14 L46 32 L32 50 L18 32 Z"/>'),
    "barricade": ("#d9893f", "#4a2608",
                  '<rect x="6" y="10" width="24" height="14"/><rect x="34" y="10" width="24" height="14"/>'
                  '<rect x="6" y="26" width="12" height="14"/><rect x="22" y="26" width="20" height="14"/><rect x="46" y="26" width="12" height="14"/>'
                  '<rect x="6" y="42" width="24" height="14"/><rect x="34" y="42" width="24" height="14"/>'),
    "metallicize": ("#aeb7c4", "#2b3140",
                    SHIELD + '<circle cx="22" cy="22" r="3" fill="#2b3140" stroke="none"/>'
                    '<circle cx="42" cy="22" r="3" fill="#2b3140" stroke="none"/><circle cx="32" cy="40" r="3" fill="#2b3140" stroke="none"/>'),
    "demon_form": ("#ff4d5e", "#4a0a14",
                   '<path d="M12 8 L24 20 H40 L52 8 L50 28 C50 46 42 56 32 56 C22 56 14 46 14 28 Z"/>'
                   '<path d="M21 32 L29 35 L21 38 Z M43 32 L35 35 L43 38 Z" fill="#ffe08a" stroke="none"/>'
                   '<path d="M25 46 L32 43 L39 46" fill="none"/>'),
    # --- chung ---
    "heart": ("#ff5a6e", "#5c1420", HEART),
    "block": ("#5aa9ff", "#17325c", SHIELD + '<path d="M32 12 V52" stroke="#17325c" stroke-width="3" fill="none" opacity=".5"/>'),
    # --- ý định quái ---
    "intent_attack": ("#ff6a5a", "#4a0f0a", SWORD),
    "intent_defend": ("#5aa9ff", "#17325c", SHIELD),
    "intent_buff": ("#6fe07a", "#14421a", '<path d="M32 6 L54 30 H41 V58 H23 V30 H10 Z"/>'),
    "intent_debuff": ("#c7a6ff", "#32205c", '<path d="M32 58 L54 34 H41 V6 H23 V34 H10 Z"/>'),
    "intent_unknown": ("#e8ecf2", "#e8ecf2",
                       '<path d="M20 22 C20 6 44 6 44 22 C44 33 32 33 32 43" stroke-width="8" fill="none"/>'
                       '<circle cx="32" cy="55" r="5" stroke="none"/>'),
}


def svg_text(name: str) -> str:
    fill, line, body = ICONS[name]
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="{SIZE}" height="{SIZE}">'
            f'<g fill="{fill}" stroke="{line}" stroke-width="{STROKE}" stroke-linejoin="round" '
            f'stroke-linecap="round">{body}</g></svg>\n')


def write_all() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    for name in ICONS:
        with open(os.path.join(OUT_DIR, f"{name}.svg"), "w", encoding="utf-8") as f:
            f.write(svg_text(name))
    print(f"đã ghi {len(ICONS)} icon vào {os.path.normpath(OUT_DIR)}")


def write_sheet(path: str) -> None:
    import io
    import cairosvg
    from PIL import Image
    cols = 6
    rows = (len(ICONS) + cols - 1) // cols
    cell = 150
    sheet = Image.new("RGBA", (cols * cell, rows * cell), (38, 42, 58, 255))
    for i, name in enumerate(ICONS):
        png = cairosvg.svg2png(bytestring=svg_text(name).encode(), output_width=128, output_height=128)
        sheet.alpha_composite(Image.open(io.BytesIO(png)).convert("RGBA"), ((i % cols) * cell + 11, (i // cols) * cell + 11))
    sheet.convert("RGB").save(path)
    print("đã lưu", path)


if __name__ == "__main__":
    write_all()
    if "--sheet" in sys.argv:
        write_sheet(sys.argv[sys.argv.index("--sheet") + 1])
