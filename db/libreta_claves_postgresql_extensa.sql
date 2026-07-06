-- =============================================================================
-- LA GRAN LIBRETA DE CLAVES DE POSTGRESQL (EDICIÓN DEFINITIVA: 40 QUERIES)
-- =============================================================================
-- Este archivo contiene exactamente 40 ejemplos prácticos divididos en 4 niveles
-- de dificultad (10 consultas por nivel). 
--
-- MODELO DE DATOS DE REFERENCIA UTILIZADO EN LOS CONTEXTOS:
-- 1. usuarios (id, nombre, email, pais, fecha_registro)
-- 2. productos (id, nombre, categoria, precio, stock, especificaciones_json)
-- 3. pedidos (id, usuario_id, fecha_pedido, estado, total)
-- 4. detalles_pedidos (id, pedido_id, producto_id, cantidad, precio_unitario)
-- 5. empleados (id, nombre, salario, departamento_id, jefe_id, fecha_contratacion)
-- 6. departamentos (id, nombre, presupuesto)
-- =============================================================================

-- =============================================================================
-- PARTE 1: NIVEL BÁSICO (1 a 10)
-- Consultas directas, filtrados esenciales, ordenamientos y funciones de agregación puras.
-- =============================================================================

-- Q1. Contexto: Obtener todos los campos de los usuarios que se registraron desde un país específico (ej. 'Colombia').
SELECT id, nombre, email, pais, fecha_registro
FROM usuarios
WHERE pais = 'Colombia';

-- Q2. Contexto: Encontrar productos que están en un rango de precio específico (entre 50 y 150 dólares) para una campaña.
SELECT id, nombre, precio, stock
FROM productos
WHERE precio BETWEEN 50 AND 150;

-- Q3. Contexto: Buscar usuarios cuyo correo electrónico pertenezca a un dominio específico (ej. 'gmail.com') ignorando mayúsculas/minúsculas.
SELECT nombre, email
FROM usuarios
WHERE email ILIKE '%@gmail.com';

-- Q4. Contexto: Listar los 5 productos más caros que tenemos en inventario para mostrarlos en el banner de destacados.
SELECT nombre, precio, stock
FROM productos
ORDER BY precio DESC
LIMIT 5;

-- Q5. Contexto: Mostrar el nombre de los productos y calcular automáticamente el precio que tendrían si les aplicamos un 15% de descuento.
SELECT nombre, precio AS precio_original, (precio * 0.85) AS precio_con_descuento
FROM productos;

-- Q6. Contexto: Saber cuántos usuarios totales se han registrado en la plataforma hasta el día de hoy.
SELECT COUNT(id) AS total_usuarios
FROM usuarios;

-- Q7. Contexto: Calcular cuánta plata representa todo el inventario que tenemos guardado en bodega (precio multiplicado por stock).
SELECT SUM(precio * stock) AS valor_total_inventario
FROM productos;

-- Q8. Contexto: Identificar cuál es el producto más barato y cuál es el más caro de la categoría 'Electrónica'.
SELECT MIN(precio) AS precio_minimo, MAX(precio) AS precio_maximo
FROM productos
WHERE categoria = 'Electrónica';

-- Q9. Contexto: Obtener una lista única y sin duplicados de todos los países de origen de nuestros usuarios para un reporte geográfico.
SELECT DISTINCT pais
FROM usuarios
ORDER BY pais ASC;

-- Q10. Contexto: Buscar qué pedidos están en un limbo legal o logístico porque no tienen asignado un estado (el campo es NULL).
SELECT id, usuario_id, total
FROM pedidos
WHERE estado IS NULL;


-- =============================================================================
-- PARTE 2: NIVEL MEDIO (11 a 20)
-- Asociaciones (JOINS), agrupaciones con condiciones, manejo de fechas y subconsultas básicas.
-- =============================================================================

-- Q11. Contexto: Cruzar datos para ver qué usuarios han hecho pedidos, mostrando el nombre del comprador, la fecha y el total pagado.
SELECT u.nombre AS cliente, p.fecha_pedido, p.total
FROM usuarios u
INNER JOIN pedidos p ON u.id = p.usuario_id;

-- Q12. Contexto: Auditoría de marketing. Listar TODOS los usuarios del sistema y ver sus pedidos. Si no han comprado nada, debe aparecer NULL.
SELECT u.nombre AS cliente, u.email, p.id AS numero_pedido
FROM usuarios u
LEFT JOIN pedidos p ON u.id = p.usuario_id;

