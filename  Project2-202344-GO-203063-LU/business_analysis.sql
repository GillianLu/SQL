-- GO, CAMILLE JUSTINE, 202344
-- LU, GILLIAN NICOLE, 203063
-- MAY 19, 2022

-- I/we certify that this submission complies with the -- DISCS Academic Integrity Policy.
     -- If I/we have discussed my/our SQL code with anyone other than
     -- my/our instructor(s), my/our groupmate(s), the teaching
     -- assistant(s), the extent of each discussion has been clearly
     -- noted along with a proper citation in the comments of my/our
     -- program.
     -- If any SQL code or documentation used in my/our program was

-- obtained from another source, either modified or unmodified,
     -- such as a textbook, website or another individual, the extent
     -- of its use has been clearly noted along with a proper citation
     -- in the comments of my/our program.
     --https://www.w3schools.com/sql/func_mysql_date_format.asp
     --https://www.sqlshack.com/sql-lag-function-overview-and-examples/


--1 What are the daily sales from July 1, 2019 to August 30, 2019? Show date and daily sales amount.
-- Order by date, oldest to most recent.

WITH daily_sales AS (
  SELECT
    DATE_FORMAT(transaction_date,"%M-%d-%Y") AS Day_of_Month,
    SUM(transaction_amount) AS Daily_Sales
  FROM customer_purchase
  GROUP BY transaction_date
  ORDER BY transaction_date ASC
)

SELECT Day_of_Month, Daily_Sales
FROM daily_sales;

--2 What are the monthly sales from July 2019 to August 2019? Show month and total amount for the month.
-- Order by month, oldest to most recent.

WITH t1 AS(
  SELECT
  date_format(transaction_date, "%M-%Y") AS Month,
  SUM(transaction_amount) AS daily_sales
FROM customer_purchase
GROUP BY transaction_date
ORDER BY transaction_date ASC
),
t2 AS (
  SELECT Month, SUM(daily_sales) AS Monthly_Sales
  FROM t1
  GROUP BY Month
)
SELECT Month, Monthly_Sales
FROM t2;

--3 How much is the overall sales for each city for the month of August 2019?
-- Show city name and overall sales for the month.
-- Order by overall sales, highest to lowest.

WITH os AS (
  SELECT city AS City, SUM(transaction_amount) AS total
  FROM customer_purchase
  INNER JOIN customer
    ON customer_purchase.customer_id = customer.customer_id
  WHERE date_format(transaction_date, "%M") = "August"
  GROUP BY city
  ORDER BY total DESC
)
SELECT City, total AS Overall_Sales_for_August
FROM os;

--4 What are the top 10 products in terms of total sales (i.e. the products that generated the most revenue)?
-- Show product name and total sales for each product. Order by total sales, highest to
--lowest. Note that the transaction amount is already the total spent by the customer for
--each transaction (i.e. it is not the amount spent per unit).

WITH tp AS(
  SELECT product_name, SUM(quantity * transaction_amount) AS total
  FROM product
  INNER JOIN customer_purchase
    ON product.product_id = customer_purchase.product_id
  GROUP BY product_name
  ORDER BY total DESC
)
SELECT product_name AS Product_name, total AS Total_Sales
FROM tp
LIMIT 10;

--5 Who are our top 10 customers that have bought the most number of products overall?
--Show the customer's first name, last name and total number of products bought by the
--customer. Assume that it is possible for 2 or more customers to have the same first +
--last name, so make sure that your query is able to distinguish those customers apart.
--Order by number of products bought, highest to lowest. And then order by customer's
--last name in ascending order for those customers who have the same number of total
--products bought.

WITH ct AS (
  SELECT CONCAT(first_name," " ,last_name) AS First_and_Last_Name, SUM(quantity) AS total
  FROM customer
  INNER JOIN customer_purchase
    ON customer.customer_id = customer_purchase.customer_id
  GROUP BY first_name, last_name
  ORDER BY total DESC
)

SELECT First_and_Last_Name, total AS Total_Number_Products
FROM ct
LIMIT 10;

