#!/usr/bin/env python3
"""Static UI color-palette audit for Gladiatus Pixel.

Usage:
    python tools/audit_ui_contrast.py
    python tools/audit_ui_contrast.py --strict

This is a palette-only WCAG contrast check, NOT a replacement for a screen
reader audit, visual QA, text-scaling tests or contrast over dynamic images.
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path

SOURCE = Path("lib/widgets/roman_theme.dart")

COMBINATIONS = (
    ("cream", "panel", "Textos principais", 4.5),
    ("paleGold", "panel", "Títulos destacados", 4.5),
    ("gold", "panel", "Títulos dourados", 4.5),
    ("gold", "dark", "Texto do cabeçalho", 4.5),
    ("red", "panel", "Texto vermelho em painel (derrota)", 4.5),
    ("red", "dark", "Texto vermelho sobre fundo", 4.5),
    ("bronze", "panel", "Contornos bronze funcionais", 3.0),
)


def palette() -> dict[str, str]:
    text = SOURCE.read_text(encoding="utf-8")
    colors = dict(re.findall(
        r"static const\s+(\w+)\s*=\s*Color\(0xFF([0-9a-fA-F]{6})\);",
        text,
    ))
    expected = {a for a, _, _, _ in COMBINATIONS} | {
        b for _, b, _, _ in COMBINATIONS
    }
    missing = expected - colors.keys()
    if missing:
        raise RuntimeError(f"Theme color(s) not found: {sorted(missing)}")
    return colors


def luminance(hex_rgb: str) -> float:
    values = [int(hex_rgb[i:i+2], 16) / 255 for i in (0, 2, 4)]
    linear = [c / 12.92 if c <= 0.04045 else ((c + .055)/1.055)**2.4
              for c in values]
    return .2126*linear[0] + .7152*linear[1] + .0722*linear[2]


def ratio(color_a: str, color_b: str) -> float:
    a, b = luminance(color_a), luminance(color_b)
    return (max(a,b)+.05)/(min(a,b)+.05)


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--strict", action="store_true",
                   help="Exit non-zero if any tracked pair fails")
    args = p.parse_args()
    colors = palette()
    failed = []
    print("Gladiatus Pixel — contrast inspection (static colors only)")
    for fg, bg, label, minimum in COMBINATIONS:
        actual = ratio(colors[fg], colors[bg])
        passed = actual >= minimum
        tag = "PASS" if passed else "FAIL"
        print(f"{tag:4} {actual:5.2f}:1  target={minimum:.1f}:1  {label}")
        if not passed:
            failed.append((fg,bg,actual))
    if failed:
        print(f"Attention: {len(failed)} palette pairs below target.")
    return 1 if args.strict and failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
