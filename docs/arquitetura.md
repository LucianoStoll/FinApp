# Arquitetura — FinApp

## Direção

Arquitetura **offline-first**, modular por feature e inspirada em Clean Architecture. O SQLite/Drift é a fonte imediata dos dados. Nenhuma operação local deve aguardar serviço remoto.

## Estrutura alvo

```text
lib/
├── core/
│   ├── database/
│   ├── di/
│   ├── errors/
│   ├── routing/
│   ├── theme/
│   ├── i18n/
│   ├── logging/
│   └── utils/
├── features/
│   ├── accounts/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── categories/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── transactions/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── transfers/
│   └── dashboard/
└── main.dart
```

Features futuras seguem a mesma estrutura: cards, budgets, goals, reports, assets, debts, investments, sync etc.

## Stack

- Estado: **BLoC/Cubit**.
- Rotas: **go_router**, rotas nomeadas e organizadas por módulo.
- DI: **get_it**, módulos e ambientes `dev/test/prod`.
- Banco: **Drift/SQLite**.
- IDs: **UUID**.
- Valores monetários: inteiros em unidade mínima.
- CI inicial: `flutter analyze` + verificação de formatação.

## Fluxo local

```text
UI → BLoC/Cubit → Use case/Domain → Repository → DAO/Drift → SQLite
```

A conclusão da gravação local significa sucesso para a operação offline.

## Sincronização futura

```text
SQLite ↔ Repository ↔ Sync Engine ↔ SyncProvider ↔ Provedor remoto
```

O primeiro provedor planejado é Google Drive, autenticado diretamente por OAuth. O domínio não conhece o provedor. Outros provedores podem ser adicionados e migrados futuramente.

Regras já definidas:
- sync apenas enquanto o app está aberto;
- sync ao abrir e após alterações relevantes;
- ação manual “Sincronizar agora”;
- Last Write Wins;
- conflitos ficam registrados;
- primeira carga em dispositivo vazio baixa a base remota;
- se houver base local independente antes da primeira sync, não mesclar automaticamente;
- status detalhado de sync;
- anexos configuráveis: automático, somente Wi-Fi ou manual.

## Erros

Erros de domínio, técnicos e mensagens de UI são separados. Uma camada central padroniza códigos, localização das mensagens e logging. Logs técnicos não devem vazar dados financeiros sensíveis.

## Desempenho

Dashboard e relatórios podem usar cache, invalidação seletiva, recálculo incremental e snapshots/agregações. Operações pesadas devem ser assíncronas e manter a UI responsiva.

## Migrations

Migrations são versionadas e sequenciais. Para alterações relevantes:
1. criar backup;
2. executar migration;
3. validar;
4. concluir ou restaurar com segurança.

## UI

Android e Windows compartilham identidade e componentes, mas podem ter navegação/layout específicos. Tema claro/escuro/sistema. A identidade visual detalhada será definida em questionário próprio.

## Princípios de dependência

- UI não executa SQL.
- domínio não conhece Flutter, Drift ou Google Drive.
- features não dependem diretamente de implementações internas de outras features.
- `core/` contém somente infraestrutura realmente compartilhada.
- integrações externas ficam atrás de contratos.
