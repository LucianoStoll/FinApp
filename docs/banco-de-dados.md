# Banco de Dados — FinApp

## Tecnologia

O MVP utilizará banco local **SQLite**. A integração com Dart/Flutter está planejada por meio do **Drift**, permitindo consultas tipadas e uma camada organizada de persistência.

> Este documento representa a modelagem inicial. O schema definitivo será versionado conforme a implementação.

## Entidades principais

### Conta (`accounts`)

Campos iniciais sugeridos:

| Campo | Tipo conceitual | Descrição |
|---|---|---|
| id | inteiro | Identificador único |
| name | texto | Nome da conta |
| type | texto/enum | Carteira, banco etc. |
| initialBalance | decimal | Saldo existente antes das transações registradas |
| createdAt | data/hora | Data de criação |

### Categoria (`categories`)

| Campo | Tipo conceitual | Descrição |
|---|---|---|
| id | inteiro | Identificador único |
| name | texto | Nome da categoria |
| type | enum | Receita ou despesa |
| parentId | inteiro opcional | Categoria pai quando representar uma subcategoria |

Usar uma referência `parentId` permite tratar categorias e subcategorias com a mesma estrutura em vez de armazenar a subcategoria como texto livre.

### Transação (`transactions`)

| Campo | Tipo conceitual | Descrição |
|---|---|---|
| id | inteiro | Identificador único |
| description | texto | Descrição da movimentação |
| amount | decimal | Valor da movimentação |
| date | data/hora | Data da movimentação |
| type | enum | Receita ou despesa |
| accountId | inteiro | Conta relacionada |
| categoryId | inteiro | Categoria/subcategoria relacionada |
| createdAt | data/hora | Data de criação do registro |

## Relacionamentos

```text
Account 1 ───── N Transaction

Category 1 ──── N Transaction

Category 1 ──── N Category
              (subcategorias)
```

Uma conta pode possuir várias transações. Uma categoria pode ser utilizada por várias transações e, quando aplicável, possuir subcategorias.

## Saldo

O saldo de uma conta não precisa ser mantido como um valor manual independente. Conceitualmente:

```text
saldo atual = saldo inicial + receitas - despesas
```

O saldo total apresentado no dashboard corresponde à soma dos saldos das contas consideradas no cálculo.

## Valores monetários

Durante a implementação deverá ser definida uma representação segura para valores financeiros. Deve-se evitar depender de comparações de ponto flutuante sem considerar suas limitações. Uma opção é persistir valores na menor unidade monetária (centavos) como inteiro e convertê-los apenas para apresentação.

Exemplo:

```text
R$ 125,90 → 12590 centavos
```

## Integridade

A implementação deve definir explicitamente o comportamento ao excluir contas ou categorias que possuam transações. Não é recomendável apagar silenciosamente o histórico financeiro. Alternativas incluem impedir a exclusão ou utilizar arquivamento lógico.

## Privacidade e offline-first

No MVP, o SQLite será a fonte local dos dados. O aplicativo não dependerá de API remota para registrar ou consultar as informações financeiras essenciais.

Backup e sincronização serão funcionalidades posteriores e não devem comprometer o funcionamento offline.
