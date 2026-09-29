# Somia — Identidade visual e interface do MVP

Versão do documento: 1.0 • 29/09/2026  
Projeto: FinApp • Marco: v0.1.0-alpha  
Origem: chat “Definir identidade visual”, de 28/09/2026.

## 1. Decisões aprovadas

| Item | Decisão |
| --- | --- |
| Nome do produto | Somia; substitui FinApp como nome apresentado ao usuário. O repositório continua FinApp. |
| Direção visual | Interface simples, leve e pouco densa, com espaço entre os elementos. |
| Cor principal | Azul acinzentado. |
| Tema do MVP | Somente escuro. Tema claro e seguir o sistema ficam para o futuro. |
| Tela inicial | Resumo do mês, gráficos e lançamentos recentes. |
| Ação principal | Botão + abre um pequeno balão flutuante com Receita, Despesa e Transferência. |
| Dashboard no MVP | Composição básica e fixa. |
| Dashboard futuro | Usuário poderá escolher quais informações aparecem e alterar a ordem. |
| Plataformas | Android e Windows, com layout adaptativo e funcionamento offline. |

A decisão mais recente de usar apenas tema escuro substitui, para o MVP, o planejamento anterior de claro/escuro/sistema.

## 2. Referência visual aprovada

O protótipo “Somia, quatro telas de finanças pessoais.png” recebeu a aprovação “Está bom”. Ele mostra Resumo, Lançamentos, Contas e Nova despesa.

