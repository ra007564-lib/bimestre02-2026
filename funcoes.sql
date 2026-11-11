-- =====================================================================
-- TRABALHO 02 - FUNCTIONS (PL/pgSQL)
-- Banco: fabrica de doces (continuacao do script1.sql)
-- Aluno: Willian de Freitas
--
-- Funcoes criadas:
-- 1) retorna_status_estoque  -> diz se o ingrediente esta com estoque ok
-- 2) rt_custo_producao       -> custo de ingredientes de 1 unidade do produto
-- 3) rt_total_pedido         -> valor total de um pedido
-- 4) baixa_ingredientes_pedido -> da baixa no estoque quando o pedido
--                                 vai para producao
-- =====================================================================


-- ---------------------------------------------------------------------
-- FUNCAO 1: status do estoque de um ingrediente (retorna TEXT)
-- Usa o FOUND pra tratar quando o id nao existe e compara o estoque
-- atual com o minimo.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION retorna_status_estoque(p_id_ingrediente INT)
RETURNS TEXT AS $$
DECLARE
    v_nome    TEXT;
    v_atual   NUMERIC(10,2);
    v_minimo  NUMERIC(10,2);
BEGIN
    SELECT nome, estoque_atual, estoque_minimo
    INTO v_nome, v_atual, v_minimo
    FROM ingredientes
    WHERE id_ingrediente = p_id_ingrediente;

    IF NOT FOUND THEN
        RETURN 'Ingrediente não encontrado!';
    END IF;

    IF v_atual < v_minimo THEN
        RETURN v_nome || ' - Estoque abaixo do mínimo, precisa comprar';
    ELSE
        RETURN v_nome || ' - Estoque OK';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Testes
SELECT retorna_status_estoque(1);    -- Açúcar (ok)
SELECT retorna_status_estoque(10);   -- Goiaba (abaixo do minimo)
SELECT retorna_status_estoque(99);   -- id que nao existe
SELECT i.nome, retorna_status_estoque(i.id_ingrediente) AS situacao
FROM ingredientes i;


-- ---------------------------------------------------------------------
-- FUNCAO 2: custo de producao de 1 unidade do produto (retorna NUMERIC)
-- Soma quantidade da receita * custo do ingrediente. Se o produto nao
-- tiver receita ou nao existir, o COALESCE devolve 0.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION rt_custo_producao(p_id_produto INT)
RETURNS NUMERIC(10,2) AS $$
DECLARE
    v_custo NUMERIC(10,2);
BEGIN
    SELECT SUM(r.quantidade * i.custo_unitario)
    INTO v_custo
    FROM receitas r
    JOIN ingredientes i ON i.id_ingrediente = r.id_ingrediente
    WHERE r.id_produto = p_id_produto;

    RETURN COALESCE(v_custo, 0.00);
END;
$$ LANGUAGE plpgsql;

-- Testes
SELECT rt_custo_producao(1);
SELECT rt_custo_producao(99);   -- retorna 0
SELECT nome, preco_venda,
       rt_custo_producao(id_produto) AS custo,
       preco_venda - rt_custo_producao(id_produto) AS lucro
FROM produtos
ORDER BY lucro DESC;


-- ---------------------------------------------------------------------
-- FUNCAO 3: valor total de um pedido (retorna NUMERIC)
-- Soma quantidade * preco_unitario dos itens do pedido.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION rt_total_pedido(p_id_pedido INT)
RETURNS NUMERIC(10,2) AS $$
DECLARE
    v_total NUMERIC(10,2);
BEGIN
    SELECT SUM(quantidade * preco_unitario)
    INTO v_total
    FROM itens_pedido
    WHERE id_pedido = p_id_pedido;

    RETURN COALESCE(v_total, 0.00);
END;
$$ LANGUAGE plpgsql;

-- Testes
SELECT rt_total_pedido(1);
SELECT rt_total_pedido(99);   -- retorna 0
SELECT p.id_pedido, c.nome, p.status, rt_total_pedido(p.id_pedido) AS total
FROM pedidos p
JOIN clientes c ON c.id_cliente = p.id_cliente
ORDER BY p.id_pedido;


-- ---------------------------------------------------------------------
-- FUNCAO 4: baixa de ingredientes de um pedido (retorna VOID)
-- Para cada ingrediente usado nos produtos do pedido, calcula o total
-- gasto (receita * quantidade pedida) e tira do estoque. No final muda
-- o status do pedido para 'em producao'.
-- So funciona para pedido pendente e se tiver estoque suficiente.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION baixa_ingredientes_pedido(p_id_pedido INT)
RETURNS VOID AS $$
DECLARE
    v_status  VARCHAR(20);
    v_estoque NUMERIC(10,2);
    reg       RECORD;
BEGIN
    SELECT status INTO v_status
    FROM pedidos
    WHERE id_pedido = p_id_pedido;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pedido % não encontrado', p_id_pedido;
    END IF;

    IF v_status <> 'pendente' THEN
        RAISE EXCEPTION 'Pedido % está com status %, só pedido pendente pode ir pra produção', p_id_pedido, v_status;
    END IF;

    FOR reg IN
        SELECT r.id_ingrediente, ing.nome,
               SUM(r.quantidade * ip.quantidade) AS total_gasto
        FROM itens_pedido ip
        JOIN receitas r     ON r.id_produto = ip.id_produto
        JOIN ingredientes ing ON ing.id_ingrediente = r.id_ingrediente
        WHERE ip.id_pedido = p_id_pedido
        GROUP BY r.id_ingrediente, ing.nome
    LOOP
        SELECT estoque_atual INTO v_estoque
        FROM ingredientes
        WHERE id_ingrediente = reg.id_ingrediente;

        IF v_estoque < reg.total_gasto THEN
            RAISE EXCEPTION 'Estoque insuficiente de % (tem %, precisa %)',
                reg.nome, v_estoque, reg.total_gasto;
        END IF;

        UPDATE ingredientes
        SET estoque_atual = estoque_atual - reg.total_gasto
        WHERE id_ingrediente = reg.id_ingrediente;
    END LOOP;

    UPDATE pedidos SET status = 'em producao' WHERE id_pedido = p_id_pedido;
END;
$$ LANGUAGE plpgsql;

-- Testes
-- antes
SELECT nome, estoque_atual FROM ingredientes ORDER BY id_ingrediente;
SELECT id_pedido, status FROM pedidos WHERE id_pedido = 10;

-- executando (pedido 10 esta pendente)
SELECT baixa_ingredientes_pedido(10);

-- depois
SELECT nome, estoque_atual FROM ingredientes ORDER BY id_ingrediente;
SELECT id_pedido, status FROM pedidos WHERE id_pedido = 10;

-- esses dois dao erro (ja entregue e pedido inexistente)
-- SELECT baixa_ingredientes_pedido(1);
-- SELECT baixa_ingredientes_pedido(99);
