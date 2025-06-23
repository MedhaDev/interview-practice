
-- ========================================
-- joins.sql - SQL JOIN Interview Prep
-- ========================================
-- Real questions used by Google, Amazon, Meta, etc.
-- Includes: self joins, anti-joins, campaign logic, nested joins,
-- multi-table queries, and analytics logic
-- ========================================

-- Tables referenced:
-- Users(user_id, name, signup_date, segment)
-- Orders(order_id, user_id, order_date, order_amount, product_id)
-- Products(product_id, category_id, price)
-- Sessions(session_id, user_id, session_date, device_type)
-- Customers(customer_id, name, region)
-- Listings(listing_id, title, seller_id, category, price, created_date)
-- Sellers(seller_id, name, join_date, location)
-- Reviews(review_id, product_id, rating, review_date)
-- Campaigns(campaign_id, campaign_name, start_date, end_date)

-- Q1: Customers and their total orders (include 0)
SELECT c.customer_id, c.name, COUNT(o.order_id) AS total_orders
FROM Customers c
LEFT JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name;

-- Q2: Products never ordered
SELECT p.product_id, p.product_name
FROM Products p
LEFT JOIN Orders o USING (product_id)
WHERE o.order_id IS NULL;

-- Q3: Employee–Manager mapping (self-join)
SELECT e.employee_id, e.name AS employee, m.name AS manager
FROM Employees e
LEFT JOIN Employees m ON e.manager_id = m.employee_id;

-- Q4: Orders with user segment
SELECT o.order_id, o.order_amount, u.segment
FROM Orders o
JOIN Users u USING (user_id);

-- Q5: Listings by new sellers priced above category average
SELECT l.listing_id, l.category, l.price
FROM Listings l
JOIN Sellers s USING (seller_id)
WHERE s.join_date >= '2023-01-01'
  AND l.price > (SELECT AVG(price) FROM Listings WHERE category = l.category);

-- Q6: Sessions per device type
SELECT device_type, COUNT(DISTINCT session_id) AS sessions
FROM Sessions
GROUP BY device_type;

-- Q7: Orders during campaign
SELECT o.order_id
FROM Orders o
JOIN Campaigns c ON o.order_date BETWEEN c.start_date AND c.end_date
WHERE c.campaign_name = 'Black Friday';

-- Q8: Suppliers by product variety
SELECT supplier_id, COUNT(DISTINCT category_id) AS num_categories
FROM SupplierProducts
GROUP BY supplier_id
HAVING COUNT(DISTINCT category_id) > 3;

-- Q9: Top 3 spending users per segment
WITH user_spend AS (
  SELECT u.user_id, u.segment, SUM(o.order_amount) AS total_spent
  FROM Orders o
  JOIN Users u USING (user_id)
  GROUP BY u.user_id, u.segment
)
SELECT *
FROM (
  SELECT *, RANK() OVER (PARTITION BY segment ORDER BY total_spent DESC) AS rnk
  FROM user_spend
) t
WHERE rnk <= 3;

-- Q10: Users with sessions but no same-day orders
SELECT DISTINCT s.user_id
FROM Sessions s
LEFT JOIN Orders o ON s.user_id = o.user_id AND DATE(s.session_date) = DATE(o.order_date)
WHERE o.order_id IS NULL;

-- Q11: Customers with only one order
SELECT customer_id
FROM Orders
GROUP BY customer_id
HAVING COUNT(*) = 1;

-- Q12: Top-rated products by category
WITH prod_rev AS (
  SELECT product_id, AVG(rating) AS avg_rating
  FROM Reviews
  GROUP BY product_id
)
SELECT p.product_id, p.product_name, pr.avg_rating
FROM Products p
JOIN prod_rev pr USING (product_id)
WHERE pr.avg_rating = (SELECT MAX(avg_rating) FROM prod_rev);

-- Q13: New vs returning user average order value
SELECT 
  CASE
    WHEN u.signup_date >= o.order_date - INTERVAL '30 days' THEN 'New'
    ELSE 'Returning'
  END AS user_type,
  AVG(o.order_amount) AS avg_order_amount
FROM Orders o
JOIN Users u USING (user_id)
GROUP BY user_type;

-- Q14: Highest-price listing per seller
WITH ranked_listings AS (
  SELECT seller_id, listing_id, price,
         RANK() OVER (PARTITION BY seller_id ORDER BY price DESC) AS rnk
  FROM Listings
  WHERE created_date >= '2023-01-01'
)
SELECT seller_id, listing_id, price
FROM ranked_listings
WHERE rnk = 1;

-- Q15: Sessions leading to ≥2 same-day orders
SELECT s.session_id
FROM Sessions s
JOIN Orders o ON s.user_id = o.user_id AND DATE(s.session_date) = DATE(o.order_date)
GROUP BY s.session_id
HAVING COUNT(DISTINCT o.order_id) > 1;

-- Q16: Returning sellers with all top 3 listings above category average
WITH seller_listings AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY seller_id ORDER BY created_date DESC) AS rn
  FROM Listings
),
top3 AS (
  SELECT seller_id, product_id, category, price FROM seller_listings WHERE rn <= 3
)
SELECT seller_id
FROM top3 t
GROUP BY seller_id
HAVING MIN(price) > (
  SELECT AVG(price) FROM Listings WHERE category = t.category
);

-- Q17: Lapsed users (orders 6–12 months ago, inactive recently)
WITH recent AS (
  SELECT DISTINCT user_id FROM Sessions WHERE session_date >= CURRENT_DATE - INTERVAL '6 months'
)
SELECT DISTINCT o.user_id
FROM Orders o
WHERE o.order_date BETWEEN CURRENT_DATE - INTERVAL '12 months' AND CURRENT_DATE - INTERVAL '6 months'
  AND o.user_id NOT IN (SELECT user_id FROM recent);

-- Q18: Sellers listing both A & B but not C
SELECT seller_id
FROM Listings
GROUP BY seller_id
HAVING BOOL_AND(category IN ('A','B')) AND BOOL_AND(category <> 'C');

-- Q19: Sessions with multiple orders
SELECT s.session_id
FROM Sessions s
JOIN Orders o ON s.user_id = o.user_id AND DATE(s.session_date) = DATE(o.order_date)
GROUP BY s.session_id
HAVING COUNT(DISTINCT o.order_id) > 1;

-- Q20: Most reviewed product per category
WITH rev_counts AS (
  SELECT p.category_id, r.product_id, COUNT(*) AS cnt
  FROM Reviews r
  JOIN Products p USING (product_id)
  GROUP BY p.category_id, r.product_id
),
ranked AS (
  SELECT *, RANK() OVER (PARTITION BY category_id ORDER BY cnt DESC) AS rnk
  FROM rev_counts
)
SELECT category_id, product_id, cnt
FROM ranked
WHERE rnk = 1;
