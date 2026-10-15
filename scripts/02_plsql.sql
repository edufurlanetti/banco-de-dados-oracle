-- =============================================================
-- Recursos Humanos — Lógica de negócio em PL/SQL
-- Trigger de histórico salarial e o pacote PKG_RH.
-- =============================================================

-- Trigger: registra toda alteração de salário e valida a faixa do cargo
CREATE OR REPLACE TRIGGER trg_funcionario_salario
BEFORE INSERT OR UPDATE OF salario, id_cargo ON funcionario
FOR EACH ROW
DECLARE
    v_min cargo.salario_minimo%TYPE;
    v_max cargo.salario_maximo%TYPE;
BEGIN
    SELECT salario_minimo, salario_maximo
      INTO v_min, v_max
      FROM cargo
     WHERE id_cargo = :NEW.id_cargo;

    IF :NEW.salario NOT BETWEEN v_min AND v_max THEN
        RAISE_APPLICATION_ERROR(-20001,
            'Salário ' || TO_CHAR(:NEW.salario, 'FM999G990D00') ||
            ' fora da faixa do cargo (' || v_min || ' a ' || v_max || ').');
    END IF;

    IF UPDATING('SALARIO') AND :OLD.salario <> :NEW.salario THEN
        INSERT INTO historico_salario (id_funcionario, salario_antigo, salario_novo)
        VALUES (:NEW.id_funcionario, :OLD.salario, :NEW.salario);
    END IF;
END;
/

-- Especificação do pacote: o que fica visível para quem usa
CREATE OR REPLACE PACKAGE pkg_rh AS
    e_funcionario_inexistente EXCEPTION;

    PROCEDURE admitir (
        p_nome   IN  funcionario.nome%TYPE,
        p_email  IN  funcionario.email%TYPE,
        p_salario IN funcionario.salario%TYPE,
        p_cargo  IN  funcionario.id_cargo%TYPE,
        p_depto  IN  funcionario.id_departamento%TYPE,
        p_gestor IN  funcionario.id_gestor%TYPE DEFAULT NULL,
        p_id     OUT funcionario.id_funcionario%TYPE
    );

    PROCEDURE reajustar_departamento (
        p_depto      IN departamento.id_departamento%TYPE,
        p_percentual IN NUMBER
    );

    PROCEDURE desligar (p_id IN funcionario.id_funcionario%TYPE);

    FUNCTION tempo_de_casa (p_id IN funcionario.id_funcionario%TYPE) RETURN NUMBER;

    FUNCTION folha_departamento (p_depto IN departamento.id_departamento%TYPE) RETURN NUMBER;
END pkg_rh;
/

-- Corpo do pacote: a implementação
CREATE OR REPLACE PACKAGE BODY pkg_rh AS

    PROCEDURE admitir (
        p_nome   IN  funcionario.nome%TYPE,
        p_email  IN  funcionario.email%TYPE,
        p_salario IN funcionario.salario%TYPE,
        p_cargo  IN  funcionario.id_cargo%TYPE,
        p_depto  IN  funcionario.id_departamento%TYPE,
        p_gestor IN  funcionario.id_gestor%TYPE DEFAULT NULL,
        p_id     OUT funcionario.id_funcionario%TYPE
    ) IS
    BEGIN
        INSERT INTO funcionario (nome, email, salario, id_cargo, id_departamento, id_gestor)
        VALUES (p_nome, LOWER(p_email), p_salario, p_cargo, p_depto, p_gestor)
        RETURNING id_funcionario INTO p_id;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20002, 'Já existe funcionário com o e-mail ' || p_email);
    END admitir;

    -- Cursor explícito com FOR UPDATE: reajusta respeitando o teto do cargo
    PROCEDURE reajustar_departamento (
        p_depto      IN departamento.id_departamento%TYPE,
        p_percentual IN NUMBER
    ) IS
        CURSOR c_func IS
            SELECT f.id_funcionario, f.salario, c.salario_maximo
              FROM funcionario f
              JOIN cargo c ON c.id_cargo = f.id_cargo
             WHERE f.id_departamento = p_depto
               AND f.ativo = 'S'
               FOR UPDATE OF f.salario;
        v_novo funcionario.salario%TYPE;
    BEGIN
        IF p_percentual NOT BETWEEN 0 AND 30 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Percentual de reajuste deve estar entre 0 e 30.');
        END IF;

        FOR r IN c_func LOOP
            v_novo := LEAST(ROUND(r.salario * (1 + p_percentual / 100), 2), r.salario_maximo);
            UPDATE funcionario SET salario = v_novo WHERE CURRENT OF c_func;
        END LOOP;
    END reajustar_departamento;

    PROCEDURE desligar (p_id IN funcionario.id_funcionario%TYPE) IS
    BEGIN
        UPDATE funcionario SET ativo = 'N' WHERE id_funcionario = p_id AND ativo = 'S';
        IF SQL%ROWCOUNT = 0 THEN
            RAISE e_funcionario_inexistente;
        END IF;
    END desligar;

    FUNCTION tempo_de_casa (p_id IN funcionario.id_funcionario%TYPE) RETURN NUMBER IS
        v_admissao funcionario.data_admissao%TYPE;
    BEGIN
        SELECT data_admissao INTO v_admissao FROM funcionario WHERE id_funcionario = p_id;
        RETURN TRUNC(MONTHS_BETWEEN(SYSDATE, v_admissao) / 12);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END tempo_de_casa;

    FUNCTION folha_departamento (p_depto IN departamento.id_departamento%TYPE) RETURN NUMBER IS
        v_total NUMBER;
    BEGIN
        SELECT NVL(SUM(salario), 0) INTO v_total
          FROM funcionario
         WHERE id_departamento = p_depto AND ativo = 'S';
        RETURN v_total;
    END folha_departamento;

END pkg_rh;
/

SHOW ERRORS
