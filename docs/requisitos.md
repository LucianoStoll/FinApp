# Levantamento de Requisitos — FinApp

## 1. Objetivo

Aplicativo multiplataforma para **Android e Windows** destinado ao controle financeiro pessoal. O sistema deve funcionar offline, armazenar os dados localmente, priorizar a privacidade do usuário e possuir foco em educação financeira. O projeto será disponibilizado como código aberto.

## 2. Stakeholders

- Usuário final
- Desenvolvedor
- Instituição de ensino / TCC
- Comunidade open-source

## 3. Requisitos Funcionais

### RF01 — Contas

O sistema deve permitir:

- criar contas;
- editar contas;
- excluir contas;
- representar diferentes tipos, como carteira e conta bancária;
- definir saldo inicial.

### RF02 — Categorias

O sistema deve permitir criar, editar e excluir categorias de receitas e despesas. Categorias poderão possuir subcategorias.

### RF03 — Receitas

O usuário deve poder cadastrar uma receita contendo:

- descrição;
- valor;
- data;
- conta;
- categoria;
- subcategoria.

### RF04 — Despesas

O usuário deve poder cadastrar uma despesa contendo:

- descrição;
- valor;
- data;
- conta;
- categoria;
- subcategoria.

### RF05 — Transações

O sistema deve:

- listar as transações;
- permitir ordenação por data;
- permitir filtro por mês e ano.

### RF06 — Saldo automático

O sistema deve calcular automaticamente o saldo considerando o saldo inicial das contas e as movimentações cadastradas.

### RF07 — Dashboard

O dashboard deve apresentar, no mínimo:

- saldo atual;
- total de receitas do mês;
- total de despesas do mês.

### RF08 — Funcionamento offline

As funcionalidades essenciais do aplicativo devem funcionar sem conexão com a internet.

## 4. Requisitos Não Funcionais

### RNF01 — Usabilidade

A interface deve ser simples, clara e intuitiva.

### RNF02 — Desempenho

As operações locais e mudanças de tela devem apresentar resposta rápida em condições normais de uso.

### RNF03 — Multiplataforma

A primeira versão deve oferecer suporte a Android e Windows utilizando Flutter.

### RNF04 — Persistência local

Os dados financeiros devem ser armazenados em banco de dados local SQLite.

### RNF05 — Código aberto

O código-fonte deve ser versionado e disponibilizado por meio do GitHub conforme a evolução do projeto.

### RNF06 — Privacidade

Os dados do MVP devem permanecer armazenados localmente no dispositivo, salvo futura funcionalidade explicitamente acionada pelo usuário, como backup ou sincronização.

## 5. Escopo inicial

O MVP concentra-se no controle financeiro pessoal local. Login, nuvem e sincronização não são dependências para seu funcionamento.

## 6. Funcionalidades futuras

- backup na nuvem;
- login de usuário;
- sincronização entre dispositivos;
- exportação de relatórios em PDF;
- metas financeiras;
- gráficos e análises financeiras;
- recursos de educação financeira;
- exportação de dados;
- categorização assistida/automática em versões posteriores.
