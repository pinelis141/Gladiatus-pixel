# Auditoria de UI e UX — Gladiatus Pixel v1.3

**Data:** 20/10/2026  
**Status:** diagnóstico e backlog. A versão do APK **não foi alterada** nesta auditoria.

## 1. Escopo e método

Auditoria estática das telas presentes em `lib/main.dart`,
`lib/screens/battle_screen.dart`, `lib/widgets/roman_theme.dart`,
`lib/widgets/pixel_avatar.dart`, dos testes existentes em
`test/widget_test.dart` e da captura real do usuário da tela Herói
anterior à compactação do cabeçalho na v1.3.

O trabalho considera: navegação, hierarquia visual, leitura, contraste,
targets de toque, feedback, prevenção de erro, acessibilidade, fluxo
de equipamento/loja/forja, descoberta de missões, combate, informações
ao jogador, performance de listas, variação de telas e texto ampliado.

**Limite do método:** a captura de tela fornecida refere-se a versão
anterior à v1.3; seu arranjo não é prova de que o mesmo cabeçalho ainda
existe no APK mais recente. O código v1.3, por sua vez, foi inspecionado
diretamente. Não foi realizado teste com TalkBack, testes visuais
automatizados em múltiplos aparelhos físicos nem entrevista com usuários.
Severidade é uma avaliação técnica de risco/impacto, não métrica de uso real.

## 2. Diagnóstico executivo

**Identidade estética:** reconhecível e com potencial; paleta
marrom escuro, dourado e creme e o avatar HD evocam Roma.

**Experiência de uso:** adequada para demonstração, mas longe da
apresentação de RPG mobile maduro. O desafio principal não é trocar
todos os componentes visuais, e sim facilitar decisões e ações frequentes.

O usuário deveria conseguir rapidamente:

1. Entender o estado atual do gladiador;
2. Identificar qual desafio enfrentar em seguida e sua dificuldade;
3. Entrar em combate e interpretar o resultado;
4. Comparar o saque com o que já usa;
5. Equipar, vender ou reforjar com baixa fricção;
6. Recuperar-se e retornar à próxima atividade;
7. Reconhecer quando seu progresso foi salvo.

Atualmente passos 2, 4, 5, 6 e 7 apresentam problemas de visibilidade
ou de feedback.

## 3. Achados por prioridade

