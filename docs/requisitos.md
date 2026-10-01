# Especificação de Requisitos — FinApp

## Visão e MVP

FinApp é um gerenciador financeiro pessoal para Android e Windows, open-source, offline-first e orientado à educação financeira. SQLite/Drift local é a fonte de verdade operacional; recursos online são opcionais.

O primeiro MVP (v0.1.0-alpha) é enxuto: contas, categorias/subcategorias, receitas, despesas, transferências, saldo atual/projetado, dashboard básico e funcionamento totalmente offline.

## Núcleo financeiro

No MVP, receitas, despesas e transferências passam a possuir explicitamente **data de lançamento, data de vencimento e data de efetivação**. A data de lançamento é uma data financeira do movimento e não deve ser confundida com `created_at`, que continua sendo metadado técnico. Conceitos adicionais de competência podem evoluir depois sem substituir essas três datas operacionais.

Estados principais: Pendente, Efetivada e Atrasada (preferencialmente derivada). O **saldo atual/realizado usa a data de efetivação** como referência temporal; pendências e movimentos futuros entram no **saldo projetado conforme o vencimento**. Previsto e realizado são preservados e comparáveis.

Ao efetivar antecipadamente um movimento cujo vencimento esteja no futuro, a interface deve perguntar se o usuário quer **Contabilizar hoje** ou **Contabilizar no vencimento**. A escolha define a data de efetivação. Se essa data for futura, o movimento não entra no saldo realizado antes dela.

Obrigações podem ter liquidações parciais com juros, multa, desconto e acréscimos. A mesma abstração atende contas a pagar/receber e antecipações de fatura.

Uma transação pode ser rateada internamente por valor ou percentual entre categorias sem duplicar a movimentação. Reembolsos ficam vinculados à despesa e à pessoa, podendo ser parciais/totais e múltiplos.

Transferências são operações vinculadas entre contas, não receita/despesa. Evoluem para tarifas, moedas distintas, câmbio/spread, datas de saída/entrada, estados Pendente/Agendada/Em trânsito/Concluída/Cancelada e recorrência.

## Contas

Tipos padrão e personalizáveis. Dinheiro/carteira é uma conta comum; saque é transferência e só há despesa quando o dinheiro é gasto.

Contas podem ser arquivadas/inativadas, reativadas e configuradas quanto à visibilidade em saldos/gráficos. Podem ficar negativas e ter cheque especial separado do saldo; limite não é patrimônio e uso é passivo.

Contas podem pertencer a grupos personalizados (liquidez, reserva, investimentos, dia a dia).

## Categorias, tags, estabelecimentos e pessoas

Categorias/subcategorias possuem ícone, cor, aliases, nome curto/completo e ordenação manual, alfabética, favoritas e frequência. Registros usados são arquivados, não apagados do histórico, e podem ser migrados/reativados.

Tags são livres e independentes, mas seguem o mesmo ciclo de arquivamento/reativação/mesclagem.

Estabelecimentos e pessoas podem ser arquivados, mesclados e manter aliases, preservando vínculos. Pessoas concentram histórico de empréstimos, reembolsos e valores a pagar/receber.

## Cartões

Módulo futuro completo: limite independente por cartão, controle de limite opcional, fechamento/vencimento, parcelas, faturas, pagamentos/antecipações, estornos, saldo credor, adicionais e importação.

Fatura é entidade própria. Compra parcelada compromete o valor total e libera limite conforme liquidações. Pagamento de fatura é liquidação/fluxo de caixa, não nova despesa. Relatórios podem alternar competência e caixa.

Compras internacionais preservam moeda/valor original, câmbio estimado/realizado, taxas, spread e valor final.

## Planejamento

Recorrências permitem editar ocorrência, ocorrência e seguintes ou série inteira. Parcelamentos têm compromisso pai e parcelas individuais.

Orçamentos podem ser gerais, por categoria/subcategoria, fixos, percentuais da renda, acumulativos ou metas de redução; cada um escolhe competência ou vencimento. Regras de acúmulo e versões possuem vigência. Uma transação pode participar de múltiplos orçamentos sem duplicar valores.

Reserva de emergência é módulo específico: alvo em valor/meses, despesas consideradas e grupo de contas/ativos que compõem a reserva. Essencial/Não essencial pode vir da categoria e ser sobrescrito na transação.

Metas evoluem para objetivos e planos encadeados. O app pode sugerir distribuição entre objetivos com base em prazo, juros, risco e importância; usuário confirma.

## Renda, saúde financeira e educação

Receitas podem ser classificadas como renda recorrente/variável; médias usam período configurável. Taxa de poupança distingue sobra de caixa de aportes efetivos.

Saúde financeira terá painel por áreas e nota geral opcional. Metodologia e pesos são transparentes e podem variar conforme perfil financeiro. Mudanças de perfil sugeridas pelo app exigem confirmação.

Análises educativas começam locais e transparentes; IA futura é opcional e não recebe dados financeiros sem consentimento explícito.

## Dívidas e patrimônio

Empréstimos/financiamentos suportam principal, juros, tarifas, seguros, impostos, parcelas, saldo devedor, renegociação vinculada e amortização extraordinária com simulações.

Bens guardam aquisição, valor atual, documentos, dívidas vinculadas e histórico; podem usar regra percentual estimada de valorização/depreciação, com valor manual prevalecendo.