--6. Who are our top 10 customers in terms of their overall spending?
--What is the product that they have respectively spent the most on, and how much have they spent on this product?
--Show the customer's first name and last name, their overall spend, the name of the product that they spent the most on, and the total amount they spent on that product. This should all be in one query. You may use derived tables, views, and CTEs. To simplify, assume that no two or more customers will have the same amount of total overall spending (i.e. none of them spent the same total amount of money for purchasing products). Assume that the total spend for each product by each customer is ----also unique (i.e. none of them spent the same total amount on any two or more products). However, assume that it is possible for 2 or more customers to have the same first + last name. So make sure that your query is able to distinguish those customers apart.

WITH cte1 AS
(
  SELECT customer_purchase.customer_id, transaction_amount, customer.first_name, customer.last_name, product.product_name, product.product_id,
  SUM(transaction_amount) OVER(PARTITION BY customer_purchase.customer_id) AS total_amount_per_customer
  FROM customer
  JOIN customer_purchase
    ON customer.customer_id = customer_purchase.customer_id
  JOIN product
    ON customer_purchase.product_id = product.product_id
),
  cte2 AS (
    SELECT cte1.customer_id, cte1.first_name, cte1.last_name, cte1.total_amount_per_customer, cte1.product_name, cte1.product_id, cte1.transaction_amount,
    SUM(cte1.transaction_amount)OVER(PARTITION BY customer_id, product_id) AS "amt_spent_on_product"
    FROM cte1
  ),
  cte0 AS (
    SELECT customer_id, first_name, last_name, total_amount_per_customer, product_name, amt_spent_on_product,
    ROW_NUMBER() OVER(PARTITION BY cte2.customer_id ORDER BY amt_spent_on_product DESC) AS "row_no"
    FROM cte2
  )
SELECT CONCAT(cte0.first_name," ",cte0.last_name) AS "Customer Full Name", cte0.total_amount_per_customer AS "Overall Spend", cte0.product_name AS "Product spent most on", amt_spent_on_product AS "Amount Spent on Product"
FROM cte0
WHERE cte0.row_no = 1
ORDER BY total_amount_per_customer DESC
LIMIT 10 OFFSET 0;

--7.For every city, what are our top 10 products in terms of overall sales?
-- Show the name of the city, the name of the product, and the overall sales
--for the product. This should all be in one query. You may use derived tables, views, and CTEs.
--Order the cities in ascending order alphabetically. For each city, order the products by overall
--sales of each product, from highest to lowest.

WITH cte3 AS
(
  SELECT customer.city, product.product_name,
  SUM(customer_purchase.transaction_amount) AS overall_sales
  FROM customer
  JOIN customer_purchase ON customer.customer_id = customer_purchase.customer_id
  JOIN product ON customer_purchase.product_id = product.product_id
  GROUP BY customer.city, product.product_name
  ORDER BY overall_sales DESC
),
  cte4 AS
  (
  SELECT cte3.city, cte3.product_name, cte3.overall_sales,
  ROW_NUMBER() OVER(PARTITION BY city ORDER BY overall_sales DESC) AS "row_num"
  FROM cte3
)

SELECT cte4.city AS "City Name", cte4.product_name AS "Product Name", cte4.overall_sales AS "Overall Sales"
FROM cte4
WHERE cte4.row_num <= 10
ORDER BY cte4.city ASC;

-- 8.What is our month-over-month growth between July 2019 and August 2019?

WITH table1 AS (
  SELECT
    DATE_FORMAT(transaction_date, "%M-%Y") AS month,
    SUM(transaction_amount) AS daily_sales
  FROM customer_purchase
  GROUP BY transaction_date
),
table2 AS (
  SELECT month, SUM(daily_sales) AS monthly_Sales
  FROM table1
  GROUP BY month
  ORDER BY month DESC
),

table3 AS (
  SELECT LAG(Monthly_Sales) OVER (ORDER BY month DESC) AS previous,
  ROW_NUMBER() OVER (
    PARTITION BY Monthly_Sales
  ) AS row_rank
  FROM table2
),
table4 AS (
  SELECT LAG(Monthly_Sales) OVER (ORDER BY month ASC) AS current,
  ROW_NUMBER() OVER (
    PARTITION BY Monthly_Sales
  ) AS row_rank
  FROM table2
),
combine AS (
  SELECT
    table4.current - table3.previous AS numerator,
    table3.previous AS denominator
  FROM table4
  INNER JOIN table3
    ON table4.row_rank = table3.row_rank
)
SELECT CONCAT(numerator/denominator * 100,"%") AS month_over_month_growth
FROM combine
WHERE numerator IS NOT NULL;
