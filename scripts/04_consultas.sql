-- =============================================================
-- Recursos Humanos — Consultas comentadas (Oracle SQL)
-- =============================================================
SET LINESIZE 200
SET PAGESIZE 100
SET SERVEROUTPUT ON
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

-- 1. Consulta hierárquica (CONNECT BY): organograma da empresa
SELECT LPAD(' ', 4 * (LEVEL - 1)) || f.nome AS organograma,
       c.titulo,
       LEVEL AS nivel
FROM funcionario f
JOIN cargo c ON c.id_cargo = f.id_cargo
START WITH f.id_gestor IS NULL
CONNECT BY PRIOR f.id_funcionario = f.id_gestor
ORDER SIBLINGS BY f.nome;

-- 2. Caminho completo até o diretor (SYS_CONNECT_BY_PATH)
SELECT nome, SYS_CONNECT_BY_PATH(nome, ' > ') AS cadeia_de_comando
FROM funcionario
WHERE CONNECT_BY_ISLEAF = 1
START WITH id_gestor IS NULL
CONNECT BY PRIOR id_funcionario = id_gestor;

-- 3. Funções analíticas: posição salarial dentro do departamento
SELECT d.nome AS departamento, f.nome, f.salario,
       RANK()       OVER (PARTITION BY d.id_departamento ORDER BY f.salario DESC) AS posicao,
       ROUND(AVG(f.salario) OVER (PARTITION BY d.id_departamento), 2)       AS media_depto,
       ROUND(f.salario / SUM(f.salario) OVER (PARTITION BY d.id_departamento) * 100, 1) AS perc_folha
FROM funcionario f
JOIN departamento d ON d.id_departamento = f.id_departamento
WHERE f.ativo = 'S'
ORDER BY d.nome, posicao;

-- 4. Funções do pacote dentro do SQL
SELECT nome, data_admissao, pkg_rh.tempo_de_casa(id_funcionario) AS anos_de_casa
FROM funcionario
ORDER BY anos_de_casa DESC;

SELECT nome AS departamento, pkg_rh.folha_departamento(id_departamento) AS folha_mensal
FROM departamento
ORDER BY folha_mensal DESC;

-- 5. Histórico salarial registrado pela trigger
SELECT f.nome, h.salario_antigo, h.salario_novo,
       ROUND((h.salario_novo / h.salario_antigo - 1) * 100, 1) AS perc_aumento,
       h.data_alteracao, h.usuario
FROM historico_salario h
JOIN funcionario f ON f.id_funcionario = h.id_funcionario
ORDER BY h.id_historico;

-- 6. Top-N (Oracle 12c+): os 3 maiores salários
SELECT nome, salario
FROM funcionario
ORDER BY salario DESC
FETCH FIRST 3 ROWS ONLY;

-- 7. PIVOT: quantidade de funcionários por cargo em cada departamento
SELECT *
FROM (SELECT d.nome AS departamento, c.titulo
      FROM funcionario f
      JOIN departamento d ON d.id_departamento = f.id_departamento
      JOIN cargo c        ON c.id_cargo        = f.id_cargo)
PIVOT (COUNT(*) FOR titulo IN ('Gerente' AS gerente, 'Desenvolvedor' AS dev,
                               'Engenheiro' AS eng, 'Técnico' AS tecnico));

-- 8. Bloco anônimo com tratamento de exceção do pacote
BEGIN
    pkg_rh.desligar(999);
EXCEPTION
    WHEN pkg_rh.e_funcionario_inexistente THEN
        DBMS_OUTPUT.PUT_LINE('Funcionário 999 não encontrado ou já desligado.');
END;
/

-- 9. Regra da trigger: salário fora da faixa do cargo deve gerar ORA-20001
BEGIN
    UPDATE funcionario SET salario = 50000 WHERE id_funcionario = 7;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro esperado: ' || SQLERRM);
        ROLLBACK;
END;
/
