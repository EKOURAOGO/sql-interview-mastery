-- ============================================================
-- 03 — Business reporting & time-series analysis
-- ============================================================
USE sql_interview_db;

-- Q24. Number of employees per department (basic count)
SELECT department_id, COUNT(*) AS num_employees
FROM employees
GROUP BY department_id;

-- Q25. Employees with no department assigned
SELECT *
FROM employees
WHERE department_id IS NULL;

-- Q28. Employees who haven't received a salary change in over a year
-- (reference date fixed to the latest date present in the dataset)
SELECT e.id, e.name, MAX(sh.change_date) AS last_change
FROM employees e
LEFT JOIN salary_history sh ON e.id = sh.employee_id
GROUP BY e.id, e.name
HAVING MAX(sh.change_date) < DATE_SUB('2024-12-01', INTERVAL 1 YEAR)
    OR MAX(sh.change_date) IS NULL;

-- Q31. Employees earning more than the average salary company-wide
SELECT *
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- Q32. Total sales per project (via project_assignments -> employees, illustrative join chain)
SELECT pr.project_name, COUNT(DISTINCT pa.employee_id) AS team_size
FROM projects pr
JOIN project_assignments pa ON pr.project_id = pa.project_id
GROUP BY pr.project_name;

-- Q33. Employees with no salary changes in the last 2 years
SELECT e.id, e.name
FROM employees e
LEFT JOIN salary_history sh ON e.id = sh.employee_id
    AND sh.change_date >= DATE_SUB('2024-12-01', INTERVAL 2 YEAR)
WHERE sh.history_id IS NULL;

-- Q35. Employees whose names start and end with the same letter
SELECT name
FROM employees
WHERE LEFT(name, 1) = RIGHT(name, 1);

-- Q37. Difference between current salary and first recorded salary
SELECT e.id, e.name, e.salary AS current_salary,
       (SELECT old_salary FROM salary_history sh
        WHERE sh.employee_id = e.id
        ORDER BY change_date ASC LIMIT 1) AS first_recorded_salary
FROM employees e;

-- Q38. Average order value per month
SELECT DATE_FORMAT(order_date, '%Y-%m') AS month,
       AVG(amount) AS avg_order_value
FROM orders
GROUP BY month
ORDER BY month;

-- Q39. Running count of orders per customer (window function)
SELECT customer_id, order_date,
       COUNT(*) OVER (PARTITION BY customer_id ORDER BY order_date) AS running_order_count
FROM orders
ORDER BY customer_id, order_date;

-- Q40. Second most recent order per customer
SELECT customer_id, order_id, order_date
FROM (
    SELECT customer_id, order_id, order_date,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn
    FROM orders
) ranked
WHERE rn = 2;

-- Q42. Customers who have never made a sale
SELECT c.customer_id, c.customer_name
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.customer_id
WHERE s.sale_id IS NULL;

-- Q44b. Average tenure of employees by department (in years, reference 2024-12-01)
SELECT department_id,
       AVG(DATEDIFF('2024-12-01', hire_date) / 365.25) AS avg_tenure_years
FROM employees
GROUP BY department_id;

-- Q46. Customers who purchased more than once in the same week
SELECT customer_id, YEARWEEK(sale_date) AS sale_week, COUNT(*) AS purchases
FROM sales
GROUP BY customer_id, sale_week
HAVING COUNT(*) > 1;

-- Q54b. Month-over-month percentage change in total sales
WITH monthly_sales AS (
    SELECT DATE_FORMAT(sale_date, '%Y-%m-01') AS month, SUM(amount) AS total_sales
    FROM sales
    GROUP BY month
)
SELECT month, total_sales,
       (total_sales - LAG(total_sales) OVER (ORDER BY month)) * 100.0
            / LAG(total_sales) OVER (ORDER BY month) AS pct_change
FROM monthly_sales
ORDER BY month;

-- Q61. Customers who placed orders only in the most recent 90 days of the dataset
SELECT DISTINCT customer_id
FROM orders
WHERE order_date >= DATE_SUB('2024-12-01', INTERVAL 90 DAY)
AND customer_id NOT IN (
    SELECT DISTINCT customer_id
    FROM orders
    WHERE order_date < DATE_SUB('2024-12-01', INTERVAL 90 DAY)
);

-- Q64. Total sales amount and order count per customer in the dataset's final year
SELECT customer_id, COUNT(*) AS total_orders, SUM(amount) AS total_sales
FROM sales
WHERE sale_date >= '2024-01-01'
GROUP BY customer_id;

-- Bonus. Average product rating per product, with review count
SELECT p.product_id, p.product_name,
       ROUND(AVG(r.rating), 2) AS avg_rating,
       COUNT(r.review_id) AS review_count
FROM products p
LEFT JOIN product_reviews r ON p.product_id = r.product_id
GROUP BY p.product_id, p.product_name;
