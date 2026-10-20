import 'package:flutter_test/flutter_test.dart';
import 'package:gladiatus_pixel/models/gear.dart';
import 'package:gladiatus_pixel/systems/content.dart';

void main(){
  const gear=Gear(
    id:'fixture',name:'Gládio do Centurião',slot:Slot.weapon,
    rarity:Rarity.blue,level:3,price:150,
    minDamage:10,maxDamage:20,strength:4,
  );
  test('forge upgrades gear without changing identity or slot',(){
    final better=gear.reforged();
    expect(better.id,gear.id);
    expect(better.slot,gear.slot);
    expect(better.forgeRank,1);
    expect(better.minDamage,greaterThan(gear.minDamage));
    expect(better.price,greaterThan(gear.price));
  });

  test('save round-trip persists reforging and legacy saves',(){
    final restored=Gear.fromJson(gear.reforged().toJson());
    expect(restored.forgeRank,1);
    expect(restored.maxDamage,greaterThan(20));
    final legacy=Map<String,dynamic>.from(gear.toJson())..remove('forgeRank');
    expect(Gear.fromJson(legacy).forgeRank,0);
  });

  test('forge capped at five ranks',(){
    var current=gear;
    for(var i=0;i<6;i++) current=current.reforged();
    expect(current.forgeRank,5);
    expect(current.reforged().forgeRank,5);
  });

  test('random items have valid stats, slots and rarities',(){
    for(var i=0;i<500;i++) {
      final random=GearFactory.create(5);
      expect(random.level,greaterThanOrEqualTo(1));
      expect(random.price,greaterThan(0));
      expect(random.forgeRank,0);
    }
  });

  test('campaign has unique opponents and ordered region gates',(){
    expect(expeditions.map((e)=>e.id).toSet().length,expeditions.length);
    expect(arenaRivals.map((e)=>e.id).toSet().length,arenaRivals.length);
    expect(expeditions.where((e)=>e.boss).length,3);
    expect(dailyContracts.length,4);
  });
  test('empty accessory gains a useful property on forging',(){
    const ring=Gear(
      id:'blank_ring',name:'Anel sem atributo',slot:Slot.ring,
      rarity:Rarity.common,level:1,price:10,
    );
    final forged=ring.reforged();
    expect(forged.forgeRank,1);
    expect(forged.strength,greaterThan(0));
  });

  test('all item slots can round trip from serialization',(){
    for(final slot in Slot.values) {
      final item=Gear(
        id:slot.name,name:'Teste',slot:slot,rarity:Rarity.common,
        level:1,price:10,
      );
      final restored=Gear.fromJson(item.toJson());
      expect(restored.slot,slot);
    }
  });

}
