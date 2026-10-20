# Auditoria integrada da versão 2.0 — Gladiatus Pixel

**Escopo:** implementação conjunta das auditorias de código, game design e UI/UX:
- [Auditoria de código v1.3](AUDITORIA_V1_3.md)
- [Auditoria de game design v1.3](AUDITORIA_GAME_DESIGN_V1_3.md)
- [Auditoria de UI/UX v1.3](AUDITORIA_UI_UX_V1_3.md)

**Procedimento solicitado:** mudanças primeiro, **nova auditoria independente
antes de gerar APK**. A execução obrigatória do GitHub Actions na branch
de desenvolvimento não compila APK. O job Android na branch `main`
depende da aprovação prévia do job `audit`.

## Intervenções realizadas

| Auditoria | Problema anterior | Mudança v2 |
|---|---|---|
| Game design P0 | Lobo e bandido com salto excessivo | Nova curva de HP, dano e probabilidade de acerto |
| Game design P0 | Primeiro chefe desproporcional | HP de chefes ajustado à região; chefes finais escalam mais |
| Game design P0 | Finta muito dominante | Redução de esquiva e multiplicador de dano; quatro habilidades com papéis distintos |
| Game design P0 | Traços dos inimigos só narrativos | Máquina de intenções táticas telegráficas por arquétipo |
| Game design P0 | Arena punitiva sem memória bilateral | Vitórias e derrotas persistidas, rank com teto |
| Game design P0 | Chefes exploráveis indefinidamente | Bônus especial só na primeira vitória |
| Game design P1 | Novo jogador sem arma viável | Gládio melhor garantido após primeiro lobo |
| Game design P1 | Energia não tem gestão | Recarga gradual de 20min/ponto; cura e energia separadas |
| Game design P1 | Campanha sem orientação | Mensagens para primeira expedição; epílogo e título da arena |
| UI P0 | Taverna e contratos escondidos | Subidos para topo de Missões com próximo confronto |
| UI P0 | Comprar/equipar sem comparar | Delta de poder e escudo vs slot equipado nas cartas |
| UI P0 | Vendas acidentais | Confirmação para raros e Undo via SnackBar |
| UI P0 | Inimigo bloqueado sem explicação | Motivo do bloqueio exposto na carta |
| UI P1 | Sprite de missão fixa a 300dp | Medidas responsivas usando `LayoutBuilder` |
| UI P1 | Batalha apertada com ações rolando | Dimensão relativa à largura e ações fixas na área inferior |
| UI P1 | Texto e toque pequenos | Botões de treino com pelo menos 48dp; corpo/legendas maiores |
| UI P1 | Contraste insuficiente | Red e bronze ajustados (WCAG pelo script estrito) |
| UI P1 | Raridade apenas por cor | Raridade traduzida em texto |
| UI P1 | Cartas excedem vida útil do jogador | Inventário virtualizado (`ListView.builder`) e filtros |
| UI P1 | Forja exibe +6 e não informa melhoria | Estado MAX e prévia de atributos |
| UI P1 | Ações sem controle de efeitos | Preferências persistentes de som e vibração |
| UI P1 | Resultado de luta duplicado | Tela de batalha apresenta combate; modal central de resultado depois |
| UI P1 | Autosave sem feedback | Estado do save no ícone e tela de opções |
| UI P2 | Comércio pouco claro | Abas internas explícitas Mercador e Ferreiro |
| UI P2 | Slots em inglês | Traduções locais de slot e raridade |
| UI P2 | Contratos difíceis de alcançar | Contratos e Taverna antes do mapa expandido |
| Engenharia | Saves divergentes | Escrita sequencial e backup de entrada inválida da v1.3 preservados |
| Engenharia | Assinatura de APK variável | Risco documentado (exige chave do proprietário em Secrets) |

## Testes obrigatórios **antes do build**

- `python tools/generate_sprites.py`, `tools/generate_hd_sprites.py`,
  `tools/extract_hero_art.py`, `tools/verify_hero_assets.py` e áudio;
- 33 PNGs e 3 WAV válidos; atlas hi-bit modular 128×144;
- `python tools/audit_ui_contrast.py --strict`;
- `python tools/pre_release_audit.py`: invariantes de conteúdo de todas
  auditorias, IA, UX, recompensas, arte e acessibilidade;
- `flutter analyze --no-fatal-infos`;
- `flutter test --reporter expanded` (testes legados, monte carlo Dart e
  testes de interface em larguras de 320, 360 e 412dp);
- execução verde na branch de desenvolvimento e revisão de eventuais erros.

**Política:** jamais executar `flutter build apk` para este pacote enquanto
o job de auditoria na branch de desenvolvimento não estiver aprovado.

## Critérios e limitações honestas

Esta v2 é um grande pacote de otimização, mas uma auditoria completa não pode
ser interpretada como garantia de nenhum bug. São necessárias validação de
instalação, assinatura e jogo em aparelhos reais. A produção de animações
quadro a quadro completas, dezenas de equipamentos únicos, histórias ramificadas,
telemetria remota e testes de acessibilidade TalkBack em hardware são esforços
de conteúdo/teste humano, não corrigidos só por patches nas regras de batalha.

### Assinatura e dados locais

`gladiatus_pixel_save_v2` continua sendo a chave de dados. Os novos campos
de energia, preferências, rivais e filtros têm valores padrão para saves antigos.
A assinatura automática criada pelo Android runner **não é uma solução segura
para atualizações instaladas sobre versões anteriores**. O usuário precisa
configurar um keystore privado persistente; este dado não pode ser inventado ou
inserido no repositório. Não desinstalar o APK antigo sem exportação/backup de
progresso.

## Resultado da reauditoria

**Pendente de CI.** Este bloco será preenchido depois de rodar a suite
pre-release e avaliar a execução mais recente. O APK não deve ser produzido
antes dessa validação.

## Itens para evolução posterior sem impedir validação funcional

- Playtest com pelo menos 5 usuários de perfis distintos;
- Assinatura persistente e estratégia de migração do APK;
- Testes TalkBack/Android Accessibility Scanner em dispositivo real;
- Aumento das variações artísticas por equipamento e animações por quadro;
- Sistema de rivalidade narrativa e eventos de campanha mais elaborados;
- Benchmarks de bateria/memória/frames em Android de entrada.

**Fonte das alterações:** `feature/optimization-unified-v2`.