| ID | Gravidade | Evidência no código/captura | Impacto e correção |
|---|---|---|---|
| UX-01 | **P0** | `missionsPage()` exibe as 3 regiões e todos os 9 encontros antes de `contractsPanel()` e da Taverna | Contratos e recuperação exigem rolagem excessiva. Subir recursos críticos para topo/atalhos persistentes. |
| UX-02 | **P0** | `gearCard()` mostra atributos isolados, mas não compara o item equipado, nem calcula delta | Comprar e equipar viram apostas. Comparador lado a lado e variação positiva/negativa para dano, defesa, atributos, requisitos e preço. |
| UX-03 | **P0** | `sell()` vende imediatamente; `gearCard()` pode exibir Vender junto com Equipar em cada linha | Toque acidental destrói item irreversivelmente. Confirmar venda de item raro/equipado de modo contextual e/ou permitir desfazer por alguns segundos. |
| UX-04 | **P0** | Inimigos bloqueados recebem `onPressed:null` e texto “BLOQUEADO” | Não há explicação contextual persistente do bloqueio; indicação explícita da causa e da ação para liberar. |
| UX-05 | **P1** | Textos de `gearCard()` e contratos usam 11–12sp; o tema monospace e títulos forçados em maiúsculas aumentam densidade | Melhoria da escala tipográfica, peso/hierarquia e menor volume de texto por cartão. Testar escalas 1.0/1.3/2.0. |
| UX-06 | **P1** | `stat()` define `minWidth:38,minHeight:38` no IconButton | Área de toque inferior ao alvo de 48dp desejável no Android; ampliar hitbox sem aumentar demasiado o símbolo. |
| UX-07 | **P1** | `missionsPage()` utiliza `Sprite(... width:300)` dentro de painel com paddings | Em janela ~320dp, largura útil ~265dp: grande risco de overflow horizontal. Usar `LayoutBuilder`/restrições responsivas e `AspectRatio`. |
| UX-08 | **P1** | `BattleScreen` exibe `Row` com avatar 136dp e inimigo 132dp; padding do painel/tela | Em janela ~320dp, área útil ~265dp, inferior aos 268dp dos sprites, antes de escalas animadas. Tornar tamanhos flexíveis. |
| UX-09 | **P1** | `heroPage()` mostra atributo total e botão “+”, mas não separa base/equipamento nem explica o efeito | Distribuição de pontos sem entender o ganho; tooltip “Melhorar Força: +1 base, +0 efeito imediato / limiar seguinte”. |
| UX-10 | **P1** | `Sprite`, `HeroAvatar` e imagens de raridade carecem de `Semantics` coerente; cores de item são a principal pista de raridade | TalkBack pode não informar personagem, raridade, slot nem estado. Textos alternativos, rótulos e semântica para barra de status. |
| UX-11 | **P1** | `battle_screen.dart` relata os resultados em texto e usa escala semelhante em quase todas ações; histórico fica abaixo | Feedback pouco diferenciado para acerto/erro/bloqueio/esquiva; mostrar números e símbolos contextuais, sem depender só de cor/som. |
| UX-12 | **P1** | Não existe opção de volume/vibração; `HapticFeedback.lightImpact` ocorre em cada turno | Usuário não consegue controlar estímulos, conforto e acessibilidade. Oferecer toggles e respeitar configurações do sistema. |
| UX-13 | **P1** | `forgePage()` mostra “Reforjar +6” em item +5; `inventoryPage()` exibe “Nível insuficiente” como rótulo de botão ainda clicável | Estados desabilitados não são representados corretamente: desativar botão e indicar requisito/cap; exibir prévia da melhoria. |
| UX-14 | **P1** | `showDialog` de resultado de luta surge depois de `BattleScreen` já exibir vitória/derrota | Duplicação de resultado interrompe o ritmo. Centralizar resultado e saque em uma tela com “Continuar/Equipar/Voltar”. |
| UX-15 | **P1** | Vários `ListView(children:[...])` reconstroem listas de até 40 itens sem virtualização | Possível queda de fluidez e scroll, especialmente em aparelhos inferiores. `ListView.builder`/slivers, separando componentes estáveis. |
| UX-16 | **P1** | `saveGame()` salva automaticamente e há ícone de disquete, mas sucesso não gera retorno explícito | Ambiguidade (“preciso salvar manualmente?”); auto-save com status salvo/salvando/erro e opção exportar progresso. |
| UX-17 | **P1** | `NavigationBar` tem 5 destinos em 72dp, mesmo em janela estreita e textos ampliados | Risco de colisão/corte de rótulos. Verificar 320/360/412dp, textos em 1.3× e 2×; adaptar destinos ou estrutura de tela. |
| UX-18 | **P2** | `marketPage()` e `forgePage()` compartilham a aba Comércio, com a Forja acessada por botão | A Forja é descoberta só depois de entrar no mercador; subtabs Mercado/Forja e memória de seção mais explícitas. |
| UX-19 | **P2** | `gear.slot.name` mostra `weapon`, `shield`, `armor` etc. em inglês no corpo do app em português | Inconsistência de idioma. Centralizar nomes de slots e unidades em português. |
| UX-20 | **P2** | Mesmo layout de cartões repetidos (ícones ✨, moldura, divisor, texto uppercase) em todas as telas | Hierarquia visual achatada e pouco espaço útil. Reservar moldura ornamentada para títulos e raridades importantes. |
| UX-21 | **P2** | Estado vazio de bolsa e mercado é textual, sem caminho claro de recuperação, tutorial, filtros ou ordenação | Criar CTAs de contexto, filtros de classe e raridade, comparação e categorização de itens. |
| UX-22 | **P2** | `newGame()` abre no Herói e não apresenta instrução imediata de início | Primeiro contato pouco orientado: “Faça sua primeira expedição → obtenha equipamento → prepare-se para a arena”. |

### Limites importantes do diagnóstico

- UX-07 e UX-08 são **riscos geométricos verificáveis no código**, não falhas
  reproduzidas em captura de tela de 320dp. Confirmar com widget tests.
