-- Soluções — Recursos Humanos (Oracle)
SET SERVEROUTPUT ON

-- 1
SELECT nome, TO_CHAR(data_admissao, 'DD/MM/YYYY') AS admissao
FROM funcionario
WHERE data_admissao < ADD_MONTHS(SYSDATE, -60)
ORDER BY data_admissao;

-- 2
SELECT g.nome AS gestor, COUNT(f.id_funcionario) AS subordinados_diretos
FROM funcionario g
JOIN funcionario f ON f.id_gestor = g.id_funcionario
GROUP BY g.nome
ORDER BY subordinados_diretos DESC;

-- 3
SELECT LPAD(' ', 2 * (LEVEL - 2)) || nome AS subordinado, LEVEL - 1 AS distancia
FROM funcionario
WHERE LEVEL > 1
START WITH nome = 'Cláudia Moreira'
CONNECT BY PRIOR id_funcionario = id_gestor;

-- 4
SELECT f.nome, f.salario, f.id_departamento
FROM funcionario f
WHERE f.salario > (SELECT AVG(f2.salario)
                   FROM funcionario f2
                   WHERE f2.id_departamento = f.id_departamento);

-- 5
SELECT d.nome AS departamento,
       LISTAGG(f.nome, ', ') WITHIN GROUP (ORDER BY f.nome) AS funcionarios
FROM departamento d
JOIN funcionario f ON f.id_departamento = d.id_departamento
GROUP BY d.nome;

-- 6 — recrie a especificação e o corpo do pacote acrescentando:
--
--   (especificação)
--   PROCEDURE promover (p_id IN funcionario.id_funcionario%TYPE,
--                       p_novo_cargo IN cargo.id_cargo%TYPE,
--                       p_novo_salario IN funcionario.salario%TYPE);
--
--   (corpo)
--   PROCEDURE promover (p_id IN funcionario.id_funcionario%TYPE,
--                       p_novo_cargo IN cargo.id_cargo%TYPE,
--                       p_novo_salario IN funcionario.salario%TYPE) IS
--   BEGIN
--       UPDATE funcionario
--          SET id_cargo = p_novo_cargo,
--              salario  = p_novo_salario
--        WHERE id_funcionario = p_id AND ativo = 'S';
--       IF SQL%ROWCOUNT = 0 THEN
--           RAISE e_funcionario_inexistente;
--       END IF;
--   END promover;
--
-- Teste: EXEC pkg_rh.promover(7, 2, 12500);  -- Igor passa a Gerente

-- 7
DECLARE
    CURSOR c_depto IS
        SELECT id_departamento, nome FROM departamento ORDER BY nome;
BEGIN
    FOR d IN c_depto LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(d.nome, 20, '.') || ' R$ ' ||
                             TO_CHAR(pkg_rh.folha_departamento(d.id_departamento), 'FM999G999G990D00'));
    END LOOP;
END;
/
