# FinApp

Aplicativo multiplataforma de controle financeiro pessoal, desenvolvido em **Dart + Flutter**, com funcionamento **offline-first**, armazenamento local e foco em **educação financeira, privacidade e código aberto**.

> Projeto em desenvolvimento, também pensado como base para TCC.

## Objetivo

Criar uma solução simples e intuitiva para que o usuário registre e acompanhe sua vida financeira sem depender de conexão com a internet ou serviços externos.

Plataformas inicialmente previstas:

- Android
- Windows

## MVP

A primeira versão deve oferecer:

- gerenciamento de contas financeiras;
- categorias e subcategorias;
- cadastro de receitas;
- cadastro de despesas;
- histórico de transações;
- ordenação e filtros por período;
- cálculo automático do saldo;
- dashboard mensal;
- persistência local e privada;
- funcionamento sem internet.

## Arquitetura

O código em `lib/` será separado em três camadas principais:

```text
lib/
├── data/
│   ├── database/       # Drift, tabelas, DAOs e configuração SQLite
│   └── repositories/   # Acesso e abstração da persistência
├── domain/
│   └── models/         # Entidades do domínio
├── presentation/
│   ├── screens/        # Telas do aplicativo
│   └── widgets/        # Componentes visuais reutilizáveis
└── main.dart            # Ponto de entrada
```

A separação busca manter persistência, domínio e interface independentes sem introduzir complexidade desnecessária no MVP.

## Tecnologias planejadas

- Dart
- Flutter
- SQLite
- Drift
- Git/GitHub

## Documentação

- [Levantamento de requisitos](docs/requisitos.md)
- [Arquitetura](docs/arquitetura.md)
- [Banco de dados](docs/banco-de-dados.md)
- [Roadmap](docs/roadmap.md)

## Funcionalidades futuras

Após o MVP, poderão ser implementados recursos como metas financeiras, relatórios PDF, exportação de dados, backup, login, sincronização entre dispositivos e ferramentas adicionais de educação financeira.

## Status

🛠️ Em desenvolvimento.
