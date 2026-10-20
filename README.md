# Gladiatus Pixel

Protótipo de RPG romano para Android, desenvolvido em Flutter com pixel art.

## Recursos implementados
- Gladiador com equipamento visual em camadas (paper doll)
- Personagem com atributos, vida, energia e progressão por níveis
- Expedições e arena contra adversários controlados pelo jogo
- Inventário de 40 espaços com equipamentos e raridades
- Mercador com compra e venda por ouro
- Taverna para recuperar vida e energia
- Salvamento local com Shared Preferences
- Geração de 17 sprites PNG pelo Pillow

## Como obter o APK
No GitHub, abra **Actions > Build Gladiatus APK**. Após a execução bem-sucedida, baixe o artifact **Gladiatus-Pixel-Art-APK**. O arquivo dentro do ZIP se chama `app-release.apk`.

O workflow cria o esqueleto Android usando `flutter create` no runner, gera os sprites, executa análise e teste e compila o aplicativo em modo release.

## Desenvolvimento local
Requisitos: Flutter estável, Android SDK, Python 3 e Pillow.

```bash
python3 -m pip install pillow
python3 tools/generate_sprites.py
flutter create --org com.roma.gladiatus --project-name gladiatus_pixel .
flutter pub get
flutter run
```

Este projeto é uma implementação independente e inicial, não é o jogo online original Gladiatus nem inclui servidores, contas ou multijogador.
