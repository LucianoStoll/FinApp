# FinApp

Gerenciador financeiro pessoal multiplataforma em **Dart + Flutter**, com arquitetura **offline-first**, privacidade local e evolução planejada para sincronização opcional.

> Projeto open-source em desenvolvimento e base de TCC.

## Plataformas

Android e Windows.

## MVP — v0.1.0-alpha

O primeiro MVP será propositalmente enxuto: contas, categorias/subcategorias, receitas, despesas, transferências, saldo atual/projetado, dashboard básico, SQLite/Drift e funcionamento 100% offline.

Os módulos avançados já possuem especificação, mas serão implementados incrementalmente.

## Arquitetura

Organização por feature, com camadas data/domain/presentation e core compartilhado.

    lib/
    ├── core/
    ├── features/
    │   ├── accounts/
    │   ├── categories/
    │   ├── transactions/
    │   ├── transfers/
    │   └── dashboard/
    └── main.dart

Stack planejada: Flutter, Drift/SQLite, BLoC/Cubit, go_router e get_it.

## Princípios

- salvar localmente nunca depende da nuvem;
- UUIDs e metadados preparados para sync futuro;
- dinheiro persistido em unidades mínimas inteiras;
- migrations versionadas e seguras;
- domínio separado da UI/infraestrutura;
- serviços externos opcionais e desacoplados;
- UI adaptativa Android/Windows.

## Evolução

A especificação cobre cartões/faturas, recorrências, parcelamentos, rateios, reembolsos, orçamentos, metas, reserva, dívidas, patrimônio, investimentos, multimoeda, importação/exportação, relatórios, backup, anexos e sincronização por provedores.

## Documentação

- [Especificação de requisitos](docs/requisitos.md)
- [Arquitetura](docs/arquitetura.md)
- [Banco de dados](docs/banco-de-dados.md)
- [Roadmap](docs/roadmap.md)
- [Identidade visual Somia](docs/identidade-visual.md)
- [Revisão do MVP — 29/09/2026](docs/revisao-mvp-2026-09-29.md)

## Revisão atual do MVP

Antes do fechamento do v0.1.0-alpha, as issues #30, #31 e #32 consolidam: três datas financeiras e novas regras de saldo/efetivação, atualização de APK sem perda de dados e nova navegação mobile por drawer.

## Desenvolvimento

Conventional Commits, branches padronizadas, PRs com checklist e Semantic Versioning. CI inicial: formatação + flutter analyze. Testes automatizados serão ampliados após o MVP.

## Status

Planejamento consolidado. Próximo marco: fundação técnica e MVP offline.
