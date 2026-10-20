# Gladiatus Pixel — RPG Romano (v1.3)

RPG **independente** para Android feito em Flutter, com interface romana, batalha por turnos e pixel art em alta resolução (128×144). O projeto não contém código, marcas, servidores ou artes do Gladiatus original.

## v1.3 — correções verificadas

- Arte da espada reposicionada com verificação de alinhamento ao punho.
- Combate corrigido: vigor, recuo com confirmação e força limitada dos rivais.
- Saves gravados sequencialmente, loja persistente e backup para registros
  inválidos, preservando o formato de save existente.
- Renovação da loja por 25 moedas; redução de exploração econômica.
- HUD mais compacto e barra de experiência com preenchimento correto.
- Novos testes de regressão de batalhas, equipamentos, XP e mercado.

**Auditoria de código e limitações restantes:**
[docs/AUDITORIA_V1_3.md](docs/AUDITORIA_V1_3.md).

**Atenção às atualizações no Android:** esta distribuição automatizada ainda
não configura uma chave de assinatura própria e persistente. Instalar o APK
sobre versões anteriores pode falhar por assinatura diferente. Antes de
desinstalar uma versão com progresso salvo, configure assinatura estável e
um procedimento de exportação do save.

## Recursos implementados

- Combate visual **por turnos**: ataque rápido, golpe pesado, defesa e finta; vigor, esquiva, crítico, combo, histórico de dano e efeitos.
- 3 regiões de expedição (Campânia, Porto de Óstia e Ruínas de Vulcano), **9 inimigos e 3 chefes**; áreas desbloqueadas ao derrotar chefes anteriores.
- Arena com **3 rivais persistentes**, cuja força e saúde aumentam depois de cada derrota.
- **4 contratos diários** com recompensas em ouro e experiência.
- Mercador, saque, inventário de 40 espaços, 5 raridades, **ferreiro até +5**, 8 espaços de equipamento.
- Personagem modular/paper doll com arte hi-bit detalhada em 128×144, base e 6 sobreposições de armadura e acessórios; fundos de ambiente por região.
- Som de espada, defesa e vitória sintetizado de forma original, sem arquivos protegidos.
- **Salvamento offline retrocompatível** com a chave `gladiatus_pixel_save_v2`. Campos novos têm valores padrão quando o save foi criado na v1.0.
- UI otimizada para navegação em 5 abas no Android.

## Arquitetura

- `lib/main.dart`: estado de jogo, economia e navegação;
- `lib/models/gear.dart`: itens, raridades, gerador e reforja;
- `lib/systems/combat.dart`: regras determinísticas de batalha (testáveis sem interface);
- `lib/systems/content.dart`: regiões, inimigos, chefes, rivais e contratos;
- `lib/screens/battle_screen.dart`: batalha com animações, sons e controles;
- `lib/widgets/`: UI romana e gladiador em camadas;
- `tools/generate_sprites.py`: 17 sprites 24–36px da primeira versão;
- `tools/generate_hd_sprites.py`: 15 sprites e fundos usados para inimigos e ambientes;
- `assets/hero/atlas_128x144.webp.b64`: arte hi-bit compactada de referência (base, botas, luvas, armadura, capacete, arma, escudo e traje completo);
- `tools/extract_hero_art.py`: extrai a arte 128×144 do atlas para 8 PNGs com transparência;
- `tools/verify_hero_assets.py`: valida enquadramento e gera uma comparação de 3 poses;
- `tools/generate_audio.py`: 3 efeitos WAV PCM originais.

O projeto mantém Flutter na interface. Optamos por **não adicionar Flame** neste ciclo, pois as animações são curtas e bem atendidas pelos widgets nativos; isso evita aumentar as dependências e a complexidade do APK.

## Como compilar / baixar o APK

O workflow `.github/workflows/build-apk.yml`:
1. Gera 33 PNGs transparentes/imagens, incluindo os 8 sprites hi-bit do personagem, e 3 áudios WAV;
2. Cria o projeto Android no runner GitHub;
3. Executa `flutter analyze` e todos os testes, incluindo a simulação de 1.000 batalhas;
4. Compila `app-release.apk` e publica em **Actions → Artifacts**, junto com uma prévia de arte 128×144.

[Execuções do GitHub Actions](https://github.com/pinelis141/Gladiatus-pixel/actions)

Descompacte o artifact `Gladiatus-Pixel-Art-APK` para instalar o `app-release.apk`. O APK utiliza assinatura de release padrão de build gerada no runner enquanto não configuramos assinatura própria para distribuição na Play Store.

## Desenvolvimento local

Requisitos: Python 3, Pillow, Flutter, Java 17 e Android SDK.

```bash
python -m pip install Pillow
python tools/generate_sprites.py
python tools/generate_hd_sprites.py
python tools/extract_hero_art.py
python tools/verify_hero_assets.py
python tools/generate_audio.py
flutter create --platforms=android --org com.roma.gladiatus --project-name gladiatus_pixel .
flutter pub get
flutter test
flutter build apk --release
```

## Licenças e referências open source

- **Sprites e áudio desta versão**: gerados pelos scripts originais do próprio projeto, sem dependência de assets copiados de jogos comerciais.
- **Flutter**: BSD-style; **audioplayers**: licença MIT de seus mantenedores, disponíveis na distribuição das dependências.
- Recursos **estudados, mas não copiados**: [Flame Engine](https://github.com/flame-engine/flame), [Kenney CC0](https://kenney.nl/assets), [Darkness Dungeon](https://github.com/RafaelBarbosatec/darkness_dungeon), [Game-icons](https://github.com/game-icons/icons). Os materiais Kenney podem ser reutilizados sob CC0 em versões futuras, mas ainda não foram incorporados.

## Próximos desafios de qualidade

Esta versão ainda é um protótipo offline. Faltam testes em diferentes aparelhos Android reais, acessibilidade, opções de volume, variedade maior de animações e telemetria para calibrar a curva econômica com jogadores.