- UX-10 é **lacuna explícita de semântica**, não uma afirmação de que
  TalkBack está totalmente inutilizável sem teste real.
- UX-15 é **risco de escalabilidade**; ainda não há perfil de frames
  documentado em aparelho de baixa performance.
- A captura do usuário mostra o cabeçalho original da v1.2; o código
  v1.3 já reduziu `toolbarHeight` e a área inferior do AppBar.

## 4. Contraste e acessibilidade — métricas concretas

Análise realizada por luminância relativa sRGB segundo a regra WCAG de contraste.

| Combinação de cor | Razão | Meta aproximada | Situação |
|---|---:|---:|---|
| Creme #F2E4CB / painel #2B1C18 | **13,05:1** | 4,5:1 texto | Atende |
| Dourado #DDB35E / painel #2B1C18 | **8,33:1** | 4,5:1 texto | Atende |
| Dourado claro #F4D69B / painel | **11,65:1** | 4,5:1 texto | Atende |
| Dourado / fundo #140E0C | **9,73:1** | 4,5:1 texto | Atende |
| Vermelho #AC3842 / painel | **2,65:1** | 4,5:1 texto | **Falha** |
| Vermelho / fundo #140E0C | **3,10:1** | 4,5:1 texto | **Falha** |
| Bronze #6F4833 / painel | **2,07:1** | 3:1 quando contorno essencial | **Falha** |

Texto vermelho aparece no estado de derrota em `BattleScreen` sobre o
painel, logo a reprovação é concreta para essa aplicação. Contornos bronze
são usados em botões e bordas; onde essenciais para perceber o controle,
sua razão também é inferior a 3:1.

O contraste não resolve isoladamente o problema de **fonte pequena**.
Recomenda-se:
- Corpo principal aproximadamente 14–16sp conforme densidade de tela;
- Legendas importantes pelo menos 12–14sp com reforço de hierarquia;
- Alvo de toque preferencial próximo de 48dp;
- Texto com zoom 200% sem conteúdo essencial cortado ou ações bloqueadas;
- Não usar somente raridade por cor: texto + ícone + tom visual.

**Ferramenta adicionada**:
`python tools/audit_ui_contrast.py`; usar `--strict` quando
corrigirmos todos os pares de contraste. Por padrão apenas relata falhas
sem quebrar a compilação atual.

## 5. Reorganização da informação (proposta)

Conservar as cinco abas **Herói, Missões, Arena, Itens e Comércio**.
A estrutura de primeira navegação já é compreensível.

### Herói

Topo compacto com nome, nível, HP, energia, ouro e XP.
Personagem visível como foco artístico; abaixo:
- ação primária **Próxima missão**;
- ação secundária **Recuperar**;
- painel de atributos com valor base, bônus e estimativa de efeito;
- equipamentos com CTA **Comparar/Equipar**.

Evitar um grande cabeçalho decorativo repetido para cada subseção.

### Missões

1. Destaque fixo: **próxima expedição sugerida**, dificuldade e recompensa;
2. acesso rápido à **Taverna** e **Contratos**;
3. seções recolhíveis das regiões bloqueadas/desbloqueadas;
4. cartas de inimigos com requisito e motivo de bloqueio visível;
5. progresso claro para o próximo chefe e objetivo narrativo.

### Arena

Rivais distintos com nome, retrato, histórico, estilo e desafio.
Botão **Preparar duelo** que mostra equipamento recomendado,
vida atual, custo de energia e risco.

### Itens

Filtros: classe, raridade, equipável/agora, recém-obtido;
ordenação: poder, nível, preço e nome. Em cada item:
- título, raridade textual e ícone;
- equipamento atual de mesmo slot ao lado;
- diferença de dano, defesa e atributos;
- ações hierarquizadas “Equipar” / “Vender”;
- confirmação/undo de venda para raros e itens que não podem ser recuperados.

### Comércio

Com subtabs **Mercador | Ferreiro**.
Mercador: preço, comparação e possibilidade de pagar.
Forja: item atual, item após upgrade, custo, rank +0…+5,
com estado MAX claramente indicado. Renovação de ofertas tem
custo exposto e confirmação ou Undo.

### Batalha

