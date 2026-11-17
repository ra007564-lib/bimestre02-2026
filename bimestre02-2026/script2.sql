-- =====================================================================

-- Banco: fábrica de doces 
-- Aluno: Willian de Freitas


-- =====================================================================


-- =====================================================================
-- COMPLEMENTO DE DADOS
-- Os pedidos do trabalho 01 são de setembro a novembro. Pra consulta de
-- "últimos 30 dias" sempre retornar alguma coisa, entra um pedido com
-- a data de hoje.
-- =====================================================================
INSERT INTO pedidos (id_cliente, data_pedido, data_entrega, status)
VALUES (3, CURRENT_DATE, NULL, 'pendente');

INSERT INTO itens_pedido (id_pedido, id_produto, quantidade, preco_unitario)
VALUES (currval('pedidos_id_pedido_seq'), 1, 10, 28.00);




-- =====================================================================

-- Questão 1
-- Problema: a fábrica quer listar os doces de amendoim ou de coco que
-- tenham preço de venda de pelo menos R$ 19,00 (linha premium).
-- Os parênteses fazem o preço valer para as duas categorias.
-- Sem os parênteses o AND seria avaliado primeiro, e a consulta ficaria
-- "categoria = amendoim OU (categoria = coco E preço >= 19)". Aí o
-- Pé de Moleque (R$ 18,00) apareceria, mesmo com preço menor que 19.
SELECT nome,
       categoria,
       preco_venda
FROM produtos
WHERE (categoria = 'Doces de amendoim' OR categoria = 'Doces de coco')
  AND preco_venda >= 19
ORDER BY preco_venda DESC;


-- Questão 2
-- Problema: achar pedidos que ainda estão abertos (nem entregues nem
-- cancelados) e que ainda não têm data de entrega definida, pra equipe
-- agendar a entrega. data_entrega é uma coluna opcional.
SELECT id_pedido,
       id_cliente,
       data_pedido,
       status
FROM pedidos
WHERE status NOT IN ('entregue', 'cancelado')
  AND data_entrega IS NULL
ORDER BY data_pedido;


-- Questão 3
-- Problema: relatório dos pedidos feitos no período de 15/09/2026 a
-- 20/10/2026 (BETWEEN pega as duas pontas) que já foram entregues ou
-- estão em produção.
SELECT id_pedido,
       id_cliente,
       data_pedido,
       status
FROM pedidos
WHERE data_pedido BETWEEN '2026-09-15' AND '2026-10-20'
  AND status IN ('entregue', 'em producao')
ORDER BY data_pedido;



-- Questão 4 
-- Problema: o vendedor lembra só de parte do nome do produto, então
-- busca tudo que tenha "cocada" em qualquer posição, sem se importar
-- com maiúscula ou minúscula.
SELECT id_produto,
       nome,
       preco_venda
FROM produtos
WHERE nome ILIKE '%CoCaDa%';

-- Questão 4 
-- Problema: separar os clientes empresa pelo formato do documento.
-- CNPJ tem formato fixo (2 dígitos.3 dígitos.3 dígitos/0001-2 dígitos),
-- então o _ vale exatamente um caractere em cada posição.
SELECT nome,
       documento,
       cidade
FROM clientes
WHERE documento LIKE '__.___.___/0001-__';




-- Questão 5
-- Problema: simular um reajuste de 6,5% no preço dos produtos por causa
-- do aumento do custo dos ingredientes. Mostra o preço original, o
-- arredondado (ROUND), o cortado (TRUNC) e o arredondado pra cima (CEIL).
SELECT nome,
       preco_venda                           AS preco_atual,
       preco_venda * 1.065                   AS preco_bruto,
       ROUND(preco_venda * 1.065, 2)         AS preco_arredondado,
       TRUNC(preco_venda * 1.065, 2)         AS preco_cortado,
       CEIL(preco_venda * 1.065)             AS preco_inteiro_acima
FROM produtos
ORDER BY nome;


