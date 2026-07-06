-- =============================================================================
-- LIBRETA DE CLAVES: MANUAL DE CONSULTAS, SUBCONSULTAS Y QUERIES MIXTOS (POSTGRESQL)
-- =============================================================================
-- Este archivo sirve como una guía de referencia rápida para construir consultas
-- desde lo básico hasta lo avanzado, utilizando un modelo de base de datos ficticio.
--
-- MODELO DE DATOS DE REFERENCIA (Imaginario para los contextos):
-- 1. departamentos (id, nombre, ubicacion)
-- 2. empleados (id, nombre, apellido, salario, fecha_contratacion, departamento_id, jefe_id)
-- 3. proyectos (id, nombre, presupuesto)
-- 4. empleados_proyectos (empleado_id, proyecto_id, horas_asignadas)
-- =============================================================================

-- =============================================================================
-- BLOQUE 1: CONSULTAS BÁSICAS, FILTRADO Y FUNCIONES ÚTILES DE POSTGRESQL
-- =============================================================================

-- Contexto: Buscar empleados cuyo apellido empiece por 'M' y tengan un salario 
-- superior a 2500, ordenados del salario más alto al más bajo.
SELECT nombre, apellido, salario
FROM empleados
WHERE apellido ILIKE 'M%' -- ILIKE en Postgres es insensible a mayúsculas/minúsculas
  AND salario > 2500
ORDER BY salario DESC;

-- Contexto: Obtener los empleados contratados en los últimos 5 años utilizando 
-- el manejo de intervalos nativo de PostgreSQL.
SELECT nombre, apellido, fecha_contratacion
FROM empleados
WHERE fecha_contratacion >= CURRENT_DATE - INTERVAL '5 years';


-- =============================================================================
-- BLOQUE 2: CONSULTAS CON AGREGACIONES Y ASOCIACIONES (JOINS + PROMEDIOS)
-- =============================================================================

-- Contexto: Como mencionabas en tu ejemplo ("asociar X tabla con otra y sacar el promedio").
-- Queremos listar todos los departamentos y calcular el promedio salarial de sus 
-- empleados. Solo queremos mostrar los departamentos cuyo promedio sea mayor a 3000.
-- Usamos ROUND y cast (::numeric) para formatear los decimales en Postgres.
SELECT 
    d.nombre AS departamento,
    COUNT(e.id) AS total_empleados,
    ROUND(AVG(e.salario)::numeric, 2) AS salario_promedio
FROM departamentos d
INNER JOIN empleados e ON d.id = e.departamento_id
GROUP BY d.nombre
HAVING AVG(e.salario) > 3000
ORDER BY salario_promedio DESC;

-- Contexto: Queremos ver TODOS los departamentos de la empresa, incluso si no tienen 
-- empleados asignados todavía (por eso usamos LEFT JOIN), y mostrar el total del presupuesto 
-- invertido en sus salarios. Si es NULL, mostrar 0 usando COALESCE.
SELECT 
    d.nombre AS departamento,
    COALESCE(SUM(e.salario), 0) AS gasto_total_salarios
FROM departamentos d
LEFT JOIN empleados e ON d.id = e.departamento_id
GROUP BY d.id, d.nombre;


-- =============================================================================
-- BLOQUE 3: SUBCONSULTAS (SUBQUERIES) EN DISTINTAS PARTES DEL QUERY
-- =============================================================================

-- TIPO A: Subconsulta en la cláusula WHERE (Escalares)
-- Contexto: Encontrar a los empleados que ganan más que el promedio general de TODA la empresa.
SELECT nombre, apellido, salario
FROM empleados
WHERE salario > (
    SELECT AVG(salario) 
    FROM empleados
);

-- TIPO B: Subconsulta correlacionada (Se ejecuta por cada fila del query externo)
-- Contexto: Seleccionar los empleados que ganan más que el promedio DE SU PROPIO departamento.
-- El query interno hace referencia a 'e1.departamento_id' del query externo.
SELECT e1.nombre, e1.apellido, e1.salario, e1.departamento_id
FROM empleados e1
WHERE e1.salario > (
    SELECT AVG(e2.salario)
    FROM empleados e2
    WHERE e2.departamento_id = e1.departamento_id
);

