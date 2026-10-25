import 'dart:math';

enum CombatMove { quick, heavy, guard, feint }
enum EnemyIntent { strike, heavy, defend, evade, special }

class EnemySpec {
  final String id, name, sprite, region, description, scene, trait;
  final int tier, minLevel;
  final bool boss, arena;
  const EnemySpec({
    required this.id, required this.name, required this.sprite,
    required this.region, required this.description, required this.scene,
    required this.trait, required this.tier,
    this.minLevel = 1, this.boss = false, this.arena = false,
  });
}

class BattleTurn {
  final int turn, inflicted, received;
  final bool guarded, critical, dodged;
  final String narration;
  const BattleTurn(this.turn, this.inflicted, this.received,
      this.guarded, this.critical, this.narration, {this.dodged = false});
}

class BattleOutcome {
  final String opponentId;
  final bool won, retreated;
  final CombatMove? dominantMove;
  final int remainingHealth, turns, damageDealt, damageTaken;
  const BattleOutcome({
    required this.opponentId, required this.won,
    this.retreated = false, this.dominantMove,
    required this.remainingHealth, required this.turns,
    required this.damageDealt, required this.damageTaken,
  });
}

class BattleEngine {
  final EnemySpec enemy;
  final Random random;
  final int maxPlayerHealth, playerLevel, power, accuracy, evasion;
  final int protection, minWeapon, maxWeapon, rivalRank, maxEnemyHealth;
  final CombatMove? rivalRememberedMove;
  final Map<CombatMove,int> moveUsage = {};
  late int playerHealth, enemyHealth;
  late EnemyIntent intent;
  int stamina = 4, round = 0, totalDealt = 0, totalTaken = 0, combo = 0;
  bool finished = false, won = false;
  final List<BattleTurn> history = [];

  BattleEngine({
    required this.enemy,
    required int startingHealth,
    required this.maxPlayerHealth,
    required this.playerLevel,
    required this.power,
    required this.accuracy,
    required this.evasion,
    required this.protection,
    required this.minWeapon,
    required this.maxWeapon,
    this.rivalRank = 0,
    this.rivalRememberedMove,
    Random? rng,
  }) : random = rng ?? Random(),
       maxEnemyHealth = 26 + enemy.tier * 11 + playerLevel * 5 +
           (enemy.boss ? 14 + max(0, enemy.tier - 3) * 11 : 0) +
           min(5, max(0, rivalRank)) * 4 {
    playerHealth = startingHealth.clamp(0, maxPlayerHealth).toInt();
    enemyHealth = maxEnemyHealth;
    intent = _nextIntent(0);
  }

  // Telegraphs are deterministic by enemy personality, so players can
  // actually learn a boss or rival's rhythm rather than guess.
  int get bossPhase =>
      enemy.boss && enemyHealth * 2 <= maxEnemyHealth ? 2 : 1;

  CombatMove? get dominantMove {
    if (moveUsage.isEmpty) return null;
    return moveUsage.entries.reduce((a,b)=>a.value>=b.value?a:b).key;
  }

  String get bossAbility => switch (enemy.id) {
    'forest_boss' => 'Pisada Sísmica',
    'port_boss' => 'Saque de Vigor',
    'final_boss' => 'Impacto de Marte',
    _ => 'Golpe Especial',
  };

  EnemyIntent _nextIntent(int nextRound) {
    if(enemy.boss && bossPhase==2 && nextRound%4==2) {
      return EnemyIntent.special;
    }
    if(enemy.arena && rivalRememberedMove!=null && nextRound%3==0) {
      return switch(rivalRememberedMove!) {
        CombatMove.quick => EnemyIntent.defend,
        CombatMove.heavy => EnemyIntent.evade,
        CombatMove.guard => EnemyIntent.heavy,
        CombatMove.feint => EnemyIntent.strike,
      };
    }
    switch (enemy.trait) {
      case 'Ágil':
      case 'Esquivo':
      case 'Astuto':
        return nextRound % 3 == 1 ? EnemyIntent.evade : EnemyIntent.strike;
      case 'Blindado':
      case 'Resistente':
        return nextRound % 3 == 1 ? EnemyIntent.defend : EnemyIntent.strike;
      case 'Feroz':
      case 'Implacável':
        return nextRound % 3 == 2 ? EnemyIntent.heavy : EnemyIntent.strike;
      case 'Colossal':
      case 'Lendário':
        return nextRound % 3 == 2 ? EnemyIntent.heavy : EnemyIntent.defend;
      case 'Tático':
      case 'Comandante':
        return [EnemyIntent.strike, EnemyIntent.defend,
          EnemyIntent.heavy, EnemyIntent.evade][nextRound % 4];
      default:
        return nextRound % 4 == 3 ? EnemyIntent.heavy : EnemyIntent.strike;
    }
  }

