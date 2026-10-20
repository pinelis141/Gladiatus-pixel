import 'package:flutter/material.dart';

class Palette {
  static const dark = Color(0xFF140E0C);
  static const panel = Color(0xFF2B1C18);
  static const panelDeep = Color(0xFF211611);
  static const gold = Color(0xFFDDB35E);
  static const paleGold = Color(0xFFF4D69B);
  static const cream = Color(0xFFF2E4CB);
  static const red = Color(0xFFAC3842);
  static const bronze = Color(0xFF6F4833);
}

class RomanPanel extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsets padding;
  const RomanPanel({super.key,required this.title, required this.child,
    this.padding = const EdgeInsets.all(14)});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: padding,
    decoration: BoxDecoration(
      color: Palette.panel,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: Palette.gold.withValues(alpha: .66), width: 1.4),
      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 7,
        offset: Offset(0, 3))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
      Row(children: [
        const Icon(Icons.auto_awesome, size: 13,color: Palette.gold),
        const SizedBox(width:7),
        Expanded(child:Text(title.toUpperCase(),style: const TextStyle(
          letterSpacing:1, fontSize:14, color: Palette.paleGold,
          fontWeight:FontWeight.bold))),
        const Icon(Icons.auto_awesome, size: 13,color: Palette.gold),
      ]),
      const Divider(color: Palette.bronze),
      child,
    ]),
  );
}

class RomanProgress extends StatelessWidget {
  final String label;
  final int current;
  final int maximum;
  final Color color;
  const RomanProgress({super.key,required this.label,required this.current,
    required this.maximum, this.color=Palette.red});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment:CrossAxisAlignment.start,children: [
    Text('$label $current / $maximum',
      style:const TextStyle(color:Palette.cream,fontSize:12)),
    const SizedBox(height:5),
    ClipRRect(borderRadius: BorderRadius.circular(5),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin:0.0,end: maximum<=0?0.0:
            (current/maximum).clamp(0.0,1.0).toDouble()),
        duration:const Duration(milliseconds:360),
        builder: (context,value,_)=>LinearProgressIndicator(
          value:value,minHeight:9,backgroundColor:Palette.panelDeep,
          valueColor:AlwaysStoppedAnimation(color),
        ),
      ),
    ),
  ]);
}

class RomanBackdrop extends StatelessWidget {
  final String scene;
  final Widget child;
  const RomanBackdrop({super.key,required this.scene, required this.child});
  @override
  Widget build(BuildContext context) => Stack(fit:StackFit.expand,children:[
    Image.asset('assets/sprites/$scene.png',fit:BoxFit.cover,
      filterQuality: FilterQuality.none,
      errorBuilder: (_,error,stack)=>const ColoredBox(color:Palette.dark)),
    const ColoredBox(color:Color(0xAA100907)),
    child,
  ]);
}
