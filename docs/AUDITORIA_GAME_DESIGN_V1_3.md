# Auditoria integral de Game Design — Gladiatus Pixel v1.3

**Data:** 20/10/2026  
**Escopo:** combate, economia, atributos, itens, progressão, curva de dificuldade,
missões, arena, campanhas, interface, retorno da ação ao jogador, audiovisual,
motivação e ritmo da sessão.

> Esta é uma auditoria **do design implementado** em `main` na versão v1.3,
> não um playtest com usuários. As estimativas de vitória vêm de um modelo
> Monte Carlo em Python que reproduz as fórmulas centrais, mas não executa
> o código Dart do jogo. Têm incerteza de amostragem e hipóteses explícitas
> sobre itens, atributos, vida inicial e estratégia. Não constituem prova de
> que um jogador real terá a mesma taxa de vitória.

## Resumo executivo

O protótipo tem um ciclo funcional: **escolher missão/arena → lutar por turnos →
receber XP, ouro ou equipamento → equipar/reforjar → tentar desafio seguinte**.
Porém a dificuldade inicial tem degraus extremos, vários atributos só funcionam
em múltiplos inteiros, a finta pode dominar o combate, o sistema de rivais
penaliza sucessos anteriores, os chefes têm recompensas recorrentes de primeira
derrota e o combate oferece pouca variedade de comportamentos inimigos.

**Estado de design:** *protótipo jogável com balanceamento inadequado para
distribuição ampla*. Priorizar a correção da curva de dificuldade e a leitura
das escolhas do combate **antes** de adicionar dezenas de monstros e itens.

## 1. Curva de dificuldade — evidência quantitativa

**Método:** `python tools/simulate_game_design.py --trials 5000` (40 combinações;
200.000 lutas). Cada luta começa com vida cheia, RNG pseudoaleatório reproduzível
do Python, sem compras, curas entre lutas, recompensas, experiência nem drops.
Diferentes estratégias: ataque normal contínuo; golpe pesado sempre que houver
vigor; finta contínua; defender e pesado alternados; estratégia adaptativa.

| Cenário | HP inimigo | Normal | Pesado | Finta | Defesa+pesado | Adaptativo |
|---|---:|---:|---:|---:|---:|---:|
| N1 lobo inicial | 44 | 94,8% | 94,5% | 98,7% | 88,2% | 95,9% |
| N1 bandido inicial | 63 | 0,9% | 13,8% | 49,1% | 19,6% | 17,7% |
| N2 chefe 1, arma inicial | 124 | 0,0% | 0,0% | 0,8% | 0,0% | 0,0% |
| N2 chefe 1, equipamento leve | 124 | 0,1% | 3,6% | 13,2% | 3,7% | 5,0% |
| N3 chefe 1, equipado | 131 | 26,3% | 46,8% | 55,3% | 35,6% | 46,1% |
| N5 chefe do Porto, equipado | 183 | 18,8% | 38,9% | 31,2% | 23,6% | 35,4% |
| N8 chefe final, equipado | 261 | 6,8% | 20,2% | 9,9% | 12,9% | 16,7% |
| N8 rival da arena, rank 10 | 279 | 0,1% | 3,0% | 0,9% | 2,3% | 2,0% |

**Definição do equipamento simulado:**

- N1: vida 100, gládio 4–8, força/destreza/agilidade 5 e armadura 0.
- N2 inicial: vida 120, gládio 4–8, força 8, destreza/agilidade 5, armadura 22.
- N2 equipado leve: vida 120, arma 6–12, força 9, destreza 6, agilidade 5,
  armadura 65.
- N3 equipado: vida 140, arma 8–16, força 12, destreza/agilidade 8,
  armadura 100.
- N5 equipado: vida 180, arma 12–24, força 20, destreza/agilidade 10,
  armadura 160.
- N8 equipado: vida 240, arma 18–35, força 28, destreza/agilidade 14,
  armadura 260.

São *construções hipotéticas ilustrativas*, não distribuições estatísticas
dos equipamentos realmente adquiridos. Comparações de estratégias dentro
do mesmo cenário são mais informativas que qualquer taxa isolada.

**P0.1 — salto entre lobo e bandido:** no nível 1, o ataque normal cai de
94,8% no lobo para 0,9% no bandido. Exibir ambos próximos e sem orientação
pode frustrar quem acabou de iniciar.

**P0.2 — primeiro chefe enganoso:** acesso a partir do nível 2, mas o exemplo
com equipamento leve tem somente 3,6% de vitória usando golpe pesado.
O requisito de nível não comunica adequadamente a exigência de equipamento.

