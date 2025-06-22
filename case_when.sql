
-- ========================================
-- case_when_google_faang_level.sql - FAANG-Level SQL CASE WHEN Interview Prep
-- ========================================
-- Focus: business logic, user segmentation, conditional grouping,
-- revenue tiers, behavior-based tagging, fraud flags, cohort bucketing
-- ========================================

-- Tables referenced:
-- Users(user_id, name, signup_date, age, region)
-- Orders(order_id, user_id, order_date, order_amount, payment_method)
-- Products(product_id, category_id, price)
-- Reviews(review_id, user_id, product_id, rating)
-- Sessions(session_id, user_id, session_date, device_type)

-- Q1: Tag users based on total spend
SELECT user_id,
  CASE 
    WHEN SUM(order_amount) > 1000 THEN 'High Value'
    WHEN SUM(order_amount) BETWEEN 500 AND 1000 THEN 'Mid Value'
    ELSE 'Low Value'
  END AS customer_type
FROM Orders
GROUP BY user_id;

-- Q2: Categorize product prices
SELECT product_id, price,
  CASE
    WHEN price > 1000 THEN 'Premium'
    WHEN price BETWEEN 500 AND 1000 THEN 'Standard'
    ELSE 'Budget'
  END AS price_band
FROM Products;

-- Q3: Classify users into age groups
SELECT user_id, age,
  CASE
    WHEN age < 18 THEN 'Teen'
    WHEN age BETWEEN 18 AND 35 THEN 'Young Adult'
    WHEN age BETWEEN 36 AND 55 THEN 'Adult'
    ELSE 'Senior'
  END AS age_group
FROM Users;

-- Q4: Label review ratings
SELECT review_id, rating,
  CASE
    WHEN rating = 5 THEN 'Excellent'
    WHEN rating = 4 THEN 'Good'
    WHEN rating = 3 THEN 'Neutral'
    WHEN rating = 2 THEN 'Poor'
    ELSE 'Terrible'
  END AS rating_label
FROM Reviews;

-- Q5: Identify payment method preferences
SELECT user_id,
  CASE
    WHEN COUNT(*) FILTER (WHERE payment_method = 'Credit Card') > COUNT(*) / 2 THEN 'Card User'
    WHEN COUNT(*) FILTER (WHERE payment_method = 'PayPal') > COUNT(*) / 2 THEN 'PayPal User'
    ELSE 'Mixed'
  END AS payment_type
FROM Orders
GROUP BY user_id;

-- Q6: Assign user lifecycle stage by signup age
SELECT user_id, signup_date,
  CASE
    WHEN signup_date >= CURRENT_DATE - INTERVAL '1 month' THEN 'New'
    WHEN signup_date >= CURRENT_DATE - INTERVAL '6 months' THEN 'Engaged'
    ELSE 'Loyal'
  END AS lifecycle_stage
FROM Users;

-- Q7: Bucket orders by value
SELECT order_id, order_amount,
  CASE 
    WHEN order_amount >= 1000 THEN 'High'
    WHEN order_amount BETWEEN 500 AND 999 THEN 'Medium'
    ELSE 'Low'
  END AS value_bucket
FROM Orders;

-- Q8: Fraud detection pattern flag
SELECT user_id,
  CASE
    WHEN COUNT(DISTINCT device_type) > 3 AND COUNT(*) > 10 THEN 'Suspicious'
    ELSE 'Normal'
  END AS activity_flag
FROM Sessions
GROUP BY user_id;

-- Q9: Weekly cohort assignment
SELECT user_id, signup_date,
  CASE
    WHEN signup_date BETWEEN '2024-01-01' AND '2024-01-07' THEN 'Week 1'
    WHEN signup_date BETWEEN '2024-01-08' AND '2024-01-14' THEN 'Week 2'
    ELSE 'Later'
  END AS signup_cohort
FROM Users;

-- Q10: Identify users based on review count
SELECT user_id,
  CASE 
    WHEN COUNT(*) >= 20 THEN 'Super Reviewer'
    WHEN COUNT(*) >= 10 THEN 'Frequent Reviewer'
    ELSE 'Occasional Reviewer'
  END AS reviewer_type
FROM Reviews
GROUP BY user_id;

-- Q11: Tag products as popular/unpopular based on reviews
SELECT product_id,
  CASE
    WHEN COUNT(*) > 100 THEN 'Popular'
    ELSE 'Unpopular'
  END AS popularity
FROM Reviews
GROUP BY product_id;

-- Q12: Assign performance score by order volume and spend
SELECT user_id,
  CASE
    WHEN COUNT(*) > 20 AND SUM(order_amount) > 10000 THEN 'Top Performer'
    WHEN COUNT(*) BETWEEN 10 AND 20 THEN 'Active'
    ELSE 'Dormant'
  END AS performance_segment
FROM Orders
GROUP BY user_id;

-- Q13: Classify orders by time of day
SELECT order_id, order_date,
  CASE
    WHEN EXTRACT(HOUR FROM order_date) BETWEEN 6 AND 11 THEN 'Morning'
    WHEN EXTRACT(HOUR FROM order_date) BETWEEN 12 AND 17 THEN 'Afternoon'
    WHEN EXTRACT(HOUR FROM order_date) BETWEEN 18 AND 22 THEN 'Evening'
    ELSE 'Night'
  END AS order_time_band
FROM Orders;

-- Q14: Tag sessions by device type
SELECT session_id,
  CASE
    WHEN device_type = 'Mobile' THEN 'On the go'
    WHEN device_type = 'Desktop' THEN 'At desk'
    ELSE 'Other'
  END AS usage_mode
FROM Sessions;

-- Q15: User engagement tag by session frequency
SELECT user_id,
  CASE
    WHEN COUNT(*) >= 30 THEN 'Highly Engaged'
    WHEN COUNT(*) BETWEEN 10 AND 29 THEN 'Moderately Engaged'
    ELSE 'Low Engagement'
  END AS engagement_level
FROM Sessions
GROUP BY user_id;

-- Q16: Mark repeat customers
SELECT user_id,
  CASE
    WHEN COUNT(DISTINCT order_date) > 1 THEN 'Repeat Customer'
    ELSE 'One-time Buyer'
  END AS repeat_status
FROM Orders
GROUP BY user_id;

-- Q17: Categorize regions into zones
SELECT region,
  CASE
    WHEN region IN ('NY', 'NJ', 'PA') THEN 'East'
    WHEN region IN ('CA', 'WA', 'OR') THEN 'West'
    ELSE 'Other'
  END AS zone
FROM Users;

-- Q18: Assign order urgency tag
SELECT order_id, order_date,
  CASE
    WHEN CURRENT_DATE - order_date <= 3 THEN 'Urgent'
    WHEN CURRENT_DATE - order_date <= 7 THEN 'Soon'
    ELSE 'Later'
  END AS urgency
FROM Orders;

-- Q19: Assign conversion likelihood
SELECT user_id,
  CASE
    WHEN COUNT(*) FILTER (WHERE device_type = 'Mobile') >= 3 THEN 'Likely'
    ELSE 'Unlikely'
  END AS conversion_likelihood
FROM Sessions
GROUP BY user_id;

-- Q20: Flag mismatched product price bands for audit
SELECT product_id, price,
  CASE
    WHEN price < 0 THEN 'Invalid'
    WHEN price > 10000 THEN 'Outlier'
    ELSE 'Normal'
  END AS price_flag
FROM Products;
