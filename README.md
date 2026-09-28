# FinApp

Aplicativo multiplataforma de controle financeiro pessoal em **Dart + Flutter**, para **Android e Windows**, com arquitetura **offline-first**, foco em privacidade, educação financeira e evolução incremental.

> Projeto em desenvolvimento e planejado como base para TCC.

## Objetivo

O FinApp deve permitir que o usuário controle sua vida financeira sem depender de internet. O banco local é a fonte imediata dos dados; recursos online serão opcionais.

## MVP — v0.1.0-alpha

O primeiro MVP será deliberadamente enxuto:

- contas financeiras;
- categorias e subcategorias;
- receitas e despesas;
- transferências entre contas;
- saldo atual e projetado;
- histórico/listagem de transações;
- dashboard básico;
- persistência local com SQLite/Drift;
- funcionamento offline em Android e Windows.

A arquitetura será preparada para as funcionalidades futuras, mas elas não bloqueiam a entrega do MVP.

## Decisões técnicas

- Flutter + Dart
- SQLite + Drift
- arquitetura híbrida por **feature**, com camadas `data/domain/presentation`
- `core/` somente para recursos realmente compartilhados
- BLoC/Cubit
- go_router
- get_it com ambientes `dev/test/prod`
- UUIDs para entidades sincronizáveis
- dinheiro persistido em unidades mínimas inteiras (centavos quando aplicável)
- migrations versionadas com backup e recuperação
- GitHub Actions inicialmente com análise e formatação
- Semantic Versioning, alpha/beta, tags e changelog

## Princípios

1. Offline-first.
2. Salvar localmente nunca depende da nuvem.
3. Recursos complexos entram incrementalmente.
4. Histórico financeiro não deve ser destruído por arquivamentos/renomeações.
5. Operações que não representam renda/despesa, como transferências e pagamento de fatura, não devem duplicar resultados.
6. Privacidade e integrações online são opt-in.
7. O modelo deve permitir evolução sem reescrever o núcleo.

## Documentação

- [Requisitos e especificação funcional](docs/requisitos.md)
- [Arquitetura](docs/arquitetura.md)
- [Banco de dados](docs/banco-de-dados.md)
- [Roadmap](docs/roadmap.md)
- [Decisões do produto](docs/especificacao-produto.md)
- [Guidelines de desenvolvimento](docs/guidelines-desenvolvimento.md)

## Status

🛠️ Planejamento consolidado; próximo marco: fundação técnica e MVP offline.
