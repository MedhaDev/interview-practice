
-- ========================================
-- cte_examples.sql - SQL CTE Interview Prep
-- ========================================
-- Covers: single and recursive CTEs, multi-CTE pipelines, window functions inside CTEs,
-- conditional filters, analytics use cases, and hiring-level business logic
-- ========================================

-- Tables referenced:
-- Employees(employee_id, name, manager_id, department_id, salary)
-- Orders(order_id, user_id, order_date, order_amount)
-- Users(user_id, signup_date, region)
-- Products(product_id, category_id, price)
-- Reviews(review_id, product_id, user_id, rating, review_date)
-- Listings(listing_id, seller_id, category, price, created_date)
-- Sellers(seller_id, name, join_date, location)

-- Q1: Get users whose total order amount is above the overall average
WITH user_totals AS (
  SELECT user_id, SUM(order_amount) AS total_spent
  FROM Orders
  GROUP BY user_id
), avg_total AS (
  SELECT AVG(total_spent) AS avg_spend FROM user_totals
)
SELECT u.user_id, total_spent
FROM user_totals u, avg_total a
WHERE u.total_spent > a.avg_spend;

-- Q2: List products with above-average price in their category
WITH category_avg AS (
  SELECT category_id, AVG(price) AS avg_price
  FROM Products
  GROUP BY category_id
)
SELECT p.*
FROM Products p
JOIN category_avg c ON p.category_id = c.category_id
WHERE p.price > c.avg_price;

-- Q3: Find the most recent order per user
WITH ranked_orders AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY order_date DESC) AS rn
  FROM Orders
)
SELECT * FROM ranked_orders
WHERE rn = 1;

-- Q4: Identify managers and how many direct reports they have
WITH report_counts AS (
  SELECT manager_id, COUNT(*) AS report_count
  FROM Employees
  WHERE manager_id IS NOT NULL
  GROUP BY manager_id
)
SELECT e.name AS manager_name, r.report_count
FROM report_counts r
JOIN Employees e ON r.manager_id = e.employee_id;

-- Q5: Find the top 3 most-reviewed products in each category
WITH review_counts AS (
  SELECT p.category_id, r.product_id, COUNT(*) AS review_count
  FROM Reviews r
  JOIN Products p ON r.product_id = p.product_id
  GROUP BY p.category_id, r.product_id
), ranked AS (
  SELECT *, RANK() OVER (PARTITION BY category_id ORDER BY review_count DESC) AS rnk
  FROM review_counts
)
SELECT * FROM ranked
WHERE rnk <= 3;

-- Q6: Get users who ordered every month in the last 6 months
WITH monthly_orders AS (
  SELECT user_id, TO_CHAR(order_date, 'YYYY-MM') AS month
  FROM Orders
  WHERE order_date >= CURRENT_DATE - INTERVAL '6 months'
  GROUP BY user_id, TO_CHAR(order_date, 'YYYY-MM')
)
SELECT user_id
FROM monthly_orders
GROUP BY user_id
HAVING COUNT(DISTINCT month) = 6;

-- Q7: Determine salary gaps between employees and department average
WITH dept_avg AS (
  SELECT department_id, AVG(salary) AS avg_salary
  FROM Employees
  GROUP BY department_id
)
SELECT e.employee_id, e.name, e.salary, d.avg_salary, e.salary - d.avg_salary AS salary_gap
FROM Employees e
JOIN dept_avg d ON e.department_id = d.department_id;

-- Q8: Find products where last review rating dropped by 2+ from the previous
WITH ranked_reviews AS (
  SELECT *, LAG(rating) OVER (PARTITION BY product_id ORDER BY review_date) AS prev_rating
  FROM Reviews
)
SELECT *
FROM ranked_reviews
WHERE prev_rating IS NOT NULL AND rating <= prev_rating - 2;

-- Q9: Calculate revenue per region per month
WITH monthly_revenue AS (
  SELECT u.region, DATE_TRUNC('month', o.order_date) AS month, SUM(o.order_amount) AS total_revenue
  FROM Orders o
  JOIN Users u ON o.user_id = u.user_id
  GROUP BY u.region, DATE_TRUNC('month', o.order_date)
)
SELECT * FROM monthly_revenue;

