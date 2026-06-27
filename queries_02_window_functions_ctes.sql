-- ============================================================
-- 02 — Window functions & CTEs
-- ============================================================
USE sql_interview_db;

-- Q8. Running total of salaries by department
SELECT name, department_id, salary,
       SUM(salary) OVER (PARTITION BY department_id ORDER BY id) AS running_total
FROM employees;

-- Q9. Longest consecutive streak of daily logins per user (gaps & islands)
WITH login_groups AS (
    SELECT user_id, login_date,
           DATE_SUB(login_date, INTERVAL ROW_NUMBER() OVER (
               PARTITION BY user_id ORDER BY login_date
           ) DAY) AS grp
    FROM user_logins
)
SELECT user_id, COUNT(*) AS streak_length,
       MIN(login_date) AS start_date, MAX(login_date) AS end_date
FROM login_groups
GROUP BY user_id, grp
ORDER BY streak_length DESC;

-- Q10. Recursive query: full reporting chain for each employee
WITH RECURSIVE reporting_chain AS (
    SELECT id, name, manager_id, 1 AS level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT e.id, e.name, e.manager_id, rc.level + 1
    FROM employees e
    JOIN reporting_chain rc ON e.manager_id = rc.id
)
SELECT * FROM reporting_chain ORDER BY level, id;

-- Q11. Find gaps in a sequence of integer IDs (using employees.id as the sequence)
SELECT id + 1 AS gap_start
FROM employees e
WHERE NOT EXISTS (SELECT 1 FROM employees WHERE id = e.id + 1)
  AND id < (SELECT MAX(id) FROM employees);

-- Q12. Cumulative distribution (CDF) of salaries
SELECT name, salary,
       CUME_DIST() OVER (ORDER BY salary) AS salary_cdf
FROM employees;

-- Q13. Compare two snapshots and find differing rows
-- (using salary_history old_salary vs employees current salary as the two "tables")
SELECT e.id, e.name, sh.old_salary, e.salary AS current_salary
FROM employees e
JOIN salary_history sh ON e.id = sh.employee_id
WHERE sh.old_salary <> e.salary;

-- Q17. Difference between current row and previous row value (LAG)
SELECT name, hire_date, salary,
       salary - LAG(salary) OVER (ORDER BY hire_date) AS salary_diff_vs_prev_hire
FROM employees;

-- Q18. Overlapping date ranges (bookings)
SELECT b1.booking_id AS booking_1, b2.booking_id AS booking_2,
       b1.resource_name, b1.start_date, b1.end_date, b2.start_date, b2.end_date
FROM bookings b1
JOIN bookings b2
  ON b1.resource_name = b2.resource_name
 AND b1.booking_id < b2.booking_id
 AND b1.start_date <= b2.end_date
 AND b2.start_date <= b1.end_date;

-- Q22. First and last purchase date per customer (orders)
SELECT customer_id,
       MIN(order_date) AS first_purchase,
       MAX(order_date) AS last_purchase
FROM orders
GROUP BY customer_id;

-- Q26. Pivot rows into columns (employee count per department as columns)
SELECT
    SUM(CASE WHEN department_id = 1 THEN 1 ELSE 0 END) AS engineering,
    SUM(CASE WHEN department_id = 2 THEN 1 ELSE 0 END) AS sales,
    SUM(CASE WHEN department_id = 3 THEN 1 ELSE 0 END) AS marketing,
    SUM(CASE WHEN department_id = 4 THEN 1 ELSE 0 END) AS hr,
    SUM(CASE WHEN department_id = 5 THEN 1 ELSE 0 END) AS finance
FROM employees;

-- Q29. Rank salespeople by monthly sales (window function on aggregated sales)
WITH monthly_sales AS (
    SELECT customer_id, DATE_FORMAT(sale_date, '%Y-%m-01') AS month, SUM(amount) AS total
    FROM sales
    GROUP BY customer_id, month
)
SELECT customer_id, month, total,
       RANK() OVER (PARTITION BY month ORDER BY total DESC) AS rank_in_month
FROM monthly_sales
ORDER BY month, rank_in_month;

-- Q36. Difference between consecutive salary changes (window function on salary_history)
SELECT employee_id, change_date, new_salary,
       new_salary - LAG(new_salary) OVER (PARTITION BY employee_id ORDER BY change_date) AS delta
FROM salary_history;

-- Q43. Top 10% earners per department (NTILE)
SELECT *
FROM (
    SELECT e.*, NTILE(10) OVER (PARTITION BY department_id ORDER BY salary DESC) AS decile
    FROM employees e
) sub
WHERE decile = 1;

