"""Extract the approved modular 128x144 hero art from a compact source atlas.

The source WEBP stores original artwork created for Gladiatus Pixel.
Columns: base, boots, bracers, cuirass, helmet, gladius, scutum, fully-equipped.
Do not change bounding boxes independently: every exported layer uses the
same 128x144 canvas and origin, making paper-doll composition deterministic.
"""
from __future__ import annotations

import base64
from io import BytesIO
from pathlib import Path

from PIL import Image

PAYLOAD = Path("assets/hero/atlas_128x144.webp.b64")
OUTPUT = Path("assets/sprites")
W, H = 128, 144
NAMES = (
    "gladiator_base_hd",
    "equip_boots_hd",
    "equip_gloves_hd",
    "equip_armor_hd",
    "equip_helmet_hd",
    "equip_weapon_hd",
    "equip_shield_hd",
    "gladiator_equipped_hd",
)


def run() -> None:
    payload = base64.b64decode(PAYLOAD.read_text(encoding="ascii").strip(), validate=True)
    with Image.open(BytesIO(payload)) as source:
        source.load()
        if source.size != (len(NAMES) * W, H):
            raise ValueError(f"Atlas dimension invalid: {source.size}")
        atlas = source.convert("RGBA")

    OUTPUT.mkdir(parents=True, exist_ok=True)
    for index, name in enumerate(NAMES):
        sprite = atlas.crop((index * W, 0, (index + 1) * W, H))
        # The weapon layer includes its gripping hand. Align that hand with
        # the base wrist; (20, 0) left a second hand below and to the right.
        # Preserve the shared canvas so all other equipment stays aligned.
        if name == "equip_weapon_hd":
            aligned = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            aligned.paste(sprite, (12, -4))
            sprite = aligned
        # Crisp silhouettes, transparent voids and lossless PNG export.
        # The input is a small, lossy WEBP atlas to keep the GitHub repo lean.
        alpha = sprite.getchannel("A").point(lambda value: 0 if value < 100 else 255)
        sprite.putalpha(alpha)
        if alpha.getbbox() is None:
            raise ValueError(f"Sprite is empty: {name}")
        sprite.save(OUTPUT / f"{name}.png", optimize=True)
        print(f"{name}.png: {sprite.width}x{sprite.height}")

    print(f"{len(NAMES)} approved hi-bit sprites extracted.")


if __name__ == "__main__":
    run()