**P0.3 — escolhas assimétricas:** a finta oferece esquiva adicional de
24 pontos percentuais, acerto base de 86 e combo +2 até três, apesar do
multiplicador de dano de 0,68. Contra o bandido inicial, sua vitória estimada
é 49,1%, contra 0,9% usando ataque normal. O jogador pode aprender a
repetir finta em vez de alternar ações táticas.

**P0.4 — rivalidade punitiva:** o rank é aumentado quando *o jogador vence*.
Até rank 10, o rival ganha 110 HP e mais 20 de dano bruto por ataque;
os traços narrativos não mudam. Mesmo com conjunto ilustrativo N8 avançado,
o rival rank 10 fica em cerca de 3% de vitória com pesado. O sistema recompensa
mal a repetição e não cria histórias ou reações especiais.

### Metas sugeridas, sujeitas a teste humano

- Lobo inicial: **80–95%** de vitórias em sessões orientadas, mantendo tensão.
- Bandido: **50–75%** com o equipamento que o tutorial de fato fornece
  (não necessariamente contra o gladiador sem upgrades).
- Primeiro chefe: **35–65%** com build esperada no nível em que ficar acessível.
- Nenhuma ação simples deveria dominar as demais em quase todos os encontros;
  criar papéis situacionais de defesa, pesado e finta.
- Rival repetido deve continuar desafiante, mas evitar torná-lo inviável
  só porque o jogador já venceu.

## 2. Progressão, atributos e equipamento

O XP exigido para o próximo nível é `30 + (nível−1)×25`. Vitórias contra
o lobo dão 24 XP, assim:

| Nível atual | XP necessário | Lobos vencidos para subir (sem outros XP) |
|---|---:|---:|
| 1 | 30 | 2 |
| 2 | 55 | 3 |
| 3 | 80 | 4 |
| 4 | 105 | 5 |
| 5 | 130 | 6 |
| 6 | 155 | 7 |
| 7 | 180 | 8 |
| 8 | 205 | 9 |

Esses números consideram partir de 0 XP do respectivo nível. Como há
XP excedente transportado, a campanha real pode exigir menos confrontos.

**P1.1 — degraus invisíveis de atributos.** A destreza afeta o acerto apenas
via `destreza ~/ 3`; a agilidade, via `agilidade ~/ 2`; a redução de dano
da armadura via `armadura ~/ 36`; a força aumenta o dano via
`força ~/ 3`. Investir um ponto pode não mudar nada naquele momento
até cruzar o próximo múltiplo. Constituição dá apenas 2 HP por ponto.
O usuário não vê o impacto previsto de cada ponto antes de confirmar.

**P1.2 — recompensa aleatória pouco direcionada.** Drops comuns ocorrem em
40% das vitórias não-chefe e slots têm chances iguais (8). Probabilidade
de sair uma arma por vitória: **5%** (média de 20 vitórias; probabilidade
de não cair arma em dez vitórias ≈59,9%). A vitrine oferece sete itens, mas
no nível 1 só ~45,6% das vitrines terão pelo menos uma arma que também pode
ser equipada, dadas as fórmulas uniformes de slot e nível. Falta um
**primeiro upgrade garantido** ou tutorial de compra de arma.

**P1.3 — itens parecem clones.** Todos os itens de um mesmo slot exibem
a mesma camada artística, independentemente do nome, nível e raridade.
Cada slot de armadura (inclusive botas e luvas) usa o mesmo multiplicador
de defesa; variáveis de item como arma, anel e amuleto não trazem talentos
ou modificadores próprios de estilo de jogo.

**Melhorias propostas:** explicar o ganho marginal de atributo, diminuir
truncamentos opacos, dar um caminho de equipamentos iniciais com recompensa
dirigida, introduzir 2–3 arquétipos de itens de efeitos distintos e reservar
variações de sprite prioritárias para itens efetivamente equipados.

## 3. Ouro, gastos, reforja e recompensas

Valores que saem diretamente das fórmulas atuais:

| Origem/gasto | Valor |
|---|---:|
| Ouro inicial | 300 |
| Lobo: vitória | 35–49 ouro |
| Chefe Campânia: vitória | 171–185 ouro |
| XP chefe Campânia | 107 XP |
| Recuperação completa na taverna | 15 ouro |
| Renovar 7 ofertas do mercador | 25 ouro |
| Contratos diários, todos resgatados | 270 ouro + 100 XP |
| Primeiro reforço em item nível 1 | 55 ouro |
| Cinco reforços em um item nível 1 | 825 ouro |

