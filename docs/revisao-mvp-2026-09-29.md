# Revisão do MVP — 29/09/2026

Esta revisão registra alterações aprovadas antes do fechamento do Somia v0.1.0-alpha.

## 1. Datas de receitas, despesas e transferências

Todos os três tipos de movimento passam a trabalhar com:

- **data de lançamento**: data financeira informada para o lançamento;
- **data de vencimento**: quando o compromisso vence;
- **data de efetivação**: quando o movimento passa a ser contabilizado no saldo realizado.

A data de lançamento não substitui `created_at`, que permanece metadado técnico.

### Regras

- saldo realizado/atual usa a data de efetivação;
- saldo projetado usa vencimentos de movimentos pendentes/futuros;
- movimento com efetivação futura não afeta o realizado antes dessa data;
- ao efetivar algo cujo vencimento está no passado ou no futuro, perguntar:
  - **Contabilizar hoje** → data de efetivação = hoje;
  - **Contabilizar no vencimento** → data de efetivação = vencimento, inclusive passado.
- quando o vencimento é hoje, contabilizar hoje diretamente;
- cancelar a confirmação mantém o movimento pendente.

Detalhamento: #30.

## 2. Atualização do APK sem perda de dados

Durante os testes do MVP, um novo APK deve atualizar a instalação existente em vez de exigir desinstalação.

Requisitos:

- `applicationId` fixo;
- chave de assinatura persistente;
- credenciais protegidas por GitHub Actions Secrets;
- `versionCode` crescente em cada build;
- migrations Drift/SQLite não destrutivas;
- teste de upgrade preservando dados;
- exportação/importação simples de backup como proteção adicional.

Ao trocar de uma assinatura antiga para a assinatura persistente pode ser necessária uma última reinstalação. Depois da transição, as builds seguintes devem atualizar normalmente.

Detalhamento: #31.

## 3. Navegação mobile e identidade Somia

A barra inferior do Android será removida.

O mobile passa a usar **drawer/menu lateral**, com:

1. Dashboard/Resumo;
2. Receitas;
3. Despesas;
4. Transferências;
5. Contas;
6. Categorias;
7. Configurações.

Receitas e Despesas são áreas independentes. O botão flutuante **+** continua oferecendo Receita, Despesa e Transferência.

No Windows, a mesma arquitetura de informação deve ser adaptada para sidebar/NavigationRail em telas largas.

Detalhamento: #32.

## 4. Temas

- **MVP:** somente tema escuro Somia, com estética leve e azul acinzentado.
- **Futuro:** tema claro/branco já possui direção visual aprovada e deve manter a mesma estrutura, componentes e hierarquia do tema escuro.
- Personalização do dashboard e opção de seguir o sistema permanecem fora do MVP.

## 5. Relações com entregas anteriores

Esta revisão complementa as issues concluídas #21, #22, #23 e #24 e deve ser concluída antes da validação final do MVP.

Documentos relacionados:

- `docs/requisitos.md`;
- `docs/banco-de-dados.md`;
- `docs/especificacao-produto.md`;
- `docs/identidade-visual.md`;
- `docs/roadmap.md`.
