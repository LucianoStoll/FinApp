# Arquitetura — FinApp

## Direção

Arquitetura offline-first, organizada por feature e em camadas. SQLite/Drift é a fonte de verdade operacional; serviços remotos são opcionais.

## Estrutura alvo

    lib/
    ├── core/
    │   ├── database/
    │   ├── errors/
    │   ├── routing/
    │   ├── di/
    │   ├── logging/
    │   ├── i18n/
    │   ├── theme/
    │   ├── sync/
    │   └── utils/
    ├── features/
    │   ├── accounts/{data,domain,presentation}
    │   ├── categories/{data,domain,presentation}
    │   ├── transactions/{data,domain,presentation}
    │   ├── transfers/{data,domain,presentation}
    │   ├── dashboard/{data,domain,presentation}
    │   └── ...
    └── main.dart

Cada feature encapsula persistência específica, domínio e apresentação. core contém somente infraestrutura transversal.

## Stack

Flutter/Dart; Drift + SQLite; BLoC/Cubit; go_router; get_it; UUID; GitHub Actions.

## Fluxo local

    UI → BLoC/Cubit → domínio/use case → Repository → DAO/Drift → SQLite

Salvar localmente significa sucesso. A UI não aguarda nuvem.

## Sincronização futura

    SQLite/Drift → change tracking → SyncEngine → SyncProvider → provedor remoto

Google Drive é o primeiro provedor provável. OneDrive, WebDAV e servidor próprio podem ser adicionados sem alterar o domínio.

Regras: sync apenas com app aberto; ao abrir e após alterações importantes; botão Sincronizar agora; Last Write Wins com conflito registrado; anexos configuráveis; autenticação no provedor; base vazia recebe dados remotos; duas bases independentes não são mescladas automaticamente.

## Persistência e integridade

UUIDs desde o MVP; dinheiro em unidades mínimas inteiras; timestamps técnicos em UTC; tombstones para entidades sincronizáveis; createdAt/updatedAt/deletedAt/deviceId/syncVersion.

Migrations são sequenciais e versionadas: backup antes, migração, validação e rollback/restauração segura em falha.

## Modelagem

Não representar conceitos distintos com uma única transação genérica. À medida que forem implementados, usar abstrações explícitas para Transaction, Transfer, Settlement, Allocation/Split, Reimbursement, Recurrence, InstallmentPlan, CardInvoice, Budget, Goal, Debt, Asset e Attachment.

Competência, vencimento e efetivação são separados. Atraso pode ser derivado. Previsto e realizado são preservados. Rateios não duplicam movimentação.

## Estado e navegação

Cubit para fluxos simples; BLoC quando eventos explícitos forem úteis. A apresentação não acessa Drift diretamente.

go_router usa rotas nomeadas organizadas por feature, adequado a Android e desktop.

## Injeção e ambientes

get_it registra dependências por módulo. Ambientes dev, test e prod podem trocar implementações sem alterar o domínio.

## Desempenho

Dashboard e relatórios podem usar cache, invalidação por dependência, recálculo incremental e agregações/snapshots. Operações pesadas são assíncronas e canceláveis quando tecnicamente seguro.

## Erros e observabilidade

Erros de domínio, erros técnicos e mensagens ao usuário são separados. Camada central mapeia códigos/tipos para mensagens localizadas. Logs locais estruturados têm níveis, rotação e modo diagnóstico, sem dados financeiros sensíveis por padrão.

## Qualidade

MVP começa com testes manuais. Depois, evoluir para testes unitários, banco/repositories/widgets e fluxos críticos. CI inicial executa formatação e flutter analyze.

## Decisões separadas

Identidade visual detalhada será definida em questionário próprio. Licença open-source será escolhida próximo da publicação.
