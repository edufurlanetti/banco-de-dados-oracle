# Lista de exercícios — Recursos Humanos (Oracle)

Execute antes os scripts `01` a `03` da pasta `scripts/`.

1. Liste os funcionários admitidos há mais de 5 anos, mostrando a data no formato `dd/mm/aaaa` (use `TO_CHAR` e `ADD_MONTHS`).
2. Mostre, para cada gestor, a quantidade de subordinados **diretos**.
3. Usando `CONNECT BY`, liste todos os subordinados (diretos e indiretos) de Cláudia Moreira.
4. Quais funcionários ganham acima da média do próprio departamento? Resolva com subconsulta correlacionada.
5. Usando `LISTAGG`, mostre em uma linha por departamento o nome de todos os seus funcionários.
6. Acrescente ao pacote `PKG_RH` a procedure `promover(p_id, p_novo_cargo, p_novo_salario)`, que troca o cargo e o salário em uma única operação (a trigger deve validar a faixa do novo cargo).
7. Escreva um bloco anônimo que percorra os departamentos com um cursor e imprima a folha de cada um com `DBMS_OUTPUT`.

As soluções estão em [`solucoes.sql`](solucoes.sql).
