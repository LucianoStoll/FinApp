# Roadmap — Somia

## Estratégia

O primeiro marco é um MVP pequeno e utilizável. Recursos avançados já têm requisitos definidos, mas entram incrementalmente.

## Controle de versões e branches

Cada ciclo de desenvolvimento deve possuir uma branch principal com o **nome exato da versão**, por exemplo `v0.1.0-alpha`, `v0.2.0-alpha` ou `v0.5.0-beta`.

Todas as issues previstas para aquela versão devem ser implementadas e validadas nessa branch. Evitar branches paralelas desnecessárias; quando uma branch auxiliar for indispensável, ela deve retornar para a branch da versão, nunca diretamente para `main`.

A branch `main` representa somente versões concluídas/estáveis dentro do marco planejado. **A Pull Request da branch da versão para `main` só deve ser aberta quando todo o escopo daquela versão estiver concluído e validado.** Depois do merge, a versão recebe tag/release/changelog e inicia-se uma nova branch com o nome da próxima versão.

Antes de qualquer implementação, verificar qual é a branch de versão ativa e manter controle das branches existentes para evitar trabalho divergente ou abandonado.

## Situação do MVP

O ciclo `v0.1.0-alpha` foi aprovado em 01/10/2026, sem bugs relatados no checklist #33. #30, #31, #32 e #35 estão concluídas. A #10 consolida documentação, PR para `main` e publicação dos pacotes Android/Windows.

## Fase 0 — Fundação
- [x] Visão, questionário e escopo
- [x] Offline-first e preparação para sync
- [x] Stack e arquitetura alvo
- [x] Criar branch de versão `v0.1.0-alpha`
- [x] Reorganizar Flutter em core + features
- [x] Configurar Drift, BLoC/Cubit, go_router e get_it
- [ ] Ambientes dev/test/prod (próximo ciclo)
- [x] GitHub Actions: formatação, análise, testes, prévias mobile, builds e publicação
- [x] Guidelines, branches/commits e PR template

## Fase 1 — Persistência do núcleo
- [x] Drift/SQLite
- [x] UUID e metadados sync-ready
- [x] Valores monetários inteiros
- [x] Migrations versionadas
- [x] Conta
- [x] Categoria/Subcategoria
- [x] Transação
- [x] Transferência
- [x] Arquivamento/soft delete
- [x] Saldo atual/projetado

## Fase 2 — MVP / v0.1.0-alpha
- [x] CRUD e arquivamento de contas
- [x] CRUD e arquivamento de categorias/subcategorias
- [x] Receitas e despesas
- [x] Transferências sem duplicidade
- [x] Lista/filtros essenciais
- [x] Dashboard básico
- [x] UI Android/Windows
- [x] Tema escuro aprovado; tema claro/sistema nos próximos ciclos
- [x] 100% offline
- [x] Validação manual

### Revisão final antes da conclusão do MVP
- [x] receitas, despesas e transferências com data de lançamento, vencimento e efetivação;
- [x] saldo realizado baseado na data de efetivação e projeções baseadas no vencimento;
- [x] aviso ao efetivar compromisso passado ou futuro: contabilizar hoje ou no vencimento;
- [x] migration Drift/SQLite não destrutiva para preservar bases já usadas;
- [x] APK Android atualizável sobre a instalação anterior, com assinatura persistente e build number crescente;
- [x] teste de atualização preservando os dados locais;
- [x] backup/exportação e importação simples como proteção durante os testes;
- [x] remover barra inferior no mobile e adotar drawer/menu lateral;
- [x] Receitas e Despesas como áreas independentes no menu;
- [x] manter tema escuro no MVP e preparar os componentes para tema claro futuro.

Issues de acompanhamento concluídas: #30, #31, #32, #35 e #33. Fechamento/release: #10.

## Pós-MVP — UX financeira
- [ ] Calculadora monetária integrada como entrada padrão para campos de valor
- [ ] Operações básicas: soma, subtração, multiplicação e divisão
- [ ] Teclas numéricas, `00`, separador decimal, limpar, apagar e confirmar
- [ ] Preservar valor anterior ao cancelar/voltar
- [ ] Precisão monetária sem erros de ponto flutuante
- [ ] Componente global reutilizável em lançamentos e módulos futuros

## Fase 3 — Núcleo financeiro avançado
- [ ] Competência e regras contábeis avançadas (lançamento/vencimento/efetivação já disponíveis no MVP)
- [ ] Análises avançadas de previsto x realizado (saldo básico já disponível)
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
- [ ] Ampliar ajuda contextual (explicação dos saldos disponível no MVP)

## Fase 8 — Robustez
- [ ] Anexos (20 MB)
- [ ] Backup diário/3 versões
- [x] Restauração local validada no MVP; evoluir proteção e automação nos próximos ciclos
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
