-- How many months have Codeflix been operating?
SELECT 
 min(subscription_start),
 max(subscription_start),
 max(subscription_end)
 FROM subscriptions;

--1.2 What kind of segments exist?
SELECT DISTINCT
segment
FROM subscriptions;

--2. What is the overall churn trend since the company started?

-- First we need a temporary table of the months, we want to calculate churn for. 
WITH months as(
  SELECT
  '2017-01-01' as first_day,
  '2017-01-31' as last_day
UNION
SELECT
  '2017-02-01' AS first_day,
  '2017-02-28' AS last_day
UNION
SELECT
  '2017-03-01' AS first_day,
  '2017-03-31' AS last_day
),

-- we then cross join the months to our subscribers
cross_join AS
(SELECT *
FROM subscriptions
CROSS JOIN months
),

-- In the following temporary table, we mark the our segments with active and or inactive, as well as marking the total subsriber base.

status AS (
  SELECT
	id,
  first_day as month,
  CASE 
  	WHEN (subscription_start < first_day) AND (subscription_end IS NULL OR subscription_end > last_day) THEN 1 ELSE 0 
  	END AS 'is_active_total',
  CASE 
  	WHEN segment = 87 AND (subscription_start < first_day) AND (subscription_end IS NULL OR subscription_end > last_day) THEN 1 ELSE 0 
  	END AS 'is_active_87',
  CASE 
  	WHEN segment = 30 AND (subscription_start < first_day) AND (subscription_end IS NULL OR subscription_end > last_day) THEN 1 ELSE 0 
  	END AS 'is_active_30',
  CASE 
  	WHEN (subscription_end BETWEEN first_day AND last_day) THEN 1 ELSE 0 
  	END AS 'is_canceled_total',
  CASE 
  	WHEN segment = 30 AND (subscription_end BETWEEN first_day AND last_day) THEN 1 ELSE 0 
  	END AS 'is_canceled_30',
  CASE
  	WHEN segment = 87 AND (subscription_end BETWEEN first_day AND last_day) THEN 1 ELSE 0
	END as 'is_canceled_87'
FROM cross_join
  ),
-- we then aggregate the total active and inactive subscribers. 
  status_aggregate AS(
  SELECT
    month,
    SUM(is_active_total) AS sum_active_total,
    SUM(is_active_87) AS sum_active_87,
    SUM(is_active_30) AS sum_active_30,
    SUM(is_canceled_total) AS sum_canceled_total,
    SUM(is_canceled_30) AS sum_canceled_87,
    SUM(is_canceled_87) AS sum_canceled_30
    FROM status
    GROUP BY month
  )
  -- lastly, we calculate the churn of the total subscriber base, as well as the two segments.
SELECT 
month,
1.0*sum_canceled_total/sum_active_total as churn_rate_total,
1.0*sum_canceled_30/sum_active_30 as churn_rate_30,
1.0*sum_canceled_87/sum_active_87 as churn_rate_87
FROM status_aggregate;