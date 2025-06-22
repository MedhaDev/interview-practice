
-- ========================================
-- aggregates.sql - SQL Interview Prep
-- ========================================
-- Focus: Real-world business use cases, advanced aggregation logic,
-- filtering with GROUP BY + HAVING, and analytical breakdowns
-- ========================================

-- Q1: Find users who made purchases on at least 3 distinct days
SELECT user_id
FROM orders
GROUP BY user_id
HAVING COUNT(DISTINCT order_date) >= 3;

-- Q2: Find the average order value for each user in 2024
SELECT user_id, AVG(order_amount) AS avg_order_value
FROM orders
WHERE EXTRACT(YEAR FROM order_date) = 2024
GROUP BY user_id;

-- Q3: Rank product categories by total revenue (most to least)
SELECT category_id, SUM(order_amount) AS total_revenue
FROM orders
JOIN products USING (product_id)
GROUP BY category_id
ORDER BY total_revenue DESC;

-- Q4: Identify the top 5 days with highest total sales
SELECT order_date, SUM(order_amount) AS total_sales
FROM orders
GROUP BY order_date
ORDER BY total_sales DESC
LIMIT 5;

-- Q5: Show conversion rate per traffic source
-- (Assume a 'sessions' table tracks visits, and 'orders' captures successful purchases)
SELECT 
  s.traffic_source,
  COUNT(DISTINCT o.user_id) * 1.0 / COUNT(DISTINCT s.user_id) AS conversion_rate
FROM sessions s
LEFT JOIN orders o ON s.user_id = o.user_id AND DATE(s.session_date) = DATE(o.order_date)
GROUP BY s.traffic_source;

-- Q6: List all customers who spent more than 2x the average order amount across all customers
SELECT customer_id, SUM(order_amount) AS total_spent
FROM orders
GROUP BY customer_id
HAVING SUM(order_amount) > 2 * (SELECT AVG(order_amount) FROM orders);

-- Q7: Find the percentage of total revenue each region contributes
SELECT region,
  ROUND(100.0 * SUM(order_amount) / (SELECT SUM(order_amount) FROM orders), 2) AS revenue_share_pct
FROM customers
JOIN orders USING (customer_id)
GROUP BY region;

-- Q8: Show month-over-month growth in total revenue
SELECT 
  TO_CHAR(order_date, 'YYYY-MM') AS month,
  SUM(order_amount) AS revenue
FROM orders
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY month;

-- Q9: Identify customers who placed only one order
SELECT customer_id
FROM orders
GROUP BY customer_id
HAVING COUNT(*) = 1;

-- Q10: For each product, show its revenue and what % it contributes to total revenue
SELECT 
  product_id,
  SUM(order_amount) AS product_revenue,
  ROUND(100.0 * SUM(order_amount) / (SELECT SUM(order_amount) FROM orders), 2) AS pct_total
FROM orders
GROUP BY product_id;

-- Q11: List the top 3 selling products by revenue in each category
WITH ranked_products AS (
  SELECT 
    category_id,
    product_id,
    SUM(order_amount) AS revenue,
    RANK() OVER (PARTITION BY category_id ORDER BY SUM(order_amount) DESC) AS rnk
  FROM orders
  JOIN products USING (product_id)
  GROUP BY category_id, product_id
)
SELECT *
FROM ranked_products
WHERE rnk <= 3;

-- Q12: Find customers who have placed orders every month in the last 6 months
SELECT customer_id
FROM (
  SELECT customer_id, TO_CHAR(order_date, 'YYYY-MM') AS month
  FROM orders
  WHERE order_date >= CURRENT_DATE - INTERVAL '6 months'
  GROUP BY customer_id, TO_CHAR(order_date, 'YYYY-MM')
) t
GROUP BY customer_id
HAVING COUNT(DISTINCT month) = 6;

-- Q13: What is the average basket size (items per order)?
SELECT AVG(item_count) AS avg_basket_size
FROM (
  SELECT order_id, COUNT(*) AS item_count
  FROM order_details
  GROUP BY order_id
) sub;

-- Q14: List the top 5 customers by revenue in the last year
SELECT customer_id, SUM(order_amount) AS revenue
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY customer_id
ORDER BY revenue DESC
LIMIT 5;

-- Q15: Determine reorder rate (users who ordered same product more than once)
SELECT customer_id, COUNT(DISTINCT product_id) AS repeated_products
FROM orders
GROUP BY customer_id, product_id
HAVING COUNT(*) > 1;

-- Q16: Calculate average revenue per customer segment
SELECT segment, AVG(order_amount) AS avg_revenue
FROM customers
JOIN orders USING (customer_id)
GROUP BY segment;

-- Q17: Show the number of active customers each month (at least 1 order)
SELECT TO_CHAR(order_date, 'YYYY-MM') AS month, COUNT(DISTINCT customer_id) AS active_customers
FROM orders
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY month;

-- Q18: List days where total orders were below 50% of the average daily order count
WITH daily_orders AS (
  SELECT order_date, COUNT(*) AS orders
  FROM orders
  GROUP BY order_date
),
avg_orders AS (
  SELECT AVG(orders) AS avg_daily_orders FROM daily_orders
)
SELECT d.order_date, d.orders
FROM daily_orders d, avg_orders a
WHERE d.orders < 0.5 * a.avg_daily_orders;

-- Q19: Which region has the highest average order value?
SELECT region, AVG(order_amount) AS avg_order_value
FROM customers
JOIN orders USING (customer_id)
GROUP BY region
ORDER BY avg_order_value DESC
LIMIT 1;

-- Q20: Find users who placed an order in the first week of every quarter
-- Advanced logic: typically used in cohort or engagement analysis
WITH filtered AS (
  SELECT user_id, DATE_TRUNC('quarter', order_date) AS quarter, MIN(order_date) AS first_order
  FROM orders
  GROUP BY user_id, DATE_TRUNC('quarter', order_date)
  HAVING MIN(order_date) <= DATE_TRUNC('quarter', order_date) + INTERVAL '6 days'
)
SELECT user_id
FROM filtered
GROUP BY user_id
HAVING COUNT(DISTINCT quarter) = (SELECT COUNT(DISTINCT DATE_TRUNC('quarter', order_date)) FROM orders);
