import 'dart:math';
import 'package:flutter/material.dart';

enum Slot { weapon, shield, helmet, armor, gloves, boots, ring, amulet }
enum Rarity { common, green, blue, purple, orange }

class Gear {
  final String id;
  final String name;
  final Slot slot;
  final Rarity rarity;
  final int level;
  final int minDamage;
  final int maxDamage;
  final int armor;
  final int strength;
  final int dexterity;
  final int agility;
  final int constitution;
  final int price;
  final int forgeRank;

  const Gear({
    required this.id, required this.name, required this.slot,
    required this.rarity, required this.level, required this.price,
    this.minDamage = 0, this.maxDamage = 0, this.armor = 0,
    this.strength = 0, this.dexterity = 0, this.agility = 0,
    this.constitution = 0, this.forgeRank = 0,
  });

  Color get color => [
    const Color(0xFFD9D9D9), const Color(0xFF80D782),
    const Color(0xFF70B9FC), const Color(0xFFC18CF8),
    const Color(0xFFFFB36A),
  ][rarity.index];

  String get icon => 'assets/sprites/icon_' + slot.name + '.png';

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'slot': slot.index, 'rarity': rarity.index,
    'level': level, 'price': price, 'minDamage': minDamage,
    'maxDamage': maxDamage, 'armor': armor, 'strength': strength,
    'dexterity': dexterity, 'agility': agility, 'constitution': constitution, 'forgeRank': forgeRank,
  };

  factory Gear.fromJson(Map<String, dynamic> j) {
    int n(String key, [int fallback = 0]) => (j[key] as num?)?.toInt() ?? fallback;
    return Gear(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? 'Item').toString(),
      slot: Slot.values[n('slot').clamp(0, Slot.values.length - 1).toInt()],
      rarity: Rarity.values[n('rarity').clamp(0, Rarity.values.length - 1).toInt()],
      level: max(1, n('level', 1)), price: max(1, n('price', 10)),
      minDamage: n('minDamage'), maxDamage: n('maxDamage'),
      armor: n('armor'), strength: n('strength'),
      dexterity: n('dexterity'), agility: n('agility'),
      constitution: n('constitution'), forgeRank: n('forgeRank'),
    );
  }
}

class GearFactory {
  static final random = Random();
  static int serial = 0;
  static const names = <Slot, List<String>>{
    Slot.weapon: ['Gládio Curto', 'Tridente', 'Espada Larga', 'Machado'],
    Slot.shield: ['Parma de Madeira', 'Scutum Romano', 'Égide'],
    Slot.helmet: ['Gálea de Couro', 'Elmo Murmillo', 'Elmo Trácio'],
    Slot.armor: ['Túnica de Linho', 'Lorica Segmentata', 'Couraça'],
    Slot.gloves: ['Luvas de Combate', 'Manica de Couro'],
    Slot.boots: ['Caligae Romanas', 'Grevas de Bronze'],
    Slot.ring: ['Anel de Cobre', 'Anel de Rubi'],
    Slot.amulet: ['Talismã de Marte', 'Insígnia da Águia'],
  };
  static const titles = [
    'do Recruta', 'do Centurião', 'de Marte',
    'do Coliseu', 'do Imperador', 'da Vitória',
  ];

  static Gear create(int level) {
    final slot = Slot.values[random.nextInt(Slot.values.length)];
    final roll = random.nextDouble();
    final rarity = roll < .40 ? Rarity.common
      : roll < .70 ? Rarity.green : roll < .87 ? Rarity.blue
      : roll < .97 ? Rarity.purple : Rarity.orange;
    final itemLevel = max(1, level + random.nextInt(3) - 1);
    final factor = 1.0 + rarity.index * .45;
    final base = names[slot]!;
    final title = base[random.nextInt(base.length)];
    final name = rarity == Rarity.common ? title :
      title + ' ' + titles[random.nextInt(titles.length)];
    final isWeapon = slot == Slot.weapon;
    final isArmor = slot == Slot.helmet || slot == Slot.armor ||
      slot == Slot.shield || slot == Slot.gloves || slot == Slot.boots;
    final bonus = max(1, (itemLevel * factor).round());
    return Gear(
      id: DateTime.now().microsecondsSinceEpoch.toString() +
        '_' + (serial++).toString() + '_' + random.nextInt(9999).toString(),
      name: name, slot: slot, rarity: rarity, level: itemLevel,
      price: ((30 + itemLevel * 35) * factor).round(),
      minDamage: isWeapon ? ((2 + itemLevel * 2) * factor).round() : 0,
      maxDamage: isWeapon ? ((5 + itemLevel * 3.5) * factor).round() : 0,
      armor: isArmor ? ((7 + itemLevel * 15) * factor).round() : 0,
      strength: random.nextBool() ? random.nextInt(bonus + 1) : 0,
      dexterity: random.nextBool() ? random.nextInt(bonus + 1) : 0,
      agility: random.nextBool() ? random.nextInt(bonus + 1) : 0,
      constitution: random.nextBool() ? random.nextInt(bonus + 1) : 0,
    );
  }
}


extension Reforging on Gear {
  int get forgeCost => (35 + level * 20) * (forgeRank + 1);
  Gear reforged() {
    if (forgeRank >= 5) return this;
    int improved(int n) => n == 0 ? 0 : n + max(1, (n * .15).round());
    final empty = minDamage == 0 && maxDamage == 0 && armor == 0 &&
        strength == 0 && dexterity == 0 && agility == 0 && constitution == 0;
    return Gear(
      id: id, name: name, slot: slot, rarity: rarity, level: level,
      price: price + forgeCost ~/ 2, forgeRank: forgeRank + 1,
      minDamage: improved(minDamage), maxDamage: improved(maxDamage),
      armor: improved(armor), strength: improved(strength) + (empty ? 1 : 0),
      dexterity: improved(dexterity), agility: improved(agility),
      constitution: improved(constitution),
    );
  }
}