-- Q10: Top seller by revenue in each category
WITH seller_revenue AS (
  SELECT l.category, l.seller_id, SUM(l.price) AS total_sales
  FROM Listings l
  GROUP BY l.category, l.seller_id
), ranked_sellers AS (
  SELECT *, RANK() OVER (PARTITION BY category ORDER BY total_sales DESC) AS rnk
  FROM seller_revenue
)
SELECT * FROM ranked_sellers WHERE rnk = 1;

-- Q11: Recursive CTE to find hierarchy depth from CEO
WITH RECURSIVE emp_tree AS (
  SELECT employee_id, name, manager_id, 1 AS depth
  FROM Employees
  WHERE manager_id IS NULL
  UNION ALL
  SELECT e.employee_id, e.name, e.manager_id, t.depth + 1
  FROM Employees e
  JOIN emp_tree t ON e.manager_id = t.employee_id
)
SELECT * FROM emp_tree;

-- Q12: Month-on-month change in user signups
WITH monthly_signups AS (
  SELECT DATE_TRUNC('month', signup_date) AS month, COUNT(*) AS total_signups
  FROM Users
  GROUP BY DATE_TRUNC('month', signup_date)
), with_change AS (
  SELECT month, total_signups,
         total_signups - LAG(total_signups) OVER (ORDER BY month) AS diff
  FROM monthly_signups
)
SELECT * FROM with_change;

-- Q13: Sellers who listed in >1 category
WITH categories_per_seller AS (
  SELECT seller_id, COUNT(DISTINCT category) AS num_categories
  FROM Listings
  GROUP BY seller_id
)
SELECT * FROM categories_per_seller WHERE num_categories > 1;

-- Q14: Products with steadily increasing reviews
WITH review_trend AS (
  SELECT *, LAG(rating) OVER (PARTITION BY product_id ORDER BY review_date) AS prev_rating
  FROM Reviews
)
SELECT product_id
FROM review_trend
GROUP BY product_id
HAVING MIN(rating - prev_rating) > 0;

-- Q15: Average review rating for products that were discounted (assume discount flag)
WITH discounted_products AS (
  SELECT * FROM Products WHERE price < 50  -- assume discount threshold
)
SELECT dp.product_id, AVG(r.rating) AS avg_rating
FROM discounted_products dp
JOIN Reviews r ON dp.product_id = r.product_id
GROUP BY dp.product_id;

-- Q16: Customers who ordered from more than 3 categories
WITH user_categories AS (
  SELECT o.user_id, COUNT(DISTINCT p.category_id) AS num_categories
  FROM Orders o
  JOIN Products p ON o.product_id = p.product_id
  GROUP BY o.user_id
)
SELECT * FROM user_categories WHERE num_categories > 3;

-- Q17: Average order size per region over time
WITH order_data AS (
  SELECT u.region, o.order_id, COUNT(*) AS items
  FROM Orders o
  JOIN Users u ON o.user_id = u.user_id
  GROUP BY u.region, o.order_id
)
SELECT region, AVG(items) AS avg_order_size
FROM order_data
GROUP BY region;

-- Q18: Most active users by number of sessions in last 30 days
WITH recent_sessions AS (
  SELECT user_id FROM Sessions
  WHERE session_date >= CURRENT_DATE - INTERVAL '30 days'
)
SELECT user_id, COUNT(*) AS session_count
FROM recent_sessions
GROUP BY user_id
ORDER BY session_count DESC
LIMIT 5;

-- Q19: Compare user’s avg order amount to monthly avg
WITH user_month_avg AS (
  SELECT user_id, DATE_TRUNC('month', order_date) AS month,
         AVG(order_amount) AS user_avg
  FROM Orders
  GROUP BY user_id, DATE_TRUNC('month', order_date)
), overall_month_avg AS (
  SELECT DATE_TRUNC('month', order_date) AS month,
         AVG(order_amount) AS overall_avg
  FROM Orders
  GROUP BY DATE_TRUNC('month', order_date)
)
SELECT u.user_id, u.month, u.user_avg, o.overall_avg
FROM user_month_avg u
JOIN overall_month_avg o ON u.month = o.month;

-- Q20: Recursively list all managers above a given employee
WITH RECURSIVE manager_chain AS (
  SELECT employee_id, name, manager_id
  FROM Employees
  WHERE employee_id = 101  -- target employee
  UNION ALL
  SELECT e.employee_id, e.name, e.manager_id
  FROM Employees e
  JOIN manager_chain mc ON e.employee_id = mc.manager_id
)
SELECT * FROM manager_chain;
