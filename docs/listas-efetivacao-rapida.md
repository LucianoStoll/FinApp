# Listas compactas e efetivação rápida — #42

Entrega pós-MVP na branch v0.2.0-alpha. Referência visual: imagem
1790865117604.jpeg fornecida pelo usuário em 01/10/2026.

## Comportamento

Receitas, despesas e transferências usam linhas com divisória fina, ícone de
status à esquerda, conta em texto menor, descrição, valor e datas. Receitas e
despesas mostram etiquetas de categoria e subcategoria; transferências mostram
origem e destino. Telas estreitas ou texto ampliado distribuem os detalhes em
mais linhas para manter controles separados e valores legíveis.

O ícone pendente/agendado efetiva com a data local de hoje: recebe, paga ou
transfere, sem alterar lançamento, vencimento, valor ou outros vínculos.
O ícone efetivado fica inativo. Uma ação em andamento desativa os controles da
linha. O feedback oferece Desfazer e Ajustar data por 12 segundos. Ajustar data
também fica no menu de três pontos, junto da edição, exclusão e retorno a pendente.

Desfazer restaura a efetivação anterior (null ou data agendada). A troca/restauração
altera só efetivação e os metadados de atualização, verificando a data esperada
antes de gravar para evitar que uma ação antiga sobrescreva uma mais recente.
Transferências preservam um registro único, usado no cálculo de ambas as contas.
A categoria, a descrição, as contas e demais datas não são regravadas nesse fluxo.
Não há migration ou nova dependência.

Ícone, descrição, valor e menu têm áreas independentes. Nesta entrega o valor
continua abrindo a edição completa; a #43 conectará a calculadora diretamente
à área já preparada. O formulário completo mantém seu fluxo anterior de datas.

## Validação manual

- Criar uma receita, despesa e transferência pendentes com vencimento diferente
  de hoje. Tocar o ícone e conferir status, data de hoje e saldos das contas.
- Tocar novamente: não deve duplicar ou abrir edição.
- Desfazer: conferir volta ao estado anterior e saldos; repetir com agendamento.
- Ajustar para uma data passada/futura pelo feedback e pelo menu; conferir saldos.
- Cancelar o seletor de data: manter efetivação atual.
- Com filtro de pendentes, efetivar e desfazer mesmo após a linha sair da lista.
- Conferir edição, valor e menu sem acionar status; conferir etiquetas de categoria.
- Testar descrição longa, valor grande, texto ampliado, celular em paisagem e PC.
- Reiniciar o app e confirmar persistência; atualizar APK preservando os dados.