-- Q13. Contexto: Conocer el comportamiento del consumidor. Agrupar las compras para saber cuántos pedidos ha hecho cada usuario en total.
SELECT u.nombre, COUNT(p.id) AS cantidad_pedidos
FROM usuarios u
INNER JOIN pedidos p ON u.id = p.usuario_id
GROUP BY u.id, u.nombre
ORDER BY cantidad_pedidos DESC;

-- Q14. Contexto: Analizar categorías de productos. Sacar el precio promedio por categoría, pero solo mostrar aquellas cuyo promedio supere los 200 dólares.
SELECT categoria, ROUND(AVG(precio)::numeric, 2) AS precio_promedio
FROM productos
GROUP BY categoria
HAVING AVG(precio) > 200;

-- Q15. Contexto: Reporte de rendimiento temporal. Extraer todos los pedidos que se realizaron específicamente en el año actual (2026).
SELECT id, total, fecha_pedido
FROM pedidos
WHERE EXTRACT(YEAR FROM fecha_pedido) = 2026;

-- Q16. Contexto: Limpieza estético-visual de datos. Concatenar nombre y apellido de empleados y transformar el resultado a mayúsculas sostenidas.
SELECT UPPER(CONCAT(nombre, ' ', 'APELLIDO_FALSO')) AS nombre_completo, salario
FROM empleados;

-- Q17. Contexto: Subconsulta en WHERE. Seleccionar los usuarios que han gastado en un solo pedido más que el promedio general de todos los pedidos históricos.
SELECT usuario_id, total
FROM pedidos
WHERE total > (SELECT AVG(total) FROM pedidos);

-- Q18. Contexto: Subconsulta con operador IN. Encontrar todos los productos que pertenecen a categorías con stock crítico (menos de 5 unidades en total de categoría).
SELECT nombre, categoria, stock
FROM productos
WHERE categoria IN (
    SELECT categoria 
    FROM productos 
    GROUP BY categoria 
    HAVING SUM(stock) < 5
);

-- Q19. Contexto: Multi-JOIN. Unir tres tablas para saber qué productos exactos compró un usuario específico (ej. id de usuario = 45).
SELECT u.nombre AS cliente, prod.nombre AS producto_comprado, dp.cantidad
FROM usuarios u
INNER JOIN pedidos p ON u.id = p.usuario_id
INNER JOIN detalles_pedidos dp ON p.id = dp.pedido_id
INNER JOIN productos prod ON dp.producto_id = prod.id
WHERE u.id = 45;

-- Q20. Contexto: Control de nulos avanzado. Mostrar los productos, pero si el campo 'stock' viene vacío (NULL), transformarlo automáticamente en un 0 usando COALESCE.
SELECT nombre, COALESCE(stock, 0) AS stock_realizado
FROM productos;


-- =============================================================================
-- PARTE 3: NIVEL PRO (21 a 30)
-- Expresiones de Tabla Comunes (CTEs), Funciones de Ventana, lógica condicional y subconsultas complejas.
-- =============================================================================

-- Q21. Contexto: CTE (Cláusula WITH). Aislar primero las ventas totales de los usuarios en una tabla temporal en memoria, y luego cruzarla con los perfiles.
WITH VentasPorUsuario AS (
    SELECT usuario_id, SUM(total) AS dinero_gastado
    FROM pedidos
    WHERE estado = 'Completado'
    GROUP BY usuario_id
)
SELECT u.nombre, u.email, v.dinero_gastado
FROM usuarios u
INNER JOIN VentasPorUsuario v ON u.id = v.usuario_id
WHERE v.dinero_gastado > 500;

-- Q22. Contexto: Función de Ventana - ROW_NUMBER(). Obtener el último pedido realizado por cada usuario sin usar agrupaciones tradicionales destructivas.
SELECT usuario_id, id AS pedido_id, fecha_pedido, total
FROM (
    SELECT usuario_id, id, fecha_pedido, total,
           ROW_NUMBER() OVER(PARTITION BY usuario_id ORDER BY fecha_pedido DESC) AS posicion
    FROM pedidos
) sub
WHERE sub.posicion = 1;