-- Q44. Customers who purchased more than once on the same day
SELECT customer_id, sale_date, COUNT(*) AS purchase_count
FROM sales
GROUP BY customer_id, sale_date
HAVING COUNT(*) > 1;

-- Q47. Rank + percent rank of salaries within department
SELECT name, department_id, salary,
       RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS salary_rank,
       PERCENT_RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS salary_percent_rank
FROM employees;

-- Q50. String aggregation of employee names per department
SELECT department_id, GROUP_CONCAT(name ORDER BY name SEPARATOR ', ') AS employee_names
FROM employees
GROUP BY department_id;

-- Q51. Employees above their department average but below the company average
SELECT *
FROM employees e
WHERE e.salary > (
    SELECT AVG(salary) FROM employees WHERE department_id = e.department_id
)
AND e.salary < (SELECT AVG(salary) FROM employees);

-- Q52. Customers who purchased all products in a given category (category_id = 10)
SELECT customer_id
FROM sales
WHERE category_id = 10
GROUP BY customer_id
HAVING COUNT(DISTINCT product_id) = (
    SELECT COUNT(DISTINCT product_id) FROM products WHERE category_id = 10
);

-- Q55. Median salary by department (MySQL 8.0+ window-based emulation)
SELECT DISTINCT department_id, salary AS median_salary
FROM (
    SELECT department_id, salary,
           ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary) AS rn,
           COUNT(*) OVER (PARTITION BY department_id) AS cnt
    FROM employees
) ranked
WHERE rn IN (FLOOR((cnt + 1) / 2), CEIL((cnt + 1) / 2));

-- Q55b. Longest tenure employees per department
WITH tenure AS (
    SELECT *, RANK() OVER (PARTITION BY department_id ORDER BY hire_date ASC) AS tenure_rank
    FROM employees
)
SELECT * FROM tenure WHERE tenure_rank = 1;

-- Q57. Overlapping shifts for the same employee
SELECT s1.employee_id, s1.shift_id AS shift_1, s2.shift_id AS shift_2
FROM shifts s1
JOIN shifts s2
  ON s1.employee_id = s2.employee_id
 AND s1.shift_id <> s2.shift_id
 AND s1.start_time < s2.end_time
 AND s1.end_time > s2.start_time;

-- Q58. Total revenue per customer, ranked
SELECT customer_id, SUM(amount) AS total_revenue,
       RANK() OVER (ORDER BY SUM(amount) DESC) AS revenue_rank
FROM sales
GROUP BY customer_id;

-- Q60. Top 3 products by total sales each month
WITH monthly_product_sales AS (
    SELECT product_id, DATE_FORMAT(sale_date, '%Y-%m-01') AS month, SUM(amount) AS total_sales
    FROM sales
    GROUP BY product_id, month
),
ranked_sales AS (
    SELECT *, RANK() OVER (PARTITION BY month ORDER BY total_sales DESC) AS sales_rank
    FROM monthly_product_sales
)
SELECT product_id, month, total_sales
FROM ranked_sales
WHERE sales_rank <= 3
ORDER BY month, sales_rank;

-- Q61b. Gaps & islands in attendance records (consecutive dates present)
WITH attendance_groups AS (
    SELECT employee_id, attendance_date,
           DATE_SUB(attendance_date, INTERVAL ROW_NUMBER() OVER (
               PARTITION BY employee_id ORDER BY attendance_date
           ) DAY) AS grp
    FROM attendance
)
SELECT employee_id, MIN(attendance_date) AS start_date, MAX(attendance_date) AS end_date,
       COUNT(*) AS consecutive_days
FROM attendance_groups
GROUP BY employee_id, grp
ORDER BY employee_id, start_date;

-- Q62b. Recursive descendants of a given manager (id = 101)
WITH RECURSIVE descendants AS (
    SELECT id, name, manager_id
    FROM employees
    WHERE manager_id = 101

    UNION ALL

    SELECT e.id, e.name, e.manager_id
    FROM employees e
    INNER JOIN descendants d ON e.manager_id = d.id
)
SELECT * FROM descendants;

-- Q63. 3-month moving average of monthly sales per product
WITH monthly_sales AS (
    SELECT product_id, DATE_FORMAT(sale_date, '%Y-%m-01') AS month, SUM(amount) AS total_sales
    FROM sales
    GROUP BY product_id, month
)
SELECT product_id, month, total_sales,
       AVG(total_sales) OVER (
           PARTITION BY product_id ORDER BY month
           ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ) AS moving_avg_3m
FROM monthly_sales
ORDER BY product_id, month;
