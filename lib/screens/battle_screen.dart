import 'dart:async';
import 'dart:math';
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
  final bool soundEnabled, vibrationEnabled;
  final CombatMove? rivalRememberedMove;
  const BattleScreen({
    super.key, required this.enemy,required this.equipment,
    required this.startingHealth,required this.maxHealth,
    required this.playerLevel,required this.power,required this.accuracy,
    required this.evasion,required this.protection,required this.minWeapon,
    required this.maxWeapon,this.rivalRank=0,
    this.soundEnabled=true,this.vibrationEnabled=true,
    this.rivalRememberedMove,
  });

  @override
  State<BattleScreen> createState()=>_BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late final BattleEngine engine;
  final AudioPlayer sfx=AudioPlayer();
  bool bounce=false,retreatDialogOpen=false;
  String message='Observe a intenção do rival e escolha sua ação.';
  BattleTurn? lastTurn;

  @override
  void initState(){
    super.initState();
    engine=BattleEngine(
      enemy:widget.enemy,startingHealth:widget.startingHealth,
      maxPlayerHealth:widget.maxHealth,playerLevel:widget.playerLevel,
      power:widget.power,accuracy:widget.accuracy,evasion:widget.evasion,
      protection:widget.protection,minWeapon:widget.minWeapon,
      maxWeapon:widget.maxWeapon,rivalRank:widget.rivalRank,
      rivalRememberedMove:widget.rivalRememberedMove,
    );
    if(widget.soundEnabled)unawaited(sfx.setVolume(.3));
  }

  Future<void> sound(String file) async {
    if(!widget.soundEnabled)return;
    try{
      await sfx.stop();
      await sfx.play(AssetSource('audio/$file.wav'));
    }catch(_){}
  }

  void play(CombatMove move){
    if(engine.finished)return;
    final next=engine.play(move);
    if(widget.vibrationEnabled)unawaited(HapticFeedback.lightImpact());
    unawaited(sound(engine.finished&&engine.won?'victory':
      next.guarded?'guard':'sword'));
    setState((){
      lastTurn=next;
      message=next.narration;
      bounce=!bounce;
    });
  }

  Future<void> retreat() async {
    if(engine.finished){finish();return;}
    if(retreatDialogOpen||!mounted)return;
    retreatDialogOpen=true;
    final confirmed=await showDialog<bool>(
      context:context,
      builder:(context)=>AlertDialog(
        title:const Text('Recuar do combate?'),
        content:const Text('Você manterá sua vida atual, mas gastará a '
          'energia da tentativa e não ganhará recompensas.'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(context,false),
            child:const Text('CONTINUAR')),
          FilledButton(onPressed:()=>Navigator.pop(context,true),
            child:const Text('RECUAR')),
        ],
      ));
    retreatDialogOpen=false;
    if(confirmed==true&&mounted) {
      Navigator.pop(context,BattleOutcome(
        opponentId:widget.enemy.id,won:false,retreated:true,
        remainingHealth:engine.playerHealth,turns:engine.round,
        damageDealt:engine.totalDealt,damageTaken:engine.totalTaken,
      ));
    }
  }

  void finish(){
    if(!engine.finished)return;
    Navigator.pop(context,engine.outcome);
  }

  @override
  void dispose(){
    unawaited(sfx.dispose());super.dispose();
  }

  Widget action(CombatMove move,String name,String subtitle,IconData icon,
    {bool available=true}){
    return Expanded(child:OutlinedButton.icon(
      onPressed:engine.finished||!available?null:()=>play(move),
      style:OutlinedButton.styleFrom(
        minimumSize:const Size(0,64),
        foregroundColor:Palette.paleGold,
        side:const BorderSide(color:Palette.gold),
        padding:const EdgeInsets.symmetric(horizontal:4,vertical:8),
      ),
      icon:Icon(icon,size:21),
      label:Column(mainAxisSize:MainAxisSize.min,children:[
        Text(name,style:const TextStyle(
          fontSize:13,fontWeight:FontWeight.bold),
          overflow:TextOverflow.ellipsis),
        Text(subtitle,style:const TextStyle(fontSize:10),
          overflow:TextOverflow.ellipsis),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final finished=engine.finished;
    return PopScope(
      canPop:false,
      onPopInvokedWithResult:(didPop,result){
        if(!didPop)unawaited(retreat());
      },
      child:Scaffold(
        appBar:AppBar(
          title:Text(widget.enemy.arena?'ARENA':'EXPEDIÇÃO',
            style:const TextStyle(color:Palette.gold,fontSize:17)),
          backgroundColor:Palette.panel,
          leading:IconButton(
            tooltip:'Voltar / recuar',onPressed:()=>unawaited(retreat()),
            icon:const Icon(Icons.arrow_back)),
        ),
        body:RomanBackdrop(
          scene:widget.enemy.scene,
          child:SafeArea(
            child:LayoutBuilder(builder:(context,constraints){
              final art=min(125.0,max(72.0,(constraints.maxWidth-90)/2));
              return Column(children:[
                Expanded(child:ListView(
                  padding:const EdgeInsets.all(10),
                  children:[
                    RomanPanel(title:widget.enemy.name,child:Column(
                      crossAxisAlignment:CrossAxisAlignment.start,
                      children:[
                      Text('${widget.enemy.trait} • ${widget.enemy.region}',
                        style:const TextStyle(fontSize:12)),
                      if(widget.enemy.boss) Padding(
                        padding:const EdgeInsets.only(top:8),
                        child:Row(children:[
                          Icon(engine.bossPhase==2?Icons.local_fire_department:
                            Icons.flag,color:Palette.gold,size:19),
                          const SizedBox(width:6),
                          Expanded(child:Text(
                            engine.bossPhase==2 ?
                            'FASE 2: ${widget.enemy.name} desbloqueou ${engine.bossAbility}!'
                            : 'FASE 1: o chefe ainda guarda seu golpe especial.',
                            style:const TextStyle(color:Palette.paleGold,
                              fontWeight:FontWeight.w600,fontSize:12))),
                        ]),
                      ),
                      if(widget.enemy.arena && widget.rivalRememberedMove!=null)
                        Padding(
                          padding:const EdgeInsets.only(top:6),
                          child:Text('RIVAL ADAPTADO: aprendeu com o último '
                            'duelo e pode contrariar seu estilo dominante.',
                            style:const TextStyle(color:Palette.paleGold,
                              fontSize:12))),
                      const SizedBox(height:8),
                      Semantics(
                        label:'Próxima ação inimiga: ${engine.intentLabel}',
                        child:Container(
                          padding:const EdgeInsets.all(8),
                          decoration:BoxDecoration(
                            color:Palette.panelDeep,
                            borderRadius:BorderRadius.circular(6)),
                          child:Row(children:[
                            const Icon(Icons.visibility,
                              color:Palette.paleGold,size:18),
                            const SizedBox(width:8),
                            Expanded(child:Text(
                              'INTENÇÃO: ${engine.intentLabel}',
                              style:const TextStyle(
                                color:Palette.paleGold,
                                fontWeight:FontWeight.w600))),
                          ]),
                        ),
                      ),
                      const SizedBox(height:8),
                      Row(
                        mainAxisAlignment:MainAxisAlignment.spaceEvenly,
                        children:[
                          AnimatedScale(scale:bounce?1.03:1,
                            duration:const Duration(milliseconds:140),
                            child:HeroAvatar(equipment:widget.equipment,
                              width:art,height:art*1.12)),
                          AnimatedScale(scale:bounce ? .96 : 1.02,
                            duration:const Duration(milliseconds:140),
                            child:Sprite(widget.enemy.sprite,
                              width:art,height:art*1.12)),
                        ],
                      ),
                      const SizedBox(height:8),
                      RomanProgress(label:'GLADIADOR',current:engine.playerHealth,
                        maximum:engine.maxPlayerHealth),
                      const SizedBox(height:8),
                      RomanProgress(label:'INIMIGO',current:engine.enemyHealth,
                        maximum:engine.maxEnemyHealth,color:Palette.gold),
                      const SizedBox(height:8),
                      Text('Rodada ${engine.round} · Vigor ${engine.stamina}/5'),
                    ])),
                    const SizedBox(height:10),
                    RomanPanel(title:'Última ação',child:Column(
                      crossAxisAlignment:CrossAxisAlignment.start,children:[
                        if(lastTurn!=null)Row(children:[
                          if(lastTurn!.critical)const Icon(
                            Icons.flash_on,color:Palette.paleGold),
                          if(lastTurn!.dodged)const Icon(
                            Icons.directions_run,color:Colors.greenAccent),
                          if(lastTurn!.guarded)const Icon(
                            Icons.shield,color:Palette.paleGold),
                        ]),
                        Text(message,style:const TextStyle(fontSize:14)),
                      ])),
                    if(engine.history.isNotEmpty)ExpansionTile(
                      title:const Text('Histórico das rodadas',
                        style:TextStyle(color:Palette.cream)),
                      children:engine.history.reversed.take(12).map((entry)=>
                        Padding(padding:const EdgeInsets.all(6),
                          child:Text('#${entry.turn}: ${entry.narration}',
                            style:const TextStyle(fontSize:12)))).toList(),
                    ),
                  ],
                )),
                Container(
                  decoration:const BoxDecoration(color:Palette.panel,
                    border:Border(top:BorderSide(color:Palette.gold))),
                  padding:const EdgeInsets.fromLTRB(10,10,10,12),
                  child:finished?SizedBox(
                    width:double.infinity,
                    child:FilledButton(
                      onPressed:finish,
                      child:Text(engine.won?'VER RECOMPENSAS':'VER RESULTADO'),
                    ),
                  ):Column(mainAxisSize:MainAxisSize.min,children:[
                    Row(children:[
                      action(CombatMove.quick,'ATAQUE','Vigor +1',Icons.gavel),
                      const SizedBox(width:8),
                      action(CombatMove.heavy,'PESADO','Custa 2',Icons.bolt,
                        available:engine.stamina>=2),
                    ]),
                    const SizedBox(height:8),
                    Row(children:[
                      action(CombatMove.guard,'DEFENDER','Vigor +2',
                        Icons.shield_outlined),
                      const SizedBox(width:8),
                      action(CombatMove.feint,'FINTA','Esquiva +combo',
                        Icons.auto_awesome),
                    ]),
                  ]),
                ),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}