**P0.5 — chefe repetível paga bônus de primeira vitória para sempre.**
`fight()` concede `+110` ouro, `+65` XP e chance de loot de 85%
em **todas** as derrotas de um chefe, mesmo depois de sua ID estar em
`defeatedBosses`. O flag apenas controla desbloqueio/visual. Após desbloquear,
repetir o chefe pode se tornar a fonte dominante de ouro e XP.

**P1.4 — recursos de energia redundantes.** A energia inicial é 10 e cada
combate gasta 1; não há regeneração baseada em tempo nem outra utilidade.
A taverna restaura vida e os dez pontos de energia instantaneamente por
15 ouro, independentemente do dano sofrido. Isso converte a energia em
uma taxa de conveniência, não em decisão estratégica. O socorro emergencial
é correto para evitar *softlock*, mas sua regra merece telemetria.

**P1.5 — economia tende ao excesso de ouro após a abertura.** O lobo concede
em média 42 ouro por vitória antes de loot; descansar uma vez custa 15 e
renovar a loja custa 25. Chefes e contratos pagam muito mais. O ferreiro
serve como gasto significativo mais tarde, mas a evolução pode se alternar
entre economia trivial e reforja caríssima. Ainda não foi feita simulação
completa de campanha/bolsa/mercado para afirmar inflação mensurada.

**Melhorias propostas:** bônus de chefe somente na primeira vitória;
replays com recompensa normal proporcional ao risco; orçamento diário de
ganhos/gastos por nível; recompensas de missões por objetivo significativo;
separar recuperação de vida da recarga de energia ou remover energia se
não trouxer uma escolha interessante.

## 4. Encontros, IA, arena e chefes

**P0.6 — traços são apenas texto.** `trait` (`Ágil`, `Blindado`,
`Feroz`, `Tático`, etc.) não é usado em nenhuma fórmula de batalha.
Todos os inimigos usam o mesmo padrão de contra-ataque e diferem
numericamente pelo `tier`, HP e bônus de chefe. Não há telegráfo de
ataque, habilidades únicas, padrões, postura nem alteração tática.

**P1.6 — chefes sem identidade mecânica.** Recebem apenas 35 HP adicionais
e mais ouro/XP/loot. Um chefe deveria demandar aprender ou responder a uma
mecânica distinta, não somente investir mais turnos e armadura.

**P1.7 — arena não possui memória relacional.** `rivalVictories` armazena
um contador por rival, mas não há registro de derrotas do jogador, rivais
que surgem após acontecimentos, feridas, técnicas favoritas, insultos ou
mudanças de personalidade. O texto promete que o rival "aprende", mas
o comportamento não muda.

**Melhorias propostas:** definições de IA por arquétipo (rápido, pesado,
defensivo); sinalização de ataque inimigo, desvio/defesa com janela de
decisão; habilidades pontuais de chefes; rivalidade baseada em **histórico
bilateral**, com limites e recompensas também para derrotas e vitórias.

## 5. Mapa, missões, narrativa e retenção

- Existem 9 posições de expedição em três regiões, três chefes e três rivais.
  Entretanto só há quatro aparências-base de inimigos
  (`wolf`, `pirate`, `minotaur`, `gladiator`); os três rivais usam o
  mesmo sprite de gladiador.
- As regiões são listas verticais com arte de fundo e botões.
  Não há exploração, caminho/rota, eventos aleatórios, narrativa dialogada,
  escolha de risco ou recompensas únicas por descoberta.
- O requisito de nível é mostrado, mas a pré-condição de derrotar o
  chefe anterior aparece só como `BLOQUEADO` e aviso após interação;
  falta progresso visual para liberar a região.
- Contratos diários aparecem **depois de todas as expedições**; em telas de
  celular, exigem longa rolagem. A taverna também fica no fim de Missões.
- A frase de 50 vitórias/“lenda das arenas” não corresponde a um sistema de
  título, conquista, recompensa ou final implementado.
- Derrotar o chefe final não dispara conclusão narrativa, epílogo nem
  atividade de endgame.
- Os contratos diários dependem do relógio do aparelho, manipulável em
  jogo offline; se o jogo continuar totalmente offline, decidir se isso
  é aceitável em vez de construir antitrapaça intrusivo.

