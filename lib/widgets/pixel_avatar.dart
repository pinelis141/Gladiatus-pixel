import 'package:flutter/material.dart';
import '../models/gear.dart';
import 'roman_theme.dart';

class Sprite extends StatelessWidget {
  final String name;
  final double width;
  final double height;
  const Sprite(this.name,{super.key,required this.width,required this.height});
  @override
  Widget build(BuildContext context)=>Image.asset(
    'assets/sprites/$name.png',
    width:width,height:height,fit:BoxFit.contain,
    filterQuality:FilterQuality.none,
    errorBuilder: (_,error,stack)=>SizedBox(width:width,height:height,
      child:const Icon(Icons.shield,color:Palette.gold)),
  );
}

/// All equipment overlays share the exact same 128x144 transparent canvas.
class HeroAvatar extends StatelessWidget {
  final Map<Slot,Gear> equipment;
  final double width;
  final double height;
  const HeroAvatar({super.key,required this.equipment,
    this.width=176,this.height=198});
  @override
  Widget build(BuildContext context) {
    final frames=<String>['gladiator_base_hd'];
    for(final slot in [Slot.boots,Slot.gloves,Slot.armor,
      Slot.helmet,Slot.weapon,Slot.shield]) {
      if(equipment.containsKey(slot)) frames.add('equip_${slot.name}_hd');
    }
    final rarity=equipment.values.fold<int>(0,
      (value,gear)=>gear.rarity.index>value?gear.rarity.index:value);
    return SizedBox(width:width,height:height,child:Stack(
      fit:StackFit.expand,children:[
        if(rarity>=3) DecoratedBox(decoration:BoxDecoration(
          shape:BoxShape.circle,
          gradient:RadialGradient(colors:[
            (rarity==4 ? Colors.orange : Colors.purple).withValues(alpha:.21),
            Colors.transparent]))),
        ...frames.map((name)=>Sprite(name,width:width,height:height)),
      ],
    ));
  }
}
