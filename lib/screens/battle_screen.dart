import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/gear.dart';
import '../systems/combat.dart';
import '../widgets/pixel_avatar.dart';
import '../widgets/roman_theme.dart';

class BattleScreen extends StatefulWidget {
  final EnemySpec enemy;
  final Map<Slot,Gear> equipment;
  final int startingHealth, maxHealth, playerLevel, power, accuracy;
  final int evasion, protection, minWeapon, maxWeapon, rivalRank;
  const BattleScreen({
    super.key, required this.enemy,required this.equipment,
    required this.startingHealth, required this.maxHealth,
    required this.playerLevel,required this.power,required this.accuracy,
    required this.evasion,required this.protection,
    required this.minWeapon,required this.maxWeapon,this.rivalRank=0,
  });

  @override
  State<BattleScreen> createState()=>_BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late final BattleEngine engine;
  final AudioPlayer sfx=AudioPlayer();
  bool bounce=false;
  String message='Escolha seu primeiro movimento.';

  @override
  void initState() {
    super.initState();
    engine=BattleEngine(
      enemy:widget.enemy,startingHealth:widget.startingHealth,
      maxPlayerHealth:widget.maxHealth,playerLevel:widget.playerLevel,
      power:widget.power,accuracy:widget.accuracy,evasion:widget.evasion,
      protection:widget.protection,minWeapon:widget.minWeapon,
      maxWeapon:widget.maxWeapon,rivalRank:widget.rivalRank,
    );
    unawaited(sfx.setVolume(.35));
  }

  Future<void> sound(String file) async {
    try {
      await sfx.stop();
      await sfx.play(AssetSource('audio/$file.wav'));
    } catch (_) {
      // Audio is optional: never block game mechanics.
    }
  }

  void play(CombatMove move) {
    if(engine.finished)return;
    final outcome=engine.play(move);
    unawaited(HapticFeedback.lightImpact());
    unawaited(sound(engine.finished && engine.won?'victory':
      outcome.guarded?'guard':'sword'));
    setState((){
      message=outcome.narration;
      bounce=!bounce;
    });
  }

  void finish() {
    if(!engine.finished)return;
    Navigator.of(context).pop(engine.outcome);
  }

  @override
  void dispose() {
    unawaited(sfx.dispose());
    super.dispose();
  }

  Widget action(String label,String explanation,CombatMove move,
      IconData icon,{bool available=true})=>OutlinedButton.icon(
    onPressed: engine.finished || !available ?null:()=>play(move),
    icon:Icon(icon,size:18),
    label:Column(mainAxisSize:MainAxisSize.min,children:[
      Text(label,style:const TextStyle(fontWeight:FontWeight.bold)),
      Text(explanation,style:const TextStyle(fontSize:10)),
    ]),
    style:OutlinedButton.styleFrom(
      foregroundColor:Palette.paleGold,
      side:const BorderSide(color:Palette.bronze),
      padding:const EdgeInsets.symmetric(vertical:11,horizontal:6),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final win=engine.finished && engine.won;
    return PopScope(
      canPop:false,
      child:Scaffold(
        appBar:AppBar(
          title:Text(widget.enemy.arena?'DUELO NO COLISEU':'EXPEDIÇÃO',
            style:const TextStyle(color:Palette.gold,fontSize:17)),
          backgroundColor:Palette.panel,
          automaticallyImplyLeading:false,
        ),
        body:RomanBackdrop(scene:widget.enemy.scene,child:SafeArea(
          child:ListView(padding:const EdgeInsets.all(12),children:[
            RomanPanel(title:widget.enemy.name,child:Column(
              crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('${widget.enemy.trait} • ${widget.enemy.region}',
                style:const TextStyle(color:Palette.gold,fontSize:12)),
              const SizedBox(height:12),
              Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,
                children:[
                AnimatedScale(
                  scale:bounce?1.035:1,duration:const Duration(milliseconds:160),
                  child:HeroAvatar(equipment:widget.equipment,
                    width:136,height:153)),
                AnimatedScale(
                  scale: bounce ? .97 : 1.045,
                  duration:const Duration(milliseconds:170),
                  child:Sprite(widget.enemy.sprite,width:132,height:145)),
              ]),
              const SizedBox(height:10),
              RomanProgress(label:'GLADIADOR',
                current:engine.playerHealth,maximum:engine.maxPlayerHealth),
              const SizedBox(height:10),
              RomanProgress(label:widget.enemy.name.toUpperCase(),
                current:engine.enemyHealth,
                maximum:engine.maxEnemyHealth,color:Palette.gold),
              const SizedBox(height:8),
              Text('Rodada ${engine.round} • Vigor ${engine.stamina}/5',
                style:const TextStyle(color:Palette.cream,fontSize:12)),
            ])),
            const SizedBox(height:14),
            RomanPanel(title:'Relato do combate',child:AnimatedSwitcher(
              duration:const Duration(milliseconds:230),
              child:Text(message,key:ValueKey(engine.round),
                style:const TextStyle(fontSize:14)))),
            const SizedBox(height:14),
            if(!engine.finished) RomanPanel(title:'Escolha sua ação',
              child:Column(children:[
                Row(children:[
                  Expanded(child:action('Ataque','Vigor +1',
                    CombatMove.quick,Icons.gavel)),
                  const SizedBox(width:8),
                  Expanded(child:action('Golpe pesado','Custa 2 vigor',
                    CombatMove.heavy,Icons.bolt,
                    available:engine.stamina>=2)),
                ]),
                const SizedBox(height:6),
                Row(children:[
                  Expanded(child:action('Defender','Dano reduzido',
                    CombatMove.guard,Icons.shield_outlined)),
                  const SizedBox(width:8),
                  Expanded(child:action('Finta','Esquiva e combo',
                    CombatMove.feint,Icons.auto_awesome)),
                ]),
              ])),
            if(engine.finished)RomanPanel(
              title:win?'Vitória!':'Derrota',
              child:Column(children:[
                Text(win?'Glória ao vencedor!':'Seu gladiador foi derrotado.',
                  style:TextStyle(color:win?Palette.gold:Palette.red)),
                const SizedBox(height:10),
                Text('Causou ${engine.totalDealt} de dano • '
                  'Recebeu ${engine.totalTaken}'),
                const SizedBox(height:10),
                FilledButton.icon(onPressed:finish,
                  icon:const Icon(Icons.check),
                  label:const Text('RECOLHER RECOMPENSAS')),
              ])),
            const SizedBox(height:12),
            if(engine.history.isNotEmpty)RomanPanel(
              title:'Histórico das rodadas',
              child:Column(crossAxisAlignment:CrossAxisAlignment.start,
                children:engine.history.reversed.take(6).map((item)=>Padding(
                  padding:const EdgeInsets.only(bottom:6),
                  child:Text('#${item.turn}  ${item.narration}',
                    style:const TextStyle(fontSize:11)))).toList())),
          ]),
        )),
      ),
    );
  }
}
