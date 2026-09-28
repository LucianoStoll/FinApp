# Guidelines de Desenvolvimento — FinApp

## Arquitetura
- features independentes com `data/domain/presentation`;
- `core/` somente para infraestrutura compartilhada;
- UI não acessa DAO/SQLite diretamente;
- domínio não depende de Flutter/Drift/provedores externos;
- integrações atrás de interfaces.

## Flutter
- BLoC/Cubit para estado;
- go_router para navegação;
- get_it para DI;
- ambientes dev/test/prod;
- componentes reutilizáveis sem concentrar regras de negócio em widgets.

## Persistência
- UUIDs;
- dinheiro em unidade mínima inteira;
- migrations versionadas;
- backup antes de migrations relevantes;
- tombstones onde sync futuro exigir;
- timestamps consistentes.

## Erros e logs
- separar erro técnico, domínio e mensagem de UI;
- mensagens localizáveis;
- logs por nível;
- nunca incluir dados financeiros sensíveis em diagnóstico por padrão.

## Git
Conventional Commits:
- `feat:`
- `fix:`
- `docs:`
- `refactor:`
- `test:`
- `chore:`

Branches sugeridas:
- `feature/issue-<n>-descricao`
- `fix/issue-<n>-descricao`
- `docs/descricao`

PRs devem referenciar issue quando houver, descrever alterações e conter checklist de validação manual relevante.

## Qualidade
Inicialmente:
- `dart format`;
- `flutter analyze`;
- testes manuais.

Evolução planejada:
- unitários de regras financeiras;
- banco/repositories;
- widgets críticos;
- migrations;
- importação;
- backup/restauração;
- sync.

## Releases
Semantic Versioning:
- `v0.x.x-alpha`;
- `v0.x.x-beta`;
- `v1.0.0` estável.

Cada release deve ter tag e changelog, relacionando issues/PRs relevantes.
