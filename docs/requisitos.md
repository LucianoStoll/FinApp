# Levantamento de Requisitos — FinApp

## 1. Objetivo

Aplicativo multiplataforma para **Android e Windows** destinado ao controle financeiro pessoal, com foco em educação financeira, privacidade e código aberto.

O FinApp adotará arquitetura **offline-first**: todas as funções essenciais utilizam armazenamento local e continuam disponíveis sem internet. A arquitetura deve estar preparada para sincronização opcional e escalável entre dispositivos em versões futuras, inicialmente utilizando Google Drive.

## 2. Stakeholders

- Usuário final
- Desenvolvedor
- Instituição de ensino / TCC
- Comunidade open-source

## 3. Requisitos Funcionais

### RF01 — Contas
Criar, editar e excluir/arquivar contas, representar tipos como carteira e banco e definir saldo inicial.

### RF02 — Categorias
Criar, editar e excluir/arquivar categorias de receitas e despesas, incluindo subcategorias.

### RF03 — Receitas
Cadastrar receita com descrição, valor, data, conta, categoria e subcategoria.

### RF04 — Despesas
Cadastrar despesa com descrição, valor, data, conta, categoria e subcategoria.

### RF05 — Transações
Listar transações, ordenar por data e filtrar por mês/ano.

### RF06 — Saldo automático
Calcular automaticamente os saldos considerando saldo inicial, receitas e despesas válidas.

### RF07 — Dashboard
Mostrar saldo atual, total de receitas do mês e total de despesas do mês.

### RF08 — Funcionamento offline
Todas as funcionalidades financeiras essenciais devem funcionar sem conexão com a internet.

### RF09 — Preparação para sincronização
Os dados sincronizáveis devem possuir identificadores e metadados suficientes para que alterações criadas em dispositivos diferentes possam ser reconciliadas futuramente.

### RF10 — Sincronização futura opcional
Em versão posterior, o usuário poderá habilitar sincronização entre dispositivos. A primeira integração planejada será Google Drive. A ausência, falha ou desconexão do serviço remoto não deve impedir o uso local.

## 4. Requisitos Não Funcionais

### RNF01 — Usabilidade
Interface simples, clara e intuitiva.

### RNF02 — Desempenho
Operações locais e mudanças de tela devem apresentar resposta rápida em condições normais de uso.

### RNF03 — Multiplataforma
Suporte inicial a Android e Windows utilizando Flutter.

### RNF04 — Persistência local
SQLite será a fonte local dos dados, integrado ao Dart/Flutter por meio do Drift.

### RNF05 — Código aberto
Código-fonte versionado no GitHub.

### RNF06 — Privacidade
Dados permanecem localmente no MVP. Qualquer sincronização futura será opcional e explicitamente habilitada pelo usuário.

### RNF07 — Independência de provedor
O domínio e a persistência local não devem depender diretamente do Google Drive. A sincronização deve utilizar uma abstração que permita outros provedores futuramente.

### RNF08 — Integridade financeira
Valores monetários devem utilizar representação persistente adequada para evitar erros de precisão. A estratégia inicial será armazenar valores em centavos como inteiros.

### RNF09 — Identificadores globais
Entidades sincronizáveis devem utilizar UUIDs, evitando colisões quando múltiplos dispositivos criarem registros offline.

### RNF10 — Exclusões sincronizáveis
Exclusões de registros sincronizáveis devem ser representáveis por exclusão lógica/tombstone até que possam ser propagadas com segurança.

## 5. Escopo do MVP

O MVP continua sendo totalmente local. Google Drive, login Google e Sync Engine **não são necessários para a primeira versão funcional**.

Entretanto, o schema do banco, os IDs e as fronteiras arquiteturais serão preparados desde o início para evitar uma migração estrutural grande quando a sincronização for implementada.

## 6. Funcionalidades futuras

- Sync Engine;
- sincronização Google Drive;
- detecção/resolução de conflitos;
- backup criptografado;
- outros provedores de sincronização;
- exportação de relatórios PDF;
- metas financeiras;
- gráficos e análises financeiras;
- recursos de educação financeira;
- exportação de dados;
- categorização assistida/automática.
