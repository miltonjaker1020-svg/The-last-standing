# Inventory Management System

## Project Description

This project consists of the design and implementation of a relational database for an Inventory Management System. The database allows the management of suppliers, products, brands, warehouses, inventory movements, purchases, and cities. It was developed following normalization principles to ensure data integrity, minimize redundancy, and improve database performance.

---

## Technologies Used

- PostgreSQL
- SQL
- DBML (Database Markup Language)
- dbdiagram.io
- Git & GitHub

---

## Database Engine

The database was developed using **PostgreSQL**.

---

## Normalization Process

The database was normalized up to the **Third Normal Form (3NF)**.

The normalization process included:

- Eliminating redundant information.
- Creating independent tables for entities such as Cities, Brands, Suppliers, Products, Warehouses, Purchases, and Inventory.
- Using Primary Keys (PK) to uniquely identify records.
- Using Foreign Keys (FK) to establish relationships between tables.
- Maintaining referential integrity throughout the database.

---

## Database Structure

The database contains the following tables:

- Cities
- Suppliers
- Brands
- Products
- Warehouses
- Inventory
- Purchases
- Types

Each table contains a primary key and the corresponding foreign keys where necessary.

---

## Entity Relationship Model

The Entity Relationship Model (ERD) includes relationships between:

- Cities → Suppliers
- Cities → Warehouses
- Suppliers → Warehouses
- Brands → Products
- Products → Purchases
- Products → Inventory
- Types → Inventory

The ERD was created using **dbdiagram.io**.

---

## Installation Instructions

1. Install PostgreSQL.
2. Open pgAdmin or psql.
3. Create a new database.
4. Execute the DDL script (`01_ddl.sql`).
5. Execute the DML script (`02_dml.sql`).
6. Execute the queries script (`03_queries.sql`).

---

## Database Creation

The database is created using SQL `CREATE TABLE` statements.

The creation script includes:

- Primary Keys
- Foreign Keys
- Constraints
- Data Types

---

## Data Loading Process

Sample data is inserted using SQL `INSERT INTO` statements.

The loading order is:

1. Cities
2. Brands
3. Types
4. Suppliers
5. Products
6. Warehouses
7. Inventory
8. Purchases

This order ensures that all foreign key relationships are respected.

---

## SQL Queries Explanation

The project includes SQL queries to answer business requirements such as:

- Available inventory by product.
- Products stored in each warehouse.
- Total purchases by supplier.
- Products with the lowest stock.
- Top five most purchased products.
- Inventory value by city.

These queries use SQL features such as:

- JOIN
- GROUP BY
- ORDER BY
- SUM()
- COUNT()
- LIMIT

---

## Developer Information

**Full Name:** Milton Ortega

**Clan:** Puerta de Oro