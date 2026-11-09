-- =====================================================================
-- JUSTIFICATIVA DO TEMA E CONTEXTO DO NEGÓCIO
-- Escolhi uma fábrica de doces porque é um negócio que mistura vários 
-- controles ao mesmo tempo e é uma coisa que entendo um pouco por trabalhar com isso,
-- compra de matéria-prima com fornecedores,
-- receitas de cada produto, estoque, e vendas para clientes (lojas,
-- mercados e pessoas físicas). A fábrica produz doces como brigadeiro,
-- pé de moleque, cocada,geleia de mocoto, goiabada,rapadura ,vende doces em pedaços e pra comer de colher tambem , vendidos em caixas ou potes.
-- Ela precisa saber o que tem de ingrediente em estoque, quanto cada produto gasta
-- de ingrediente, quem comprou o quê e quanto faturou.
-- =====================================================================

DROP TABLE IF EXISTS itens_pedido;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS receitas;
DROP TABLE IF EXISTS produtos;
DROP TABLE IF EXISTS ingredientes;
DROP TABLE IF EXISTS fornecedores;
DROP TABLE IF EXISTS clientes;

-- =====================================================================
-- CRIAÇÃO DAS TABELAS
-- =====================================================================

-- Tabela fornecedores
-- Guarda as empresas que vendem matéria-prima para a fábrica. Serve para
-- saber de quem comprar cada ingrediente e como entrar em contato.
CREATE TABLE fornecedores (
    id_fornecedor SERIAL PRIMARY KEY,
    nome          VARCHAR(100) NOT NULL,
    cnpj          VARCHAR(18)  NOT NULL UNIQUE,
    cidade        VARCHAR(60)  NOT NULL,
    telefone      VARCHAR(20)
);

-- Tabela ingredientes
-- Controla a matéria-prima usada na produção (açúcar, leite em pó, amido,
-- etc). Mostra o estoque atual, o estoque mínimo para avisar quando
-- precisa comprar mais e qual fornecedor entrega cada item.
CREATE TABLE ingredientes (
    id_ingrediente SERIAL PRIMARY KEY,
    nome           VARCHAR(80)   NOT NULL UNIQUE,
    unidade_medida VARCHAR(5)    NOT NULL DEFAULT 'kg',
    estoque_atual  NUMERIC(10,2) NOT NULL DEFAULT 0,
    estoque_minimo NUMERIC(10,2) NOT NULL DEFAULT 5,
    custo_unitario NUMERIC(8,2)  NOT NULL,
    id_fornecedor  INTEGER       NOT NULL REFERENCES fornecedores(id_fornecedor),
    CONSTRAINT ck_ingrediente_estoque CHECK (estoque_atual >= 0),
    CONSTRAINT ck_ingrediente_custo   CHECK (custo_unitario > 0)
);

-- Tabela produtos
-- Lista os doces que a fábrica vende, com categoria, preço de venda e
-- quantidade pronta em estoque. O campo ativo permite tirar um produto
-- de linha sem apagar o histórico de vendas.
CREATE TABLE produtos (
    id_produto  SERIAL PRIMARY KEY,
    nome        VARCHAR(80)   NOT NULL UNIQUE,
    categoria   VARCHAR(40)   NOT NULL,
    preco_venda NUMERIC(8,2)  NOT NULL,
    estoque     INTEGER       NOT NULL DEFAULT 0,
    ativo       BOOLEAN       NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_produto_preco   CHECK (preco_venda > 0),
    CONSTRAINT ck_produto_estoque CHECK (estoque >= 0)
);

-- Tabela receitas
-- Liga cada produto aos ingredientes que ele usa e na quantidade
-- necessária para produzir 1 unidade. É a tabela que permite calcular
-- o custo de produção e o quanto de ingrediente vai ser gasto.
CREATE TABLE receitas (
    id_produto     INTEGER       NOT NULL REFERENCES produtos(id_produto),
    id_ingrediente INTEGER       NOT NULL REFERENCES ingredientes(id_ingrediente),
    quantidade     NUMERIC(8,3)  NOT NULL,
    PRIMARY KEY (id_produto, id_ingrediente),
    CONSTRAINT ck_receita_qtd CHECK (quantidade > 0)
);

