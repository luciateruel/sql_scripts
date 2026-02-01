-- 1 Sales and Profit Analysis by Product Category

WITH ej_1 AS(
    SELECT 
        quarter_of_year AS quarter_year,
        category AS category,
        maintenance AS maintenance,
        product AS product,
        parts AS parts,
        support AS support,
        total AS total_sales,
        units_sold AS units_sold,
        profit AS total_profit,
        ROUND(total/ SUM(total) OVER() *100,2) AS percentage_total,     
    FROM sales
    WHERE account =  'Adabs Entertainment' 
          AND year = 2020
)
SELECT 
    *,
     ROUND(maintenance/ total_sales  *100,2) AS percentage_by_maintenance,
     ROUND(product/ total_sales *100,2) AS percentage_by_product,
     ROUND(parts/ total_sales *100,2) AS percentage_by_parts,
     ROUND(support/ total_sales *100,2) AS percentage_by_support
FROM ej_1;


-- 2 Performance Comparison by Country in APAC and EMEA Regions

-- A. Filter by countries in APAC and EMEA and then calculate averages

WITH table_by_region AS(
    SELECT 
        country,
        industry,
        account,
        region
    FROM accounts
    WHERE region = 'EMEA' OR region = 'APAC'
    )
SELECT
    region AS region,
    country AS country,
    ROUND(AVG(total), 2) AS average_revenue,
    ROUND(AVG(units_sold), 2) AS average_units_sold,
    ROUND(AVG(profit), 2) AS average_profit
FROM table_by_region t_r
LEFT JOIN sales s
    ON t_r.account = s.account
WHERE year IS NOT null
GROUP BY region, country
ORDER BY region;

-- B. Also calculate average just by Region

WITH table_by_region AS(
    SELECT 
        country,
        industry,
        account,
        region
    FROM accounts
    WHERE region = 'EMEA' OR region = 'APAC'
    )
SELECT
    region AS region,
--    country AS country,
    ROUND(AVG(total), 2) AS average_revenue,
    ROUND(AVG(units_sold), 2) AS average_units_sold,
    ROUND(AVG(profit), 2) AS average_profit
FROM table_by_region t_r
LEFT JOIN sales s
    ON t_r.account = s.account
WHERE year IS NOT null
GROUP BY region
ORDER BY region;


-- 3 Total Profit Analysis by Industry: Study of Committed Stage Clients

WITH forecast_filtered AS(
    SELECT *
    FROM forecasts
    WHERE forecast > 500000 
        AND prediction_category = 'Commit'
),
forecast_profit_industry_filtered AS(
    SELECT 
        industry,
        SUM(profit) AS total_profit                    
    FROM forecast_filtered f_f
    LEFT JOIN accounts a
        ON f_f.account = a.account
    LEFT JOIN sales s
        ON f_f.account = s.account
    WHERE profit IS NOT null
    GROUP BY industry
)
SELECT 
    *,
    CASE
         WHEN total_profit > 1000000 THEN 'High'
        ELSE 'Normal'
    END AS benefit_category
FROM forecast_profit_industry_filtered
ORDER BY total_profit DESC;


-- 4 Forecast vs Actual Profit Evolution: Trajectory Analysis by Category

-- Create two CTEs, one with aggregated profit and another with forecast, then join them

WITH agg_profit AS(
    SELECT 
        category, 
        SUM(profit) AS total_profit_2021
    FROM SALES
    WHERE year = 2021
    GROUP BY category
),
agg_forecasts AS (
    SELECT 
        category, 
        SUM(forecast) AS total_forecast_2022, 
        COUNT(*) AS num_opportunities,
        MIN(opportunity_age) AS most_recent_opportunity,
        MAX(opportunity_age) AS oldest_opportunity
    FROM forecasts
    WHERE year = 2022
    GROUP BY category
)
SELECT
    COALESCE(p.category, f.category) AS category,
    p.total_profit_2021,
    f.total_forecast_2022,
    f.num_opportunities,
    f.most_recent_opportunity,
    f.oldest_opportunity    
FROM agg_profit AS p
FULL OUTER JOIN agg_forecasts AS f
ON p.category = f.category 
;


-- PRACTICAL CASE - Most profitable categories and Accounts contributing most to profit

-- Part 3.A - Most profitable categories by year

WITH sales_total_profit AS (
    SELECT
        year,
        category,
        SUM(profit) AS total_profit
    FROM sales
    GROUP BY year, category
    ORDER BY year
)
SELECT
    *,
    SUM(total_profit) OVER (PARTITION BY year) AS total_by_year,
    ROUND((total_profit/total_by_year *100), 2) AS percentage_by_year_category
FROM sales_total_profit
ORDER BY category;

 
-- Part 3.B - Most profitable Accounts by category

WITH sales_total_profit AS (
    SELECT
        year,
        category,
        account,
        SUM(profit) AS total_profit
    FROM sales
    GROUP BY category, account, year
    ORDER BY year
),
sales_with_percentage AS (

    SELECT
        *,
        SUM(total_profit) OVER (PARTITION BY year, category) AS total_profit_category,
        ROUND((total_profit / total_profit_category * 100), 2) AS percentage_account_over_category,
        ROW_NUMBER() OVER (PARTITION BY year, category ORDER BY total_profit DESC) AS rn
    FROM sales_total_profit
)
SELECT *
FROM sales_with_percentage
WHERE rn <= 3
ORDER BY year, category, rn;
