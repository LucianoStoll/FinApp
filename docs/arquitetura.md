# Arquitetura — FinApp

## Objetivo

O FinApp adotará uma arquitetura em camadas inspirada em Clean Architecture e orientada a **offline-first**. O MVP funcionará integralmente com SQLite local, mas as interfaces serão definidas para permitir sincronização futura sem reescrever domínio, telas ou repositories.

## Estrutura inicial

```text
lib/
├── data/
│   ├── database/
│   │   ├── tables/
│   │   └── daos/
│   ├── repositories/
│   └── sync/
│       ├── sync_engine.dart          # futuro
│       ├── sync_provider.dart        # contrato do provedor remoto
│       ├── conflict_resolver.dart    # futuro
│       └── google_drive/             # implementação futura
├── domain/
│   └── models/
├── presentation/
│   ├── screens/
│   └── widgets/
└── main.dart
```

Os arquivos de sincronização podem ser introduzidos gradualmente. O ponto importante no MVP é manter as fronteiras que permitirão adicioná-los depois.

## Fluxo offline atual

```text
Tela Flutter
    ↓
Repository
    ↓
DAO / Drift
    ↓
SQLite
```

Salvar no SQLite significa sucesso para o usuário. A interface nunca deverá aguardar um serviço remoto para concluir uma operação financeira local.

## Fluxo futuro com sincronização

```text
                    FinApp
                      │
                 Repository
                      │
                Drift / SQLite
                      │
                 Sync Engine
                      │
                SyncProvider
                      │
               Google Drive
```

O Sync Engine lê alterações locais, troca dados com um `SyncProvider`, resolve/identifica conflitos e aplica alterações remotas ao banco local.

## Camada `data/database`

Responsável por Drift/SQLite, tabelas, DAOs, consultas e migrations. As tabelas serão criadas desde o início com UUIDs e metadados necessários à sincronização futura.

## Camada `data/repositories`

É a interface de persistência utilizada pelo restante do app. Telas não executam SQL nem acessam Google Drive diretamente.

Repositories iniciais:

```text
account_repository.dart
category_repository.dart
transaction_repository.dart
```

## Camada `data/sync`

Será responsável exclusivamente pela sincronização.

### `SyncProvider`

Contrato abstrato para o armazenamento remoto. A lógica central não deve depender de uma implementação específica.

Conceitualmente:

```text
SyncProvider
    ├── GoogleDriveSyncProvider
    ├── OneDriveSyncProvider (possível futuro)
    └── WebDavSyncProvider (possível futuro)
```

### `SyncEngine`

Responsável por coordenar:

- alterações locais pendentes;
- download de alterações remotas;
- aplicação local;
- upload;
- versões de sincronização;
- estado da última sincronização.

### `ConflictResolver`

Isola a política para alterações concorrentes. Inicialmente poderá ser simples e evoluir posteriormente.

## Camada `domain`

Contém os conceitos centrais do negócio e não deve depender de Flutter, SQLite ou Google Drive.

Modelos iniciais:

```text
account_model.dart
category_model.dart
transaction_model.dart
```

## Camada `presentation`

Contém telas e widgets. Futuramente poderá exibir estado da sincronização, por exemplo:

```text
Sincronizado
3 alterações pendentes
Última sincronização: ...
Erro de sincronização
```

Esses estados não devem impedir o usuário de continuar utilizando o app.

## Regras arquiteturais

1. Local-first: SQLite é a fonte imediata do aplicativo.
2. Salvar localmente nunca depende da nuvem.
3. A UI não acessa banco ou Drive diretamente.
4. O domínio não conhece Google Drive.
5. O provedor remoto é substituível.
6. IDs devem ser globais (UUID).
7. Exclusões sincronizáveis usam tombstones (`deletedAt`).
8. Valores monetários devem evitar ponto flutuante como representação persistente principal.
9. Migrations do banco devem ser versionadas.
10. Sincronização deve ser adicionada somente após o núcleo offline estar estável.

## Evolução opcional

Conforme o projeto crescer, poderão ser adicionados:

```text
lib/
├── core/
│   ├── theme/
│   ├── utils/
│   └── constants/
└── presentation/
    └── providers/
```

Gerenciamento de estado (por exemplo Riverpod) pode ser incorporado sem alterar o princípio offline-first.
