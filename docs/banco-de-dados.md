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

## Revisão do MVP — três datas e atualização segura

A revisão de 29/09/2026 torna obrigatórias três datas financeiras para **receitas, despesas e transferências**:

- `launch_at`: data de lançamento escolhida pelo usuário;
- `due_at`: data de vencimento;
- `effective_at`: data usada para contabilização no saldo realizado.

`created_at` continua sendo somente metadado técnico de criação e não substitui `launch_at`.

### Regras de cálculo

- saldo realizado/atual considera apenas movimentos cuja `effective_at` esteja dentro do corte consultado;
- movimento com `effective_at` futura não altera o saldo realizado antes dessa data;
- saldo projetado considera movimentos pendentes/futuros usando `due_at`;
- ao efetivar antecipadamente um movimento futuro, a aplicação permite definir `effective_at` como hoje ou como o vencimento;
- transferências aplicam a mesma regra temporal nas duas contas e continuam fora das receitas/despesas.

### Migration

A alteração deve entrar por migration aditiva, preservando os registros existentes. Não recriar nem apagar o banco para acomodar o novo schema. Campos antigos de data devem ser migrados para defaults compatíveis e documentados, evitando perda ou mudança silenciosa de histórico.

Também faz parte da validação do MVP testar a abertura de uma base criada por uma versão anterior do app, executar a migration e confirmar que contas, categorias, receitas, despesas e transferências continuam disponíveis.

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
- `schemaVersion` é 4. Novas versões entram como passos sequenciais em
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

### Issue #21 — receitas e despesas

`transactions` registra o valor previsto em unidades mínimas. Um movimento
efetivado também registra o valor realizado (igual ao previsto nesta etapa) e
`effective_at`; um pendente mantém ambos nulos e não afeta o saldo atual.
`competence_at` representa a data escolhida para o lançamento em UTC (início
do dia). A exclusão é lógica (`deleted_at`) e remove o movimento dos saldos e
da lista sem quebrar o histórico de categorias ou contas. Atualizações de
valor, data e descrição em movimentos históricos podem ser feitas mesmo após
arquivamento da conta/categoria; mudar vínculos exige destino ativo.

A lista oferece filtros de tipo, conta, categoria, estado e período. A
persistência e os cálculos continuam locais; sincronização não é necessária.

### Issue #22 — transferências entre contas

`transfers` guarda uma única operação com conta de origem, conta de destino,
valor e estado. Quando efetivada, a consulta de saldos subtrai da origem e
soma no destino; a operação não entra em `transactions` nem em receitas ou
despesas. Transferências pendentes não alteram o saldo atual. A exclusão
lógica retira as duas pontas do cálculo. O MVP aceita somente contas distintas
com a mesma moeda, sem tarifa ou conversão.

A migration v3→v4 acrescenta `planned_at` a `transfers`, preserva as linhas
existentes e preenche a data a partir de `effective_at` ou `created_at`. Assim,
a data selecionada também persiste para uma transferência pendente. Atualizar
valor ou data de um registro histórico não exige reativar contas arquivadas;
trocar uma das contas exige uma conta ativa.

### Issue #23 — saldos atual e projetado

Uma consulta compartilhada calcula os saldos por conta. O saldo atual parte do
saldo inicial, adiciona receitas realizadas, subtrai despesas realizadas e
aplica transferências efetivadas nas duas contas. Lançamentos excluídos e com
`ignore_balance = 1` ficam fora do cálculo. O saldo projetado adiciona as
receitas/despesas pendentes pelo valor previsto e as transferências pendentes;
é possível limitar essas pendências pela data planejada, inclusive a data
escolhida. Sem limite, considera todas as pendências. O consolidado inclui
contas arquivadas com histórico e agrupa por moeda, sem converter ou somar
moedas diferentes. `include_in_analytics` não altera saldo patrimonial.

### Issue #24 — dashboard básico

O resumo mensal apresenta saldo atual/projetado por moeda, receitas e despesas
efetivadas no mês de competência e as cinco movimentações recentes, incluindo
transferências sem contá-las como receita ou despesa. Os totais mensais respeitam
`ignore_analytics` e `include_in_analytics`; saldos seguem a regra patrimonial
da #23. Uma leitura transacional mantém os cartões e a lista coerentes durante
a atualização. Navegar de volta ao início, retomar o aplicativo, atualizar
manualmente ou puxar a lista recarrega o banco local sem reiniciar o app. Os
cartões se adaptam à largura disponível no Android e no Windows.

Os saldos em destaque usam o último dia do mês selecionado como corte: somente
movimentos efetivados até essa data entram no saldo atual, e a projeção adiciona
apenas movimentos planejados até a mesma data que ainda não estavam efetivados
naquele momento. Um lançamento de dezembro não altera os saldos mostrados em
outubro. A tela de Contas permanece com a posição atual sem corte mensal.
