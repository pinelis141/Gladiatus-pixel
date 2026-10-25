import '../models/gear.dart';

/// One-of-a-kind rewards from a boss's *first* defeat.
/// Items use stable IDs and are serializable with the existing Gear model.
const bossRewards = <String, Gear>{
  'forest_boss': Gear(
    id:'relic_forest_greaves',name:'Grevas do Guardião',
    slot:Slot.boots,rarity:Rarity.blue,level:2,price:180,
    armor:46,agility:3,constitution:2,
  ),
  'port_boss': Gear(
    id:'relic_ostia_blade',name:'Lâmina do Almirante',
    slot:Slot.weapon,rarity:Rarity.purple,level:5,price:460,
    minDamage:18,maxDamage:30,dexterity:4,strength:3,
  ),
  'final_boss': Gear(
    id:'relic_mars_crown',name:'Coroa de Marte',
    slot:Slot.helmet,rarity:Rarity.orange,level:8,price:950,
    armor:110,strength:6,constitution:5,
  ),
};

/// This collection is a claimable inbox. It retains rewards if the
/// player's bag (40 slots) was full when a boss was defeated.
class RewardVault {
  static const bagCapacity = 40;

  static bool hasGear(Iterable<Gear> bag, Iterable<Gear> equipped,
      Iterable<Gear> vault, String id) =>
    [...bag, ...equipped, ...vault].any((gear)=>gear.id==id);

  static bool addUnique({
    required Gear item,
    required List<Gear> bag,
    required List<Gear> vault,
    required Iterable<Gear> equipped,
  }) {
    if (hasGear(bag,equipped,vault,item.id)) return false;
    if (bag.length<bagCapacity) {
      bag.add(item);
    } else {
      vault.add(item);
    }
    return true;
  }

  static bool claim({
    required Gear item,
    required List<Gear> bag,
    required List<Gear> vault,
  }) {
    if (bag.length>=bagCapacity) return false;
    final index=vault.indexWhere((g)=>g.id==item.id);
    if (index<0) return false;
    bag.add(vault.removeAt(index));
    return true;
  }
}
