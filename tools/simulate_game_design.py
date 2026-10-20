#!/usr/bin/env python3
"""Monte Carlo game-design audit mirroring Gladiatus Pixel v1.3 combat formulas.

This is an INDEPENDENT Python model for balancing. It does not run Dart/Flutter
and it does not claim to test real players. Update the model when combat.dart
changes. Each trial starts at full life and has no persistent campaign economy.
"""
from __future__ import annotations
import argparse
import json
import random
from dataclasses import dataclass

@dataclass(frozen=True)
class Hero:
    level: int
    life: int
    minimum: int
    maximum: int
    power: int
    dexterity: int
    agility: int
    armor: int

@dataclass(frozen=True)
class Encounter:
    name: str
    hero: Hero
    tier: int
    boss: bool = False
    rank: int = 0

SCENARIOS = [
    Encounter("N1 lobo inicial", Hero(1,100,4,8,5,5,5,0),1),
    Encounter("N1 bandido inicial", Hero(1,100,4,8,5,5,5,0),2),
    Encounter("N2 chefe arma inicial", Hero(2,120,4,8,8,5,5,22),3,True),
    Encounter("N2 chefe equipamento leve", Hero(2,120,6,12,9,6,5,65),3,True),
    Encounter("N3 chefe equipado", Hero(3,140,8,16,12,8,8,100),3,True),
    Encounter("N5 chefe Porto", Hero(5,180,12,24,20,10,10,160),5,True),
    Encounter("N8 chefe final", Hero(8,240,18,35,28,14,14,260),8,True),
    Encounter("N8 rival rank 10", Hero(8,240,18,35,28,14,14,260),5,False,10),
]

POLICIES = ("normal", "pesado", "finta", "guarda_pesado", "adaptativo")

def clamp(n, lo, hi):
    return min(hi, max(lo, n))

def fight(encounter: Encounter, policy: str, seed: int) -> dict:
    p = encounter.hero
    tier = encounter.tier
    rival = clamp(encounter.rank, 0, 10)
    rng = random.Random(seed)
    enemy_life = 18 + tier*19 + p.level*7 + (35 if encounter.boss else 0) + rival*11
    hero_life = p.life
    max_enemy_life = enemy_life
    vigor, combo, round_number, received = 4, 0, 0, 0

    while hero_life > 0 and enemy_life > 0 and round_number < 35:
        if policy == "normal":
            action = "normal"
        elif policy == "finta":
            action = "finta"
        elif policy == "pesado":
            action = "pesado" if vigor >= 2 else "normal"
        elif policy == "guarda_pesado":
            action = "guarda" if round_number % 2 == 0 else (
                "pesado" if vigor >= 2 else "normal"
            )
        elif policy == "adaptativo":
            action = "finta" if hero_life <= p.life*.33 else (
                "pesado" if vigor >= 2 else "normal"
            )
        else:
            raise ValueError(policy)

        if action == "pesado" and vigor < 2:
            action = "normal"
        round_number += 1
        if action == "guarda":
            vigor = min(5, vigor+2)
            combo = min(3, combo+1)
        else:
            vigor = vigor-2 if action == "pesado" else min(5, vigor+1)
            nominal_hit = 65 if action == "pesado" else (
                86 if action == "finta" else 83
            )
            hit_odds = clamp(nominal_hit + p.dexterity//3 - tier*3,20,96)
            if rng.randrange(100) < hit_odds:
                base = rng.randint(p.minimum,p.maximum)+p.power//3
                crit = rng.randrange(100) < clamp(7+p.dexterity//8,4,28)
                if action == "pesado":
                    base = int(base*1.65+0.5)
                elif action == "finta":
                    base = int(base*.68+0.5)
                if crit:
                    base = int(base*1.5+0.5)
                base += combo*2
                enemy_life = max(0, enemy_life-max(1,base-(tier+rival)//2))
                combo = min(3,combo+1) if action == "finta" else 0
            else:
                combo = 0

        if enemy_life > 0:
            evade = clamp(p.agility//2 + (24 if action == "finta" else 0),0,45)
            if rng.randrange(100) >= evade:
                blow = 3 + tier*3 + p.level + rival*2 + rng.randrange(7)
                blow = max(1,blow-p.armor//36)
                if action == "guarda":
                    blow = max(1,int(blow*.35+.5))
                received += blow
                hero_life = max(0,hero_life-blow)

    return {
        "won": enemy_life == 0 and hero_life > 0,
        "rounds": round_number,
        "hero_remaining": hero_life,
        "received": received,
        "enemy_max_life": max_enemy_life,
    }

def analyze(trials: int) -> list:
    results = []
    for scene in SCENARIOS:
        rates = {}
        for policy in POLICIES:
            runs = [fight(scene,policy,1009+i*37) for i in range(trials)]
            rates[policy] = {
                "win_pct": round(100*sum(run["won"] for run in runs)/trials,1),
                "average_rounds": round(sum(run["rounds"] for run in runs)/trials,1),
                "average_damage_received": round(
                    sum(run["received"] for run in runs)/trials,1
                ),
            }
        results.append({
            "scenario":scene.name,
            "enemy_hp":18+scene.tier*19+scene.hero.level*7+
                       (35 if scene.boss else 0)+min(scene.rank,10)*11,
            "rates":rates,
        })
    return results

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--trials",type=int,default=5000)
    parser.add_argument("--json",action="store_true")
    args = parser.parse_args()
    if args.trials <= 0:
        parser.error("--trials must be positive")
    rows = analyze(args.trials)
    if args.json:
        print(json.dumps({"trials":args.trials,"results":rows},
                         ensure_ascii=False,indent=2))
    else:
        print(f"Monte Carlo model: {args.trials} trials per scenario and policy")
        print("| Scenario | Enemy HP | Normal | Heavy | Feint | Guard+Heavy | Adaptive |")
        print("|---|---:|---:|---:|---:|---:|---:|")
        for row in rows:
            data = row["rates"]
            vals = [data[key]["win_pct"] for key in POLICIES]
            print(f'| {row["scenario"]} | {row["enemy_hp"]} | '+
                  " | ".join(f"{v:.1f}%" for v in vals)+" |")