-- Q23. Contexto: Función de Ventana - SUM() OVER. Calcular un "Total Acumulado" (Running Total) de las ventas de la empresa a lo largo de los días.
SELECT id AS pedido_id, fecha_pedido, total,
       SUM(total) OVER(ORDER BY fecha_pedido ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS saldo_acumulado_historico
FROM pedidos;

-- Q24. Contexto: Lógica condicional con CASE WHEN. Clasificar dinámicamente los productos en tres rangos de etiquetas según su precio actual.
SELECT nombre, precio,
       CASE 
           WHEN precio < 50 THEN 'Económico'
           WHEN precio BETWEEN 50 AND 200 THEN 'Estándar'
           ELSE 'Premium/Lujo'
       END AS clasificacion_precio
FROM productos;

-- Q25. Contexto: Subconsulta Correlacionada Avanzada. Filtrar los empleados cuyo salario sea superior al promedio del departamento al que pertenecen.
SELECT e.nombre, e.salario, e.departamento_id
FROM empleados e
WHERE e.salario > (
    SELECT AVG(sub.salario)
    FROM empleados sub
    WHERE sub.departamento_id = e.departamento_id
);

-- Q26. Contexto: Función de Ventana - LAG(). Comparar la venta del pedido actual contra la venta del pedido inmediatamente anterior para ver si el ticket subió o bajó.
SELECT id AS pedido_id, usuario_id, total AS venta_actual,
       LAG(total, 1) OVER(PARTITION BY usuario_id ORDER BY fecha_pedido ASC) AS venta_anterior,
       (total - LAG(total, 1) OVER(PARTITION BY usuario_id ORDER BY fecha_pedido ASC)) AS diferencia
FROM pedidos;

-- Q27. Contexto: Optimización con operador EXISTS. Buscar usuarios que tengan al menos una compra registrada sin necesidad de cargar todos los JOINS pesados.
SELECT u.nombre, u.email
FROM usuarios u
WHERE EXISTS (
    SELECT 1 
    FROM pedidos p 
    WHERE p.usuario_id = u.id AND p.estado = 'Completado'
);

-- Q28. Contexto: CTEs Múltiples Encadenadas. Definir dos bloques lógicos arriba y unirlos abajo para un reporte gerencial cruzado de inventario vs pedidos.
WITH ResumenStock AS (
    SELECT categoria, SUM(stock) AS unidades_disponibles
    FROM productos
    GROUP BY categoria
),
ResumenVentas AS (
    SELECT prod.categoria, SUM(dp.cantidad) AS unidades_vendidas
    FROM detalles_pedidos dp
    INNER JOIN productos prod ON dp.producto_id = prod.id
    GROUP BY prod.categoria
)
-- Consulta final uniendo ambas tablas temporales
SELECT rs.categoria, rs.unidades_disponibles, COALESCE(rv.unidades_vendidas, 0) AS unidades_vendidas
FROM ResumenStock rs
LEFT JOIN ResumenVentas rv ON rs.categoria = rv.categoria;

-- Q29. Contexto: Agregación de cadenas de texto (STRING_AGG). Listar en una sola fila compacta, separados por comas, todos los productos de un pedido.
SELECT pedido_id, 
       STRING_AGG(prod.nombre, ', ' ORDER BY prod.nombre) AS lista_productos
FROM detalles_pedidos dp
INNER JOIN productos prod ON dp.producto_id = prod.id
GROUP BY pedido_id;

-- Q30. Contexto: Intervalos y funciones de tiempo complejas. Encontrar empleados cuya antigüedad exacta en la empresa supere los 3 años y 6 meses.
SELECT nombre, fecha_contratacion, AGE(NOW(), fecha_contratacion) AS antiguedad_exacta
FROM empleados
WHERE fecha_contratacion <= NOW() - INTERVAL '3 years 6 months';


-- =============================================================================
-- PARTE 4: NIVEL LEGEND (31 a 40)
-- CTEs Recursivas, manipulación JSONB nativa, uniones laterales, upserts y búsquedas avanzadas.
-- =============================================================================

-- Q31. Contexto: CTE Recursiva (Estructuras Jerárquicas). Recorrer un organigrama de empleados hacia abajo para calcular el nivel de jerarquía de cada uno respecto a sus jefes.
WITH RECURSIVE Organigrama AS (
    -- Ancla de la recursión: Buscar a los jefes máximos (quienes no tienen jefe)
    SELECT id, nombre, jefe_id, 1 AS nivel_jerarquico
    FROM empleados
    WHERE jefe_id IS NULL
    
    UNION ALL
    
    -- Miembro recursivo: Unir los subordinados con sus respectivos jefes calculados arriba
    SELECT e.id, e.nombre, e.jefe_id, o.nivel_jerarquico + 1
    FROM empleados e
    INNER JOIN Organigrama o ON e.jefe_id = o.id
)
SELECT id, nombre, jefe_id, nivel_jerarquico 
FROM Organigrama
ORDER BY nivel_jerarquico, id;

-- Q32. Contexto: Consultas sobre JSONB (NoSQL dentro de Postgres). Extraer propiedades embebidas dentro de un objeto JSON y filtrar usando operadores flecha (`->>`).
-- El campo 'especificaciones_json' guarda estructuras como: {"marca": "Sony", "color": "Negro", "garantia_meses": 24}
SELECT nombre, 
       especificaciones_json ->> 'marca' AS marca, 
       especificaciones_json ->> 'color' AS color
FROM productos
WHERE especificaciones_json ->> 'marca' = 'Sony';

-- Q33. Contexto: Operador de contención JSONB (`@>`). Filtrar de manera ultra eficiente indexada filas que contengan una clave-valor exacta dentro de su estructura JSON.
SELECT id, nombre, especificaciones_json
FROM productos
WHERE especificaciones_json @> '{"garantia_meses": 24}';

-- Q34. Contexto: LATERAL JOIN (Subconsultas dependientes por fila). Para cada departamento del sistema, traer dinámicamente los 2 empleados que registran el salario más alto.
SELECT d.nombre AS depto, emp.nombre AS empleado, emp.salario
FROM departamentos d
LEFT JOIN LATERAL (
    SELECT nombre, salario
    FROM empleados e
    WHERE e.departamento_id = d.id
    ORDER BY salario DESC
    LIMIT 2
) emp ON TRUE;

-- Q35. Contexto: UPSERT (ON CONFLICT). Insertar un nuevo producto en la tabla, pero si el 'id' ya existe (conflicto de llave primaria), actualizar el stock sumándole el nuevo ingresado.
INSERT INTO productos (id, nombre, categoria, precio, stock)
VALUES (105, 'Teclado Mecánico RGB', 'Accesorios', 89.99, 10)
ON CONFLICT (id) 
DO UPDATE SET stock = productos.stock + EXCLUDED.stock, precio = EXCLUDED.precio;

-- Q36. Contexto: Ventanas con marcos móviles avanzados (Moving Average). Calcular el promedio móvil de ingresos considerando el pedido actual y las 2 ventas previas directas.
SELECT id, fecha_pedido, total,
       ROUND(AVG(total) OVER(ORDER BY fecha_pedido ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)::numeric, 2) AS promedio_movil_3_pedidos
FROM pedidos;

-- Q37. Contexto: Full-Text Search (Búsqueda de texto indexada). Buscar palabras utilizando vectores lingüísticos y diccionarios nativos de Postgres, ignorando plurales o conjugaciones.
-- Busca productos que contengan variaciones de las palabras 'computadora' y 'portátil' eficientemente.
SELECT id, nombre
FROM productos
WHERE to_tsvector('spanish', nombre) @@ to_tsquery('spanish', 'computadora & portátil');

-- Q38. Contexto: Agrupaciones Matriciales Avanzadas - ROLLUP. Generar subtotales automáticos por jerarquía de campos: Ventas totales por Año, por Mes dentro de ese año, y el Gran Total global.
SELECT EXTRACT(YEAR FROM fecha_pedido) AS anio,
       EXTRACT(MONTH FROM fecha_pedido) AS mes,
       SUM(total) AS ingresos_totales
FROM pedidos
GROUP BY ROLLUP (EXTRACT(YEAR FROM fecha_pedido), EXTRACT(MONTH FROM fecha_pedido))
ORDER BY anio, mes;

-- Q39. Contexto: Manipulación avanzada de Arrays nativos. Agrupar los IDs de todos los productos comprados por un usuario dentro de un arreglo y verificar si compró ciertos elementos usando operadores de arreglos.
SELECT usuario_id, 
       ARRAY_AGG(producto_id) AS lista_ids_comprados
FROM pedidos p
INNER JOIN detalles_pedidos dp ON p.id = dp.pedido_id
GROUP BY usuario_id
HAVING ARRAY_AGG(producto_id) && ARRAY[10, 15, 22]; -- El operador '&&' verifica si hay elementos en común (intersección)

-- Q40. Contexto: Desglose expansivo de datos JSONB (jsonb_to_recordset). Transformar un arreglo de objetos JSON almacenado en una celda en un conjunto de filas y columnas SQL estructuradas tradicionales.
-- Imaginemos que el JSON contiene un historial de revisiones técnicas: [{"fecha":"2026-01-01", "tecnico":"Juan"}, {"fecha":"2026-05-01", "tecnico":"Ana"}]
SELECT p.nombre, rev.fecha, rev.tecnico
FROM productos p,
LATERAL jsonb_to_recordset(p.especificaciones_json -> 'historial_revisiones') 
    AS rev(fecha DATE, tecnico TEXT);
