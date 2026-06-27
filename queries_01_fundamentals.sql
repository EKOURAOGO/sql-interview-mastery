-- ============================================================
-- 01 — Fundamentals: filtering, aggregation, basic joins
-- ============================================================
USE sql_interview_db;

-- Q1. Second highest salary
SELECT MAX(salary) AS second_highest_salary
FROM employees
WHERE salary < (SELECT MAX(salary) FROM employees);

-- Q2. Duplicate records by name
SELECT name, COUNT(*) AS occurrences
FROM employees
GROUP BY name
HAVING COUNT(*) > 1;

-- Q3. Employees who earn more than their manager
SELECT e.name AS employee, e.salary, m.name AS manager, m.salary AS manager_salary
FROM employees e
JOIN employees m ON e.manager_id = m.id
WHERE e.salary > m.salary;

-- Q4. Departments with more than 5 employees
SELECT department_id, COUNT(*) AS num_employees
FROM employees
GROUP BY department_id
HAVING COUNT(*) > 5;

-- Q5. Employees who joined in the last 6 months (relative to a fixed reference date,
--     since the dataset is historical — replace CURDATE() with '2024-12-01' if needed)
SELECT *
FROM employees
WHERE join_date >= DATE_SUB('2024-12-01', INTERVAL 6 MONTH);

-- Q6. Departments with no employees
SELECT d.department_name
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
WHERE e.id IS NULL;

-- Q7. Median salary (MySQL 8.0+ has no native MEDIAN; emulate with PERCENTILE-style ranking)
SELECT AVG(salary) AS median_salary
FROM (
    SELECT salary,
           ROW_NUMBER() OVER (ORDER BY salary) AS rn,
           COUNT(*) OVER () AS cnt
    FROM employees
) ranked
WHERE rn IN (FLOOR((cnt + 1) / 2), CEIL((cnt + 1) / 2));

-- Q14. Rank employees by salary within department (dense rank)
SELECT name, department_id, salary,
       DENSE_RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS salary_rank
FROM employees;

-- Q15. Customers who have not made any purchase
SELECT c.customer_id, c.customer_name
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.customer_id
WHERE s.sale_id IS NULL;

-- Q19. Employees with salary greater than department average
SELECT e.*
FROM employees e
WHERE e.salary > (
    SELECT AVG(salary) FROM employees WHERE department_id = e.department_id
);

-- Q21. Employees who have the same salary as their manager
SELECT e.name AS employee, e.salary, m.name AS manager
FROM employees e
JOIN employees m ON e.manager_id = m.id
WHERE e.salary = m.salary;

-- Q23. Departments with the highest average salary
SELECT department_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
ORDER BY avg_salary DESC
LIMIT 1;

-- Q34. Department with the lowest average salary
SELECT department_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
ORDER BY avg_salary ASC
LIMIT 1;

-- Q41. Duplicate rows based on multiple columns (generic pattern on sales)
SELECT customer_id, sale_date, COUNT(*) AS occurrences
FROM sales
GROUP BY customer_id, sale_date
HAVING COUNT(*) > 1;

-- Q45. Departments and employee counts, including zero-employee departments
SELECT d.department_id, d.department_name, COUNT(e.id) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name;

-- Q48 / Q62. Products never sold / never ordered
SELECT p.product_id, p.product_name
FROM products p
LEFT JOIN sales s ON p.product_id = s.product_id
WHERE s.sale_id IS NULL;

SELECT p.product_id, p.product_name
FROM products p
LEFT JOIN orders o ON p.product_id = o.product_id
WHERE o.order_id IS NULL;

-- Q53. Nth highest salary (N = 3 as example)
SELECT DISTINCT salary
FROM employees
ORDER BY salary DESC
LIMIT 1 OFFSET 2;

-- Q54. Employees with no salary_history entries
SELECT e.*
FROM employees e
LEFT JOIN salary_history sh ON e.id = sh.employee_id
WHERE sh.employee_id IS NULL;

-- Q55. Department with the most employees
SELECT department_id, COUNT(*) AS employee_count
FROM employees
GROUP BY department_id
ORDER BY employee_count DESC
LIMIT 1;

-- Q59. Employees who never received a promotion
SELECT e.*
FROM employees e
LEFT JOIN promotions p ON e.id = p.employee_id
WHERE p.employee_id IS NULL;

-- Q65. Top 5 highest-paid employees per department
SELECT *
FROM (
    SELECT e.*, ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rn
    FROM employees e
) sub
WHERE rn <= 5;
