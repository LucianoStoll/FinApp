# Banco de Dados — FinApp

## Estratégia

SQLite + Drift, offline-first. O schema começa pequeno para o MVP, mas utiliza decisões que evitam bloqueios futuros.

## Campos comuns

Entidades sincronizáveis devem suportar, conforme aplicável:

| Campo | Uso |
|---|---|
| id | UUID global |
| createdAt | criação |
| updatedAt | última alteração |
| deletedAt | tombstone/exclusão lógica |
| deviceId | origem da alteração |
| syncVersion | revisão para sync |

Timestamps de sincronização devem ser normalizados consistentemente.

## Valores monetários

Não persistir dinheiro como `double`. Usar unidade mínima inteira associada à moeda. Para BRL:

```text
R$ 125,90 → 12590
```

O desenho deve comportar moedas cuja unidade mínima não siga exatamente duas casas.

## MVP

### accounts
Conceitualmente:
- id;
- name;
- type;
- currencyCode;
- initialBalanceMinor;
- archivedAt/status;
- configuração de visibilidade em totais/análises;
- metadados comuns.

Conta em espécie é uma conta normal com tipo/dados cadastrais diferentes. Conta arquivada não recebe novos lançamentos e pode ser reativada.

### categories
- id;
- name;
- shortName opcional;
- parentId opcional;
- icon/color;
- aliases;
- archivedAt/status;
- metadados comuns.

Categorias com histórico são arquivadas, não destruídas. Subcategorias preservam vínculo/histórico.

### transactions
O MVP implementa somente o necessário, mas o modelo deve evoluir para:
- descrição;
- valor;
- tipo;
- accountId;
- categoryId/subcategoryId;
- competenceDate;
- dueDate;
- effectiveDate;
- status;
- ignoreBalance;
- ignoreAnalytics;
- valor previsto x realizado;
- metadados comuns.

`Atrasada` pode ser derivada de vencimento + ausência de efetivação, evitando estado redundante quando adequado.

### transfers
Transferência deve possuir identidade própria e movimentos vinculados, evitando contabilização como receita/despesa. Taxas são despesas separáveis.

## Evoluções previstas do modelo

- recurrence/series;
- installments;
- settlements/liquidações parciais;
- cards/invoices/card purchases;
- splits/rateios;
- reimbursements;
- people;
- tags;
- merchants;
- budgets e versões;
- goals/plans;
- assets;
- debts/loans;
- investments/quotes;
- attachments;
- audit log;
- operation history/undo;
- trash;
- sync state.

## Rateio

Uma transação principal pode possuir N divisões internas por valor ou percentual. A soma das divisões deve fechar o valor aplicável. O rateio não duplica a transação no saldo.

## Liquidações

Uma obrigação pode possuir várias liquidações, cada uma com data, valor, juros, multa, desconto e acréscimos. O modelo preserva valor original, total liquidado e saldo restante. A mesma abstração pode atender contas a pagar/receber e antecipações/pagamentos de fatura.

## Cartões

Fatura é entidade própria. Compras são despesas; pagamento de fatura é liquidação/transferência financeira e não uma segunda despesa. Limite e saldo credor são conceitos separados. Parcelamento compromete o valor total do limite e libera conforme regras de pagamento.

## Lixeira e exclusão

Exclusão de registros sincronizáveis usa tombstone. A lixeira pode reter itens indefinidamente por padrão e ter limpeza automática opcional. Exclusão definitiva exige confirmação.

## Anexos

Conteúdo fica na área interna do FinApp; banco armazena metadados, vínculo, tamanho, tipo e hash. Limite inicial por arquivo: **20 MB**. Hash permite integridade/deduplicação futura.

## Backup

Backup local automático diário; manter **3 versões** recentes por padrão. Restauração valida integridade/compatibilidade e cria backup do estado atual antes de substituir a base.
