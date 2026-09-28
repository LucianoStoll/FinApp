# Banco de Dados — FinApp

## Estratégia

O FinApp será **offline-first**. O banco local **SQLite**, acessado por meio do **Drift**, será a fonte primária para leitura e escrita no dispositivo. Nenhuma operação financeira essencial deverá depender de internet.

A modelagem do MVP já será preparada para uma futura sincronização entre Android e Windows, inicialmente planejada por meio do Google Drive, sem tornar a nuvem obrigatória.

## Princípios

1. Toda alteração é salva primeiro no SQLite local.
2. Sincronização é opcional e posterior ao salvamento local.
3. Ausência de internet nunca impede o uso normal do app.
4. Registros devem possuir identificadores globais para evitar colisões entre dispositivos.
5. Alterações e exclusões precisam ser rastreáveis para sincronização futura.
6. O domínio não deve depender diretamente do Google Drive, permitindo outros provedores futuramente.

## Identificadores

As entidades sincronizáveis utilizarão **UUID** como identificador principal em vez de IDs inteiros autoincrementais.

Exemplo:

```text
550e8400-e29b-41d4-a716-446655440000
```

Assim, Android e Windows podem criar registros offline sem risco prático de gerar o mesmo identificador.

## Campos comuns de sincronização

As entidades sincronizáveis deverão possuir, conforme aplicável:

| Campo | Finalidade |
|---|---|
| id | UUID global do registro |
| createdAt | Data/hora de criação |
| updatedAt | Última alteração |
| deletedAt | Exclusão lógica (tombstone), quando aplicável |
| deviceId | Dispositivo que originou a última alteração |
| syncVersion | Versão/revisão usada pelo mecanismo de sincronização |

Datas usadas para sincronização devem ser persistidas de forma consistente, preferencialmente normalizadas em UTC.

## Conta (`accounts`)

| Campo | Tipo conceitual | Descrição |
|---|---|---|
| id | UUID | Identificador global |
| name | texto | Nome da conta |
| type | enum/texto | Carteira, banco etc. |
| initialBalanceCents | inteiro | Saldo inicial em centavos |
| createdAt | data/hora | Criação |
| updatedAt | data/hora | Última alteração |
| deletedAt | data/hora opcional | Exclusão lógica |
| deviceId | UUID/texto | Origem da alteração |
| syncVersion | inteiro | Revisão de sincronização |

## Categoria (`categories`)

| Campo | Tipo conceitual | Descrição |
|---|---|---|
| id | UUID | Identificador global |
| name | texto | Nome da categoria |
| type | enum | Receita ou despesa |
| parentId | UUID opcional | Categoria pai para subcategorias |
| createdAt | data/hora | Criação |
| updatedAt | data/hora | Última alteração |
| deletedAt | data/hora opcional | Exclusão lógica |
| deviceId | UUID/texto | Origem da alteração |
| syncVersion | inteiro | Revisão de sincronização |

## Transação (`transactions`)

| Campo | Tipo conceitual | Descrição |
|---|---|---|
| id | UUID | Identificador global |
| description | texto | Descrição da movimentação |
| amountCents | inteiro | Valor em centavos |
| date | data/hora | Data da movimentação |
| type | enum | Receita ou despesa |
| accountId | UUID | Conta relacionada |
| categoryId | UUID | Categoria/subcategoria relacionada |
| createdAt | data/hora | Criação |
| updatedAt | data/hora | Última alteração |
| deletedAt | data/hora opcional | Exclusão lógica |
| deviceId | UUID/texto | Origem da alteração |
| syncVersion | inteiro | Revisão de sincronização |

## Relacionamentos

```text
Account 1 ───── N Transaction
Category 1 ──── N Transaction
Category 1 ──── N Category
              (subcategorias)
```

## Valores monetários

Valores financeiros serão armazenados preferencialmente em **centavos como inteiro**, evitando problemas de precisão de ponto flutuante.

```text
R$ 125,90 → 12590
```

## Saldo

```text
saldo atual = saldo inicial + receitas - despesas
```

O saldo será derivado dos dados financeiros válidos, desconsiderando registros marcados como excluídos.

## Exclusão lógica

Entidades sincronizáveis não devem ser removidas fisicamente imediatamente. Ao excluir um registro:

```text
deletedAt = instante da exclusão
updatedAt = instante da exclusão
```

Esse tombstone permite que outro dispositivo descubra que o registro foi removido. Uma política futura poderá eliminar tombstones antigos somente quando for seguro.

## Preparação para conflitos

`updatedAt`, `deviceId` e `syncVersion` fornecem metadados para o mecanismo de sincronização. A primeira estratégia poderá utilizar Last Write Wins, mas a arquitetura não deve impedir a adoção posterior de detecção/resolução explícita de conflitos.

## Sincronização futura

O Google Drive será inicialmente considerado como provedor remoto, usando armazenamento específico do aplicativo. Entretanto, SQLite/Drift e os repositories não devem conhecer diretamente a API do Drive.

```text
SQLite/Drift
     ↕
Repositories
     ↕
Sync Engine
     ↕
Sync Provider
     ↕
Google Drive (inicialmente)
```

Essa abstração permitirá adicionar outros provedores no futuro sem alterar o banco ou as regras principais do aplicativo.
