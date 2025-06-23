
-- ========================================
-- joins.sql - SQL Interview Prep
-- ========================================
-- Focus: Complex joins, self joins, multi-table logic, outer joins with filters,
-- anti-joins, semi-joins, NULL handling, and advanced join conditions
-- ========================================

-- Q1: List customers and their total number of orders (LEFT JOIN)
SELECT c.customer_id, c.name, COUNT(o.order_id) AS total_orders
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name;

-- Q2: Get products that have never been ordered (LEFT JOIN + IS NULL)
SELECT p.product_id, p.product_name
FROM products p
LEFT JOIN order_details od ON p.product_id = od.product_id
WHERE od.order_id IS NULL;

-- Q3: Find employees and their managers (SELF JOIN)
SELECT e.employee_id, e.name AS employee_name, m.name AS manager_name
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id;

-- Q4: Show orders and the customer segment who placed them
SELECT o.order_id, o.order_amount, c.segment
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id;

-- Q5: Find suppliers who supply more than 5 products (JOIN + GROUP BY)
SELECT s.supplier_id, s.name, COUNT(p.product_id) AS product_count
FROM suppliers s
JOIN products p ON s.supplier_id = p.supplier_id
GROUP BY s.supplier_id, s.name
HAVING COUNT(p.product_id) > 5;

-- Q6: List employees who worked on more than 3 projects (many-to-many JOIN)
SELECT e.employee_id, e.name, COUNT(ep.project_id) AS project_count
FROM employees e
JOIN employee_project ep ON e.employee_id = ep.employee_id
GROUP BY e.employee_id, e.name
HAVING COUNT(ep.project_id) > 3;

-- Q7: Get all users who had a session but didn’t place an order (LEFT JOIN + anti-join)
SELECT s.user_id
FROM sessions s
LEFT JOIN orders o ON s.user_id = o.user_id AND DATE(s.session_date) = DATE(o.order_date)
WHERE o.order_id IS NULL;

-- Q8: Find products where the selling price is lower than the cost (JOIN + condition)
SELECT p.product_id, p.product_name, i.cost, p.price
FROM products p
JOIN inventory i ON p.product_id = i.product_id
WHERE p.price < i.cost;

-- Q9: Return the most recent order for each customer (JOIN + window function)
WITH ranked_orders AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn
  FROM orders
)
SELECT o.*
FROM ranked_orders o
WHERE rn = 1;

-- Q10: List orders with shipping delays > 3 days (JOIN + date diff)
SELECT o.order_id, o.order_date, s.shipped_date, s.delivery_date
FROM orders o
JOIN shipping s ON o.order_id = s.order_id
WHERE s.delivery_date - s.shipped_date > 3;

-- Q11: List all employees who haven't submitted time entries for this week (anti-join)
SELECT e.employee_id, e.name
FROM employees e
LEFT JOIN time_entries t ON e.employee_id = t.employee_id AND t.week = '2024-W20'
WHERE t.entry_id IS NULL;

-- Q12: For each order, show product names and total quantity (JOIN + aggregation)
SELECT o.order_id, STRING_AGG(p.product_name, ', ') AS products_ordered, SUM(od.quantity) AS total_qty
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN products p ON od.product_id = p.product_id
GROUP BY o.order_id;

-- Q13: List each employee's department and total team size (JOIN + COUNT)
SELECT e.employee_id, e.name, d.department_name, COUNT(e2.employee_id) AS dept_size
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN employees e2 ON e2.department_id = d.department_id
GROUP BY e.employee_id, e.name, d.department_name;

-- Q14: Show the top 3 users by session count per device type (JOIN + window func)
WITH session_ranks AS (
  SELECT s.user_id, s.device_type, COUNT(*) AS session_count,
         RANK() OVER (PARTITION BY s.device_type ORDER BY COUNT(*) DESC) AS rnk
  FROM sessions s
  GROUP BY s.user_id, s.device_type
)
SELECT * FROM session_ranks WHERE rnk <= 3;

-- Q15: Find which products were bought by users from California (multi-join)
SELECT DISTINCT p.product_name
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_details od ON o.order_id = od.order_id
JOIN products p ON od.product_id = p.product_id
WHERE c.state = 'CA';

-- Q16: List order IDs and names of users who placed them during a campaign (JOIN + filter)
SELECT o.order_id, u.name
FROM orders o
JOIN users u ON o.user_id = u.user_id
JOIN marketing_campaigns m ON o.order_date BETWEEN m.start_date AND m.end_date
WHERE m.campaign_name = 'Spring Sale';

-- Q17: Count how many unique categories each supplier provides (JOIN + COUNT DISTINCT)
SELECT s.supplier_id, COUNT(DISTINCT p.category_id) AS category_count
FROM suppliers s
JOIN products p ON s.supplier_id = p.supplier_id
GROUP BY s.supplier_id;

-- Q18: Show sessions that led to multiple orders (JOIN + HAVING)
SELECT s.session_id, COUNT(o.order_id) AS order_count
FROM sessions s
JOIN orders o ON s.user_id = o.user_id AND DATE(s.session_date) = DATE(o.order_date)
GROUP BY s.session_id
HAVING COUNT(o.order_id) > 1;

-- Q19: Display top-selling product in each category (JOIN + RANK)
WITH category_sales AS (
  SELECT p.product_id, p.category_id, SUM(od.quantity) AS total_sold,
         RANK() OVER (PARTITION BY p.category_id ORDER BY SUM(od.quantity) DESC) AS rnk
  FROM products p
  JOIN order_details od ON p.product_id = od.product_id
  GROUP BY p.product_id, p.category_id
)
SELECT * FROM category_sales WHERE rnk = 1;

-- Q20: Compare average order value between new and returning users (JOIN + CASE)
SELECT 
  CASE 
    WHEN u.signup_date >= o.order_date - INTERVAL '30 days' THEN 'New'
    ELSE 'Returning'
  END AS user_type,
  AVG(o.order_amount) AS avg_order_value
FROM users u
JOIN orders o ON u.user_id = o.user_id
GROUP BY user_type;