  String get intentLabel {
    final description = switch (intent) {
      EnemyIntent.strike => 'Ataque comum',
      EnemyIntent.heavy => 'Golpe pesado chegando!',
      EnemyIntent.defend => 'Postura defensiva',
      EnemyIntent.evade => 'Preparando esquiva',
      EnemyIntent.special => bossAbility,
    };
    final phase = bossPhase==2 ? 'FASE 2 · ' : '';
    final remembered = enemy.arena && rivalRememberedMove!=null &&
      round%3==0 ? 'RIVAL ADAPTADO · ' : '';
    return '$phase$remembered$description';
  }

  BattleTurn play(CombatMove move) {
    if (finished) throw StateError('Combate encerrado');
    if (move == CombatMove.heavy && stamina < 2) move = CombatMove.quick;
    moveUsage.update(move,(count)=>count+1,ifAbsent:()=>1);
    round++;
    var dealt = 0, received = 0;
    var crit = false, dodged = false;
    final guarding = move == CombatMove.guard;
    final notes = <String>[];

    if (guarding) {
      stamina = min(5, stamina + 2);
      combo = min(2, combo + 1);
      notes.add('Você prepara a defesa.');
    } else {
      stamina = move == CombatMove.heavy
          ? stamina - 2 : min(5, stamina + 1);
      final nominal = move == CombatMove.heavy ? 74
          : move == CombatMove.feint ? 82 : 84;
      final evasive = intent == EnemyIntent.evade ? 17 : 0;
      final odds = (nominal + accuracy ~/ 3 - enemy.tier * 2 - evasive)
          .clamp(25, 96);
      if (random.nextInt(100) < odds) {
        final low = max(1, minWeapon), high = max(low, maxWeapon);
        var damage = low + random.nextInt(high - low + 1) + power ~/ 3;
        crit = random.nextInt(100) < (8 + accuracy ~/ 7).clamp(5, 26);
        if (move == CombatMove.heavy) damage = (damage * 1.55).round();
        if (move == CombatMove.feint) damage = (damage * .77).round();
        if (crit) damage = (damage * 1.45).round();
        damage += combo * 3;
        if (intent == EnemyIntent.defend) {
          damage = (damage * .55).round();
        }
        dealt = max(1, damage - enemy.tier ~/ 3
            - min(5, max(0, rivalRank)) ~/ 2);
        enemyHealth = max(0, enemyHealth - dealt);
        totalDealt += dealt;
        notes.add(crit ? 'CRÍTICO: $dealt de dano!' : '$dealt de dano causado.');
        combo = move == CombatMove.feint ? min(2, combo + 1) : 0;
      } else {
        notes.add('O adversário evitou seu golpe.');
        combo = 0;
      }
    }

    if (enemyHealth > 0) {
      final dodgeOdds = (evasion ~/ 2 +
          (move == CombatMove.feint ? 12 : 0)).clamp(0, 42);
      dodged = random.nextInt(100) < dodgeOdds;
      if (dodged) {
        notes.add('ESQUIVA!');
      } else {
        var blow = 3 + enemy.tier * 2 + playerLevel +
            min(5, max(0, rivalRank)).toInt() + random.nextInt(6);
        if (intent == EnemyIntent.heavy) blow = (blow * 1.65).round();
        if (intent == EnemyIntent.defend) blow = (blow * .65).round();
        if (intent == EnemyIntent.special) {
          blow = (blow * (enemy.id=='final_boss'?1.65:1.3)).round();
          notes.add('$bossAbility!');
        }
        final armorDivisor=intent==EnemyIntent.special &&
          enemy.id=='forest_boss' ? 50 : 30;
        blow = max(1, blow - protection ~/ armorDivisor);
        if (guarding) {
          final guardMultiplier=intent==EnemyIntent.special &&
            enemy.id=='final_boss' ? .65 : .30;
          blow = max(1, (blow * guardMultiplier).round());
        }
        if(intent==EnemyIntent.special && enemy.id=='port_boss' &&
            stamina>0) {
          stamina=max(0,stamina-1);
          notes.add('O Almirante roubou 1 ponto de vigor!');
        }
        received = blow;
        playerHealth = max(0, playerHealth - received);
        totalTaken += received;
        notes.add(guarding ? 'DEFESA: apenas $received de dano recebido.' :
            '${enemy.name} causa $received de dano.');
      }
    }

    if (enemyHealth <= 0 || playerHealth <= 0 || round >= 35) {
      finished = true;
      won = enemyHealth <= 0 && playerHealth > 0;
      notes.add(won ? 'Vitória!' : 'Combate encerrado sem vitória.');
    } else {
      intent = _nextIntent(round);
    }
    final event = BattleTurn(round, dealt, received, guarding, crit,
        notes.join(' '), dodged: dodged);
    history.add(event);
    return event;
  }

  BattleOutcome get outcome {
    if (!finished) throw StateError('Combate ainda em andamento');
    return BattleOutcome(
      opponentId: enemy.id, won: won, remainingHealth: playerHealth,
      turns: round, damageDealt: totalDealt, damageTaken: totalTaken,
      dominantMove: dominantMove,
    );
  }
}