-- TIPO C: Subconsulta en la cláusula FROM (Tablas derivadas)
-- Contexto: Primero calculamos el promedio de horas trabajadas en proyectos en una "subtabla" 
-- y luego asociamos los empleados para ver quiénes están por encima de ese promedio de horas.
SELECT e.nombre, res.proyecto_id, res.horas_asignadas
FROM empleados e
INNER JOIN empleados_proyectos ep ON e.id = ep.empleado_id
INNER JOIN (
    -- Subconsulta que actúa como tabla temporal en memoria
    SELECT proyecto_id, AVG(horas_asignadas) AS promedio_horas
    FROM empleados_proyectos
    GROUP BY proyecto_id
) res ON ep.proyecto_id = res.proyecto_id
WHERE ep.horas_asignadas > res.promedio_horas;


-- =============================================================================
-- BLOQUE 4: CONSULTAS MIXTAS Y AVANZADAS (CTEs Y FUNCIONES DE VENTANA)
-- =============================================================================

-- TIPO A: Expresiones de Tabla Comunes (CTEs / Cláusula WITH) - ¡Súper usado en Postgres!
-- Contexto: Es una forma mucho más limpia y legible de hacer subconsultas complejas.
-- Queremos un reporte que desglose el presupuesto de los proyectos, el gasto real en salarios 
-- de la gente metida en ese proyecto, y la diferencia restante.
WITH GastoProyecto AS (
    -- Primera "subconsulta" organizada arriba
    SELECT 
        ep.proyecto_id,
        SUM(e.salario * (ep.horas_asignadas / 160.0)) AS costo_estimado_personal
    FROM empleados_proyectos ep
    INNER JOIN empleados e ON ep.empleado_id = e.id
    GROUP BY ep.proyecto_id
)
SELECT 
    p.nombre AS nombre_proyecto,
    p.presupuesto,
    ROUND(gp.costo_estimado_personal::numeric, 2) AS costo_personal,
    ROUND((p.presupuesto - gp.costo_estimado_personal)::numeric, 2) AS balance_restante
FROM proyectos p
INNER JOIN GastoProyecto gp ON p.id = gp.proyecto_id;

-- TIPO B: Funciones de Ventana (Window Functions - OVER / PARTITION BY)
-- Contexto: Queremos listar a los empleados con sus salarios, pero al lado de cada uno queremos 
-- ver cuál es el salario más alto de su departamento y qué puesto (ranking) ocupa el empleado 
-- dentro de su propio departamento según su sueldo, SIN colapsar las filas en un GROUP BY.
SELECT 
    e.nombre,
    e.apellido,
    d.nombre AS departamento,
    e.salario,
    -- Obtiene el máximo del departamento actual sin agrupar
    MAX(e.salario) OVER(PARTITION BY e.departamento_id) AS salario_maximo_depto,
    -- Genera una posición (1, 2, 3...) según el salario dentro del departamento
    RANK() OVER(PARTITION BY e.departamento_id ORDER BY e.salario DESC) AS ranking_salario_depto
FROM empleados e
INNER JOIN departamentos d ON e.departamento_id = d.id;


-- =============================================================================
-- BLOQUE 5: CONSULTAS MIXTAS DE CONTROL Y OPERADORES DE CONJUNTOS
-- =============================================================================

-- Contexto: Queremos una lista única de personas clave. Combinaremos usando UNION 
-- a los directores de departamento (jefes) y a los empleados que tienen asignadas 
-- más de 40 horas en un solo proyecto, eliminando duplicados.
SELECT nombre, apellido, 'Director/Jefe' AS rol
FROM empleados
WHERE id IN (SELECT DISTINCT jefe_id FROM empleados WHERE jefe_id IS NOT NULL)

UNION

SELECT DISTINCT e.nombre, e.apellido, 'Alta Carga de Proyecto' AS rol
FROM empleados e
INNER JOIN empleados_proyectos ep ON e.id = ep.empleado_id
WHERE ep.horas_asignadas > 40;
