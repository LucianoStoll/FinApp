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
