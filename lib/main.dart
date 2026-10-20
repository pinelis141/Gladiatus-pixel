import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/gear.dart';
import 'systems/combat.dart';
import 'systems/content.dart';
import 'screens/battle_screen.dart';
import 'widgets/roman_theme.dart';
import 'widgets/pixel_avatar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GladiatusApp());
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

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const saveKey = 'gladiatus_pixel_save_v2';
  final random = Random();
  int page = 0, shopSection = 0, level = 1, experience = 0, gold = 300;
  String itemFilter = 'Todos';
  bool soundEnabled=true, vibrationEnabled=true, tutorialSeen=false;
  String saveStatus='Salvo';
  int energy = 10, health = 100, wins = 0, points = 0;
  int strength = 5, dexterity = 5, agility = 5, constitution = 5;
  bool loading = true;
  final Map<Slot, Gear> equipped = {};
  final List<Gear> bag = [];
  final List<Gear> shop = [];
  final Map<String,int> rivalVictories = {};
  final Map<String,int> rivalDefeats = {};
  final Map<String,int> contracts = {};
  final Set<String> claimedContracts = {};
  final Set<String> defeatedBosses = {};
  String contractDay = localDayKey(DateTime.now());
  bool isFighting = false;
  Future<void> _saveQueue = Future<void>.value();

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
    rivalVictories.clear();rivalDefeats.clear(); contracts.clear();
    soundEnabled=true;vibrationEnabled=true;tutorialSeen=false;
    claimedContracts.clear(); defeatedBosses.clear();
    contractDay=localDayKey(DateTime.now());
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
    SharedPreferences? recoveryPrefs;
    String? originalRaw;
    try {
      final prefs = await SharedPreferences.getInstance();
      recoveryPrefs = prefs;
      final raw = prefs.getString(saveKey);
      originalRaw = raw;
      if (raw == null) {
        newGame();
      } else {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        int n(String key, int fallback) =>
          (data[key] as num?)?.toInt() ?? fallback;
        level = max(1, n('level', 1));
        experience = max(0, n('experience', 0));
        gold = max(0, n('gold', 300));
        energy = n('energy', 10).clamp(0, 10).toInt();
        wins = max(0, n('wins', 0));
        rivalVictories..clear()..addAll(
          (data['rivalVictories'] as Map<String,dynamic>? ?? {})
              .map((key,value)=>MapEntry(key,(value as num).toInt())));
        rivalDefeats..clear()..addAll(
          (data['rivalDefeats'] as Map<String,dynamic>? ?? {})
              .map((key,value)=>MapEntry(key,(value as num).toInt())));
        soundEnabled=data['soundEnabled'] != false;
        vibrationEnabled=data['vibrationEnabled'] != false;
        tutorialSeen=data['tutorialSeen'] == true;
        contracts..clear()..addAll(
          (data['contracts'] as Map<String,dynamic>? ?? {})
              .map((key,value)=>MapEntry(key,(value as num).toInt())));
        claimedContracts..clear()..addAll(
          (data['claimedContracts'] as List<dynamic>? ?? []).cast<String>());
        defeatedBosses..clear()..addAll(
          (data['defeatedBosses'] as List<dynamic>? ?? []).cast<String>());
        contractDay=(data['contractDay'] ?? localDayKey(DateTime.now())).toString();
        if(contractDay!=localDayKey(DateTime.now())) {
          contracts.clear(); claimedContracts.clear();
          contractDay=localDayKey(DateTime.now());
        }
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
        health = n('health', maxHealth).clamp(0, maxHealth).toInt();
        shop.clear();
        if (data['shop'] is List) {
          shop.addAll((data['shop'] as List<dynamic>).map((value) =>
            Gear.fromJson(Map<String, dynamic>.from(value as Map))));
        } else {
          refreshShop(); // Legacy save compatibility.
        }
      }
    } catch (_) {
      // Keep a recoverable copy before the next save replaces damaged data.
      var backedUp = false;
      if (originalRaw != null && recoveryPrefs != null) {
        try {
          backedUp = await recoveryPrefs.setString(
              '${saveKey}_corrupt_backup', originalRaw);
        } catch (_) {
          backedUp = false;
        }
      }
      newGame();
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) notice(backedUp
              ? 'Save inválido: uma cópia foi preservada para recuperação.'
              : 'Falha ao carregar o save: não foi possível fazer backup.');
        });
      }
    }
    if (mounted) setState(() => loading = false);
  }

  // Serialize writes so a slow older save cannot overwrite a newer one.
  // Snapshot the state before scheduling the write.
  Future<void> saveGame() {
    if(mounted && saveStatus!='Salvando')setState(()=>saveStatus='Salvando');
    final snapshot = jsonEncode({
      'level': level, 'experience': experience, 'gold': gold,
      'energy': energy, 'health': health, 'wins': wins, 'points': points,
      'strength': strength, 'dexterity': dexterity,
      'agility': agility, 'constitution': constitution,
      'rivalVictories': rivalVictories,'rivalDefeats':rivalDefeats,
      'soundEnabled':soundEnabled,'vibrationEnabled':vibrationEnabled,
      'tutorialSeen':tutorialSeen, 'contracts': contracts,
      'claimedContracts': claimedContracts.toList(),
      'defeatedBosses': defeatedBosses.toList(), 'contractDay': contractDay,
      'equipped': equipped.values.map((g) => g.toJson()).toList(),
      'bag': bag.map((g) => g.toJson()).toList(),
      'shop': shop.map((g) => g.toJson()).toList(),
    });
    _saveQueue = _saveQueue.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final stored = await prefs.setString(saveKey, snapshot);
        if (!stored) throw StateError('Persistência recusada');
        if(mounted)setState(()=>saveStatus='Salvo');
      } catch (_) {
        if (mounted){
          setState(()=>saveStatus='Erro ao salvar');
          notice('Falha ao salvar. Tente novamente.');
        }
      }
    });
    return _saveQueue;
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
    // Emergency recovery prevents softlocks, but free resting while healthy
    // would make combat and the economy consequence-free.
    if (gold < 15 && health > 0 && energy > 0) {
      notice('Descanso custa 15 moedas. Emergências são gratuitas.');
      return;
    }
    if (gold < 15) notice('Socorro de emergência gratuito.');
    setState(() {
      if(gold>=15) gold-=15;
      health=maxHealth;energy=10;
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

  void dailyResetIfNeeded(){
    final today=localDayKey(DateTime.now());
    if(contractDay!=today) {
      contracts.clear();claimedContracts.clear();contractDay=today;
    }
  }

  void progressContract(String type){
    dailyResetIfNeeded();
    contracts[type]=(contracts[type]??0)+1;
  }

  void checkLevelUp(){
    while(experience>=xpNeeded) {
      experience-=xpNeeded;level++;points+=3;health=maxHealth;
    }
  }

  void claimContract(Contract contract){
    dailyResetIfNeeded();
    if((contracts[contract.id]??0)<contract.target ||
        claimedContracts.contains(contract.id)) return;
    setState((){
      claimedContracts.add(contract.id);
      gold+=contract.gold;experience+=contract.xp;checkLevelUp();
    });
    unawaited(saveGame());
    notice('Contrato: +' + contract.gold.toString() +
      ' ouro e +' + contract.xp.toString() + ' XP.');
  }

  bool accessible(EnemySpec opponent){
    if(level<opponent.minLevel)return false;
    if(opponent.region=='Porto de Óstia' &&
       !defeatedBosses.contains('forest_boss'))return false;
    if(opponent.region=='Ruínas de Vulcano' &&
       !defeatedBosses.contains('port_boss'))return false;
    return true;
  }

  Future<void> fight(EnemySpec enemy) async {
    if(isFighting)return;
    if(!accessible(enemy)) {
      notice('Região bloqueada. Suba de nível e derrote o chefe anterior.');
      return;
    }
    if(energy==0){notice('Sem energia. Descanse na taverna.');return;}
    if(health==0){notice('Ferido. Descanse na taverna.');return;}
    setState((){
      isFighting=true;energy--;
    });
    unawaited(saveGame());
    final weapon=equipped[Slot.weapon];
    BattleOutcome? outcome;
    try {
      outcome=await Navigator.of(context).push<BattleOutcome>(
        MaterialPageRoute(builder: (_)=>BattleScreen(
          enemy:enemy,equipment:Map<Slot,Gear>.from(equipped),
          startingHealth:health,maxHealth:maxHealth,
          playerLevel:level,power:attack,accuracy:hitChance,
          evasion:dodgeChance,protection:protection,
          minWeapon:weapon?.minDamage??3,
          maxWeapon:weapon?.maxDamage??6,
          rivalRank:max(0,(rivalVictories[enemy.id]??0)-
            (rivalDefeats[enemy.id]??0)),
          soundEnabled:soundEnabled,vibrationEnabled:vibrationEnabled,
        )),
      );
    } finally {
      isFighting=false;
    }
    if(outcome==null||!mounted)return;
    if (outcome.retreated) {
      setState(() => health = outcome!.remainingHealth);
      unawaited(saveGame());
      notice('Você recuou. Energia consumida; saúde preservada.');
      return;
    }
    String? drop;
    final firstBossWin=enemy.boss&&!defeatedBosses.contains(enemy.id);
    final reward=outcome.won ? 22+enemy.tier*13+
      (firstBossWin?110:0)+random.nextInt(15):0;
    final gainedXp=outcome.won ? 15+enemy.tier*9+
      (firstBossWin?65:0):0;
    setState((){
      health=outcome!.remainingHealth;
      if(outcome.won) {
        wins++;gold+=reward;experience+=gainedXp;
        progressContract('victories');
        progressContract(enemy.arena?'arena':'expedition');
        if(enemy.arena) {
          rivalVictories[enemy.id]=(rivalVictories[enemy.id]??0)+1;
        }
        if(enemy.boss)defeatedBosses.add(enemy.id);
        checkLevelUp();
        final guarantee=enemy.id=='wolf' && wins==1;
        if(bag.length<40&&(guarantee || random.nextDouble()<
            (firstBossWin?.85:.40))) {
          final loot=guarantee?
              Gear(id:'first_upgrade',name:'Gládio do Recruta',
                slot:Slot.weapon,rarity:Rarity.green,level:1,
                price:90,minDamage:7,maxDamage:12,strength:1):
              GearFactory.create(level);
          bag.add(loot);drop=loot.name;
        }
      } else if(enemy.arena){
        rivalDefeats[enemy.id]=(rivalDefeats[enemy.id]??0)+1;
      }
    });
    unawaited(saveGame());
    if(!mounted)return;
    showDialog<void>(context:context,builder:(context)=>AlertDialog(
      backgroundColor:Palette.panel,
      title:Text(outcome!.won?'Triunfo romano':'Derrota'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        Text(enemy.name),
        Text('Rodadas: '+outcome.turns.toString()),
        Text(outcome.won?'+'+reward.toString()+' ouro • +'+
          gainedXp.toString()+' XP':'Tente novamente.'),
        if(drop!=null)Text('Espólio: '+drop!),
        if(enemy.arena&&outcome.won)
          Text('Rivalidade '+(rivalVictories[enemy.id]??0).toString()),
        if(enemy.boss&&outcome.won)
          const Text('Uma nova região foi desbloqueada!'),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),
        child:const Text('CONTINUAR'))],
    ));
  }

  void forge(Gear gear,{required bool fromEquipment}){
    final existing=fromEquipment?equipped[gear.slot]:
      (bag.where((g)=>g.id==gear.id).isEmpty?null:
       bag.firstWhere((g)=>g.id==gear.id));
    if(existing==null||existing.id!=gear.id)return;
    if(gear.forgeRank>=5){notice('Reforja máxima alcançada.');return;}
    if(gold<gear.forgeCost){notice('Ouro insuficiente.');return;}
    final upgrade=gear.reforged();
    setState((){
      gold-=gear.forgeCost;
      if(fromEquipment){equipped[gear.slot]=upgrade;}
      else {
        final i=bag.indexWhere((g)=>g.id==gear.id);
        if(i>=0)bag[i]=upgrade;
      }
      progressContract('forge');
      health=min(health,maxHealth);
    });
    unawaited(saveGame());
    notice('Ferreiro concluiu o reforço +'+upgrade.forgeRank.toString()+'.');
  }

  String slotLabel(Slot s)=>switch(s){
    Slot.weapon=>'Arma', Slot.shield=>'Escudo',
    Slot.helmet=>'Capacete', Slot.armor=>'Armadura',
    Slot.gloves=>'Luvas',Slot.boots=>'Botas',
    Slot.ring=>'Anel',Slot.amulet=>'Amuleto',
  };
  String rarityLabel(Rarity r)=>switch(r){
    Rarity.common=>'Comum',Rarity.green=>'Incomum',
    Rarity.blue=>'Raro',Rarity.purple=>'Épico',
    Rarity.orange=>'Lendário',
  };
  String lockReason(EnemySpec e){
    if(level<e.minLevel)return 'Exige nível ${e.minLevel}';
    if(e.region=='Porto de Óstia'&&
        !defeatedBosses.contains('forest_boss')){
      return 'Derrote o Guardião da Floresta';
    }
    if(e.region=='Ruínas de Vulcano'&&
        !defeatedBosses.contains('port_boss')){
      return 'Derrote o Almirante Renegado';
    }
    return '';
  }
  Future<void> sellSafely(Gear gear) async {
    if(!bag.any((x)=>x.id==gear.id))return;
    if(gear.rarity.index>=2){
      final ok=await showDialog<bool>(context:context,
        builder:(context)=>AlertDialog(
          title:const Text('Vender equipamento raro?'),
          content:Text('Vender ${gear.name} por '
            '${max(1,gear.price~/2)} moedas? Esta venda é reversível '
            'por alguns segundos.'),
          actions:[
            TextButton(onPressed:()=>Navigator.pop(context,false),
              child:const Text('CANCELAR')),
            FilledButton(onPressed:()=>Navigator.pop(context,true),
              child:const Text('VENDER')),
          ]));
      if(ok!=true||!mounted)return;
    }
    final value=max(1,gear.price~/2);
    sell(gear);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:Text('Vendido: ${gear.name}. +$value ouro.'),
      action:SnackBarAction(label:'DESFAZER',onPressed:(){
        if(gold<value||bag.length>=40){
          notice('Não foi possível desfazer.');return;
        }
        setState((){
          gold-=value;
          bag.add(gear);
        });
        unawaited(saveGame());
      }),
    ));
  }
  void openMission(){setState(()=>page=1);}
  void recover(){
    rest();
  }
  void showPreferences(){
    showModalBottomSheet<void>(context:context,showDragHandle:true,
      builder:(context)=>StatefulBuilder(builder:(context,refresh)=>
        SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
          const ListTile(title:Text('Configurações de acessibilidade'),
            subtitle:Text('Preferências salvas neste dispositivo')),
          SwitchListTile(
            title:const Text('Efeitos sonoros'),
            value:soundEnabled,
            onChanged:(v){setState(()=>soundEnabled=v);
              refresh((){});unawaited(saveGame());}),
          SwitchListTile(
            title:const Text('Vibração dos golpes'),
            value:vibrationEnabled,
            onChanged:(v){setState(()=>vibrationEnabled=v);
              refresh((){});unawaited(saveGame());}),
          ListTile(
            leading:const Icon(Icons.save_outlined),
            title:Text('Estado do save: $saveStatus'),
            subtitle:const Text('O jogo também salva automaticamente'),
            onTap:()=>unawaited(saveGame())),
          const SizedBox(height:12),
        ]))));
  }

  Widget panel(String heading,Widget child)=>Padding(
    padding:const EdgeInsets.only(bottom:12),
    child:RomanPanel(title:heading,child:child),
  );

  Widget metric(String name, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Expanded(child: Text(name)),
      Text(value, style: const TextStyle(color: Palette.gold)),
    ]),
  );

  Widget stat(String name,int value,{int equipmentBonus=0})=>Padding(
    padding:const EdgeInsets.symmetric(vertical:3),
    child:Row(children:[
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
        children:[
        Text(name,style:const TextStyle(fontSize:14)),
        Text('Base ${value-equipmentBonus} + itens $equipmentBonus',
          style:const TextStyle(fontSize:12,color:Palette.paleGold)),
      ])),
      Text('$value',style:const TextStyle(color:Palette.gold,fontSize:16)),
      const SizedBox(width:6),
      IconButton(
        onPressed:points>0?()=>train(name):null,
        tooltip:'Aumentar $name em 1 ponto',
        icon:const Icon(Icons.add_circle_outline,size:23),
        constraints:const BoxConstraints(minHeight:48,minWidth:48)),
    ]),
  );

  Widget gearCard(Gear gear,String action,VoidCallback? onPressed,
    {VoidCallback? secondary,String? secondaryLabel}){
    final current=equipped[gear.slot];
    final deltaDamage=gear.maxDamage-(current?.maxDamage??0);
    final deltaArmor=gear.armor-(current?.armor??0);
    final deltaStrength=gear.strength-(current?.strength??0);
    final deltaDex=gear.dexterity-(current?.dexterity??0);
    String difference(int n)=>n>0?'+$n':'$n';
    final lines=<String>[
      if(gear.minDamage>0)'Dano ${gear.minDamage}–${gear.maxDamage}',
      if(gear.armor>0)'Armadura ${gear.armor}',
      if(gear.strength>0)'Força +${gear.strength}',
      if(gear.dexterity>0)'Destreza +${gear.dexterity}',
      if(gear.agility>0)'Agilidade +${gear.agility}',
      if(gear.constitution>0)'Constituição +${gear.constitution}',
    ];
    final comparison=current==null?'Espaço vazio':
      'Vs equipado: dano ${difference(deltaDamage)} · '
      'defesa ${difference(deltaArmor)} · '
      'FOR ${difference(deltaStrength)} · DES ${difference(deltaDex)}';
    return Card(
      margin:const EdgeInsets.symmetric(vertical:4),
      color:Palette.panelDeep,
      shape:RoundedRectangleBorder(
        side:BorderSide(color:gear.color.withValues(alpha:.7)),
        borderRadius:BorderRadius.circular(8)),
      child:Padding(padding:const EdgeInsets.all(10),
        child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Semantics(label:'${rarityLabel(gear.rarity)}, ${slotLabel(gear.slot)}',
          child:Image.asset(gear.icon,width:48,height:48,
            filterQuality:FilterQuality.none,
            excludeFromSemantics:true,
            errorBuilder:(_,error,stack)=>const Icon(Icons.shield,size:48))),
        const SizedBox(width:10),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
          children:[
          Text(gear.name+(gear.forgeRank>0?' +${gear.forgeRank}':''),
            style:TextStyle(fontWeight:FontWeight.bold,
              color:gear.color,fontSize:14)),
          Text('${rarityLabel(gear.rarity)} · ${slotLabel(gear.slot)}'
            ' · Nível ${gear.level}',style:const TextStyle(fontSize:12)),
          if(lines.isNotEmpty)Text(lines.join(' · '),
            style:const TextStyle(fontSize:12)),
          Text(comparison,style:const TextStyle(
            color:Palette.paleGold,fontSize:12)),
          const SizedBox(height:8),
          Wrap(spacing:6,runSpacing:4,children:[
            OutlinedButton(onPressed:onPressed,child:Text(action)),
            if(secondary!=null)TextButton(
              onPressed:secondary,child:Text(secondaryLabel??'Vender')),
          ]),
        ])),
      ])),
    );
  }

  Widget heroPage()=>ListView(
    padding:const EdgeInsets.all(12),children:[
      panel('Seu gladiador',Column(children:[
        Semantics(label:'Gladiador de nível $level',
          child:Center(child:HeroAvatar(equipment:equipped))),
        Text('GLADIADOR · NÍVEL $level',
          style:const TextStyle(color:Palette.gold,
            fontWeight:FontWeight.bold)),
        Text('Vitórias: $wins'),
        if(wins>=50)const Text('★ LENDA DA ARENA ★',
          style:TextStyle(color:Palette.paleGold)),
        const SizedBox(height:10),
        RomanProgress(label:'VIDA',current:health,
          maximum:maxHealth,color:Palette.red),
        const SizedBox(height:10),
        RomanProgress(label:'EXPERIÊNCIA',
          current:experience,maximum:xpNeeded,color:Palette.gold),
        const SizedBox(height:12),
        Row(children:[
          Expanded(child:FilledButton.icon(
            onPressed:openMission,
            icon:const Icon(Icons.map),label:const Text('MISSÕES'))),
          const SizedBox(width:6),
          Expanded(child:OutlinedButton.icon(
            onPressed:recover,icon:const Icon(Icons.hotel),
            label:const Text('RECUPERAR'))),
        ]),
      ])),
      panel('Atributos • $points pontos',Column(children:[
        stat('Força',strength+bonus((g)=>g.strength),
          equipmentBonus:bonus((g)=>g.strength)),
        stat('Destreza',dexterity+bonus((g)=>g.dexterity),
          equipmentBonus:bonus((g)=>g.dexterity)),
        stat('Agilidade',agility+bonus((g)=>g.agility),
          equipmentBonus:bonus((g)=>g.agility)),
        stat('Constituição',constitution+bonus((g)=>g.constitution),
          equipmentBonus:bonus((g)=>g.constitution)),
        const Text('Cada 3 pontos de Força aumentam o dano; '
          'Destreza melhora acertos; Agilidade melhora esquivas; '
          'Constituição aumenta a vida.',
          style:TextStyle(fontSize:12)),
        metric('Ataque',attack.toString()),
        metric('Defesa',protection.toString()),
      ])),
      panel('Equipamentos',Column(children:[
        ...Slot.values.map((slot){
          final gear=equipped[slot];
          return ListTile(
            dense:true,
            leading:Image.asset('assets/sprites/icon_${slot.name}.png',
              width:36,height:36,filterQuality:FilterQuality.none),
            title:Text(gear?.name??'Vazio'),
            subtitle:Text(slotLabel(slot)),
            trailing:gear==null?null:IconButton(
              tooltip:'Retirar ${slotLabel(slot)}',
              onPressed:()=>removeGear(slot),
              icon:const Icon(Icons.remove_circle_outline)),
          );
        }),
      ])),
    ],
  );

  Widget opponent(EnemySpec enemy){
    final available=accessible(enemy);
    final rivalry=rivalVictories[enemy.id]??0;
    return panel(enemy.name,Row(children:[
      Sprite(enemy.sprite,width:95,height:110),
      const SizedBox(width:10),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
        children:[
        Text(enemy.description,style:const TextStyle(fontSize:12)),
        const SizedBox(height:4),
        Text('Força: '+enemy.tier.toString()+
          ' • Nível mínimo '+enemy.minLevel.toString(),
          style:const TextStyle(color:Palette.gold,fontSize:12)),
        if(enemy.boss)const Text('★ CHEFE',style:TextStyle(
          color:Palette.paleGold,fontWeight:FontWeight.bold)),
        if(defeatedBosses.contains(enemy.id))
          const Text('✓ Vencido',style:TextStyle(color:Colors.green)),
        if(enemy.arena)Text('Rivalidade '+rivalry.toString(),
          style:const TextStyle(fontSize:11)),
        const SizedBox(height:6),
        ElevatedButton(
          onPressed:available&&!isFighting?()=>fight(enemy):null,
          child:Text(available?'COMBATER':'BLOQUEADO')),
      ])),
    ]));
  }

  Widget contractsPanel() {
    return panel('Contratos diários',Column(children:[
      const Text('Renovação a cada dia local. Conclua objetivos '
        'para resgatar ouro e experiência.',
        style:TextStyle(fontSize:11)),
      const SizedBox(height:9),
      ...dailyContracts.map((contract){
        final progress=contracts[contract.id]??0;
        final finished=claimedContracts.contains(contract.id);
        return Padding(padding:const EdgeInsets.only(bottom:12),
          child:Row(children:[
            Expanded(child:Column(
              crossAxisAlignment:CrossAxisAlignment.start,
              children:[
                Text(contract.title,style:const TextStyle(
                  color:Palette.gold,fontWeight:FontWeight.bold)),
                Text(contract.description,
                  style:const TextStyle(fontSize:11)),
                Text(progress.toString()+'/'+contract.target.toString()+
                  ' • +'+contract.gold.toString()+' ouro',
                  style:const TextStyle(fontSize:11)),
              ])),
            TextButton(
              onPressed:finished||progress<contract.target?null:
                 ()=>claimContract(contract),
              child:Text(finished?'RESGATADO':'RESGATAR')),
          ]),
        );
      }),
    ]));
  }

  Widget missionsPage() => ListView(
    padding:const EdgeInsets.all(12),
    children:[
      panel('Mapa das expedições',const Text(
        'Enfrente inimigos, desbloqueie regiões derrotando chefes '
        'e conquiste recompensas especiais. Cada luta custa 1 energia.')),
      ...regions.entries.map((region)=>Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          panel(region.key,Column(
            crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(region.value),
            const SizedBox(height:10),
            Sprite(
              region.key=='Campânia'?'scene_forest':
              region.key=='Porto de Óstia'?'scene_port':'scene_ruins',
              width:300,height:110),
          ])),
          ...expeditions.where((e)=>e.region==region.key).map(opponent),
        ])),
      contractsPanel(),
      panel('Taverna',Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Restaure sua saúde e energia por 15 moedas. '
          'Se estiver sem ouro, os médicos da arena oferecem '
          'socorro gratuito para evitar que sua jornada trave.'),
        const SizedBox(height:8),
        ElevatedButton.icon(onPressed:rest,icon:const Icon(Icons.hotel),
          label:const Text('DESCANSAR')),
      ])),
    ],
  );

  Widget arenaPage()=>ListView(
    padding:const EdgeInsets.all(12),
    children:[
      panel('Rivais do Coliseu',const Text(
        'Os adversários guardam memória das suas vitórias. '
        'Cada revanche aumenta sua força e sua vida. '
        'Enfrente-os para construir sua reputação.')),
      ...arenaRivals.map(opponent),
      panel('Cartaz de vitórias',Text('Você venceu '+wins.toString()+
        ' lutas. Alcance 50 vitórias para se tornar '
        'uma lenda das arenas.')),
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

  void rerollShop() {
    const fee = 25;
    if (gold < fee) {
      notice('Você precisa de 25 moedas para renovar a loja.');
      return;
    }
    setState(() {
      gold -= fee;
      refreshShop();
    });
    unawaited(saveGame());
  }

  Widget marketPage() => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      FilledButton.icon(
        onPressed:()=>setState(()=>shopSection=1),
        icon:const Icon(Icons.hardware),
        label:const Text('VISITAR O FERREIRO')),
      const SizedBox(height:12),
      panel('Mercador', Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Mercadorias com raridade e atributos variados.'),
        TextButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Renovar ofertas • 25 ouro'),
          onPressed: gold >= 25 ? rerollShop : null),
      ])),
      ...shop.map((gear) => gearCard(
        gear, 'Comprar • ' + gear.price.toString() + ' ouro',
        () => buy(gear))),
      if (shop.isEmpty) const Text('As mercadorias acabaram. Atualize a lista.'),
    ],
  );

  Widget forgePage()=>ListView(
    padding:const EdgeInsets.all(12),
    children:[
      Align(alignment:Alignment.centerLeft,child:TextButton.icon(
        onPressed:()=>setState(()=>shopSection=0),
        icon:const Icon(Icons.arrow_back),
        label:const Text('Voltar ao mercador'))),
      panel('Oficina do ferreiro',const Text(
        'Reforce armas, escudos, armaduras e acessórios '
        'até +5. Cada etapa custa ouro e melhora os atributos.')),
      panel('Equipados',Column(children:
        equipped.values.map((gear)=>gearCard(
          gear,'Reforjar +'+(gear.forgeRank+1).toString()+
            ' • '+gear.forgeCost.toString()+' ouro',
          ()=>forge(gear,fromEquipment:true),
        )).toList())),
      panel('Itens na bolsa',bag.isEmpty
        ?const Text('Sua bolsa está vazia.')
        :Column(children:bag.map((gear)=>gearCard(
          gear,'Reforjar +'+(gear.forgeRank+1).toString()+
          ' • '+gear.forgeCost.toString()+' ouro',
          ()=>forge(gear,fromEquipment:false),
        )).toList())),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 52,
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
        preferredSize: const Size.fromHeight(32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 5),
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
          inventoryPage(), shopSection==0?marketPage():forgePage(),
        ]),
    bottomNavigationBar: NavigationBar(
      height: 72,
      backgroundColor: Palette.panel,
      selectedIndex: page,
      onDestinationSelected: (next) {
        setState(() {
          page = next;
          if (next == 1) dailyResetIfNeeded();
        });
        if (next == 1) unawaited(saveGame());
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.person), label: 'Herói'),
        NavigationDestination(icon: Icon(Icons.map), label: 'Missões'),
        NavigationDestination(icon: Icon(Icons.shield), label: 'Arena'),
        NavigationDestination(icon: Icon(Icons.backpack), label: 'Itens'),
        NavigationDestination(icon: Icon(Icons.storefront), label: 'Comércio'),
      ],
    ),
  );
}
