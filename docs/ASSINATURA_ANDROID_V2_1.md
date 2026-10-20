# Assinatura Android permanente — Gladiatus Pixel v2.1

## Diagnóstico confirmado

As versões anteriores do projeto eram construídas a partir de
`flutter create` e mantinham no Gradle a configuração
`signingConfig = signingConfigs.getByName("debug")`.
Em CI, chaves de depuração não são uma identidade de publicação persistente.

**Importante:** sem a chave privada anterior, é impossível produzir um APK
que o Android aceite como uma atualização da instalação antiga.
Um certificado público extraído de APK **não contém** a chave privada.
Criar um certificado estável agora impede esse problema **nas próximas
atualizações**, mas não altera a assinatura dos APKs antigos.

## Nova solução

A versão v2.1 `2.1.0+6` usa a identidade estável:

- Package ID: `com.roma.gladiatus.gladiatus_pixel`
- Formato da chave: `PKCS12`, RSA 3072, alias `gladiatus_release`
- SHA-256 público do certificado:
  `74ea35c6b35690ab025343b42a046b18cd4ebdb08fecb6fd8e99cc72472187f6`
- O valor é fixado no arquivo público
  `tools/expected_release_cert.sha256`.

A chave privada **não existe no repositório**.

O GitHub Actions deve receber exatamente dois secrets de repositório:

1. `GLADIATUS_KEYSTORE_BASE64`: conteúdo integral do arquivo
   `01_GLADIATUS_KEYSTORE_BASE64.txt`.
2. `GLADIATUS_KEYSTORE_PASSWORD`: conteúdo de
   `02_GLADIATUS_KEYSTORE_PASSWORD.txt`.

### Configurar no GitHub (somente proprietário)

1. Baixe o pacote privado da chave entregue ao proprietário por canal privado
   e guarde uma cópia offline em local seguro.
2. No GitHub, vá a `Settings → Secrets and variables → Actions → New repository secret`.
3. Crie `GLADIATUS_KEYSTORE_BASE64`, copiando seu texto do arquivo indicado.
4. Crie `GLADIATUS_KEYSTORE_PASSWORD`, copiando seu texto.
5. Em `Actions → Audit Before APK → Run workflow`, escolha `main`
   e inicie a execução. Primeiro roda a auditoria de sprites,
   `flutter analyze` e testes; depois a compilação assinada.
6. Só compartilhe o APK quando o **job Android** estiver verde e publicar
   o artefato `Gladiatus-Pixel-APK-Assinado`, acompanhado do SHA-256 do APK.

**Nunca** cole o conteúdo desses arquivos em issues, chats públicos,
repositórios, commits, PRs, logs ou screenshots. Não compartilhe a
senha nem o keystore separadamente.

## Barreiras de segurança no código

- `tools/configure_android_signing.py`: recusa gerar release sem os dois
  secrets, recusa certificados diferentes do fingerprint esperado, confere
  keystore via `keytool`, configura apenas signingConfig `release`
  no Kotlin Gradle e apaga qualquer vestígio se a senha/alias forem inválidos.
- `tools/verify_android_signature.py`: usa `apksigner verify`, compara
  SHA-256 do certificado ao valor fixado e gera SHA-256 do APK.
- `.gitignore`: ignora senhas, keystores, PKCS12 e Android gerado.
- Workflow: `needs: audit` exige todos os testes ANTES do build;
  somente publica artifact se as verificações forem aprovadas.
- Após cada execução, a chave do runner é apagada pelo passo
  `if: always()`. O runner temporário também é descartado.
- Testes unitários automatizados verificam a recusa de assinatura sem
  segredo, Base64 inválido, assinatura com chave divergente e a configuração
  correta de release. Esses testes usam credenciais fictícias.

## Atualizações, dados salvos e primeira migração

Atualizações Android precisam combinar **ID de aplicativo, certificado
assinante e versionCode**. Aqui o ID é preservado e o versionCode aumenta,
mas o certificado novo difere das versões anteriores assinadas em CI
com chave debug efêmera.

Portanto, a migração da versão 2.0 ou anterior para 2.1 pode falhar com
`INSTALL_FAILED_UPDATE_INCOMPATIBLE`.

**Se houver progresso importante, não desinstale o aplicativo antigo até
existir uma cópia recuperável dos dados.** Os saves ficam armazenados em
SharedPreferences do sandbox Android; a compatibilidade JSON do jogo não
basta se o Android rejeitar atualizar um APK com outra assinatura.

A partir da **primeira instalação da versão 2.1 com assinatura fixa**, as
novas versões assinadas pelo mesmo keystore poderão atualizar por cima sem
essa incompatibilidade (desde que versionCode aumente).

Não é possível extrair a chave privada das versões antigas apenas dos APKs.
A recuperação do save antigo é uma tarefa separada que pode exigir acesso
ao dispositivo ou ao mecanismo de backup. Não há promessa de migração
automática sem a chave anterior.

## Recuperação e custódia

Preserve **duas cópias offline criptografadas** do pacote da assinatura.
Se perder a senha e o keystore, futuras atualizações da instalação assinada
não serão possíveis. Se a chave for exposta, gere outra identidade e
planeje migração; não faça rotação silenciosa alterando o fingerprint.
