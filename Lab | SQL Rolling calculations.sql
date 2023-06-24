use sakila;

-- 1. Get number of monthly active customers.
WITH cte_rentals AS (
  SELECT customer_id, rental_date,
    EXTRACT(YEAR_MONTH FROM rental_date) AS activity_year_month
  FROM rental
)
SELECT EXTRACT(YEAR FROM rental_date) AS activity_year,
  EXTRACT(MONTH FROM rental_date) AS activity_month,
  COUNT(DISTINCT customer_id) AS active_customers
FROM cte_rentals
GROUP BY activity_year, activity_month;

-- 2. Active users in the previous month.

WITH cte_rentals AS (
  SELECT customer_id, rental_date,
    EXTRACT(YEAR_MONTH FROM rental_date) AS activity_year_month
  FROM rental
), cte_active_users AS (
  SELECT EXTRACT(YEAR FROM rental_date) AS activity_year,
    EXTRACT(MONTH FROM rental_date) AS activity_month,
    COUNT(DISTINCT customer_id) AS active_customers
  FROM cte_rentals
  GROUP BY activity_year, activity_month
)
SELECT activity_year, activity_month, active_customers,
  LAG(active_customers) OVER (ORDER BY activity_year, activity_month) AS last_month_active_customers
FROM cte_active_users;


-- 3. Percentage change in the number of active customers.
with cte_active_cust as
	(select
		customer_id,
        date_format(convert(payment_date, date),'%m') as Activity_month,
        date_format(convert(payment_date, date),'%y') as Activity_year
	from payment
    ), cte_cust_list as 
	(select activity_year,activity_month, count(distinct(customer_id)) as monthly_active_users, lag(count(distinct(customer_id))) over (order by activity_year, activity_month) as previous_month_active_users from cte_active_cust
    group by activity_year, activity_month
    order by activity_year, activity_month)
    select *, (((monthly_active_users-previous_month_active_users)/previous_month_active_users)*100) as percentage_change from cte_cust_list;

-- 4. Retained customers every month.
WITH cte_rentals AS (
  SELECT customer_id, rental_date,
    EXTRACT(YEAR_MONTH FROM rental_date) AS activity_year_month
  FROM rental
), cte_active_users AS (
  SELECT EXTRACT(YEAR FROM rental_date) AS activity_year,
    EXTRACT(MONTH FROM rental_date) AS activity_month,
    COUNT(DISTINCT customer_id) AS active_customers
  FROM cte_rentals
  GROUP BY activity_year, activity_month
), cte_retained_customers AS (
  SELECT activity_year, activity_month, active_customers,
    LAG(active_customers) OVER (ORDER BY activity_year, activity_month) AS last_month_active_customers,
    (active_customers - LAG(active_customers) OVER (ORDER BY activity_year, activity_month)) AS customer_growth
  FROM cte_active_users
)
SELECT activity_year, activity_month, active_customers,
  active_customers - COALESCE(customer_growth, 0) AS retained_customers
FROM cte_retained_customers;