**P1.8 — falta onboarding/objetivo imediato.** Na primeira abertura, o
usuário vê o personagem e números, mas não uma sequência guiada
"Primeiro lobo → equipar recompensa → preparar bandido → liberar chefe".

**P2 — profundidade da campanha:** contratos regionais, chefes com
recompensas inéditas, encontros de escolha, eventos e epílogo após final.

## 6. UX, informação e feedback audiovisual

- HUD e sprite HD estão mais consistentes após a auditoria v1.3.
- Combate usa `AnimatedScale` em duas poses, mas não possui animações por
  frame específicas para atacar, bloquear, ser atingido ou esquivar.
- Descrições das quatro ações são curtas e não revelam precisão, risco,
  valor de esquiva ou o efeito real dos combos.
- Não há previsão de dano do inimigo nem indicador de dificuldade baseado
  em equipamento efetivo. O jogador descobre um combate inviável perdendo.
- Falta controle de volume individual de efeitos e resposta mais visível
  para acerto crítico, defesa e recompensa rara.
- A raridade do item tem cor, mas poderia usar nomenclatura, comparação
  com equipamento atual e acessibilidade para quem não distingue cores.

**P1.9 — principais melhorias UX:** aba de contratos em destaque,
taverna acessível sem rolar nove encontros, painel de preparação com chance
aproximada de vitória *calibrada*, recompensas/sinalização de chefe e
comparador de atributos de equipamentos.

## 7. Ordem recomendada para mudanças

| Ordem | Mudança | Critério de aceite |
|---|---|---|
| **P0-A** | Refazer curva do nível 1 ao primeiro chefe | Taxas de vitória e duração definidas por loadout esperado; validar com 10 jogadores ou testes guiados |
| **P0-B** | Diferenciar quatro ações e o comportamento de inimigos | Cada ação tem uso situacional vantajoso, sem repetição dominante |
| **P0-C** | Corrigir recompensas repetidas de chefes | Primeiro prêmio apenas uma vez, payout de replay explícito |
| **P0-D** | Reequilibrar arena para progressão bilateral | Rivais desafiadores mas vencíveis, mudanças visíveis entre duelos |
| **P1-A** | Tutorial, caminho de itens e comunicação da força exigida | Novo jogador chega ao primeiro upgrade e entende pré-requisitos |
| **P1-B** | Reformular energia/taverna e orçamento de ouro | Custo/benefício testado no nível 1, 3, 5 e 8 sem travar progresso |
| **P1-C** | Traços, padrões inimigos e habilidades de chefes | Ao menos três estilos identificáveis por comportamento |
| **P1-D** | Recompensas de progressão e vitória final | Desbloqueios reais, não apenas textos prometidos |
| **P2** | Campanha narrativa, itens únicos, novas artes e sons | Conteúdo criado após estabilizar regras existentes |

## 8. Matriz de QA de game design

Cada alteração nas fórmulas deve reexecutar Monte Carlo e, posteriormente,
testes de usuários. Medir por encontro e estratégia:

- % vitórias e derrotas; vida restante; rodadas médias e p95;
- ação mais utilizada; % de esquiva; razão dano causado/recebido;
- ouro e XP líquidos após loja, venda, recuperação, reforja e boss replay;
- tempo necessário para nível 2/3/5/8 e para enfrentar os chefes;
- % players sem arma superior após 5, 10 e 20 encontros;
- total de vitórias/derrotas em rivais e chance de revanche por rank;
- abandono do primeiro bandido e primeiro chefe;
- descoberta/uso de contratos, taverna e ferreiro.

**Ferramenta incluída:** `tools/simulate_game_design.py`, que oferece
`--trials N` e `--json` para análise repetível.
Este modelo está separado do jogo; revisar o modelo quando
`lib/systems/combat.dart` mudar. Não instalar balanceamento novo
automaticamente usando números hipotéticos sem playtest.

## Referências de implementação

- `lib/systems/combat.dart` — vigor, dano, esquiva, IA e HP.
- `lib/models/gear.dart` — gerador de raridades/atributos e reforja.
- `lib/systems/content.dart` — regiões, chefes, rivais, contratos.
- `lib/main.dart` — ouro, XP, saves, drops, comércio, taverna, desbloqueios.
- `lib/screens/battle_screen.dart` — UX das ações por turnos.

## Decisão de release

**Não classificar a v1.3 como game design balanceado.** É um protótipo jogável
com bugs técnicos corrigidos, mas cuja calibragem e profundidade dos encontros
continuam pendentes. Esta auditoria registra os problemas e não altera a
dificuldade do APK atual.
