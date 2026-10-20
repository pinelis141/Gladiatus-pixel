import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:gladiatus_pixel/systems/combat.dart';
import 'package:gladiatus_pixel/systems/content.dart';

void main() {
  BattleEngine setup({int tier=1,int seed=1,int rivalRank=0})=>BattleEngine(
    enemy:expeditions.firstWhere((e)=>e.tier==tier),
    startingHealth:120,maxPlayerHealth:120,
    playerLevel:3,power:18,accuracy:12,evasion:10,
    protection:25,minWeapon:7,maxWeapon:13,
    rivalRank:rivalRank,rng:Random(seed),
  );

  test('battle advances turns and respects health and stamina bounds',(){
    final game=setup();
    for(var i=0;i<40 && !game.finished;i++) {
      game.play(i.isEven?CombatMove.quick:CombatMove.guard);
      expect(game.playerHealth,inInclusiveRange(0,game.maxPlayerHealth));
      expect(game.enemyHealth,inInclusiveRange(0,game.maxEnemyHealth));
      expect(game.stamina,inInclusiveRange(0,5));
      expect(game.history.length,game.round);
    }
    expect(game.finished,true);
    expect(game.outcome.remainingHealth,game.playerHealth);
  });

  test('heavy strike consumes vigor; recovery restores it',(){
    final game=setup(seed:4);
    final previous=game.stamina;
    game.play(CombatMove.heavy);
    expect(game.stamina,previous-2);
    if(!game.finished) {
      game.play(CombatMove.guard);
      expect(game.stamina,4);
    }
  });

  test('battle outcome cannot be collected early',(){
    final game=setup();
    expect(()=>game.outcome,throwsStateError);
  });

  test('simulation across 1000 seeds never yields invalid results',(){
    var completed=0;
    for(var seed=0;seed<1000;seed++) {
      final game=setup(seed:seed);
      while(!game.finished) {
        final action=game.stamina>=2 && game.round%3==0
            ?CombatMove.heavy
            :game.round%4==0?CombatMove.guard:CombatMove.quick;
        game.play(action);
      }
      expect(game.round,lessThanOrEqualTo(35));
      expect(game.outcome.remainingHealth,greaterThanOrEqualTo(0));
      expect(game.outcome.turns,greaterThan(0));
      completed++;
    }
    expect(completed,1000);
  });
  test('insufficient stamina heavy is only one quick action',(){
    final game=setup(seed:2);
    game.stamina=1;
    game.play(CombatMove.heavy);
    expect(game.round,1);
    expect(game.history.length,1);
    expect(game.stamina,2);
  });

  test('arena rivalry capped to avoid unwinnable encounters',(){
    final veteran=setup(rivalRank:10,seed:1);
    final extreme=setup(rivalRank:100000,seed:1);
    expect(extreme.maxEnemyHealth,veteran.maxEnemyHealth);
    final a=veteran.play(CombatMove.quick);
    final b=extreme.play(CombatMove.quick);
    expect(a.inflicted,b.inflicted);
    expect(a.received,b.received);
  });

  test('surrender outcome cannot be mistaken for a victory',(){
    const retreat=BattleOutcome(
      opponentId:'wolf',won:false,retreated:true,
      remainingHealth:90,turns:2,damageDealt:10,damageTaken:10,
    );
    expect(retreat.retreated,true);
    expect(retreat.won,false);
  });

}