-- Tabela clientes
-- Cadastro de quem compra da fábrica: pessoas físicas (PF) e empresas
-- como mercados e padarias (PJ). Serve para registrar os pedidos e ver
-- quais clientes compram mais.
CREATE TABLE clientes (
    id_cliente    SERIAL PRIMARY KEY,
    nome          VARCHAR(100) NOT NULL,
    tipo          CHAR(2)      NOT NULL DEFAULT 'PJ',
    documento     VARCHAR(18)  NOT NULL UNIQUE,
    cidade        VARCHAR(60)  NOT NULL,
    telefone      VARCHAR(20),
    data_cadastro DATE         NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT ck_cliente_tipo CHECK (tipo IN ('PF', 'PJ'))
);

-- Tabela pedidos
-- Registra cada pedido feito por um cliente, com a data, a previsão de
-- entrega e o andamento (status). Cada pedido tem vários itens, que
-- ficam na tabela itens_pedido.
CREATE TABLE pedidos (
    id_pedido     SERIAL PRIMARY KEY,
    id_cliente    INTEGER     NOT NULL REFERENCES clientes(id_cliente),
    data_pedido   DATE        NOT NULL DEFAULT CURRENT_DATE,
    data_entrega  DATE,
    status        VARCHAR(20) NOT NULL DEFAULT 'pendente',
    CONSTRAINT ck_pedido_status  CHECK (status IN ('pendente', 'em producao', 'entregue', 'cancelado')),
    CONSTRAINT ck_pedido_entrega CHECK (data_entrega IS NULL OR data_entrega >= data_pedido)
);

-- Tabela itens_pedido
-- Detalha os produtos de cada pedido: quantidade comprada e o preço
-- cobrado na hora da venda (guardado aqui para o histórico não mudar se
-- o preço do produto for alterado depois).
CREATE TABLE itens_pedido (
    id_pedido      INTEGER      NOT NULL REFERENCES pedidos(id_pedido),
    id_produto     INTEGER      NOT NULL REFERENCES produtos(id_produto),
    quantidade     INTEGER      NOT NULL,
    preco_unitario NUMERIC(8,2) NOT NULL,
    PRIMARY KEY (id_pedido, id_produto),
    CONSTRAINT ck_item_qtd   CHECK (quantidade > 0),
    CONSTRAINT ck_item_preco CHECK (preco_unitario > 0)
);

-- =====================================================================
-- INSERÇÃO DE DADOS
-- =====================================================================

INSERT INTO fornecedores (nome, cnpj, cidade, telefone) VALUES
('Açúcar Cristal Copersucar', '11.222.333/0001-01', 'Criciuma SC', '(48) 3437-4804'),
('Lacteos Piracanjuba',     '22.333.444/0001-02', 'Minas Gerais',         '(33) 3213-3700'),
('Chocolates Nestle Profissional',     '33.444.555/0001-03', 'Sao Paulo','(11) 3722-3003'),
('Coco SulCoco',        '44.555.666/0001-04', 'Sao Paulo',    '(11) 3720-4004'),
('indemil industria e Comercio',     '55.666.777/0001-05', 'Paranavai PR','(44) 3312-5005'),
('Frigorifico Franca Boi',   '66.777.888/0001-06', 'Franca SP', '(16) 3255-6006'),
('Coamo Alimentos', '77.654.987/0001-7', 'Campo Mourao', '(44) 3599-8000'),
('Agroindustria Koch', '88.546.789/0001-8', 'Vera Cruz RS', '(51) 99959-4893'),
('Altfran Comercio e Distribuidora de Frutas','10.472.632/0001-9','Franca SP', '(16) 99181-1608');

INSERT INTO ingredientes (nome, unidade_medida, estoque_atual, estoque_minimo, custo_unitario, id_fornecedor) VALUES
('Açúcar Cristal',      'kg', 120.00, 30.00, 4.50, 1),
('Leite em po',     'kg',  100.00, 25.00, 14.90, 2),
('Chocolate em pó',      'kg',  35.00, 10.00, 22.00, 3),
('Manteiga',             'kg',  18.00, 15.00, 38.00, 7),
('Coco ralado',          'kg',  40.00, 15.00, 16.50, 4),
('Amendoim torrado',     'kg',  60.00, 20.00, 12.00, 8),
('Leite integral',       'l',   3.000, 1.000,  4.80, 2),
('Chocolate meio amargo','kg',  22.00, 12.00, 45.00, 3),
('Amido de Milho',     'kg',  12.00, 10.00,  9.80, 5),
('Goiaba', 'Cx',    3.00,  4.00, 60.00, 9);