-- Questão 6 
-- Problema: dividir os pedidos em dois lotes de separação. Número
-- de pedido par vai pro lote A e ímpar pro lote B (MOD pelo id).
SELECT id_pedido,
       status,
       MOD(id_pedido, 2) AS resto,
       CASE
           WHEN MOD(id_pedido, 2) = 0 THEN 'Lote A'
           ELSE 'Lote B'
       END AS lote
FROM pedidos
ORDER BY id_pedido;

-- Questão 6 
-- Problema: sorteio de um produto ativo pra entrar na promoção da
-- semana (um diferente a cada execução).
SELECT id_produto,
       nome,
       preco_venda
FROM produtos
WHERE ativo = TRUE
ORDER BY RANDOM()
LIMIT 1;


-- Questão 7
-- Problema: montar uma etiqueta pros produtos com nome limpo (sem a
-- parte da embalagem), categoria em maiúsculo e uma descrição completa.
-- SPLIT_PART tira o que vem depois do " (" e a embalagem é pega com
-- SUBSTRING. CONCAT trata NULL como texto vazio, então não quebra
-- se algum campo estiver vazio.
SELECT id_produto,
       SPLIT_PART(nome, ' (', 1)                       AS nome_curto,
       SUBSTRING(nome FROM '\((.*)\)')                 AS embalagem,
       UPPER(categoria)                                AS categoria_maiuscula,
       CONCAT(INITCAP(SPLIT_PART(nome, ' (', 1)), ' - ',
              categoria, ' - R$ ', preco_venda)        AS etiqueta
FROM produtos
ORDER BY id_produto;



-- Questão 8
-- Problema: ver os pedidos dos últimos 30 dias, separando ano, mês e
-- dia da semana pra saber em quais dias os clientes mais pedem.
-- (0 = domingo ... 6 = sábado)
SELECT id_pedido,
       data_pedido,
       EXTRACT(YEAR FROM data_pedido)               AS ano,
       EXTRACT(MONTH FROM data_pedido)              AS mes,
       EXTRACT(DOW FROM data_pedido)                AS dia_semana,
       DATE_TRUNC('month', data_pedido)::DATE       AS inicio_do_mes
FROM pedidos
WHERE data_pedido >= NOW() - INTERVAL '30 days'
ORDER BY data_pedido;


-- Questão 9
-- Problema: saber há quanto tempo cada pedido foi feito e qual o
-- vencimento do pagamento, que é 30 dias depois do pedido.
SELECT id_pedido,
       data_pedido,
       AGE(NOW(), data_pedido)                      AS tempo_decorrido,
       (data_pedido + INTERVAL '30 days')::DATE     AS vencimento
FROM pedidos
WHERE status <> 'cancelado'
ORDER BY data_pedido;


-- Questão 10
-- Problema: relatório gerencial dos pedidos com o nome do cliente, data
-- no padrão brasileiro e o valor total formatado em reais. O código do
-- pedido sai com zeros à esquerda (LPAD) e tem uma frase montada com
-- FORMAT. O TRANSLATE troca vírgula por ponto pra ficar no padrão BR
-- (1.234,56), já que o TO_CHAR sai no padrão americano.
SELECT LPAD(p.id_pedido::TEXT, 5, '0')                       AS codigo,
       c.nome                                                AS cliente,
       TO_CHAR(p.data_pedido, 'DD/MM/YYYY')                  AS data_pedido,
       TRANSLATE(TO_CHAR(SUM(i.quantidade * i.preco_unitario),
                         'FM999,999,990.00'), ',.', '.,')    AS valor_total,
       FORMAT('Pedido %s de %s - %s', p.id_pedido, c.nome, p.status) AS resumo
FROM pedidos p
INNER JOIN clientes c     ON c.id_cliente = p.id_cliente
INNER JOIN itens_pedido i ON i.id_pedido = p.id_pedido
GROUP BY p.id_pedido, c.nome, p.data_pedido, p.status
ORDER BY p.id_pedido;
