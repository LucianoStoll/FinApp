# Atualização do APK do Somia (MVP)

O identificador Android permanece `com.example.finapp`. Não altere esse valor
durante o ciclo `v0.1.0-alpha`: o Android usa identificador e assinatura para
decidir se um APK pode atualizar uma instalação existente.

## Configurar a chave persistente uma única vez

Gere a chave em uma máquina de confiança e mantenha uma cópia privada dela e
da senha fora do repositório. Use o alias `somia` e a mesma senha para o
keystore e a chave:

```sh
keytool -genkeypair -v -keystore somia-upload.jks -alias somia \
  -keyalg RSA -keysize 3072 -validity 10000
```

Em **Settings → Secrets and variables → Actions** do repositório, crie:

- `SOMIA_KEYSTORE_B64`: conteúdo Base64 do arquivo `somia-upload.jks`;
- `SOMIA_KEYSTORE_PASSWORD`: senha usada na geração.

No PowerShell, obtenha o primeiro valor com
`[Convert]::ToBase64String([IO.File]::ReadAllBytes('somia-upload.jks'))`.
Não publique a chave, a senha nem o Base64 em issues, commits ou logs.

**Estado atual:** a geração de APK está pausada a pedido do usuário. Depois de
criar a chave e avisar, reativaremos a etapa Android no workflow e validaremos
os APKs consecutivos. O procedimento abaixo descreve o comportamento após a
reativação.

A Action
decodifica a chave apenas no runner e a usa para assinar o APK release. Quando
os Secrets ainda não existem, a Action publica somente o artefato
`somia-debug-not-updateable`; ele não é o APK de atualização.

O APK de atualização estará em **Actions → Flutter CI → Artifacts →
`somia-signed-apk`**. O `versionCode` é o número crescente da execução do
workflow; o `versionName` continua `0.1.0-alpha`. Confira que duas execuções
consecutivas publicam APKs com o mesmo certificado e números de versão
crescentes. A chave privada não deve ser recriada nas execuções futuras.

Se o APK atualmente instalado tiver outra assinatura, será necessária uma
última reinstalação para adotar essa chave. Antes, exporte um backup em
**Ajustes → Exportar backup**, salve o arquivo fora do dispositivo e restaure
em **Ajustes → Restaurar backup** após a instalação. Nas atualizações seguintes,
instale o novo APK sobre o anterior e confirme que Android oferece
**Atualizar** e que os dados permanecem.

## Backup local

O botão Exportar cria um snapshot SQLite consistente da base em uso e abre o
seletor do sistema para salvar o arquivo. Restaurar valida integridade,
relações e schema do arquivo, migra cópias antigas até o schema atual e prepara
a substituição. Feche e abra o Somia para aplicar a restauração. A base anterior
fica guardada localmente como `finapp.before-restore.sqlite` para recuperação
técnica. O arquivo exportado contém dados financeiros sem criptografia;
guarde-o em local privado.

Valide no Android: criar conta, categoria, receita, despesa e transferência;
exportar; instalar dois APKs assinados consecutivos; conferir os dados; e
restaurar o backup em uma instalação de teste. Repita o fluxo de backup no
Windows.