INSERT INTO produtos (nome, categoria, preco_venda, estoque, ativo) VALUES
('Brigadeiro picadinho (caixa 12un)', 'Brigadeiros', 28.00, 150, TRUE),
('Cocada (caixa 12un)',               'Coco', 28.00, 120, TRUE),
('Pé de Moleque (caixa 20un)',                 'Doces de amendoim', 18.00, 200, TRUE),
('Doce de leite (pote 400g)',           'Doces cremosos', 22.00, 90, TRUE),
('Cocada Morena (caixa 10un)',                 'Doces de coco', 20.00, 110, TRUE),
('Pé de Moça (caixa 15un)',          'Doces de amendoim', 19.50, 85, TRUE),
('Goiabada (caixa 8un)',      'Cascão', 32.00, 60, TRUE),
('Rapadura  (caixa 12un)',     'Doce', 38.00, 40, FALSE);

-- quantidade gasta de cada ingrediente para fazer 1 unidade do produto
INSERT INTO receitas (id_produto, id_ingrediente, quantidade) VALUES
(1, 2, 0.395), (1, 3, 0.050), (1, 4, 0.020),
(2, 2, 0.395), (2, 5, 0.100), (2, 4, 0.020),
(3, 6, 0.300), (3, 1, 0.150),
(4, 7, 1.000), (4, 1, 0.400),
(5, 5, 0.300), (5, 1, 0.250), (5, 2, 0.200),
(6, 6, 0.250), (6, 1, 0.200), (6, 9, 0.050),
(7, 8, 0.200), (7, 4, 0.030), (7, 2, 0.100),
(8, 8, 0.150), (8, 2, 0.395), (8, 4, 0.020);

INSERT INTO clientes (nome, tipo, documento, cidade, telefone, data_cadastro) VALUES
('Mercado Tião João',       'PJ', '10.111.222/0001-10', 'São Sebastião do Paraíso', '(35) 3531-1010', '2026-01-15'),
('Padaria 5 Estrela',      'PJ', '20.222.333/0001-20', 'São Sebastião do Paraíso', '(35) 3551-2020', '2026-02-03'),
('Cafeteria Bendito Casarao',  'PJ', '30.333.444/0001-30', 'Passos',                   '(35) 3521-3030', '2026-03-21'),
('Maria Celia',   'PF', '123.456.789-01',     'São Sebastião do Paraíso', '(35) 99911-4040', '2026-04-10'),
('Empório Sao Vicente',   'PJ', '50.555.666/0001-50', 'Franca',                   '(16) 3722-5050', '2026-05-02'),
('Lazaro Donizete',      'PF', '987.654.321-09',     'Jacui',              '(35) 99822-6060', '2026-06-18'),
('Escola Cecilia Mambrini', 'PJ', '70.777.888/0001-70', 'São Sebastião do Paraíso', '(35) 3531-7070', '2026-07-07'),
('Buffet Terra Santa',      'PJ', '80.888.999/0001-80', 'Ribeirão Preto',           '(16) 3633-8080', '2026-08-25');

INSERT INTO pedidos (id_cliente, data_pedido, data_entrega, status) VALUES
(1, '2026-09-05', '2026-09-08', 'entregue'),
(2, '2026-09-12', '2026-09-14', 'entregue'),
(3, '2026-09-20', '2026-09-23', 'entregue'),
(8, '2026-09-28', '2026-10-02', 'entregue'),
(1, '2026-10-06', '2026-10-09', 'entregue'),
(5, '2026-10-14', '2026-10-18', 'entregue'),
(4, '2026-10-20', NULL,         'cancelado'),
(7, '2026-10-25', '2026-10-29', 'em producao'),
(2, '2026-10-28', '2026-11-03', 'em producao'),
(6, '2026-11-02', NULL,         'pendente');

INSERT INTO itens_pedido (id_pedido, id_produto, quantidade, preco_unitario) VALUES
(1, 1, 20, 28.00),
(1, 3, 30, 18.00),
(2, 2, 15, 28.00),
(2, 5, 10, 20.00),
(3, 7, 12, 32.00),
(3, 1, 8,  28.00),
(4, 1, 40, 27.00),
(4, 2, 30, 27.00),
(4, 4, 20, 22.00),
(5, 3, 25, 18.00),
(5, 6, 15, 19.50),
(6, 5, 18, 20.00),
(6, 4, 12, 22.00),
(7, 7, 2,  32.00),
(8, 1, 35, 28.00),
(8, 3, 40, 18.00),
(9, 2, 20, 28.00),
(9, 6, 10, 19.50),
(10, 4, 3, 22.00),
(10, 5, 2, 20.00);

