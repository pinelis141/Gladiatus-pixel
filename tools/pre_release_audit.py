#!/usr/bin/env python3
"""Pre-release structural audit. Run before flutter analyze/test and APK.

The purpose is to fail closed when critical UX/game-design regressions appear.
This is not a substitute for Flutter widget tests, instrumented Android
tests, signing verification, accessibility scanners or human playtests.
"""
from pathlib import Path
from PIL import Image
import re

ROOT=Path(__file__).resolve().parent.parent

def content(path):
    f=ROOT/path
    if not f.is_file():raise AssertionError(f'Missing: {path}')
    return f.read_text(encoding='utf-8')

def require_source(path, needles):
    text=content(path)
    for needle in needles:
        if needle not in text:
            raise AssertionError(f'Feature marker missing: {path}: {needle}')
    return text

def run():
    reports=[
        'docs/AUDITORIA_V1_3.md',
        'docs/AUDITORIA_GAME_DESIGN_V1_3.md',
        'docs/AUDITORIA_UI_UX_V1_3.md',
        'docs/AUDITORIA_INTEGRADA_V2.md',
    ]
    for doc in reports:
        assert len(content(doc))>1000, f'Incomplete audit: {doc}'
    main=require_source('lib/main.dart',[
        "gladiatus_pixel_save_v2",
        'Future<void> sellSafely(',
        'Vs equipado:',
        "final firstBossWin=",
        "itemFilter",
        "rivalDefeats",
        "tutorialSeen",
        "showPreferences",
        "saveStatus",
        "guarantee",
        "contractsPanel()",
        "restPanel()",
        "lockReason(",
    ])
    battle=require_source('lib/systems/combat.dart',[
        "enum EnemyIntent",
        "intentLabel",
        "_nextIntent",
        "case 'Ágil':",
        "case 'Blindado':",
        "case 'Feroz':",
        "case 'Colossal':",
        "case 'Tático':",
    ])
    screen=require_source('lib/screens/battle_screen.dart',[
        "LayoutBuilder", "RomanProgress",
        "onPopInvokedWithResult", "soundEnabled", "vibrationEnabled",
        "INTENÇÃO", "VER RECOMPENSAS",
    ])
    gear=require_source('lib/models/gear.dart',[
        "enum Slot", "enum Rarity", "forgeRank", "reforged",
    ])
    theme=require_source('lib/widgets/roman_theme.dart',[
        "Semantics(", "Color(0xFFE7838C)",
        "Color(0xFFB58E69)",
    ])
    # Unambiguous critical regressions from previous audits.
    assert 'enemy.boss?110:0' not in main
    assert 'enemy.boss ? 110 : 0' not in main
    assert 'firstBossWin?110:0' in main
    assert 'NavigationDestinationLabelBehavior.alwaysShow' in main
    assert 'width:300,height:110' not in main
    assert 'scale:bounce?.97' not in screen
    assert 'minHeight:38' not in main
    assert 'if (move == CombatMove.heavy && stamina < 2)' in battle
    # Confirm 8 layered HD assets and corresponding 128 x 144 alignment.
    preview=ROOT/'assets/previews/gladiator_comparison.png'
    with Image.open(preview) as im:
        assert im.size==(128*3,144),im.size
    for name in ('gladiator_base_hd','equip_helmet_hd',
                 'equip_armor_hd','equip_weapon_hd',
                 'equip_shield_hd','equip_gloves_hd','equip_boots_hd'):
        with Image.open(ROOT/'assets/sprites'/f'{name}.png') as im:
            assert im.size==(128,144),f'{name}: {im.size}'
    print('AUDIT OK: documented risks and release safety invariants verified')
    print('Reminder: Android update-signature issue still requires a private keystore.')

if __name__=='__main__':
    run()
