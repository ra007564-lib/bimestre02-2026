[README.md](https://github.com/user-attachments/files/34594918/README.md)
# bimestre02-2026# Gestão de Banco de Dados - PostgreSQL

Aluno: Willian de Freitas
RA: 007564

Repositório com os trabalhos da disciplina de Gestão de Banco de Dados.

## Estrutura

```
ra007564-lib/
└── bimestre02-2026/
    └── trabalho01/
        ├── script_trabalho01.sql
        └── diagrama_der.pdf
```

## Trabalho 01 - Fábrica de Doces

Banco de dados de uma fábrica de doces que produz doces como brigadeiro,
pé de moleque, cocada,geleia de mocoto, goiabada,rapadura ,vende doces em pedaços ( etc).
Controla fornecedores, ingredientes, receitas dos produtos, clientes e pedidos.

Tabelas: fornecedores, ingredientes, produtos, receitas, clientes, pedidos e itens_pedido.

- `script_trabalho01.sql`: criação das tabelas, restrições, inserts e consultas
- `diagrama_der.pdf`: diagrama de entidade e relacionamento

Para rodar o script:

```
psql -U postgres -d nome_do_banco -f script_trabalho01.sql
```
