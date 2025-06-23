
-- ========================================
-- window_functions.sql - SQL Interview Prep
-- ========================================
-- Focus: RANK, DENSE_RANK, ROW_NUMBER, LAG, LEAD, NTILE, FIRST_VALUE, LAST_VALUE
-- Covers: partitions, ordering, filtering with window outputs, analytics cases
-- ========================================

-- Tables Used:
-- users(user_id, signup_date)
-- orders(order_id, user_id, order_amount, order_date)
-- sessions(session_id, user_id, session_date)
-- employees(employee_id, department_id, salary)
-- products(product_id, category_id, price)
-- reviews(review_id, product_id, user_id, rating, review_date)

-- Q1: For each user, show their 3 most recent orders
SELECT *
FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY order_date DESC) AS rn
  FROM orders
) t
WHERE rn <= 3;

-- Q2: Find users whose last order amount was higher than their previous one
SELECT user_id, order_id, order_amount,
       LAG(order_amount) OVER (PARTITION BY user_id ORDER BY order_date) AS prev_amount
FROM orders
QUALIFY order_amount > prev_amount;

-- Q3: For each employee, get their salary rank within the department
SELECT employee_id, department_id, salary,
       RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS salary_rank
FROM employees;

-- Q4: Find users who had a session followed by no orders within 3 days (LAG + anti-pattern)
WITH user_sessions AS (
  SELECT user_id, session_date,
         LEAD(session_date, 1) OVER (PARTITION BY user_id ORDER BY session_date) AS next_session
  FROM sessions
)
SELECT * FROM user_sessions
WHERE next_session IS NOT NULL;

-- Q5: For each product, show the difference between current and previous review rating
SELECT product_id, review_id, rating,
       rating - LAG(rating) OVER (PARTITION BY product_id ORDER BY review_date) AS rating_diff
FROM reviews;

-- Q6: Get products with the highest price per category using RANK()
SELECT *
FROM (
  SELECT *, RANK() OVER (PARTITION BY category_id ORDER BY price DESC) AS rnk
  FROM products
) t
WHERE rnk = 1;

-- Q7: Show the average order value and the user’s deviation from it
SELECT user_id, order_id, order_amount,
       AVG(order_amount) OVER (PARTITION BY user_id) AS avg_amount,
       order_amount - AVG(order_amount) OVER (PARTITION BY user_id) AS deviation
FROM orders;

-- Q8: Identify users who placed multiple orders on the same day
SELECT user_id, order_date, COUNT(*) AS orders_count
FROM (
  SELECT user_id, order_date, COUNT(*) OVER (PARTITION BY user_id, order_date) AS day_orders
  FROM orders
) t
WHERE day_orders > 1
GROUP BY user_id, order_date;

-- Q9: Show sessions with time since previous session for each user
SELECT user_id, session_id, session_date,
       session_date - LAG(session_date) OVER (PARTITION BY user_id ORDER BY session_date) AS days_since_last
FROM sessions;

-- Q10: For each department, show top 2 highest paid employees
SELECT *
FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rn
  FROM employees
) t
WHERE rn <= 2;

-- Q11: Assign quartiles (NTILE) to products within each category based on price
SELECT product_id, category_id, price,
       NTILE(4) OVER (PARTITION BY category_id ORDER BY price DESC) AS price_quartile
FROM products;

-- Q12: Show users’ first and last session dates
SELECT user_id,
       FIRST_VALUE(session_date) OVER (PARTITION BY user_id ORDER BY session_date) AS first_seen,
       LAST_VALUE(session_date) OVER (
         PARTITION BY user_id ORDER BY session_date
         ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
       ) AS last_seen
FROM sessions;

-- Q13: For each product, find the running average of review ratings over time
SELECT product_id, review_date, rating,
       ROUND(AVG(rating) OVER (PARTITION BY product_id ORDER BY review_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS running_avg
FROM reviews;

-- Q14: Show each user’s largest order and its rank among all their orders
SELECT user_id, order_id, order_amount,
       DENSE_RANK() OVER (PARTITION BY user_id ORDER BY order_amount DESC) AS amount_rank
FROM orders;

-- Q15: Find users who improved their average order value over time
WITH order_avg AS (
  SELECT user_id, order_date, AVG(order_amount) OVER (PARTITION BY user_id ORDER BY order_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS avg_window
  FROM orders
)
SELECT * FROM order_avg
WHERE avg_window > 100;

-- Q16: Identify products whose review ratings are consistently increasing
WITH rating_trends AS (
  SELECT product_id, review_date, rating,
         LAG(rating) OVER (PARTITION BY product_id ORDER BY review_date) AS prev_rating
  FROM reviews
)
SELECT * FROM rating_trends
WHERE rating > prev_rating;

-- Q17: Calculate order rank per user by month
SELECT user_id, order_id, order_date,
       RANK() OVER (PARTITION BY user_id, DATE_TRUNC('month', order_date) ORDER BY order_amount DESC) AS monthly_rank
FROM orders;

-- Q18: Show employees with a salary above the median in their department
WITH dept_ranked AS (
  SELECT *, NTILE(2) OVER (PARTITION BY department_id ORDER BY salary) AS half
  FROM employees
)
SELECT * FROM dept_ranked WHERE half = 2;

-- Q19: For each user, compare current session time with next (LEAD + analysis)
SELECT user_id, session_id, session_date,
       LEAD(session_date) OVER (PARTITION BY user_id ORDER BY session_date) AS next_session_date
FROM sessions;

-- Q20: For each review, show how it ranks compared to all other reviews of that product
SELECT review_id, product_id, rating,
       PERCENT_RANK() OVER (PARTITION BY product_id ORDER BY rating DESC) AS rating_percentile
FROM reviews;
