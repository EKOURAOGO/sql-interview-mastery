-- ============================================================
-- SQL Interview Mastery — Schema
-- Compatible MySQL 8.0+ / MariaDB 10.5+
-- ============================================================

DROP DATABASE IF EXISTS sql_interview_db;
CREATE DATABASE sql_interview_db CHARACTER SET utf8mb4;
USE sql_interview_db;

-- ------------------------------------------------------------
-- departments
-- ------------------------------------------------------------
CREATE TABLE departments (
    department_id   INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(100) NOT NULL
);

-- ------------------------------------------------------------
-- employees (self-referencing hierarchy via manager_id)
-- ------------------------------------------------------------
CREATE TABLE employees (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    name            VARCHAR(100) NOT NULL,
    department_id   INT,
    manager_id      INT,
    salary          DECIMAL(10,2) NOT NULL,
    hire_date       DATE NOT NULL,
    join_date       DATE NOT NULL,
    FOREIGN KEY (department_id) REFERENCES departments(department_id),
    FOREIGN KEY (manager_id) REFERENCES employees(id)
);

-- ------------------------------------------------------------
-- salary_history — past salary changes per employee
-- ------------------------------------------------------------
CREATE TABLE salary_history (
    history_id      INT PRIMARY KEY AUTO_INCREMENT,
    employee_id     INT NOT NULL,
    old_salary      DECIMAL(10,2),
    new_salary      DECIMAL(10,2),
    change_date     DATE NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employees(id)
);

-- ------------------------------------------------------------
-- promotions
-- ------------------------------------------------------------
CREATE TABLE promotions (
    promotion_id    INT PRIMARY KEY AUTO_INCREMENT,
    employee_id     INT NOT NULL,
    promotion_date  DATE NOT NULL,
    new_title       VARCHAR(100),
    FOREIGN KEY (employee_id) REFERENCES employees(id)
);

-- ------------------------------------------------------------
-- attendance
-- ------------------------------------------------------------
CREATE TABLE attendance (
    attendance_id    INT PRIMARY KEY AUTO_INCREMENT,
    employee_id      INT NOT NULL,
    attendance_date  DATE NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employees(id)
);

-- ------------------------------------------------------------
-- projects / project_assignments
-- ------------------------------------------------------------
CREATE TABLE projects (
    project_id      INT PRIMARY KEY AUTO_INCREMENT,
    project_name    VARCHAR(150) NOT NULL,
    start_date      DATE,
    end_date        DATE
);

CREATE TABLE project_assignments (
    assignment_id   INT PRIMARY KEY AUTO_INCREMENT,
    project_id      INT NOT NULL,
    employee_id     INT NOT NULL,
    role            VARCHAR(100),
    FOREIGN KEY (project_id) REFERENCES projects(project_id),
    FOREIGN KEY (employee_id) REFERENCES employees(id)
);

-- ------------------------------------------------------------
-- customers
-- ------------------------------------------------------------
CREATE TABLE customers (
    customer_id     INT PRIMARY KEY AUTO_INCREMENT,
    customer_name   VARCHAR(100) NOT NULL,
    signup_date     DATE
);

-- ------------------------------------------------------------
-- products
-- ------------------------------------------------------------
CREATE TABLE products (
    product_id      INT PRIMARY KEY AUTO_INCREMENT,
    product_name    VARCHAR(100) NOT NULL,
    category_id     INT,
    price           DECIMAL(10,2)
);

-- ------------------------------------------------------------
-- orders / order_items
-- ------------------------------------------------------------
CREATE TABLE orders (
    order_id        INT PRIMARY KEY AUTO_INCREMENT,
    customer_id     INT NOT NULL,
    product_id      INT,
    order_date      DATE NOT NULL,
    amount          DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE order_items (
    order_item_id   INT PRIMARY KEY AUTO_INCREMENT,
    order_id        INT NOT NULL,
    product_id      INT NOT NULL,
    quantity        INT NOT NULL,
    unit_price      DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ------------------------------------------------------------
-- sales — independent fact table (sale_date, amount, product_id, customer_id)
-- ------------------------------------------------------------
CREATE TABLE sales (
    sale_id         INT PRIMARY KEY AUTO_INCREMENT,
    customer_id     INT,
    product_id      INT,
    category_id     INT,
    sale_date       DATE NOT NULL,
    amount          DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ------------------------------------------------------------
-- user_logins — daily login streak analysis
-- ------------------------------------------------------------
CREATE TABLE user_logins (
    login_id        INT PRIMARY KEY AUTO_INCREMENT,
    user_id         INT NOT NULL,
    login_date      DATE NOT NULL
);

-- ------------------------------------------------------------
-- product_reviews
-- ------------------------------------------------------------
CREATE TABLE product_reviews (
    review_id       INT PRIMARY KEY AUTO_INCREMENT,
    product_id      INT NOT NULL,
    customer_id     INT NOT NULL,
    rating          INT,
    review_date     DATE,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ------------------------------------------------------------
-- shifts — overlapping shift detection
-- ------------------------------------------------------------
CREATE TABLE shifts (
    shift_id        INT PRIMARY KEY AUTO_INCREMENT,
    employee_id     INT NOT NULL,
    start_time      DATETIME NOT NULL,
    end_time        DATETIME NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employees(id)
);

-- ------------------------------------------------------------
-- bookings — overlapping date range detection
-- ------------------------------------------------------------
CREATE TABLE bookings (
    booking_id      INT PRIMARY KEY AUTO_INCREMENT,
    resource_name   VARCHAR(100) NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL
);
