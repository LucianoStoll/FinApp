# Banco de Dados — FinApp

## Estratégia

SQLite + Drift, offline-first. A base local é a fonte de verdade operacional. O schema nasce preparado para evolução e sincronização futura.

## Convenções

Entidades sincronizáveis usam UUID e, conforme aplicável, createdAt, updatedAt, deletedAt, deviceId e syncVersion. Timestamps técnicos ficam em UTC. Dinheiro usa inteiros na unidade mínima da moeda, nunca double como representação persistente principal.

## Núcleo do MVP

### accounts
ID, nome, tipo, moeda, saldo inicial, dados opcionais conforme tipo, ícone/cor, estado ativo/arquivado, visibilidade em análises, cheque especial opcional e metadados. Dinheiro/carteira é apenas um tipo de conta.

### categories
ID, nome curto/completo, tipo, parentId, ícone, cor, aliases, arquivamento e metadados.

### transactions
ID, descrição, descrição bruta opcional, tipo, valor previsto, valor realizado opcional, competência, vencimento, efetivação, conta, categoria/subcategoria, flags ignoreBalance/ignoreAnalytics e metadados. Atraso deve ser derivado quando possível.

### transfers
Entidade/operação própria ligando origem e destino. Começa simples no MVP e evolui para tarifas, moedas distintas, estados e datas diferentes.

## Saldos

Saldo atual = saldo inicial + movimentos efetivados que afetam saldo.

Saldo projetado = saldo atual + movimentos futuros/pendentes considerados.

Transferência move patrimônio entre contas e não é receita/despesa.

## Evoluções previstas

Adicionar por migrations, não antecipar todas no MVP: rateios, liquidações, reembolsos, recorrências, parcelamentos, cartões/faturas, orçamentos/versionamento, metas/planos, pessoas, estabelecimentos, tags N:N, dívidas, amortizações, renegociações, bens/avaliações, investimentos/cotações, anexos, auditoria, notificações, relatórios salvos, filtros e change log de sync.

## Rateio e liquidações

Uma transação permanece única; allocations distribuem seu valor entre categorias/subcategorias sem duplicar despesa.

Uma obrigação pode possuir várias liquidações. Cada liquidação pode decompor principal, juros, multa, tarifa, desconto e outros componentes.

## Reembolsos

Reembolso é vinculado à despesa original e à pessoa, com valor esperado/recebido e datas. Relatórios podem exibir bruto e líquido sem apagar o fluxo real.

## Cartões

Card e CardInvoice são entidades próprias. Pagamento de fatura é liquidação/fluxo de caixa, não nova despesa. Limite é independente por cartão. Saldo credor é separado de limite.

## Multimoeda

Conta possui moeda; perfil possui moeda base. Conversões preservam valor/moeda original, cotação e convertido. Taxas são estruturadas. Cotações externas são cacheáveis.

## Exclusão e lixeira

Soft delete/tombstone suporta lixeira e sync. Entidades históricas como categorias usadas são arquivadas. Limpeza automática da lixeira é opcional.

## Migrations

Fluxo: backup → migration → validação → confirmação; em falha, rollback/restauração segura.

## Backup

Backup automático local diário, mantendo 3 versões recentes. Restauração valida integridade/compatibilidade e cria backup do estado atual.

## Anexos

Conteúdo em armazenamento interno; banco guarda metadados como ID, entidade, nome original, MIME/type, tamanho, hash e chave/caminho. Limite inicial de 20 MB. Hash prepara integridade/deduplicação.

## Sync

Metadados suportam Last Write Wins com registro de conflito. SyncProvider é infraestrutura, não domínio. Tombstones permanecem até descarte seguro.

## Implementação v1 (Issue #18)

O arquivo `lib/core/database/schema_v1.dart` contém o schema inicial imutável:
`accounts`, `categories`, `transactions` e `transfers`. A classe
`AppDatabase` abre `finapp.sqlite` no diretório de suporte do aplicativo,
usa Drift sobre SQLite em isolate de fundo e é registrada em `get_it` antes
que a interface seja exibida. O schema v1 usa SQL explícito por meio de Drift;
as DAOs tipadas das próximas issues podem ser adicionadas sem alterar esta
versão publicada.

- IDs são UUID v4 gerados por `EntityMetadata.newId()`; a geração é feita na
  aplicação, inclusive em operações offline.
- Valores são `INTEGER` em unidades mínimas (`*_minor`). Para BRL, 12345
  representa R$ 123,45. Não grave `double` nem valor formatado.
- `created_at`, `updated_at` e `deleted_at` são epoch em milissegundos UTC;
  `device_id` e `sync_version` preparam sincronização, sem habilitá-la.
- Chaves estrangeiras são ativadas em toda abertura. Exclusão lógica usa
  `deleted_at`; referências históricas usam `ON DELETE RESTRICT`.
- `schemaVersion` é 3. Novas versões entram como passos sequenciais em
  `onUpgrade`; o schema da v1 permanece imutável. Uma versão sem migration
  explícita falha, preservando o banco anterior.

### Procedimento para uma migration futura

Antes de uma migration que altera ou remove dados, criar uma cópia consistente
com `VACUUM INTO` em arquivo separado, verificar espaço e manter esse backup
até a validação. Adicionar um case sequencial em `onUpgrade`, executar as
mudanças em transação, validar `PRAGMA foreign_key_check` e testar abertura
nova, atualização a partir de versões anteriores e falha com rollback. Não
usar migration destrutiva. Se a validação falhar, manter o arquivo de backup
para restauração explícita; não sobrescrever automaticamente dados do usuário.
A versão 1 cria uma base nova, então ainda não há dados anteriores para copiar.

Validação local: `flutter pub get`, `dart format lib test`, `flutter analyze`
e `flutter test test/core/database/app_database_test.dart`. O `pubspec.lock`
deve ser atualizado pelo `flutter pub get` na máquina de desenvolvimento ao
adicionar as dependências desta issue.

### v2 — contas financeiras

A migration v1→v2 adiciona gatilhos que rejeitam novos lançamentos e
transferências quando a conta está arquivada ou excluída. Transferências
entre moedas diferentes também são rejeitadas enquanto não houver conversão
implementada. A migration é aditiva e preserva os dados existentes; o teste
automatizado abre uma base v1 real, migra para v2 e confere o saldo.

O saldo atual de uma conta é o saldo inicial mais receitas efetivadas menos
despesas efetivadas, usando valor realizado e ignorando lançamentos pendentes,
removidos ou marcados para não afetar saldo. Transferências efetivadas reduzem
a origem e aumentam o destino. O campo `include_in_analytics` é independente
do saldo e prepara os relatórios posteriores.

### v3 — categorias e subcategorias

A migration v2→v3 acrescenta `icon_key` e `color_argb` à tabela existente,
sem reescrever categorias ou vínculos. Subcategorias têm apenas um nível:
`parent_id` aponta para categoria principal do mesmo tipo. Os gatilhos do
SQLite rejeitam vínculos inválidos e novos lançamentos em categoria arquivada,
excluída, de tipo diferente ou com principal arquivada. Lançamentos antigos
mantêm `category_id` e continuam no histórico. Arquivar uma categoria principal
arquiva suas subcategorias ativas em transação; reativá-la não reativa
automaticamente as filhas.
