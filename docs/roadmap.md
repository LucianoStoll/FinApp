# Roadmap — FinApp

O roadmap serve como orientação e poderá ser atualizado conforme os requisitos e resultados dos testes.

## Fase 0 — Fundação

- [x] Definir objetivo inicial
- [x] Levantar requisitos do MVP
- [x] Definir arquitetura inicial
- [x] Criar repositório GitHub
- [x] Documentar projeto
- [ ] Criar/configurar projeto Flutter local
- [ ] Preparar estrutura `data/domain/presentation`
- [ ] Configurar dependências iniciais

## Fase 1 — Persistência e domínio

- [ ] Criar modelo de Conta
- [ ] Criar modelo de Categoria
- [ ] Criar modelo de Transação
- [ ] Configurar SQLite/Drift
- [ ] Criar tabelas
- [ ] Criar DAOs
- [ ] Criar repositories
- [ ] Implementar migrations iniciais

## Fase 2 — Contas e categorias

- [ ] Listar contas
- [ ] Criar conta
- [ ] Editar conta
- [ ] Excluir/arquivar conta
- [ ] Criar categorias
- [ ] Editar categorias
- [ ] Excluir/arquivar categorias
- [ ] Implementar subcategorias

## Fase 3 — Transações

- [ ] Cadastrar receita
- [ ] Cadastrar despesa
- [ ] Editar transação
- [ ] Excluir transação
- [ ] Listar transações
- [ ] Ordenar por data
- [ ] Filtrar por mês/ano

## Fase 4 — Dashboard

- [ ] Calcular saldo das contas
- [ ] Calcular saldo total
- [ ] Exibir receitas do mês
- [ ] Exibir despesas do mês
- [ ] Exibir transações recentes
- [ ] Validar atualização automática após movimentações

## Fase 5 — Qualidade do MVP

- [ ] Revisar experiência Android
- [ ] Revisar experiência Windows
- [ ] Testar funcionamento totalmente offline
- [ ] Criar testes para cálculos financeiros
- [ ] Criar testes para repositories
- [ ] Revisar desempenho
- [ ] Revisar documentação

## Fase 6 — Educação financeira

Possíveis recursos após estabilização do controle financeiro básico:

- [ ] Resumo de gastos por categoria
- [ ] Comparação entre períodos
- [ ] Indicadores de comprometimento de renda
- [ ] Alertas configuráveis
- [ ] Conteúdo/dicas de educação financeira

## Fase 7 — Expansão

- [ ] Metas financeiras
- [ ] Relatórios PDF
- [ ] Exportação de dados
- [ ] Backup
- [ ] Login opcional
- [ ] Sincronização entre dispositivos
- [ ] Nuvem

## Princípio do roadmap

O funcionamento local não deve depender das funcionalidades futuras de nuvem. O objetivo é primeiro construir um núcleo financeiro confiável e utilizável offline e, depois, adicionar integrações opcionais.
