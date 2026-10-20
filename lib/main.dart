import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GladiatusApp());
}

class Palette {
  static const dark = Color(0xFF1A120B);
  static const panel = Color(0xFF2C1E14);
  static const gold = Color(0xFFC59B27);
  static const cream = Color(0xFFF4E7D3);
  static const red = Color(0xFF9F3234);
}

class GladiatusApp extends StatelessWidget {
  const GladiatusApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Gladiatus Pixel',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Palette.dark,
      colorScheme: const ColorScheme.dark(
        primary: Palette.gold,
        secondary: Palette.red,
        surface: Palette.panel,
        onSurface: Palette.cream,
      ),
      fontFamily: 'monospace',
    ),
    home: const GameScreen(),
  );
}

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

  const Gear({
    required this.id, required this.name, required this.slot,
    required this.rarity, required this.level, required this.price,
    this.minDamage = 0, this.maxDamage = 0, this.armor = 0,
    this.strength = 0, this.dexterity = 0, this.agility = 0,
    this.constitution = 0,
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
    'dexterity': dexterity, 'agility': agility, 'constitution': constitution,
  };

  factory Gear.fromJson(Map<String, dynamic> j) {
    int n(String key, [int fallback = 0]) => (j[key] as num?)?.toInt() ?? fallback;
    return Gear(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? 'Item').toString(),
      slot: Slot.values[n('slot').clamp(0, Slot.values.length - 1)],
      rarity: Rarity.values[n('rarity').clamp(0, Rarity.values.length - 1)],
      level: max(1, n('level', 1)), price: max(1, n('price', 10)),
      minDamage: n('minDamage'), maxDamage: n('maxDamage'),
      armor: n('armor'), strength: n('strength'),
      dexterity: n('dexterity'), agility: n('agility'),
      constitution: n('constitution'),
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

class Sprite extends StatelessWidget {
  final String name;
  final double width;
  final double height;
  const Sprite(this.name, {super.key, required this.width, required this.height});
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/sprites/' + name + '.png',
    width: width, height: height, fit: BoxFit.fill,
    filterQuality: FilterQuality.none,
    errorBuilder: (context, error, stack) => Container(
      width: width, height: height,
      alignment: Alignment.center,
      color: Palette.panel,
      child: const Icon(Icons.shield, color: Palette.gold),
    ),
  );
}

class HeroAvatar extends StatelessWidget {
  final Map<Slot, Gear> equipment;
  const HeroAvatar({super.key, required this.equipment});
  @override
  Widget build(BuildContext context) {
    final assets = <String>['gladiator_base'];
    for (final slot in [Slot.armor, Slot.helmet, Slot.weapon, Slot.shield]) {
      if (equipment.containsKey(slot)) assets.add('equip_' + slot.name);
    }
    return SizedBox(
      width: 176, height: 198,
      child: Stack(
        children: assets.map((path) => Positioned.fill(
          child: Sprite(path, width: 176, height: 198),
        )).toList(),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const saveKey = 'gladiatus_pixel_save_v2';
  final random = Random();
  int page = 0, level = 1, experience = 0, gold = 300;
  int energy = 10, health = 100, wins = 0, points = 0;
  int strength = 5, dexterity = 5, agility = 5, constitution = 5;
  bool loading = true;
  final Map<Slot, Gear> equipped = {};
  final List<Gear> bag = [];
  final List<Gear> shop = [];

  int bonus(int Function(Gear) f) =>
    equipped.values.fold<int>(0, (sum, gear) => sum + f(gear));
  int get maxHealth => 70 + level * 20 +
    (constitution + bonus((g) => g.constitution)) * 2;
  int get attack => strength + bonus((g) => g.strength);
  int get protection => bonus((g) => g.armor);
  int get xpNeeded => 30 + (level - 1) * 25;
  int get hitChance => dexterity + bonus((g) => g.dexterity);
  int get dodgeChance => agility + bonus((g) => g.agility);

  @override
  void initState() {
    super.initState();
    unawaited(loadGame());
  }

  void newGame() {
    page = 0; level = 1; experience = 0; gold = 300; energy = 10;
    wins = 0; points = 0;
    strength = 5; dexterity = 5; agility = 5; constitution = 5;
    bag.clear(); equipped.clear();
    equipped[Slot.weapon] = const Gear(
      id: 'initial_gladius', name: 'Gládio de Treino',
      slot: Slot.weapon, rarity: Rarity.common, level: 1,
      price: 15, minDamage: 4, maxDamage: 8,
    );
    health = maxHealth;
    refreshShop();
  }

  void refreshShop() {
    shop
      ..clear()
      ..addAll(List.generate(7, (_) => GearFactory.create(level)));
  }

  Future<void> loadGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(saveKey);
      if (raw == null) {
        newGame();
      } else {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        int n(String key, int fallback) =>
          (data[key] as num?)?.toInt() ?? fallback;
        level = max(1, n('level', 1));
        experience = max(0, n('experience', 0));
        gold = max(0, n('gold', 300));
        energy = n('energy', 10).clamp(0, 10);
        wins = max(0, n('wins', 0));
        points = max(0, n('points', 0));
        strength = max(1, n('strength', 5));
        dexterity = max(1, n('dexterity', 5));
        agility = max(1, n('agility', 5));
        constitution = max(1, n('constitution', 5));
        equipped.clear();
        for (final value in (data['equipped'] as List<dynamic>? ?? [])) {
          final gear = Gear.fromJson(Map<String, dynamic>.from(value as Map));
          equipped[gear.slot] = gear;
        }
        bag
          ..clear()
          ..addAll((data['bag'] as List<dynamic>? ?? []).map((value) =>
            Gear.fromJson(Map<String, dynamic>.from(value as Map))));
        health = n('health', maxHealth).clamp(0, maxHealth);
        refreshShop();
      }
    } catch (_) {
      newGame();
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> saveGame() async {
    final data = {
      'level': level, 'experience': experience, 'gold': gold,
      'energy': energy, 'health': health, 'wins': wins, 'points': points,
      'strength': strength, 'dexterity': dexterity,
      'agility': agility, 'constitution': constitution,
      'equipped': equipped.values.map((g) => g.toJson()).toList(),
      'bag': bag.map((g) => g.toJson()).toList(),
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(saveKey, jsonEncode(data));
    } catch (_) {
      if (mounted) notice('Não foi possível salvar neste dispositivo.');
    }
  }

  void notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)));
  }

  void equip(Gear gear) {
    if (gear.level > level) {
      notice('Necessário nível ' + gear.level.toString());
      return;
    }
    if (!bag.any((g) => g.id == gear.id)) return;
    setState(() {
      bag.removeWhere((g) => g.id == gear.id);
      final previous = equipped[gear.slot];
      if (previous != null) bag.add(previous);
      equipped[gear.slot] = gear;
      health = min(health, maxHealth);
    });
    unawaited(saveGame());
  }

  void removeGear(Slot slot) {
    if (bag.length >= 40) {
      notice('Inventário cheio.'); return;
    }
    if (!equipped.containsKey(slot)) return;
    setState(() {
      bag.add(equipped.remove(slot)!);
      health = min(health, maxHealth);
    });
    unawaited(saveGame());
  }

  void sell(Gear gear) {
    if (!bag.any((g) => g.id == gear.id)) return;
    setState(() {
      bag.removeWhere((g) => g.id == gear.id);
      gold += max(1, gear.price ~/ 2);
    });
    unawaited(saveGame());
  }

  void buy(Gear gear) {
    if (gold < gear.price) { notice('Ouro insuficiente.'); return; }
    if (bag.length >= 40) { notice('Inventário cheio.'); return; }
    if (!shop.any((g) => g.id == gear.id)) return;
    setState(() {
      gold -= gear.price; bag.add(gear);
      shop.removeWhere((g) => g.id == gear.id);
    });
    unawaited(saveGame());
  }

  void rest() {
    if (gold < 15) { notice('Precisa de 15 moedas.'); return; }
    setState(() {
      gold -= 15; health = maxHealth; energy = 10;
    });
    unawaited(saveGame());
    notice('Vida e energia restauradas!');
  }

  void train(String attribute) {
    if (points <= 0) return;
    setState(() {
      switch (attribute) {
        case 'Força': strength++; break;
        case 'Destreza': dexterity++; break;
        case 'Agilidade': agility++; break;
        case 'Constituição': constitution++; break;
      }
      points--;
    });
    unawaited(saveGame());
  }

  void fight(String name, String sprite, int difficulty) {
    if (energy == 0) { notice('Sem energia. Visite a taverna.'); return; }
    if (health == 0) { notice('Ferido. Visite a taverna.'); return; }
    final weapon = equipped[Slot.weapon];
    final lower = weapon?.minDamage ?? 3;
    final upper = max(lower, weapon?.maxDamage ?? 6);
    var enemyHp = 18 + difficulty * 17 + level * 6;
    var myHp = health, rounds = 0, damageDone = 0, damageTaken = 0;
    while (myHp > 0 && enemyHp > 0 && rounds < 30) {
      rounds++;
      if (random.nextInt(100) < min(94, 70 + hitChance - difficulty * 2)) {
        final damage = lower + random.nextInt(upper - lower + 1) +
          attack ~/ 3;
        enemyHp -= damage;
        damageDone += damage;
      }
      if (enemyHp <= 0) break;
      if (random.nextInt(100) >= min(35, dodgeChance)) {
        final damage = max(1, 3 + difficulty * 3 + level +
          random.nextInt(7) - protection ~/ 35);
        myHp -= damage;
        damageTaken += damage;
      }
    }
    final won = enemyHp <= 0;
    final reward = won ? 15 + difficulty * 12 + random.nextInt(16) : 0;
    final earnedXp = won ? 12 + difficulty * 9 : 0;
    String? drop;
    setState(() {
      energy--; health = max(0, myHp);
      if (won) {
        wins++; gold += reward; experience += earnedXp;
        while (experience >= xpNeeded) {
          experience -= xpNeeded;
          level++; points += 3; health = maxHealth;
        }
        if (bag.length < 40 && random.nextDouble() < .35) {
          final loot = GearFactory.create(level);
          bag.add(loot);
          drop = loot.name;
        }
      }
    });
    unawaited(saveGame());
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Palette.panel,
        title: Text(won ? 'Vitória: ' + name : 'Derrota: ' + name),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Sprite(sprite, width: 100, height: 100),
          const SizedBox(height: 12),
          Text('Rodadas: ' + rounds.toString() +
            ' • Dano causado: ' + damageDone.toString() +
            ' • Recebido: ' + damageTaken.toString(),
            textAlign: TextAlign.center),
          if (won) Text('+' + reward.toString() + ' ouro • +' +
            earnedXp.toString() + ' XP'),
          if (drop != null) Text('Espólio: ' + drop!,
            textAlign: TextAlign.center),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CONTINUAR')),
        ],
      ),
    );
  }

  Widget panel(String heading, Widget child) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Palette.panel,
      border: Border.all(color: Palette.gold.withOpacity(.6)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading.toUpperCase(), style: const TextStyle(
          color: Palette.gold, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );

  Widget metric(String name, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Expanded(child: Text(name)),
      Text(value, style: const TextStyle(color: Palette.gold)),
    ]),
  );

  Widget stat(String name, int value) => Row(children: [
    Expanded(child: Text(name)),
    Text(value.toString(), style: const TextStyle(color: Palette.gold)),
    IconButton(
      onPressed: points > 0 ? () => train(name) : null,
      tooltip: 'Melhorar ' + name,
      icon: const Icon(Icons.add_circle_outline),
    ),
  ]);

  Widget gearCard(Gear gear, String action, VoidCallback onPressed,
    {VoidCallback? secondary, String? secondaryLabel}) {
    final stats = <String>[
      if (gear.minDamage > 0)
        'Dano ' + gear.minDamage.toString() + '-' + gear.maxDamage.toString(),
      if (gear.armor > 0) 'Armadura ' + gear.armor.toString(),
      if (gear.strength > 0) 'FOR +' + gear.strength.toString(),
      if (gear.dexterity > 0) 'DES +' + gear.dexterity.toString(),
      if (gear.agility > 0) 'AGI +' + gear.agility.toString(),
      if (gear.constitution > 0) 'CON +' + gear.constitution.toString(),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: gear.color.withOpacity(.6)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Image.asset(gear.icon, width: 52, height: 52,
          filterQuality: FilterQuality.none,
          errorBuilder: (_, error, stack) =>
            const Icon(Icons.shield, size: 52)),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(gear.name, style: TextStyle(
            color: gear.color, fontWeight: FontWeight.bold)),
          Text('Nível ' + gear.level.toString() + ' • ' + gear.slot.name,
            style: const TextStyle(fontSize: 12)),
          Text(stats.isEmpty ? 'Sem atributos adicionais' : stats.join(' • '),
            style: const TextStyle(fontSize: 11)),
          Wrap(spacing: 6, children: [
            OutlinedButton(onPressed: onPressed, child: Text(action,
              style: const TextStyle(fontSize: 11))),
            if (secondary != null)
              TextButton(onPressed: secondary,
                child: Text(secondaryLabel ?? 'Vender',
                  style: const TextStyle(fontSize: 11))),
          ]),
        ])),
      ]),
    );
  }

  Widget heroPage() => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      panel('Seu gladiador', Column(children: [
        Center(child: HeroAvatar(equipment: equipped)),
        Text('GLADIADOR • NÍVEL ' + level.toString(),
          style: const TextStyle(
            color: Palette.gold, fontWeight: FontWeight.bold)),
        Text('Vitórias: ' + wins.toString()),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: health / maxHealth, minHeight: 9,
          color: Palette.red),
        Text('Vida ' + health.toString() + '/' + maxHealth.toString()),
        const SizedBox(height: 9),
        LinearProgressIndicator(value: experience / xpNeeded, minHeight: 7),
        Text('Experiência ' + experience.toString() +
          '/' + xpNeeded.toString()),
      ])),
      panel('Atributos • ' + points.toString() + ' pontos disponíveis',
        Column(children: [
          stat('Força', strength + bonus((g) => g.strength)),
          stat('Destreza', dexterity + bonus((g) => g.dexterity)),
          stat('Agilidade', agility + bonus((g) => g.agility)),
          stat('Constituição', constitution + bonus((g) => g.constitution)),
          metric('Poder de ataque', attack.toString()),
          metric('Armadura', protection.toString()),
        ])),
      panel('Equipamentos', Column(
        children: Slot.values.map((slot) {
          final gear = equipped[slot];
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Image.asset('assets/sprites/icon_' + slot.name + '.png',
              width: 36, height: 36, filterQuality: FilterQuality.none,
              errorBuilder: (_, error, stack) =>
                const Icon(Icons.shield)),
            title: Text(gear?.name ?? 'Vazio • ' + slot.name),
            trailing: gear == null ? null : IconButton(
              tooltip: 'Retirar equipamento',
              onPressed: () => removeGear(slot),
              icon: const Icon(Icons.remove_circle_outline)),
          );
        }).toList(),
      )),
    ],
  );

  Widget opponent(String name, String image, int difficulty,
    String description) => panel(name, Row(children: [
      Sprite(image, width: 94, height: 94),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(description),
        Text('Dificuldade ' + difficulty.toString() + '/5',
          style: const TextStyle(color: Palette.gold)),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => fight(name, image, difficulty),
          child: const Text('COMBATER')),
      ])),
    ]));

  Widget missionsPage() => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      panel('Expedições', const Text(
        'Enfrente inimigos para ganhar ouro, experiência e itens. '
        'Cada luta consome 1 energia.')),
      opponent('Lobo da Floresta', 'enemy_wolf', 1,
        'Predador à espreita nas estradas.'),
      opponent('Pirata do Porto', 'enemy_pirate', 2,
        'Saqueador das rotas comerciais.'),
      opponent('Minotauro', 'enemy_minotaur', 4,
        'Uma fera poderosa. Prepare-se!'),
      panel('Taverna', Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Restaure vida e energia por 15 moedas.'),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: rest,
          icon: const Icon(Icons.hotel),
          label: const Text('DESCANSAR • 15 OURO')),
      ])),
    ],
  );

  Widget arenaPage() => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      panel('Arena Romana', const Text(
        'Desafie rivais controlados pelo jogo e prove o seu valor.')),
      opponent('Recruta da Arena', 'enemy_gladiator', 2,
        'Adversário em início de carreira.'),
      opponent('Veterano Pretoriano', 'enemy_gladiator', 3,
        'Treinado nas legiões romanas.'),
      opponent('Campeão do Coliseu', 'enemy_gladiator', 5,
        'Desafio reservado aos mais fortes.'),
    ],
  );

  Widget inventoryPage() => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      panel('Inventário • ' + bag.length.toString() + '/40',
        bag.isEmpty
          ? const Text('Nenhum item. Explore ou visite o mercado.')
          : Column(children: bag.map((gear) => gearCard(
              gear, gear.level > level ? 'Nível insuficiente' : 'Equipar',
              () => equip(gear),
              secondary: () => sell(gear),
              secondaryLabel: 'Vender +' +
                (max(1, gear.price ~/ 2)).toString(),
            )).toList())),
    ],
  );

  Widget marketPage() => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      panel('Mercador', Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Mercadorias com raridade e atributos variados.'),
        TextButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Atualizar mercadorias'),
          onPressed: () => setState(refreshShop)),
      ])),
      ...shop.map((gear) => gearCard(
        gear, 'Comprar • ' + gear.price.toString() + ' ouro',
        () => buy(gear))),
      if (shop.isEmpty) const Text('As mercadorias acabaram. Atualize a lista.'),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Palette.panel,
      title: const Text('GLADIATUS PIXEL',
        style: TextStyle(color: Palette.gold, fontSize: 18,
          fontWeight: FontWeight.bold)),
      actions: [
        IconButton(
          tooltip: 'Salvar jogo',
          onPressed: () => unawaited(saveGame()),
          icon: const Icon(Icons.save_outlined)),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Row(children: [
            Expanded(child: Text('NV ' + level.toString() +
              ' • OURO ' + gold.toString(),
              style: const TextStyle(color: Palette.gold))),
            Text('❤ ' + health.toString() + '/' + maxHealth.toString() +
              '  ⚡ ' + energy.toString() + '/10',
              style: const TextStyle(fontSize: 12)),
          ]),
        ),
      ),
    ),
    body: loading
      ? const Center(child: CircularProgressIndicator())
      : IndexedStack(index: page, children: [
          heroPage(), missionsPage(), arenaPage(),
          inventoryPage(), marketPage(),
        ]),
    bottomNavigationBar: NavigationBar(
      height: 72,
      backgroundColor: Palette.panel,
      selectedIndex: page,
      onDestinationSelected: (next) => setState(() => page = next),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.person), label: 'Herói'),
        NavigationDestination(icon: Icon(Icons.map), label: 'Missões'),
        NavigationDestination(icon: Icon(Icons.shield), label: 'Arena'),
        NavigationDestination(icon: Icon(Icons.backpack), label: 'Itens'),
        NavigationDestination(icon: Icon(Icons.storefront), label: 'Mercado'),
      ],
    ),
  );
}
