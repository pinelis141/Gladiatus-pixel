import 'dart:math';

enum CombatMove { quick, heavy, guard, feint }

class EnemySpec {
  final String id;
  final String name;
  final String sprite;
  final String region;
  final String description;
  final String scene;
  final String trait;
  final int tier;
  final int minLevel;
  final bool boss;
  final bool arena;
  const EnemySpec({
    required this.id, required this.name, required this.sprite,
    required this.region, required this.description, required this.scene,
    required this.trait, required this.tier,
    this.minLevel = 1, this.boss = false, this.arena = false,
  });
}

class BattleTurn {
  final int turn;
  final int inflicted;
  final int received;
  final bool guarded;
  final bool critical;
  final String narration;
  const BattleTurn(this.turn, this.inflicted, this.received,
      this.guarded, this.critical, this.narration);
}

class BattleOutcome {
  final String opponentId;
  final bool won;
  final int remainingHealth;
  final int turns;
  final int damageDealt;
  final int damageTaken;
  const BattleOutcome({
    required this.opponentId, required this.won,
    required this.remainingHealth, required this.turns,
    required this.damageDealt, required this.damageTaken,
  });
}

/// Pure Dart battle rules, separated from Flutter widgets for deterministic tests.
/// Fight rewards are applied only once by the calling game screen.
class BattleEngine {
  final EnemySpec enemy;
  final Random random;
  final int maxPlayerHealth;
  final int maxEnemyHealth;
  final int playerLevel;
  final int power;
  final int accuracy;
  final int evasion;
  final int protection;
  final int minWeapon;
  final int maxWeapon;
  final int rivalRank;
  late int playerHealth;
  late int enemyHealth;
  int stamina = 4;
  int round = 0;
  int totalDealt = 0;
  int totalTaken = 0;
  int combo = 0;
  bool finished = false;
  bool won = false;
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
    Random? rng,
  }) : random = rng ?? Random(),
       maxEnemyHealth = 18 + enemy.tier * 19 + playerLevel * 7 +
           (enemy.boss ? 35 : 0) + min(10, max(0, rivalRank)) * 11 {
    playerHealth = startingHealth.clamp(0, maxPlayerHealth).toInt();
    enemyHealth = maxEnemyHealth;
  }

  BattleTurn play(CombatMove move) {
    if (finished) throw StateError('Combate encerrado');
    // Invalid heavy attacks fall back to one quick action, not two stamina
    // gains or two turns.
    if (move == CombatMove.heavy && stamina < 2) {
      move = CombatMove.quick;
    }
    round++;
    int dealt = 0, received = 0;
    bool crit = false;
    final notes = <String>[];
    final defending = move == CombatMove.guard;
    if (defending) {
      stamina = min(5, stamina + 2);
      combo = min(3, combo + 1);
      notes.add('Você assume posição defensiva.');
    } else {
      if (move == CombatMove.heavy) {
        stamina -= 2;
      } else if (move == CombatMove.quick) {
        stamina = min(5, stamina + 1);
      } else {
        stamina = min(5, stamina + 1);
      }
      final hit = move == CombatMove.heavy ? 65 : move == CombatMove.feint ? 86 : 83;
      final odds = (hit + accuracy ~/ 3 - enemy.tier * 3).clamp(20, 96);
      if (random.nextInt(100) < odds) {
        final lo = max(1, minWeapon);
        final hi = max(lo, maxWeapon);
        var base = lo + random.nextInt(hi - lo + 1) + power ~/ 3;
        crit = random.nextInt(100) < (7 + accuracy ~/ 8).clamp(4, 28);
        if (move == CombatMove.heavy) base = (base * 1.65).round();
        if (move == CombatMove.feint) base = (base * .68).round();
        if (crit) base = (base * 1.5).round();
        base += combo * 2;
        dealt = max(1, base - (enemy.tier + rivalRank) ~/ 2);
        enemyHealth = max(0, enemyHealth - dealt);
        totalDealt += dealt;
        notes.add(crit ? 'Golpe crítico! -$dealt HP.' : 'Você causa $dealt de dano.');
        combo = move == CombatMove.feint ? min(3, combo + 1) : 0;
      } else {
        notes.add('Seu golpe foi evitado.');
        combo = 0;
      }
    }
    if (enemyHealth > 0) {
      final dodged = random.nextInt(100) <
          (evasion ~/ 2 + (move == CombatMove.feint ? 24 : 0)).clamp(0, 45);
      if (dodged) {
        notes.add('Você esquiva do contra-ataque!');
      } else {
        var blow = 3 + enemy.tier * 3 + playerLevel +
            min(10, max(0, rivalRank)) * 2 + random.nextInt(7);
        blow = max(1, blow - protection ~/ 36);
        if (defending) blow = max(1, (blow * .35).round());
        received = blow;
        playerHealth = max(0, playerHealth - received);
        totalTaken += received;
        notes.add('${enemy.name} causa $received de dano.');
      }
    }
    if (enemyHealth <= 0 || playerHealth <= 0 || round >= 35) {
      finished = true;
      won = enemyHealth <= 0 && playerHealth > 0;
      notes.add(won ? 'Vitória na arena!' : 'O adversário venceu.');
    }
    final event = BattleTurn(round, dealt, received, defending, crit,
        notes.join(' '));
    history.add(event);
    return event;
  }

  BattleOutcome get outcome {
    if (!finished) throw StateError('Combate ainda em andamento');
    return BattleOutcome(
      opponentId: enemy.id, won: won, remainingHealth: playerHealth,
      turns: round, damageDealt: totalDealt, damageTaken: totalTaken,
    );
  }
}
