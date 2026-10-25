import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:gladiatus_pixel/models/gear.dart';
import 'package:gladiatus_pixel/systems/boss_rewards.dart';
import 'package:gladiatus_pixel/systems/combat.dart';
import 'package:gladiatus_pixel/systems/content.dart';

BattleEngine setup(EnemySpec spec,{
  CombatMove? learned, int seed=18,
}){
  return BattleEngine(
    enemy:spec,startingHealth:400,maxPlayerHealth:400,
    playerLevel:8,power:18,accuracy:10,evasion:0,
    protection:25,minWeapon:7,maxWeapon:12,
    rivalRememberedMove:learned,rng:Random(seed),
  );
}

void main(){
  test('each boss enters phase two and telegraphs a unique special',(){
    for(final id in ['forest_boss','port_boss','final_boss']){
      final boss=expeditions.firstWhere((e)=>e.id==id);
      final battle=setup(boss);
      expect(battle.bossPhase,1);
      battle.enemyHealth=battle.maxEnemyHealth~/2;
      expect(battle.bossPhase,2);
      battle.play(CombatMove.guard);
      battle.play(CombatMove.guard);
      expect(battle.intent,EnemyIntent.special);
      expect(battle.intentLabel,contains(battle.bossAbility));
      final outcome=battle.play(CombatMove.guard);
      expect(outcome.narration,contains(battle.bossAbility));
      if(id=='port_boss'){
        expect(outcome.narration,contains('roubou 1 ponto de vigor'));
        expect(battle.stamina,4);
      }
    }
  });

  test('a rival counters the last preferred move without infinite scaling',(){
    final rival=arenaRivals.first;
    final naive=setup(rival);
    final learned=setup(rival,learned:CombatMove.heavy);
    expect(naive.intent,EnemyIntent.strike);
    expect(learned.intent,EnemyIntent.evade);
    expect(learned.intentLabel,contains('RIVAL ADAPTADO'));
    expect(learned.maxEnemyHealth,naive.maxEnemyHealth);
  });

  test('dominant move is recorded in the final outcome',(){
    final rival=arenaRivals.first;
    final battle=setup(rival);
    battle.play(CombatMove.feint);
    battle.play(CombatMove.feint);
    battle.play(CombatMove.feint);
    battle.play(CombatMove.quick);
    while(!battle.finished) battle.play(CombatMove.guard);
    expect(battle.outcome.dominantMove,CombatMove.feint);
  });

  test('boss first-time relics have unique IDs and sensible requirements',(){
    expect(bossRewards.keys.toSet(),
      {'forest_boss','port_boss','final_boss'});
    final ids=bossRewards.values.map((g)=>g.id).toSet();
    expect(ids.length,3);
    expect(bossRewards['forest_boss']!.level,2);
    expect(bossRewards['port_boss']!.slot,Slot.weapon);
    expect(bossRewards['final_boss']!.rarity,Rarity.orange);
    for(final relic in bossRewards.values){
      expect(Gear.fromJson(relic.toJson()).id,relic.id);
    }
  });

  test('full bag never discards the one-time relic',(){
    final bag=List<Gear>.generate(RewardVault.bagCapacity,
      (i)=>Gear(id:'filler_$i',name:'Saco $i',
        slot:Slot.ring,rarity:Rarity.common,level:1,price:1));
    final vault=<Gear>[];
    final bossRelic=bossRewards['forest_boss']!;
    expect(RewardVault.addUnique(item:bossRelic,bag:bag,
      vault:vault,equipped:const []),isTrue);
    expect(bag.length,RewardVault.bagCapacity);
    expect(vault.single.id,bossRelic.id);
    expect(RewardVault.addUnique(item:bossRelic,bag:bag,
      vault:vault,equipped:const []),isFalse);
    expect(RewardVault.claim(item:bossRelic,bag:bag,vault:vault),isFalse);
    bag.removeLast();
    expect(RewardVault.claim(item:bossRelic,bag:bag,vault:vault),isTrue);
    expect(vault,isEmpty);
    expect(bag.last.id,bossRelic.id);
  });

  test('relic duplication is prevented across equipped gear',(){
    final relic=bossRewards['port_boss']!;
    final bag=<Gear>[];
    final vault=<Gear>[];
    expect(RewardVault.addUnique(item:relic,bag:bag,
      vault:vault,equipped:[relic]),isFalse);
    expect(bag,isEmpty);
    expect(vault,isEmpty);
  });
}
