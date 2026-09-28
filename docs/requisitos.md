# Requisitos — FinApp

## 1. Visão

Aplicativo pessoal de finanças para Android e Windows, offline-first, open-source e orientado a educação financeira. O produto deve começar simples, mas seu modelo deve comportar evolução para cartões, orçamento, metas, patrimônio, dívidas, investimentos, importação, backup e sincronização.

## 2. MVP obrigatório

### RF-MVP-01 — Contas
Criar, editar, arquivar, reativar e consultar contas. Conta arquivada não aceita novos lançamentos, mas preserva histórico e pode ser configurada para aparecer ou não em totais/gráficos.

### RF-MVP-02 — Categorias
Categorias e subcategorias editáveis, arquiváveis e reativáveis, com ícone/cor, histórico preservado e ordenação manual, alfabética, favoritas ou por uso.

### RF-MVP-03 — Receitas e despesas
Cadastrar, editar, excluir logicamente e listar lançamentos. O modelo deve comportar competência, vencimento e efetivação, status Pendente/Efetivada/Atrasada e flags independentes para ignorar saldo ou análises.

### RF-MVP-04 — Transferências
Transferência é operação vinculada entre contas e não é receita/despesa. O modelo deve permitir taxas e evolução futura para moedas diferentes, agendamento e estado em trânsito.

### RF-MVP-05 — Saldos
Exibir saldo atual baseado em movimentos efetivados e saldo projetado incluindo compromissos pendentes/futuros conforme regras.

### RF-MVP-06 — Dashboard
Resumo básico de saldos, receitas, despesas e movimentações recentes.

### RF-MVP-07 — Offline
Todas as funções do MVP funcionam sem internet.

## 3. Requisitos transversais já definidos

- valores monetários persistidos sem ponto flutuante como representação principal;
- UUIDs;
- timestamps consistentes;
- histórico/auditoria para alterações relevantes;
- exclusão lógica/tombstone para dados sincronizáveis;
- lixeira; limpeza automática opcional;
- validações em tempo real classificadas em Erro/Aviso/Sugestão;
- operações demoradas assíncronas, com progresso e cancelamento quando seguro;
- ajuda contextual e documentação integrada;
- PT-BR inicialmente, mas idioma, moeda base e formatação regional independentes;
- tema claro, escuro e seguir sistema;
- acessibilidade básica: leitor de tela, contraste e texto escalável;
- Android e Windows com layouts adaptativos;
- atalhos configuráveis no Windows;
- central de notificações internas;
- telemetria e crash reports opcionais e separados;
- consentimento granular para qualquer recurso online.

## 4. Funcionalidades pós-MVP consolidadas

### Transações avançadas
Recorrências; modelos inteligentes/autocomplete; previsto x realizado; liquidações parciais; taxas/juros/descontos estruturados; rateio por valor ou percentual mantendo uma única transação principal; reembolsos vinculados; anexos; edição em lote; desfazer/refazer; descrições importadas bruta + normalizada.

### Cartões
Faturas como entidades; fechamento variável; compra/processamento/fatura real; parcelamento; limite individual por cartão e opcional; histórico de limite; saldo credor; pagamentos/antecipações parciais; estornos; compras internacionais; competência x caixa; cartão arquivado com histórico.

### Planejamento
Orçamentos fixos, percentuais, acumulativos e metas de redução; referência por competência ou vencimento; carry-over configurável; versionamento; múltiplos orçamentos com prioridade/exclusividade. Metas e objetivos encadeados; prioridades e sugestões de distribuição; reserva de emergência por meses/valor e grupo de contas.

### Educação financeira
Classificação Essencial/Não essencial; renda recorrente/variável/média; taxa de poupança; saúde financeira por dimensões e nota opcional; metodologia transparente; perfil financeiro evolutivo; recomendações e simulações.

### Patrimônio e dívidas
Patrimônio líquido; bens com valor de compra/atual e histórico; regra opcional de valorização/depreciação percentual; empréstimos/financiamentos com principal, juros e encargos; renegociação; amortização extraordinária; empréstimos informais vinculados a pessoas; cheque especial como passivo quando utilizado.

### Multimoeda e investimentos
Contas em moedas diferentes; moeda base; conversões e histórico cambial; transferências cambiais; última cotação disponível offline. Investimentos em módulo próprio, preparado para provedores de cotação via abstração.

### Importação/exportação
CSV/Excel com mapeamento guiado; PDF; preparação para OFX; detecção/conciliação futura; categorias externas ignoradas em favor das regras internas. Exportação completa em pacote portátil/versionado com integridade; importação com validação e backup prévio.

### Backup e sync
Backup local diário, 3 versões por padrão; restauração com validação e backup prévio. Futuro SyncProvider desacoplado, começando por Google Drive/OAuth; sincronização somente com app aberto, ao abrir e após alterações relevantes; botão manual; Last Write Wins com conflito registrado; status detalhado; anexos em modo Automático/Somente Wi-Fi/Manual.

## 5. Requisitos não funcionais

- desempenho: cache, recálculo incremental e agregações/snapshots;
- migrations versionadas, backup antes de mudanças importantes e rollback seguro;
- logs locais por nível, rotação e modo diagnóstico;
- pacote de diagnóstico sem dados financeiros sensíveis por padrão;
- segurança opcional: bloqueio/PIN/biometria e criptografia local independentes;
- código modular e documentado;
- `dart format` e `flutter analyze` no CI;
- testes manuais no início; evolução posterior para testes automatizados dos fluxos críticos.

## 6. Fora do MVP

Cartões, orçamento, metas, sync, investimentos, patrimônio, empréstimos, importação avançada, anexos e demais módulos descritos acima são requisitos planejados, não critérios de conclusão do primeiro MVP.
