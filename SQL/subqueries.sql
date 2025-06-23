
-- ========================================
-- subqueries.sql - SQL Subquery Interview Prep
-- ========================================
-- Covers: scalar, correlated, EXISTS/NOT EXISTS, IN/NOT IN, derived tables,
-- filtering, ranking, nested aggregation, and analytics-focused logic
-- ========================================

-- Tables referenced:
-- Users(user_id, name, signup_date, region)
-- Orders(order_id, user_id, order_date, order_amount, product_id)
-- Products(product_id, category_id, price)
-- Reviews(review_id, product_id, user_id, rating, review_date)
-- Employees(employee_id, department_id, salary, manager_id)
-- Sessions(session_id, user_id, session_date)

-- Q1: Users who have spent more than the average of all users
SELECT user_id
FROM Orders
GROUP BY user_id
HAVING SUM(order_amount) > (SELECT AVG(order_amount) FROM Orders);

-- Q2: Products that cost more than the average in their category
SELECT product_id, price
FROM Products p
WHERE price > (
  SELECT AVG(price) FROM Products WHERE category_id = p.category_id
);

-- Q3: Users who placed an order on every day someone else did
SELECT DISTINCT o1.user_id
FROM Orders o1
WHERE NOT EXISTS (
  SELECT 1
  FROM Orders o2
  WHERE o2.user_id <> o1.user_id
    AND NOT EXISTS (
      SELECT 1
      FROM Orders o3
      WHERE o3.user_id = o1.user_id
        AND o3.order_date = o2.order_date
    )
);

-- Q4: Products that were never reviewed
SELECT product_id
FROM Products
WHERE product_id NOT IN (
  SELECT DISTINCT product_id FROM Reviews
);

-- Q5: Users who only ordered once
SELECT user_id
FROM Orders
GROUP BY user_id
HAVING COUNT(*) = 1;

-- Q6: Employees who earn more than their manager
SELECT employee_id
FROM Employees e
WHERE salary > (
  SELECT salary FROM Employees m WHERE m.employee_id = e.manager_id
);

-- Q7: Latest order per user
SELECT *
FROM Orders o
WHERE order_date = (
  SELECT MAX(order_date)
  FROM Orders o2
  WHERE o2.user_id = o.user_id
);

-- Q8: Top spending users (top 10%)
SELECT user_id
FROM Orders
GROUP BY user_id
HAVING SUM(order_amount) >= (
  SELECT PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY total_spent)
  FROM (
    SELECT user_id, SUM(order_amount) AS total_spent
    FROM Orders
    GROUP BY user_id
  ) t
);

-- Q9: Users who reviewed all products they ordered
SELECT user_id
FROM Orders
WHERE product_id IN (
  SELECT product_id FROM Reviews WHERE Reviews.user_id = Orders.user_id
)
GROUP BY user_id
HAVING COUNT(DISTINCT product_id) = (
  SELECT COUNT(DISTINCT product_id)
  FROM Orders o2
  WHERE o2.user_id = Orders.user_id
);

-- Q10: Products with the highest price in each category
SELECT product_id, category_id, price
FROM Products p
WHERE price = (
  SELECT MAX(price)
  FROM Products
  WHERE category_id = p.category_id
);

-- Q11: Users with no sessions in the past 30 days
SELECT user_id
FROM Users
WHERE user_id NOT IN (
  SELECT DISTINCT user_id
  FROM Sessions
  WHERE session_date >= CURRENT_DATE - INTERVAL '30 days'
);

-- Q12: Users who placed more than one order on the same day
SELECT DISTINCT user_id
FROM Orders o
WHERE EXISTS (
  SELECT 1
  FROM Orders o2
  WHERE o.user_id = o2.user_id
    AND o.order_date = o2.order_date
    AND o.order_id <> o2.order_id
);

-- Q13: Products with more reviews than average
SELECT product_id
FROM Reviews
GROUP BY product_id
HAVING COUNT(*) > (
  SELECT AVG(review_count)
  FROM (
    SELECT product_id, COUNT(*) AS review_count
    FROM Reviews
    GROUP BY product_id
  ) sub
);

-- Q14: Departments with salary above overall average
SELECT DISTINCT department_id
FROM Employees
WHERE department_id IN (
  SELECT department_id
  FROM Employees
  GROUP BY department_id
  HAVING AVG(salary) > (SELECT AVG(salary) FROM Employees)
);

-- Q15: Products ordered by all regions
SELECT product_id
FROM Orders o
JOIN Users u ON o.user_id = u.user_id
GROUP BY product_id
HAVING COUNT(DISTINCT u.region) = (
  SELECT COUNT(DISTINCT region) FROM Users
);

-- Q16: Users with increasing order value in last 3 orders
SELECT user_id
FROM (
  SELECT user_id, order_amount,
         LAG(order_amount, 1) OVER (PARTITION BY user_id ORDER BY order_date) AS prev1,
         LAG(order_amount, 2) OVER (PARTITION BY user_id ORDER BY order_date) AS prev2
  FROM Orders
) t
WHERE prev2 IS NOT NULL AND order_amount > prev1 AND prev1 > prev2;

-- Q17: Users with highest total spend in their region
SELECT u.user_id
FROM Users u
JOIN Orders o ON u.user_id = o.user_id
GROUP BY u.user_id, u.region
HAVING SUM(o.order_amount) >= ALL (
  SELECT SUM(order_amount)
  FROM Orders o2
  JOIN Users u2 ON o2.user_id = u2.user_id
  WHERE u2.region = u.region
  GROUP BY o2.user_id
);

-- Q18: Products with review count above 75th percentile
SELECT product_id
FROM (
  SELECT product_id, COUNT(*) AS cnt
  FROM Reviews
  GROUP BY product_id
) r
WHERE cnt > (
  SELECT PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY cnt)
  FROM (
    SELECT COUNT(*) AS cnt
    FROM Reviews
    GROUP BY product_id
  ) t
);

-- Q19: Users with no orders but at least one session
SELECT user_id
FROM Sessions
WHERE user_id NOT IN (
  SELECT DISTINCT user_id FROM Orders
);

-- Q20: Users who have placed orders in consecutive days
SELECT DISTINCT o1.user_id
FROM Orders o1
JOIN Orders o2 ON o1.user_id = o2.user_id
WHERE o1.order_date = o2.order_date + INTERVAL '1 day';
