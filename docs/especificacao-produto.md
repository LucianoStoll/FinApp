# Especificação de Produto — FinApp

Este documento consolida as decisões do questionário de produto. Ele complementa `requisitos.md` e evita que funcionalidades futuras sejam confundidas com o MVP.

## Produto
- gerenciador financeiro pessoal completo, construído incrementalmente;
- um perfil principal agora; arquitetura para perfis independentes no futuro;
- Android + Windows;
- offline-first;
- interface adaptativa;
- ajuda contextual em todas as áreas complexas.

## Contas
Tipos amplos e personalizáveis. Conta pode ser arquivada/inativada, bloqueando novos lançamentos, reativada depois e configurada quanto à participação/visibilidade em análises. Dinheiro em espécie é conta comum. Grupos de contas suportam conceitos como liquidez, dia a dia e reserva. Cheque especial é limite separado e vira passivo quando utilizado.

## Transações
Três datas: competência, vencimento e efetivação. Status principais: Pendente, Efetivada e Atrasada. Saldo atual e projetado são separados. Lançamentos podem ser ignorados independentemente em saldo e analytics.

Previsto x realizado é preservado. Liquidações parciais suportam juros, multa, desconto e acréscimos. Taxas/encargos são componentes estruturados. Rateio divide internamente uma única transação por valor ou percentual. Reembolsos ficam vinculados à despesa original e podem ser parciais ou totais.

## Produtividade
Ações rápidas personalizáveis. Autocomplete usa modelos e histórico: ao digitar “Jantar”, pode preencher categoria, subcategoria, conta e demais dados fixos, deixando valor/data e outros campos variáveis. Modelos podem ter variantes contextuais. Não usar localização.

## Categorias, tags, estabelecimentos e pessoas
Categorias/subcategorias: defaults + personalização, arquivamento, reativação, migração, aliases, ícone/cor e múltiplas ordenações. Tags são livres, mas seguem o mesmo ciclo de vida de categorias. Estabelecimentos e pessoas podem ser mesclados, arquivados e manter aliases. Regras automáticas valem para novos dados; em conflito, a regra mais recente vence; edição manual de uma transação não altera a regra.

## Cartões
Faturas são entidades próprias. Compras, processamento e fatura real podem ter datas distintas. Pagamento da fatura é liquidação, não nova despesa. Suportar pagamento parcial/antecipado, saldo credor, estorno, limite opcional, histórico de limite, encerramento/reativação e compras internacionais com estimado x realizado. Cada cartão tem limite independente.

## Parcelamentos
Compra/compromisso pai + parcelas. Suportar antecipação, juros/descontos, edição e histórico. Relatórios podem mostrar compra total, parcelas por competência e compromissos futuros sem duplicar totais.

## Orçamento
Estratégias: fixo, percentual da renda, acumulativo, meta de redução. Referência configurável por competência ou vencimento. Carry-over configurável, inclusive percentual/teto/saldo negativo. Orçamentos são versionados. Uma transação pode participar de múltiplos orçamentos, com prioridade/exclusividade.

## Metas e planejamento
Metas evoluem de valor/prazo para contribuições e projeções. Objetivos podem acumular, quitar dívida, reduzir gasto etc. e formar planos encadeados. Prioridades têm sugestão de distribuição, confirmada pelo usuário.

Reserva de emergência: meta por valor/meses, despesas consideradas configuráveis e grupo explícito de contas/ativos que compõem a reserva.

## Educação financeira
Essencial/Não essencial por categoria/subcategoria, com override por transação. Renda separa recorrente, variável e média. Taxa de poupança diferencia sobra de aporte. Saúde financeira possui dimensões, histórico, explicações e nota geral opcional. Metodologia transparente e perfil financeiro evolutivo com confirmação.

## Dívidas e patrimônio
Empréstimos/financiamentos: principal, juros, tarifas, seguros/impostos, saldo devedor, amortizações, renegociação e simulações. Empréstimos informais vinculados a pessoas. Bens: compra, valor atual, histórico, documentos, dívida associada, inclusão opcional no patrimônio e regra percentual estimada de valorização/depreciação. Futuro: estimativas de mercado via provedores.

## Multimoeda
Conta possui moeda própria; perfil possui moeda base. Exibir conversão prática sem alterar a moeda real da conta. Histórico de câmbio e transferências entre moedas. Provedores de cotação desacoplados e última cotação disponível offline.

## Backup, arquivos e privacidade
Anexos internos, hash e limite inicial de 20 MB. Backup automático diário com 3 versões. Restauração validada e com backup prévio. Segurança (PIN/biometria/criptografia) opcional e independente. Central de privacidade e consentimento granular. Telemetria e crash reports separados e opt-in.

## Sync futuro
Provider abstrato, Google Drive primeiro. OAuth direto no provedor. Sync apenas com app aberto: ao abrir, após alterações relevantes e manualmente. LWW com conflito registrado. Dispositivo vazio baixa a base remota. Bases independentes não são mescladas automaticamente. Status e histórico detalhados.

## Interface
Dashboard customizável no futuro. Gráficos/relatórios configuráveis. Busca global avançada. Filtros globais podem ser salvos. Favoritos/fixados. Relatórios salvos recalculam ao abrir. Tema claro/escuro/sistema. Ajuda contextual, busca de ajuda, tutoriais e futuro assistente baseado na documentação.

## Fechamento
Fechamento mensal cria snapshot; período fechado exige reabertura para edição. Exportações de relatório recebem versão e data/hora.

## MVP
Somente: contas, categorias/subcategorias, receitas/despesas, transferências, saldo e dashboard básico. Todo o restante é evolução planejada.
