# Roadmap — FinApp

## Fase 0 — Fundação

- [x] Definir objetivo inicial
- [x] Levantar requisitos do MVP
- [x] Definir arquitetura inicial
- [x] Criar repositório GitHub
- [x] Documentar projeto
- [x] Definir estratégia offline-first
- [x] Definir preparação para sincronização futura
- [ ] Criar/configurar projeto Flutter local
- [ ] Preparar estrutura `data/domain/presentation`
- [ ] Configurar dependências iniciais

## Fase 1 — Persistência preparada para Sync

- [ ] Configurar SQLite/Drift
- [ ] Definir geração de UUID
- [ ] Definir `deviceId` persistente por instalação
- [ ] Criar modelo de Conta
- [ ] Criar modelo de Categoria
- [ ] Criar modelo de Transação
- [ ] Adicionar `createdAt`, `updatedAt`, `deletedAt`, `deviceId` e `syncVersion`
- [ ] Armazenar valores monetários em centavos
- [ ] Criar tabelas
- [ ] Criar DAOs
- [ ] Criar repositories
- [ ] Implementar migrations
- [ ] Testar criação simultânea de registros com UUIDs

## Fase 2 — Contas e categorias

- [ ] Listar contas
- [ ] Criar conta
- [ ] Editar conta
- [ ] Implementar exclusão lógica/arquivamento
- [ ] Criar categorias
- [ ] Editar categorias
- [ ] Implementar exclusão lógica/arquivamento
- [ ] Implementar subcategorias

## Fase 3 — Transações

- [ ] Cadastrar receita
- [ ] Cadastrar despesa
- [ ] Editar transação
- [ ] Implementar exclusão lógica
- [ ] Listar transações
- [ ] Ordenar por data
- [ ] Filtrar por mês/ano

## Fase 4 — Dashboard

- [ ] Calcular saldo das contas
- [ ] Calcular saldo total
- [ ] Exibir receitas do mês
- [ ] Exibir despesas do mês
- [ ] Exibir transações recentes
- [ ] Validar atualização automática

## Fase 5 — Qualidade do MVP offline

- [ ] Revisar experiência Android
- [ ] Revisar experiência Windows
- [ ] Testar funcionamento totalmente offline
- [ ] Testar cálculos financeiros
- [ ] Testar repositories
- [ ] Testar migrations
- [ ] Revisar desempenho
- [ ] Revisar documentação

## Fase 6 — Educação financeira

- [ ] Resumo de gastos por categoria
- [ ] Comparação entre períodos
- [ ] Indicadores de comprometimento de renda
- [ ] Alertas configuráveis
- [ ] Conteúdo/dicas de educação financeira

## Fase 7 — Sync Engine

Somente iniciar após o núcleo offline estar estável.

- [ ] Definir contrato `SyncProvider`
- [ ] Implementar fila/identificação de alterações pendentes
- [ ] Criar Sync Engine independente de provedor
- [ ] Implementar manifest/versionamento remoto
- [ ] Implementar download e aplicação de mudanças
- [ ] Implementar upload de mudanças
- [ ] Implementar tombstones remotos
- [ ] Definir política inicial de conflitos
- [ ] Registrar última sincronização e erros
- [ ] Criar testes com dois bancos/dispositivos simulados

## Fase 8 — Google Drive Sync

- [ ] Configurar projeto Google/OAuth
- [ ] Implementar autenticação
- [ ] Solicitar somente permissões necessárias
- [ ] Implementar `GoogleDriveSyncProvider`
- [ ] Utilizar armazenamento de dados específico do app
- [ ] Sincronização manual (`Sincronizar agora`)
- [ ] Sincronização ao iniciar/retomar quando apropriado
- [ ] Exibir alterações pendentes e última sincronização
- [ ] Testar Android ↔ Windows
- [ ] Testar operação offline prolongada e reconciliação

## Fase 9 — Expansão

- [ ] Metas financeiras
- [ ] Relatórios PDF
- [ ] Exportação de dados
- [ ] Backup criptografado
- [ ] Outros provedores de sync
- [ ] Estratégias avançadas de conflitos

## Princípio do roadmap

O FinApp deve permanecer utilizável mesmo sem internet, sem conta Google e sem serviço remoto. A sincronização complementa o banco local; ela nunca substitui o núcleo offline.
