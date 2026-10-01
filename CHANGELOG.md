# Changelog

## 0.1.0-alpha — 2026-10-01

Primeiro MVP do Somia, validado pelo usuário nas issues #30, #31, #32, #35 e no checklist final #33. Fechamento acompanhado pela #10.

### Funcionalidades
- Contas, categorias e subcategorias com cadastro, edição e arquivamento.
- Receitas, despesas e transferências com valores monetários inteiros.
- Lançamento, vencimento e efetivação separados; confirmação para contabilizar hoje ou no vencimento em compromissos passados/futuros.
- Saldo acumulado efetivado e projeção individual/consolidada até o fim do mês escolhido.
- Participação no saldo do mês independente das análises, permitindo separar aplicações.
- Dashboard mensal com receitas/despesas, histórico de seis meses, gastos por categoria e transações recentes, também no celular.
- Seletor mensal compartilhado, navegação por setas, seleção de mês/ano e filtros avançados nas listas.
- Tema escuro e identidade Somia, drawer mobile e sidebar no PC.
- Formulários Android em tela cheia, fluxo Descrição → Valor, teclado decimal e controles responsivos; janelas no Windows.
- Descrição de transferências persistida e exibida nas listas.
- Backup SQLite com exportação, validação e restauração ao reiniciar; migrations até o schema v7.
- Ajuda sobre saldos e identificação da versão/compilação nos Ajustes.

### Correções e distribuição
- Resumo e gráficos usam efetivação quando preenchida, ou vencimento nos movimentos previstos, incluindo lançamentos registrados em outro mês.
- Ajustes de espaçamento, paisagem, telas estreitas e texto ampliado.
- APK release com chave persistente, verificação de certificado/package e número crescente de compilação.
- Pacote Windows x64 em modo release; pré-release GitHub com APK, ZIP Windows, relatório de assinatura e SHA-256.
- CI com formatação, análise, 57 testes, testes no Windows, prévias mobile e builds de ambas as plataformas.

### Instalação e limites
Instale o APK sobre a versão anterior, sem desinstalar. No Windows, extraia todo o ZIP e abra `finapp.exe`. Faça backup pelos Ajustes; a restauração é aplicada após fechar e abrir o app.

Esta versão é offline e mantém dados locais. Sincronização, cartões, recorrências, calculadora integrada, tema claro e backup automático ficam para os próximos ciclos.
