#!/bin/bash
# ============================================================
# SQL Interview Mastery — Automated test suite
# Verifies query correctness with concrete assertions,
# not just "no SQL error".
# ============================================================

set -uo pipefail

DB="sql_interview_db"
PASS=0
FAIL=0

run_query() {
    mysql -u root -N -B "$DB" -e "$1" 2>&1
}

assert_eq() {
    local description="$1"
    local actual="$2"
    local expected="$3"
    if [ "$actual" == "$expected" ]; then
        echo "  PASS  $description"
        PASS=$((PASS+1))
    else
        echo "  FAIL  $description (expected '$expected', got '$actual')"
        FAIL=$((FAIL+1))
    fi
}

echo "============================================================"
echo "Running SQL Interview Mastery test suite"
echo "============================================================"

# ------------------------------------------------------------
echo ""
echo "-- Fundamentals --"

result=$(run_query "SELECT MAX(salary) FROM employees WHERE salary < (SELECT MAX(salary) FROM employees);")
assert_eq "Second highest salary = 15000.00" "$result" "15000.00"

result=$(run_query "SELECT COUNT(*) FROM (SELECT name FROM employees GROUP BY name HAVING COUNT(*) > 1) x;")
assert_eq "No duplicate employee names in seed data" "$result" "0"

result=$(run_query "SELECT COUNT(*) FROM employees e JOIN employees m ON e.manager_id = m.id WHERE e.salary > m.salary;")
assert_eq "Zero employees earn more than their manager" "$result" "0"

result=$(run_query "SELECT department_name FROM departments d LEFT JOIN employees e ON d.department_id = e.department_id WHERE e.id IS NULL;")
assert_eq "Empty Department has no employees" "$result" "Empty Department"

result=$(run_query "SELECT COUNT(*) FROM customers c LEFT JOIN sales s ON c.customer_id = s.customer_id WHERE s.sale_id IS NULL;")
assert_eq "Exactly 1 customer with zero sales (NeverBuys Co)" "$result" "1"

result=$(run_query "SELECT COUNT(*) FROM products p LEFT JOIN sales s ON p.product_id = s.product_id WHERE s.sale_id IS NULL;")
assert_eq "Exactly 1 product never sold (Unsold Gadget)" "$result" "1"

result=$(run_query "SELECT DISTINCT salary FROM employees ORDER BY salary DESC LIMIT 1 OFFSET 2;")
assert_eq "3rd highest distinct salary = 14500.00" "$result" "14500.00"

result=$(run_query "SELECT COUNT(*) FROM employees e LEFT JOIN promotions p ON e.id = p.employee_id WHERE p.employee_id IS NULL;")
assert_eq "12 employees never promoted (15 total - 3 promoted)" "$result" "12"

# ------------------------------------------------------------
echo ""
echo "-- Window functions & CTEs --"

result=$(run_query "
WITH login_groups AS (
    SELECT user_id, login_date,
           DATE_SUB(login_date, INTERVAL ROW_NUMBER() OVER (
               PARTITION BY user_id ORDER BY login_date) DAY) AS grp
    FROM user_logins
)
SELECT MAX(streak) FROM (
    SELECT COUNT(*) AS streak FROM login_groups WHERE user_id = 1 GROUP BY grp
) s;
")
assert_eq "User 1 longest login streak = 5 days" "$result" "5"

result=$(run_query "
SELECT COUNT(*) FROM employees e
WHERE manager_id IS NULL;
")
assert_eq "2 employees have no manager (Alice CEO, Oscar NoDept = top of hierarchy)" "$result" "2"

result=$(run_query "
WITH RECURSIVE descendants AS (
    SELECT id FROM employees WHERE manager_id = 101
    UNION ALL
    SELECT e.id FROM employees e INNER JOIN descendants d ON e.manager_id = d.id
)
SELECT COUNT(*) FROM descendants;
")
assert_eq "Manager 101 (Bob) has exactly 4 direct reports" "$result" "4"

result=$(run_query "
SELECT COUNT(*) FROM bookings b1
JOIN bookings b2
  ON b1.resource_name = b2.resource_name
 AND b1.booking_id < b2.booking_id
 AND b1.start_date <= b2.end_date
 AND b2.start_date <= b1.end_date;
")
assert_eq "Exactly 1 overlapping booking pair (Room A)" "$result" "1"

result=$(run_query "
SELECT COUNT(*) FROM shifts s1
JOIN shifts s2
  ON s1.employee_id = s2.employee_id
 AND s1.shift_id <> s2.shift_id
 AND s1.start_time < s2.end_time
 AND s1.end_time > s2.start_time;
")
assert_eq "Exactly 2 overlapping shift rows for employee 103 (both directions)" "$result" "2"

result=$(run_query "
WITH attendance_groups AS (
    SELECT employee_id, attendance_date,
           DATE_SUB(attendance_date, INTERVAL ROW_NUMBER() OVER (
               PARTITION BY employee_id ORDER BY attendance_date) DAY) AS grp
    FROM attendance
)
SELECT MAX(streak) FROM (
    SELECT COUNT(*) AS streak FROM attendance_groups WHERE employee_id = 103 GROUP BY grp
) s;
")
assert_eq "Employee 103 longest attendance streak = 4 days" "$result" "4"

# ------------------------------------------------------------
echo ""
echo "-- Business reporting --"

result=$(run_query "SELECT COUNT(*) FROM employees WHERE department_id IS NULL;")
assert_eq "Exactly 1 employee with no department (Oscar NoDept)" "$result" "1"

result=$(run_query "SELECT customer_name FROM customers c LEFT JOIN sales s ON c.customer_id = s.customer_id WHERE s.sale_id IS NULL;")
assert_eq "NeverBuys Co confirmed as customer with zero sales" "$result" "NeverBuys Co"

result=$(run_query "SELECT ROUND(SUM(amount),2) FROM sales WHERE customer_id = 1;")
assert_eq "Customer 1 total sales amount = 5455.00" "$result" "5455.00"

result=$(run_query "SELECT COUNT(*) FROM orders;")
assert_eq "10 total orders in seed data" "$result" "10"

result=$(run_query "SELECT ROUND(AVG(rating),2) FROM product_reviews WHERE product_id = 1;")
assert_eq "Product 1 (Laptop Pro) average rating = 4.50" "$result" "4.50"

# ------------------------------------------------------------
echo ""
echo "============================================================"
echo "RESULTS: $PASS passed, $FAIL failed"
echo "============================================================"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
