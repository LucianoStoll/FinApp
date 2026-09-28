# Arquitetura — FinApp

## Objetivo

O FinApp adotará uma arquitetura em camadas inspirada em Clean Architecture, simplificada para manter o projeto compreensível e adequado ao tamanho inicial da aplicação.

## Estrutura

```text
lib/
├── data/
│   ├── database/
│   └── repositories/
├── domain/
│   └── models/
├── presentation/
│   ├── screens/
│   └── widgets/
└── main.dart
```

## Camada `data`

Responsável pela persistência e obtenção dos dados.

### `data/database/`

Deverá concentrar a infraestrutura do banco local, incluindo:

- configuração do Drift/SQLite;
- definição das tabelas;
- DAOs;
- consultas locais;
- migrations do banco quando necessárias.

### `data/repositories/`

Os repositories funcionam como a interface utilizada pelo restante da aplicação para consultar e alterar dados. Dessa forma, a apresentação não precisa executar SQL nem conhecer detalhes internos do banco.

Repositories iniciais previstos:

```text
account_repository.dart
category_repository.dart
transaction_repository.dart
```

## Camada `domain`

Contém os conceitos centrais do negócio e deve evitar dependência direta da interface gráfica.

### `domain/models/`

Modelos iniciais:

```text
account_model.dart
category_model.dart
transaction_model.dart
```

Responsabilidades típicas:

- `Account`: representar uma conta financeira e seu saldo inicial;
- `Category`: representar categorias/subcategorias e seu tipo;
- `Transaction`: representar receitas e despesas.

## Camada `presentation`

Responsável pela experiência do usuário e interface Flutter.

### `presentation/screens/`

Telas inicialmente previstas:

```text
dashboard/
transactions/
accounts/
categories/
settings/
```

### `presentation/widgets/`

Componentes reutilizáveis, por exemplo:

```text
balance_card.dart
transaction_tile.dart
```

Um widget deve ser extraído para essa área quando fizer sentido reutilizá-lo ou quando sua separação tornar as telas mais simples.

## `main.dart`

É o ponto de entrada da aplicação. Deve permanecer pequeno e concentrar principalmente a inicialização do Flutter, configuração global e montagem do widget raiz.

## Fluxo esperado

Exemplo de cadastro de uma despesa:

```text
Tela Flutter
    ↓
Repository
    ↓
DAO / Drift
    ↓
SQLite
```

Na leitura dos dados, o caminho ocorre no sentido inverso até que a interface seja atualizada.

## Princípios adotados

1. A UI não deve executar SQL diretamente.
2. Regras e modelos de negócio não devem depender desnecessariamente de widgets Flutter.
3. A persistência deve ficar isolada na camada `data`.
4. Componentes visuais reutilizáveis devem ser separados das telas.
5. A arquitetura poderá evoluir conforme a complexidade real do projeto exigir.

## Possíveis extensões

Quando necessário, poderão ser adicionados sem reestruturar todo o projeto:

```text
lib/
├── core/
│   ├── theme/
│   ├── utils/
│   └── constants/
└── presentation/
    └── providers/
```

`core/` deve ser criado somente quando existirem responsabilidades globais suficientes para justificá-lo. `providers/` poderá concentrar gerenciamento de estado caso Riverpod ou solução equivalente seja adotada.