Patrimônio líquido acompanha ativos menos passivos. Investimentos são módulo futuro separado, preparado para PriceProvider, cotações, múltiplas moedas e cache offline.

## Moedas e encargos

Cada conta pode ter moeda própria e o perfil uma moeda base. Conversões preservam valores originais e equivalentes. Encargos são componentes estruturados: IOF, juros, tarifa, spread, multa, desconto etc.

## Importação, exportação e conciliação

CSV e Excel para importação/exportação, PDF para relatórios e importação guiada; OFX/extratos/faturas são evolução futura.

Categorias externas importadas são ignoradas. Descrição bruta é preservada e uma versão normalizada serve à exibição, busca e regras.

Conciliação compara saldo real e app. Pacote completo de exportação é portátil/versionado e inclui banco, anexos e configurações. Importação valida integridade/compatibilidade, cria backup e substitui explicitamente a base.

## Produtividade

Regras automáticas valem para novos lançamentos/importações; em conflito, a última criada vence. Alteração manual afeta apenas a transação.

Ações rápidas, autocompletar e modelos inteligentes reutilizam histórico e contexto. Busca global, edição em lote, desfazer/refazer, lixeira, favoritos, relatórios salvos e filtros globais fazem parte da evolução.

## UX

### Calculadora monetária integrada (pós-MVP)

Campos de valor financeiro devem usar um componente global de calculadora monetária no lugar do teclado numérico padrão. Ao tocar ou editar o valor de receitas, despesas e transferências, a calculadora abre sempre; para lançamentos simples, o usuário pode utilizá-la como um teclado comum, digitando o valor e confirmando.

A calculadora deve oferecer operações básicas (`+`, `−`, `×`, `÷`), números, `00`, separador decimal, limpar, apagar último dígito e confirmar. O resultado confirmado é aplicado ao campo monetário; cancelar/voltar preserva o valor anterior. Os cálculos devem respeitar a precisão monetária do FinApp, evitando erros de ponto flutuante e convertendo o resultado para unidades monetárias inteiras/centavos ao confirmar.

O componente deve ser reutilizável por outros campos monetários futuros, como saldo inicial, parcelas, orçamentos, metas, juros, descontos e rateios. A funcionalidade é pós-MVP e não altera o escopo da `v0.1.0-alpha`.

UI adaptativa Android/Windows. No MVP, o Somia usa **tema escuro**; tema claro e opção de seguir o sistema ficam para evolução posterior, já com direção visual aprovada.

No mobile, a navegação principal usa **drawer/menu lateral**, sem barra inferior. O menu expõe Dashboard/Resumo, Receitas, Despesas, Transferências, Contas, Categorias e Configurações. **Receitas e Despesas são áreas independentes**. Em telas largas do Windows, a mesma arquitetura de informação pode ser apresentada como sidebar/NavigationRail persistente.

Acessibilidade básica: leitor de tela, contraste e texto escalável. Sem localização em lançamentos.

Onboarding contínuo e Ajuda contextual com tooltips, busca, guias e futuro assistente baseado na documentação. Windows terá atalhos configuráveis.

Validações distinguem Erro, Aviso e Sugestão. Operações longas são assíncronas, com progresso e cancelamento quando seguro. Há central interna de notificações.

## Perfis, privacidade e segurança

Múltiplos perfis futuros serão independentes, privados e em bases separadas; todas as configurações pertencem ao perfil. Idioma, moeda base e formatação regional são independentes.

PIN/senha, biometria Android e criptografia local são opcionais e independentes. Telemetria separa falhas e métricas de uso, ambas opt-in. Recursos online exigem consentimento granular em central de privacidade.

## Backup, anexos e sync

Anexos são armazenados internamente com metadados/hash; limite inicial de 20 MB por arquivo.

Backup automático local diário mantém 3 versões. Restauração cria backup atual e valida integridade/compatibilidade.

Sync futuro ocorre apenas com app aberto: ao abrir, após alterações importantes e por comando manual. Provedor é desacoplado (Google Drive primeiro provável; OneDrive/WebDAV/servidor próprio futuros). Autenticação é no provedor.

Conflitos usam Last Write Wins com histórico. Anexos: Automático/Somente Wi-Fi/Manual. Base vazia em novo dispositivo baixa a remota; se já houver base local independente, não há mesclagem automática.

## Requisitos técnicos

Flutter/Dart, Drift/SQLite, UUID, BLoC/Cubit, go_router, get_it, arquitetura por feature com data/domain/presentation + core, migrations com backup/validação/rollback, tratamento central de erros e cache/agregações para desempenho.

CI inicial: formatação + flutter analyze. Para os APKs de teste do MVP, o Android deve manter `applicationId` fixo, assinatura persistente e `versionCode` crescente, permitindo atualizar o app sem desinstalação. Migrations Drift/SQLite devem ser aditivas/não destrutivas e preservar os dados locais entre versões. Um mecanismo simples de exportação/importação de backup pode ser usado como proteção adicional durante os testes.

MVP começa com testes manuais; testes automatizados dos fluxos críticos entram depois.

Git: Conventional Commits, branches padronizadas, PR checklist, vínculo com issues. Releases seguem Semantic Versioning com alpha/beta, tags e changelog. Licença será decidida próximo da publicação.
