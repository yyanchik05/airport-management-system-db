# Airport Management System Database

This is a comprehensive PostgreSQL database project designed to manage core airport operations, including flight scheduling, gate management, service tasks, and access control.

## Project Structure

* **`airport_ddl.sql`**: Database schema definition (Tables, Constraints, Indexes).
* **`airport_dml.sql`**: Data population script with realistic test data (10+ records per table).
* **`airport_views.sql`**: Analytical views for different user roles (Passenger Board, Manager Dashboard).
* **`airport_procedures.sql`**: Stored procedures and functions (PL/pgSQL) for business logic automation.
* **`airport_security.sql`**: RBAC implementation (Manager vs Viewer roles).

## Key Features

* **Natural Keys Usage**: IATA codes used for delay tracking.
* **Data Integrity**: Strict constraints on timestamps, prices, and statuses.
* **Automation**:
    * `fn_calculate_total_cost`: Automatically calculates service costs per flight.
    * `sp_register_new_flight`: Prevents duplicate flight entries.
* **Security**: Implemented Role-Based Access Control (RBAC) preventing unauthorized deletion of data.

## How to Run

1.  Open your SQL client (e.g., DBeaver).
2.  Run scripts in the following order:
    1.  `airport_ddl.sql`
    2.  `airport_dml.sql`
    3.  `airport_views.sql`
    4.  `airport_procedures.sql`
    5.  `airport_security.sql`

## Author
Yana Shtaba - Aviation Industry Database Coursework