[Consultar o protótipo aprovado](https://chatgpt.com/api/library/files/libfile_700dcbc0194c8191b160a6f7c864bd8d/download)

As referências enviadas no chat estão preservadas nos links abaixo. Esses links exigem acesso aos arquivos no ChatGPT; não são imagens públicas hospedadas no GitHub.

- [1000066877.jpg](https://chatgpt.com/api/library/files/libfile_d748dff3dd3081919deef8899caa7ba7/download)
- [1000066774.jpg](https://chatgpt.com/api/library/files/libfile_4d00ea461f8c8191a69d091c7144a766/download)
- [1000066875.jpg](https://chatgpt.com/api/library/files/libfile_cd146d8edfb48191a3e6ed22ad9089b1/download)
- [1000066880.jpg](https://chatgpt.com/api/library/files/libfile_4141097250fc81919c0ca2404f4deac8/download)
- [1000066879.jpg](https://chatgpt.com/api/library/files/libfile_45862f927ed081918f98fbe728fd168c/download)
- [1000066876.jpg](https://chatgpt.com/api/library/files/libfile_a34821b1cd408191baf036a989185ded/download)

Os valores, nomes de contas e datas do protótipo são ilustrativos. Não devem ser inseridos como dados reais ou fixos no aplicativo.

## 3. Navegação e telas

### Resumo

- Identificação Somia no cabeçalho.
- Mês de referência visível, com navegação entre meses.
- Resultado do mês em destaque, com receitas e despesas do mesmo período.
- Gráfico básico de gastos por categoria, com legenda e valores/percentuais.
- Lançamentos recentes e acesso à listagem completa.
- Saldo total acessível na área de Contas; quando exibido no resumo, deve ser claramente separado do resultado mensal.
- Atualização após criar, editar ou excluir movimentos, sem reiniciar o aplicativo.

Resultado mensal significa receitas menos despesas do período. Não deve ser confundido com o saldo acumulado das contas. Transferências entre contas não entram como receita/despesa nem no gráfico de gastos.

### Lançamentos

- Período de referência visível.
- Lista organizada por data, com descrição, conta, valor e identificação do tipo.
- Diferenciação de receitas e despesas também por texto/sinal/ícone, sem depender apenas da cor.
- Acesso aos fluxos existentes de criação, edição e exclusão.
- Botão + acessível sem cobrir conteúdo ou comandos importantes.

### Contas

- Saldo total e lista de contas com nome, ícone e saldo.
- Ação para adicionar conta.
- Acesso às ações existentes de gerenciamento.
- Preservar regras de conta inativa, saldo inicial e histórico.

### Nova receita / Nova despesa

- Valor com maior destaque.
- Descrição, conta, data, categoria e subcategoria.
- Categoria e subcategoria em seletores distintos.
- Subcategorias coerentes com a categoria escolhida; limpar seleção incompatível ao trocar a categoria.
- Campos adicionais existentes podem ficar em “Mais detalhes”, mantendo os obrigatórios acessíveis.
- Botão “Salvar lançamento” claramente identificado.
- Manter validações e persistência offline existentes.

### Transferência

A opção no balão deve abrir o fluxo específico de transferência, com contas de origem/destino e valor. Reutilizar a operação financeira existente e preservar a consistência entre os dois lados.

### Ajustes

A navegação do protótipo contém Resumo, Lançamentos, Contas e Ajustes. No MVP, Ajustes deve apresentar apenas funcionalidades disponíveis. Não incluir controles de tema claro ou personalização do dashboard nesta entrega.

## 4. Comportamento do botão +

1. Ao tocar/clicar no +, abrir um pequeno menu flutuante próximo ao botão.
2. Exibir Receita, Despesa e Transferência, cada uma com ícone e texto.
3. Ao selecionar uma opção, fechar o menu e abrir o formulário correspondente.
4. Fechar também ao tocar fora, voltar ou pressionar Escape no desktop.
5. Manter foco de teclado e semântica acessível; evitar múltiplos menus sobrepostos.

Os três tipos de ação são fixos no MVP. Personalização das ações rápidas é evolução futura.

## 5. Sistema visual

### Diretrizes aprovadas

- Fundo escuro e superfícies discretamente diferenciadas.
- Azul acinzentado como destaque principal.
- Poucos elementos concorrendo por atenção.
- Hierarquia clara entre título, informação principal, rótulos e informações secundárias.
- Cards e listas com respiro, sem excesso de bordas, sombras ou efeitos.

### Recomendações técnicas para implementação

Estas recomendações operacionalizam a direção aprovada; não são escolhas adicionais explicitamente aprovadas no chat.

- Centralizar cores, tipografia, espaçamentos e raios no tema Flutter.
- Utilizar tipografia sem serifa legível e consistente com o projeto.
- Dar destaque aos valores principais e manter rótulos discretos, porém legíveis.
- Usar uma escala consistente de espaçamento e componentes compartilhados.
- Usar cores semânticas discretas para receita, despesa e erro.
- Conferir contraste, escala de texto e áreas de toque nas plataformas alvo.
- Em telas largas, aproveitar colunas e navegação lateral sem esticar cartões indefinidamente.
- Evitar adicionar dependências apenas para reproduzir efeitos decorativos.

Códigos HEX, família tipográfica definitiva, medidas exatas e logotipo vetorial não estão confirmados no registro recuperado. Devem ser definidos durante a implementação respeitando o protótipo; não tratar valores arbitrários como decisões do usuário.

## 6. Estados e regras de dados

- Sem lançamentos: mensagem objetiva e ação para adicionar o primeiro.
- Sem gastos no mês: gráfico vazio informativo, sem divisão por zero.
- Sem contas: orientar criação de conta antes do lançamento.
- Erro ao salvar: manter os dados digitados e apresentar feedback compreensível.
- Valores negativos, nomes longos e texto ampliado não podem quebrar o layout.
- Totais e gráficos devem vir das consultas e regras financeiras do projeto.
- Mudanças visuais não devem alterar banco, saldos, transferências ou histórico sem necessidade explícita.

## 7. Escopo e evolução

| MVP v0.1.0-alpha | Pós-MVP |
| --- | --- |
| Tema escuro | Tema claro e opção de seguir o sistema |
| Dashboard básico com composição fixa | Mostrar/ocultar e reordenar blocos |
| Resumo mensal e gráfico básico por categoria | Relatórios e gráficos avançados/personalizáveis |
| + com três ações fixas | Ações rápidas personalizáveis |
| Formulários essenciais e seletores separados | Autocomplete, modelos e fluxos avançados |
| Android/Windows offline | Integrações opcionais previstas no roadmap |

Preparar componentes independentes para facilitar evolução, sem implementar agora um editor de dashboard ou persistência de preferências que não serão utilizadas.

## 8. Plano de implementação

1. Conferir a versão atual da branch v0.1.0-alpha e os componentes existentes.
2. Consolidar o tema escuro Somia e os componentes reutilizáveis.
3. Ajustar navegação e implementar o balão do +.
4. Aplicar a composição aprovada em Resumo, Lançamentos, Contas e formulários.
5. Conectar o resumo e o gráfico aos dados locais.
6. Validar Android/Windows, acessibilidade básica e uso offline.
7. Rodar as verificações do projeto e disponibilizar APK pelo GitHub Actions.
8. Após validação do usuário, concluir a issue e seguir o fluxo de PR para main.

Usar branch identificada pela versão. A entrega desta documentação não significa que a interface já foi implementada ou validada.

## 9. Relação com as issues existentes

- #24 e #8: dashboard básico; complementar com resumo mensal, gráfico por categoria e composição Somia.
- #25: ajustar escopo de tema para apenas escuro no MVP; manter acessibilidade e validação Android/Windows.
- #21 e #5: preservar receitas/despesas e seletores separados.
- #22 e #6: reutilizar transferências no menu +.
- #19 e #3: aplicar identidade à área de Contas.
- #14: manter relatórios avançados no pós-MVP.
- #10: incluir verificação visual na validação final do MVP.

As referências acima não declaram essas issues abertas, fechadas ou implementadas; registram a relação de escopo.

## 10. Critérios de aceite da interface

- [ ] Nome Somia apresentado ao usuário nas telas alteradas.
- [ ] Tema exclusivamente escuro no MVP, com destaque azul acinzentado.
- [ ] Composição leve e coerente com o protótipo aprovado.
- [ ] Navegação Resumo, Lançamentos, Contas e Ajustes.
- [ ] Resumo mensal e gráfico básico usam dados reais e atualizam após alterações.
- [ ] Resultado do mês claramente distinto do saldo total.
- [ ] Transferências excluídas das receitas/despesas e dos gastos por categoria.
- [ ] + abre balão com Receita, Despesa e Transferência.
- [ ] Categoria e subcategoria em campos distintos.
- [ ] Dashboard permanece fixo nesta versão.
- [ ] Estados vazios, erros e valores extremos tratados.
- [ ] Layout funcional em Android e Windows, offline.
- [ ] Análise/formatação do projeto aprovadas e APK disponível para teste.
- [ ] Validação visual e funcional do usuário antes do encerramento.

