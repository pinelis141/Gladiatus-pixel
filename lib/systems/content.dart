import 'combat.dart';

/// Original names and mechanics; the game does not copy proprietary Gladiatus assets.
const regions = <String, String>{
  'Campânia': 'Campos e florestas nas proximidades de Roma',
  'Porto de Óstia': 'Rotas comerciais dominadas por saqueadores',
  'Ruínas de Vulcano': 'Santuário antigo guardado por criaturas ferozes',
};

const expeditions = <EnemySpec>[
  EnemySpec(id:'wolf', name:'Lobo Selvagem', sprite:'enemy_wolf_hd',
    region:'Campânia', description:'Predador das colinas.',
    scene:'scene_forest', trait:'Feroz', tier:1),
  EnemySpec(id:'bandit', name:'Bandido da Estrada', sprite:'enemy_pirate_hd',
    region:'Campânia', description:'Saqueia mercadores nas estradas.',
    scene:'scene_forest', trait:'Astuto', tier:2),
  EnemySpec(id:'forest_boss', name:'Guardião da Floresta',
    sprite:'enemy_minotaur_hd', region:'Campânia',
    description:'Chefe da região: desbloqueia Óstia.',
    scene:'scene_forest', trait:'Colossal', tier:3, minLevel:2, boss:true),
  EnemySpec(id:'corsair', name:'Corsário de Óstia', sprite:'enemy_pirate_hd',
    region:'Porto de Óstia', description:'Experiente nos assaltos marítimos.',
    scene:'scene_port', trait:'Ágil', tier:3, minLevel:3),
  EnemySpec(id:'mercenary', name:'Mercenário de Cartago',
    sprite:'enemy_gladiator_hd', region:'Porto de Óstia',
    description:'Guerreiro por contrato.',
    scene:'scene_port', trait:'Blindado', tier:4, minLevel:4),
  EnemySpec(id:'port_boss', name:'Almirante Renegado',
    sprite:'enemy_pirate_hd', region:'Porto de Óstia',
    description:'Chefe da região: desbloqueia as ruínas.',
    scene:'scene_port', trait:'Comandante', tier:5, minLevel:5, boss:true),
  EnemySpec(id:'sentinel', name:'Sentinela Caído',
    sprite:'enemy_gladiator_hd', region:'Ruínas de Vulcano',
    description:'Antigo soldado perdido no santuário.',
    scene:'scene_ruins', trait:'Implacável', tier:5, minLevel:6),
  EnemySpec(id:'beast', name:'Minotauro Ancestral',
    sprite:'enemy_minotaur_hd', region:'Ruínas de Vulcano',
    description:'Protetor das câmaras subterrâneas.',
    scene:'scene_ruins', trait:'Colossal', tier:6, minLevel:7),
  EnemySpec(id:'final_boss', name:'Colosso de Marte',
    sprite:'enemy_minotaur_hd', region:'Ruínas de Vulcano',
    description:'O maior desafio desta temporada.',
    scene:'scene_ruins', trait:'Lendário', tier:8, minLevel:8, boss:true),
];

const arenaRivals = <EnemySpec>[
  EnemySpec(id:'cassius', name:'Cássio, o Obstinado',
    sprite:'enemy_gladiator_hd', region:'Arena',
    description:'O rival aprende a resistir aos seus ataques.',
    scene:'scene_colosseum', trait:'Resistente', tier:2, arena:true),
  EnemySpec(id:'felix', name:'Félix, a Raposa',
    sprite:'enemy_gladiator_hd', region:'Arena',
    description:'Adversário rápido que reage aos seus desafios.',
    scene:'scene_colosseum', trait:'Esquivo', tier:3, minLevel:3, arena:true),
  EnemySpec(id:'valerius', name:'Valério, o Campeão',
    sprite:'enemy_gladiator_hd', region:'Arena',
    description:'Campeão veterano. Nunca subestime a revanche.',
    scene:'scene_colosseum', trait:'Tático', tier:5, minLevel:5, arena:true),
];

class Contract {
  final String id, title, description;
  final int target, gold, xp;
  const Contract(this.id,this.title,this.description,
      this.target,this.gold,this.xp);
}

const dailyContracts = <Contract>[
  Contract('victories','Primeiras vitórias','Vença 2 combates.',2,65,20),
  Contract('expedition','Explorador romano','Vença 2 expedições.',2,70,25),
  Contract('arena','Glória no Coliseu','Vença 1 duelo de arena.',1,80,30),
  Contract('forge','Ferreiro aprendiz','Reforce 1 equipamento.',1,55,25),
];

String localDayKey(DateTime date) =>
    '${date.year.toString().padLeft(4,'0')}-'
    '${date.month.toString().padLeft(2,'0')}-'
    '${date.day.toString().padLeft(2,'0')}';
