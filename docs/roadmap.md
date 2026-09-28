# Roadmap — FinApp

## Estratégia

O primeiro marco é um MVP pequeno e utilizável. Recursos avançados já têm requisitos definidos, mas entram incrementalmente.

## Controle de versões e branches

Cada ciclo de desenvolvimento deve possuir uma branch principal com o **nome exato da versão**, por exemplo `v0.1.0-alpha`, `v0.2.0-alpha` ou `v0.5.0-beta`.

Todas as issues previstas para aquela versão devem ser implementadas e validadas nessa branch. Evitar branches paralelas desnecessárias; quando uma branch auxiliar for indispensável, ela deve retornar para a branch da versão, nunca diretamente para `main`.

A branch `main` representa somente versões concluídas/estáveis dentro do marco planejado. **A Pull Request da branch da versão para `main` só deve ser aberta quando todo o escopo daquela versão estiver concluído e validado.** Depois do merge, a versão recebe tag/release/changelog e inicia-se uma nova branch com o nome da próxima versão.

Antes de qualquer implementação, verificar qual é a branch de versão ativa e manter controle das branches existentes para evitar trabalho divergente ou abandonado.

## Fase 0 — Fundação
- [x] Visão, questionário e escopo
- [x] Offline-first e preparação para sync
- [x] Stack e arquitetura alvo
- [x] Criar branch de versão `v0.1.0-alpha`
- [ ] Reorganizar Flutter em core + features
- [ ] Configurar Drift, BLoC/Cubit, go_router e get_it
- [ ] Ambientes dev/test/prod
- [ ] GitHub Actions: format + flutter analyze
- [ ] Guidelines, branches/commits e PR template

## Fase 1 — Persistência do núcleo
- [ ] Drift/SQLite
- [ ] UUID e metadados sync-ready
- [ ] Valores monetários inteiros
- [ ] Migrations versionadas
- [ ] Conta
- [ ] Categoria/Subcategoria
- [ ] Transação
- [ ] Transferência
- [ ] Arquivamento/soft delete
- [ ] Saldo atual/projetado

## Fase 2 — MVP / v0.1.0-alpha
- [ ] CRUD e arquivamento de contas
- [ ] CRUD e arquivamento de categorias/subcategorias
- [ ] Receitas e despesas
- [ ] Transferências sem duplicidade
- [ ] Lista/filtros essenciais
- [ ] Dashboard básico
- [ ] UI Android/Windows
- [ ] Claro/escuro/sistema
- [ ] 100% offline
- [ ] Validação manual

## Fase 3 — Núcleo financeiro avançado
- [ ] Competência/vencimento/efetivação
- [ ] Previsto x realizado
- [ ] Recorrências e parcelamentos
- [ ] Liquidações parciais
- [ ] Rateio
- [ ] Reembolsos/pessoas
- [ ] Tags/estabelecimentos
- [ ] Regras automáticas
- [ ] Autocompletar/modelos
- [ ] Edição em lote, desfazer/refazer, lixeira
- [ ] Agendamentos/projeções

## Fase 4 — Cartões
- [ ] Cartões/limites
- [ ] Faturas
- [ ] Compras parceladas
- [ ] Pagamentos/antecipações
- [ ] Saldo credor/estornos
- [ ] Compras internacionais
- [ ] Competência x caixa

## Fase 5 — Planejamento
- [ ] Orçamentos/versionamento/acúmulo
- [ ] Metas e objetivos
- [ ] Reserva de emergência/grupos
- [ ] Essencial x não essencial
- [ ] Renda e taxa de poupança
- [ ] Plano financeiro
- [ ] Saúde financeira
- [ ] Alertas progressivos

## Fase 6 — Dívidas e patrimônio
- [ ] Empréstimos/financiamentos
- [ ] Juros/encargos
- [ ] Renegociação/amortização/simulações
- [ ] Bens e avaliações
- [ ] Patrimônio líquido
- [ ] Investimentos e PriceProvider

## Fase 7 — Relatórios/importação/produtividade
- [ ] Dashboard customizável
- [ ] Relatórios/gráficos
- [ ] Relatórios salvos/filtros globais
- [ ] Fechamento/snapshots
- [ ] CSV/Excel/PDF
- [ ] OFX futuro
- [ ] Conciliação
- [ ] Pacote portátil
- [ ] Favoritos/atalhos
- [ ] Ajuda contextual

## Fase 8 — Robustez
- [ ] Anexos (20 MB)
- [ ] Backup diário/3 versões
- [ ] Restauração validada
- [ ] Logs/diagnóstico
- [ ] Telemetria opt-in
- [ ] Cache/agregações
- [ ] Evoluir testes automatizados

## Fase 9 — Sync Engine
- [ ] SyncProvider/change tracking
- [ ] Sync com app aberto
- [ ] Sync ao abrir/após mudanças
- [ ] Last Write Wins + histórico
- [ ] Status/pendências/histórico
- [ ] Anexos Automático/Wi-Fi/Manual
- [ ] Primeira sincronização
- [ ] Bloqueio de merge de bases independentes
- [ ] Migração entre provedores

## Fase 10 — Google Drive e integrações
- [ ] Google OAuth
- [ ] GoogleDriveSyncProvider
- [ ] Android ↔ Windows
- [ ] Central de privacidade
- [ ] Provedores futuros
- [ ] APIs de cotações
- [ ] Assistente de ajuda futuro

## Antes do 1.0
- [ ] Identidade visual final
- [ ] Testes automatizados críticos
- [ ] CI ampliado
- [ ] Definir licença
- [ ] Revisar documentação
- [ ] Changelog e v1.0.0

## Releases

Semantic Versioning: 0.x-alpha para desenvolvimento inicial, 0.x-beta para estabilização e 1.0.0 para primeira versão estável. Cada release terá tag, changelog e issues/PRs relacionados.
