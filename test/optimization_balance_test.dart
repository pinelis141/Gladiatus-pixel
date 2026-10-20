import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:gladiatus_pixel/systems/combat.dart';
import 'package:gladiatus_pixel/systems/content.dart';

BattleEngine engine({
  required EnemySpec enemy, required int seed,
  int level=1, int hp=100,
  int low=4, int high=8,
  int power=5, int accuracy=5, int agility=5, int armor=0,
  int rank=0,
})=>BattleEngine(
  enemy:enemy,startingHealth:hp,maxPlayerHealth:hp,
  playerLevel:level,power:power,accuracy:accuracy,
  evasion:agility,protection:armor,minWeapon:low,maxWeapon:high,
  rivalRank:rank,rng:Random(seed),
);

double winRate(EnemySpec enemy,{
  int level=1,int hp=100,int low=4,int high=8,int power=5,
  int accuracy=5,int agility=5,int armor=0,int rank=0,
  CombatMove move=CombatMove.quick,
}){
  var wins=0;
  const n=300;
  for(var seed=0;seed<n;seed++){
    final g=engine(enemy:enemy,seed:101+seed*31,level:level,
      hp:hp,low:low,high:high,power:power,
      accuracy:accuracy,agility:agility,armor:armor,rank:rank);
    while(!g.finished){
      g.play(move==CombatMove.heavy&&g.stamina<2
        ?CombatMove.quick:move);
    }
    if(g.won)wins++;
  }
  return wins/n;
}

void main(){
  final wolf=expeditions.firstWhere((x)=>x.id=='wolf');
  final bandit=expeditions.firstWhere((x)=>x.id=='bandit');
  final boss=expeditions.firstWhere((x)=>x.id=='forest_boss');
  test('beginner encounters have a teachable difficulty ramp',(){
    final wolfRate=winRate(wolf);
    final banditRate=winRate(bandit);
    expect(wolfRate,inInclusiveRange(.78,1));
    expect(banditRate,inInclusiveRange(.25,.95));
    expect(wolfRate,greaterThan(banditRate));
  });

  test('first boss is challenging but possible with reachable gear',(){
    final rate=winRate(boss,level:2,hp:120,low:6,high:12,
      power:9,accuracy:6,agility:5,armor:65,move:CombatMove.heavy);
    expect(rate,inInclusiveRange(.15,.90));
  });

  test('telegraphed enemy behaviour is actually distinct',(){
    final fast=engine(enemy:bandit,seed:1);
    final slow=engine(enemy:wolf,seed:1);
    expect(fast.intentLabel,isNotEmpty);
    expect(slow.intentLabel,isNotEmpty);
    fast.play(CombatMove.guard);
    slow.play(CombatMove.guard);
    expect(fast.intentLabel,isNot(slow.intentLabel));
  });

  test('rival strength remains bounded after repeated wins',(){
    final rival=arenaRivals.first;
    final limited=engine(enemy:rival,seed:15,rank:5);
    final extreme=engine(enemy:rival,seed:15,rank:5000);
    expect(limited.maxEnemyHealth,extreme.maxEnemyHealth);
    expect(limited.play(CombatMove.quick).received,
      extreme.play(CombatMove.quick).received);
  });

  test('guard is useful against telegraphed heavy hit',(){
    final heavy=expeditions.firstWhere((e)=>e.id=='final_boss');
    final guard=engine(enemy:heavy,seed:72,level:8,hp:240,
      low:18,high:35,power:28,accuracy:14,agility:14,armor:260);
    final normal=engine(enemy:heavy,seed:72,level:8,hp:240,
      low:18,high:35,power:28,accuracy:14,agility:14,armor:260);
    var defendedDamage=0,unprotectedDamage=0;
    for(var i=0;i<2;i++){
      defendedDamage+=guard.play(CombatMove.guard).received;
      unprotectedDamage+=normal.play(CombatMove.quick).received;
    }
    expect(defendedDamage,lessThanOrEqualTo(unprotectedDamage));
  });
}
