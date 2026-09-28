# Roadmap — FinApp

## Marco 0 — Planejamento e fundação
- [x] Objetivo e escopo
- [x] Questionário de produto/implementação
- [x] Estratégia offline-first
- [x] Arquitetura alvo
- [x] MVP definido
- [ ] Reestruturar projeto Flutter por features
- [ ] Configurar BLoC/Cubit, go_router e get_it
- [ ] Configurar Drift/SQLite e UUID
- [ ] Configurar CI: format + flutter analyze
- [ ] Definir tratamento central de erros/logs

## Marco 1 — MVP v0.1.0-alpha
Critério: app útil offline sem cartões, orçamento, metas ou nuvem.

### Contas
- [ ] CRUD
- [ ] tipos de conta
- [ ] saldo inicial
- [ ] arquivar/reativar
- [ ] visibilidade em totais/gráficos

### Categorias
- [ ] categorias/subcategorias
- [ ] ícone/cor
- [ ] arquivar/reativar
- [ ] ordenação básica

### Transações
- [ ] receita
- [ ] despesa
- [ ] edição/exclusão lógica
- [ ] listagem/filtros essenciais
- [ ] datas e status essenciais
- [ ] saldo atual/projetado

### Transferências
- [ ] transferência vinculada entre contas
- [ ] não duplicar receita/despesa

### Dashboard
- [ ] saldos
- [ ] receitas/despesas
- [ ] movimentações recentes

### Qualidade
- [ ] Android
- [ ] Windows
- [ ] funcionamento 100% offline
- [ ] migrations seguras
- [ ] testes manuais do MVP

## Marco 2 — Transações avançadas
- recorrências e séries;
- autocomplete/modelos;
- previsto x realizado;
- liquidações parciais;
- rateio;
- reembolsos/pessoas;
- tags/estabelecimentos;
- edição em lote e undo;
- anexos/lixeira.

## Marco 3 — Cartões e compromissos
- cartões e limites;
- faturas;
- parcelamentos;
- antecipações;
- saldo credor;
- compras internacionais;
- competência x caixa;
- agendamentos e projeções.

## Marco 4 — Planejamento
- orçamentos avançados/versionados;
- metas e objetivos encadeados;
- reserva de emergência;
- renda/taxa de poupança;
- alertas;
- saúde financeira e educação financeira.

## Marco 5 — Relatórios e interoperabilidade
- relatórios/gráficos configuráveis;
- relatórios salvos;
- filtros globais;
- CSV/Excel;
- PDF;
- OFX futuro;
- conciliação;
- pacote completo de exportação/importação.

## Marco 6 — Patrimônio e dívidas
- patrimônio líquido;
- bens;
- empréstimos/financiamentos;
- amortização/renegociação;
- cheque especial;
- investimentos;
- multimoeda/cotações.

## Marco 7 — Backup e sincronização
- backup local diário (3 versões);
- SyncProvider;
- Sync Engine;
- Google Drive OAuth;
- Last Write Wins + histórico de conflito;
- sync com app aberto;
- status/histórico de sync;
- anexos configuráveis;
- migração futura entre provedores.

## Marco 8 — Qualidade e publicação
- testes automatizados gradualmente;
- builds/release pipeline;
- changelog e tags SemVer;
- alpha → beta → 1.0;
- decidir licença open-source;
- revisão de privacidade, acessibilidade e documentação.

## Princípio

Funcionalidades pós-MVP não devem atrasar o núcleo. A arquitetura deve suportá-las, mas cada marco precisa produzir software utilizável.
