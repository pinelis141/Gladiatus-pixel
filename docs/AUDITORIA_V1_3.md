# Auditoria do Gladiatus Pixel — v1.3 (2026-10-20)

## Abrangência

Revisão estática de todos os arquivos versionados em `lib/`, do workflow Android,
dos três geradores de assets, dos extratores e validadores HD e dos testes.
A interface foi confrontada com captura real de Android recebida do jogador.

**Importante:** compilar e executar testes unitários não equivale a testar a
experiência em todos os aparelhos. A auditoria não é garantia de ausência total
de defeitos, nem substitui análise de dependências e assinatura de release.

## Defeitos identificados e correções

| Gravidade | Falha | Tratamento |
|---|---|---|
| Alta | Gládio flutuava à esquerda do gladiador inicial | Reposicionamento da camada `equip_weapon_hd` no extrator; teste automático mede sobreposição do punho à mão |
| Alta | Múltiplas gravações de save sem ordem garantida | Fila de gravação, criando snapshot JSON sincronamente |
| Alta | Save inválido era substituído silenciosamente | Cópia `gladiatus_pixel_save_v2_corrupt_backup` antes de iniciar sessão de recuperação |
| Alta | Botão Voltar indisponível durante batalha | Recuo com confirmação e resultado distinto de derrota |
| Média | Golpe pesado sem vigor concedia recuperação dupla | Conversão determinística para uma única ação rápida |
| Média | Rival da arena escalava sem limite | Limite de bônus de rivalidade a dez degraus em vida, defesa e ataque |
| Média | Mercador atualizava 7 ofertas gratuitamente | Rerrolagem custa 25 moedas; opções e preço são persistidos |
| Média | Lojas ressorteadas toda vez que aplicativo reiniciava | Estado da vitrine incluído no save com compatibilidade com versões anteriores |
| Média | Barra de XP vazia usava preenchimento visual incorreto | `RomanProgress` dedicado, cores de track/XP explícitas e teste de regressão |
| Baixa | Forjar item sem atributos gastava ouro sem resultado prático | Primeiro reforço concede um atributo básico; testes |
| Baixa | Cabeçalho e linhas ocupavam altura excessiva | AppBar e atributos compactos |
| Baixa | Contratos alteravam estado durante build de Widget | Reset movido para eventos, navegação e progresso |

## Integridade de dados

- Chave de save mantida: `gladiatus_pixel_save_v2`, para **não reiniciar progresso por mudança de formato**.
- Dados novos: `shop` opcional em saves v1.2 antigos; inicialização compatível.
- Em caso de corrupção detectada por parser, o arquivo bruto original é copiado
  para uma chave de backup. O restante da sessão inicia provisoriamente.
- Escritas sequenciais evitam que uma gravação mais antiga finalize depois de
  uma gravação mais recente.

## Testes adicionados/estendidos

- 1.000 batalhas reproduzíveis com RNG injetado (já existiam).
- Golpe pesado com vigor 1: 1 rodada e só +1 vigor.
- Rivalidade 10 versus 100.000: vida, ataque e defesa limitados.
- Resultado de recuo não gera vitória.
- Itens sem atributos ganham melhoria ao forjar.
- Serialize/deserialize todos os slots.
- Barra de XP 0/30 na primeira sessão.
- Renovação paga da loja e conteúdo salvo.
- Teste de Pillow mede a interseção visual real da espada com a mão do
  gladiador e falha em caso de desalinhamento.
- Verificação de PNGs RGBA 128×144, scripts de assets, análise Flutter e APK
  executados em GitHub Actions.

## Limitações abertas — não considerar resolvidas

1. **Assinatura de atualização Android:** `flutter create` gera o projeto
   Android em cada execução. Sem keystore seguro e persistente em Secrets do
   GitHub Actions, o APK pode ser assinado por uma chave de teste diferente,
   impedindo atualização sobre versões anteriores e colocando o save em risco
   em caso de desinstalação. Configurar um keystore privado e assinatura
   estável antes de distribuição pública. Nunca subir a chave privada no repo.
2. **Teste em aparelho real:** interface, acessibilidade, rolagem, sons,
   economia, perda de foco e migração entre APKs precisam de QA manual.
3. **Arte modular:** transparência/alinhamento lógico verificados, mas clipping
   de equipamentos em todas as combinações precisa de revisão visual.
4. **Balanceamento:** combate automatizado testa limites e integridade; taxas
   de vitória, lucro por hora e dificuldade de chefes exigem telemetria
   ou testes humanos. O modo offline permite ajuste do relógio do aparelho,
   afetando contratos diários.
5. **Arquitetura:** `GameScreen` ainda concentra mutação de estado,
   persistência e UI. Refatorar futuramente para um controlador testável e
   repositório de storage, evitando uma reescrita arriscada nesta auditoria.
6. **Dependências:** CI usa Flutter `stable` móvel; ainda é preciso fixar
   versões do Flutter/Gradle e rodar verificação específica de vulnerabilidades
   e licenças para uma release distribuída amplamente.

## Fluxo de release

`audit/quality-balance-ux-v13` -> GitHub Actions verde -> Pull Request ->
`main` -> GitHub Actions verde -> artifact APK v1.3.

A instalação do APK foi automatizada, mas não houve execução interativa
em um celular físico pelo auditor.