-- =====================================================================
-- CONSULTAS
-- =====================================================================

-- 1) Pedidos com o nome do cliente e o status (JOIN)
SELECT p.id_pedido, c.nome AS cliente, p.data_pedido, p.status
FROM pedidos p
JOIN clientes c ON c.id_cliente = p.id_cliente
ORDER BY p.data_pedido;

-- 2) Valor total de cada pedido (JOIN + GROUP BY)
SELECT p.id_pedido, c.nome AS cliente,
       SUM(i.quantidade * i.preco_unitario) AS valor_total
FROM pedidos p
JOIN clientes c     ON c.id_cliente = p.id_cliente
JOIN itens_pedido i ON i.id_pedido = p.id_pedido
GROUP BY p.id_pedido, c.nome
ORDER BY valor_total DESC;

-- 3) Produtos mais vendidos em pedidos que não foram cancelados
SELECT pr.nome, SUM(i.quantidade) AS total_vendido
FROM itens_pedido i
JOIN produtos pr ON pr.id_produto = i.id_produto
JOIN pedidos p   ON p.id_pedido = i.id_pedido
WHERE p.status <> 'cancelado'
GROUP BY pr.nome
ORDER BY total_vendido DESC;

-- 4) Clientes que já gastaram mais de R$ 1000 (GROUP BY + HAVING)
SELECT c.nome, COUNT(DISTINCT p.id_pedido) AS qtd_pedidos,
       SUM(i.quantidade * i.preco_unitario) AS total_gasto
FROM clientes c
JOIN pedidos p      ON p.id_cliente = c.id_cliente
JOIN itens_pedido i ON i.id_pedido = p.id_pedido
WHERE p.status = 'entregue'
GROUP BY c.nome
HAVING SUM(i.quantidade * i.preco_unitario) > 1000
ORDER BY total_gasto DESC;

-- 5) Ingredientes com estoque abaixo do mínimo e seu fornecedor
SELECT i.nome AS ingrediente, i.estoque_atual, i.estoque_minimo,
       f.nome AS fornecedor, f.telefone
FROM ingredientes i
JOIN fornecedores f ON f.id_fornecedor = i.id_fornecedor
WHERE i.estoque_atual < i.estoque_minimo;

-- 6) Custo de ingredientes para produzir 1 unidade de cada produto
SELECT pr.nome AS produto, pr.preco_venda,
       SUM(r.quantidade * i.custo_unitario) AS custo_producao,
       pr.preco_venda - SUM(r.quantidade * i.custo_unitario) AS margem
FROM produtos pr
JOIN receitas r     ON r.id_produto = pr.id_produto
JOIN ingredientes i ON i.id_ingrediente = r.id_ingrediente
GROUP BY pr.nome, pr.preco_venda
ORDER BY margem DESC;

-- 7) Faturamento por mês (pedidos entregues)
SELECT TO_CHAR(p.data_pedido, 'YYYY-MM') AS mes,
       SUM(i.quantidade * i.preco_unitario) AS faturamento
FROM pedidos p
JOIN itens_pedido i ON i.id_pedido = p.id_pedido
WHERE p.status = 'entregue'
GROUP BY TO_CHAR(p.data_pedido, 'YYYY-MM')
ORDER BY mes;

-- 8) Pedidos de clientes de São Sebastião do Paraíso ainda não entregues
SELECT p.id_pedido, c.nome, p.status, p.data_entrega
FROM pedidos p
JOIN clientes c ON c.id_cliente = p.id_cliente
WHERE c.cidade = 'São Sebastião do Paraíso'
  AND p.status IN ('pendente', 'em producao');

-- 9) Quantidade de ingredientes por fornecedor
SELECT f.nome AS fornecedor, COUNT(i.id_ingrediente) AS qtd_ingredientes
FROM fornecedores f
LEFT JOIN ingredientes i ON i.id_fornecedor = f.id_fornecedor
GROUP BY f.nome
ORDER BY qtd_ingredientes DESC;