Prioridade de tela: adversário e gladiador → intenções da rodada →
duas barras de HP legíveis → botões de ação → feedback contextual.
Histórico de eventos pode ficar recolhível.
Acertos, erros, bloqueios, esquivas, críticos e desfecho precisam de
feedback **visualmente distinto**; feedback sonoro e tátil opcional.
A ação escolhida deve continuar compreensível em telas menores
sem exigir procurar os botões rolando a cada turno.

## 6. Matriz mínima de validação UX

| Dispositivo/estado | Critério de aceite |
|---|---|
| Larguras 320, 360, 412, 600dp | Nenhum `RenderFlex overflowed`, clipping importante ou scroll horizontal involuntário |
| Alturas 568, 640, 800dp | Combate e navegação acessíveis; CTA primário evidente |
| Texto 1,0× / 1,3× / 2,0× | Itens, valores e ações essenciais visíveis; sem corte de diálogo |
| TalkBack | Nome, função, valor e estado de ações e progress bars anunciados |
| Raridade sem cores | Um jogador distingue comum/raro/épico pelos textos e símbolos |
| Item acima do nível | “Equipar” desativado com requisito explícito |
| Equipamento +5 | “MAX” em vez de “Reforjar +6” |
| Vender item raro | Confirmação/undo e retorno ao inventário |
| Missão bloqueada | Causa e objetivo de desbloqueio apresentados sem tentativa de clique |
| Combate concluído | Um resultado unificado e transição para recompensa/novo desafio |
| Jogador sem ouro/vida | Ação de recuperação acessível em até 2 toques sem rolagem longa |
| Salvar | Indicação de estado salvo/erro e instrução de backup |
| Reduzir animações | Respeitar acessibilidade e desligamento de efeitos quando solicitado |
| Esconde/mostra teclado, rotação, split screen | Layout sem perda de controles, quando suportado |

### Ferramentas para execução

- `flutter test --coverage`: testes de widgets com `tester.view.physicalSize`,
  `devicePixelRatio` e `MediaQuery.textScaler`;
- captura de screenshots golden test para Hero, Missões, Itens, Comércio,
  Forja e Batalha em tamanhos-alvo;
- Android Accessibility Scanner e TalkBack em aparelho real;
- Flutter DevTools Performance para verificar stutter, layouts e scroll;
- roteiro rápido de usabilidade com 5–10 pessoas, sem instruções prévias.

Nenhuma dessas ferramentas foi executada integralmente nesta auditoria.
Os critérios são um plano de aceitação, não resultados já aprovados.

## 7. Roadmap de implementação

### P0 — Corrigir fluxos

- Reorganizar Missões: contratos, taverna e próxima missão visíveis logo no topo.
- Entregar comparação de itens antes de comprar/equipar/forjar.
- Proteger ações irreversíveis de venda.
- Indicar por que um inimigo ou item está indisponível.

### P1 — Tornar a interface utilizável em mais aparelhos

- Widgets responsivos em 320dp, 360dp, 412dp e tablet.
- Aumentar áreas de toque, adequar fontes e contraste.
- Semantics e rótulos para TalkBack, raridade em texto.
- Feedback de combate, de progresso salvo e de nível acima/forja MAX.
- Reduzir reconstrução de listas longas e testar desempenho.
- Remover resultado duplicado de combate.

### P2 — Refinamento e personalidade visual

- Reorganizar decoração romana sem eliminar a estética aprovada.
- Animações distintas para golpe/esquiva/defesa/crit, com ajustes de volume.
- Tutorial opcional e orientação de objetivos.
- Filtros, atalhos, breadcrumbs e conteúdos vazios orientados à ação.
- Suporte mais completo a texto ampliado, navegação assistiva e dispositivos.

## 8. Decisão

**Não classificar a v1.3 como UI/UX aprovada para lançamento público.**
O visual e a estrutura básica são reconhecíveis, mas ainda faltam
hierarquia, clareza de decisões, prevenção de erro e acessibilidade.

Esta auditoria **não modifica o jogo nem o APK**, apenas adiciona
documentação e um instrumento de medição ao projeto.
Mudanças propostas deverão ser aplicadas por etapas e aprovadas
com screenshots reais, testes de widgets e validação de jogabilidade.
