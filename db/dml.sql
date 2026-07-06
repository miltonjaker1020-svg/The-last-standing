-- ==========================
-- TABLA CITIES
-- ==========================
CREATE TABLE cities (
    cities_id SERIAL PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL
);

-- ==========================
-- TABLA TYPES
-- ==========================
CREATE TABLE types (
    type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL
);

-- ==========================
-- TABLA BRAND
-- ==========================
CREATE TABLE brand (
    brand_id SERIAL PRIMARY KEY,
    brand_name VARCHAR(100) NOT NULL
);

-- ==========================
-- TABLA PRODUCTS
-- ==========================
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    product_description VARCHAR(255),
    unit_price NUMERIC(10,2),
    brand_id INTEGER,

    CONSTRAINT fk_product_brand
        FOREIGN KEY (brand_id)
        REFERENCES brand(brand_id)
);

-- ==========================
-- TABLA SUPPLIERS
-- ==========================
CREATE TABLE suppliers (
    supplier_id SERIAL PRIMARY KEY,
    supplier_name VARCHAR(150) NOT NULL,
    city_name INTEGER,
    supplier_tax VARCHAR(30),
    supplier_phone VARCHAR(20),

    CONSTRAINT fk_supplier_city
        FOREIGN KEY (city_name)
        REFERENCES cities(cities_id)
);

-- ==========================
-- TABLA WAREHOUSE
-- ==========================
CREATE TABLE warehouse (
    warehouse_id SERIAL PRIMARY KEY,
    warehouse_name VARCHAR(100),
    warehouse_address VARCHAR(225) NOT NULL,
    supplier_id INTEGER NOT NULL,
    city_id INTEGER,

    CONSTRAINT fk_warehouse_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES suppliers(supplier_id),

    CONSTRAINT fk_warehouse_city
        FOREIGN KEY (city_id)
        REFERENCES cities(cities_id)
);

-- ==========================
-- TABLA INVENTORY
-- ==========================
CREATE TABLE inventory (
    inventory_id SERIAL PRIMARY KEY,
    product_id INTEGER,
    type_id INTEGER,
    movement_date TIMESTAMP,
    movement_quantity INTEGER,
    movement_stock_before INTEGER,

    CONSTRAINT fk_inventory_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id),

    CONSTRAINT fk_inventory_type
        FOREIGN KEY (type_id)
        REFERENCES types(type_id)
);

-- ==========================
-- TABLA PURCHASES
-- ==========================
CREATE TABLE purchases (
    purchase_id SERIAL PRIMARY KEY,
    purchase_date TIMESTAMP,
    purchased_quantity INTEGER,
    unit_measure VARCHAR(50),
    product_id INTEGER,
    observations TEXT,
    responsible_user VARCHAR(100),

    CONSTRAINT fk_purchase_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
);




problemas de diseño:

. city_name en suppliers debería llamarse city_id, porque almacena una FK, no el nombre de la ciudad.
. unit_measure no debería ser FK si no existe una tabla unit_measure.
. observations no debería ser FK, debe ser TEXT.
. responsible_user no debería ser PK, ya que la clave primaria ya es purchase_id.

A products le falta supplier_id, porque piden:

Registrar un nuevo producto asociado al proveedor.

Entonces debería quedar:

supplier_id INTEGER,
FOREIGN KEY (supplier_id)
    REFERENCES suppliers(supplier_id)

Te faltan algunos CHECK, por ejemplo:

unit_price NUMERIC(10,2) CHECK (unit_price > 0),
purchased_quantity INTEGER CHECK (purchased_quantity > 0),
movement_quantity INTEGER CHECK (movement_quantity >= 0)

Mi recomendación: no entregues este modelo tal cual. Con unos pequeños cambios queda mucho más profesional y te facilitará las consultas SQL que te piden.



















Para el DML

Supongamos que corriges eso.

1. Insertar un proveedor

    INSERT INTO suppliers
    (supplier_name, city_id, supplier_tax, supplier_phone)
    VALUES
    ('Alimentos del Norte',1,'900123456','3004567890');

2. Insertar una marca
    INSERT INTO brands
    (brand_name)
    VALUES
    ('Nestlé');

3. Insertar un producto
    INSERT INTO products
    (product_name,
    product_description,
    unit_price,
    supplier_id,
    brand_id)

    VALUES
    (
    'Leche Entera',
    'Bolsa 1 Litro',
    4500,
    1,
    1
    );
  

Cambiar teléfono proveedor

    UPDATE suppliers

    SET supplier_phone='3115559988'

    WHERE supplier_id=1;

Cambiar ciudad de bodega
    UPDATE warehouse

    SET city_id=2

    WHERE warehouse_id=1;


Cambiar precio
    UPDATE products

    SET unit_price=5200

    WHERE product_id=1;
    DELETE

El profesor dice

eliminar únicamente cuando no tenga compras ni movimientos.

Entonces:

DELETE FROM products p

WHERE product_id=1

AND NOT EXISTS(

SELECT *

FROM purchases c

WHERE c.product_id=p.product_id

)

AND NOT EXISTS(

SELECT *

FROM inventory i

WHERE i.product_id=p.product_id

);


Si tiene registros no borrará nada.



CONSULTA 1

Inventario disponible

SELECT

p.product_name,

SUM(i.movement_quantity) AS stock

FROM products p

JOIN inventory i

ON p.product_id=i.product_id

GROUP BY p.product_name;


CONSULTA 2

Productos por bodega

Aquí tienes un problema.

No existe una relación entre Inventario y Warehouse.

Necesitas

inventory

warehouse_id FK

Entonces:

SELECT

w.warehouse_name,

p.product_name,

i.movement_quantity

FROM warehouse w

JOIN inventory i

ON w.warehouse_id=i.warehouse_id

JOIN products p

ON p.product_id=i.product_id;


CONSULTA 3

Total comprado por proveedor

SELECT

s.supplier_name,

SUM(c.purchased_quantity*p.unit_price) AS total

FROM suppliers s

JOIN products p

ON s.supplier_id=p.supplier_id

JOIN purchases c

ON p.product_id=c.product_id

GROUP BY s.supplier_name;


CONSULTA 4

Menor existencia

SELECT

p.product_name,

SUM(i.movement_quantity) stock

FROM products p

JOIN inventory i

ON p.product_id=i.product_id

GROUP BY p.product_name

ORDER BY stock

LIMIT 10;


CONSULTA 5

Top 5 comprados

SELECT

p.product_name,

SUM(c.purchased_quantity) total

FROM purchases c

JOIN products p

ON c.product_id=p.product_id

GROUP BY p.product_name

ORDER BY total DESC

LIMIT 5;


CONSULTA 6

Valor económico por ciudad

SELECT

c.city_name,

SUM(i.movement_quantity*p.unit_price) valor

FROM cities c

JOIN warehouse w

ON c.cities_id=w.city_id

JOIN inventory i

ON w.warehouse_id=i.warehouse_id

JOIN products p

ON p.product_id=i.product_id

GROUP BY c.city_name;