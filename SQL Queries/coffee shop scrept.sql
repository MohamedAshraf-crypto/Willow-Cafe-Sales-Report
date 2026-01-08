/* overview*/
SELECT * FROM coffee_shop ;
describe coffee_shop;

/* cleaning the data*/
-- chnaging the type of the column from str to date

UPDATE coffee_shop
SET transaction_date = STR_TO_DATE(transaction_date, '%c/%e/%Y');

alter table coffee_shop
modify column transaction_date date;

-- chnaging the type of the column from str to time

UPDATE coffee_shop
SET transaction_time = STR_TO_DATE(transaction_time, '%H:%i:%s');

alter table coffee_shop
modify column transaction_time time;

-- change the column name from 'ï»¿transaction_id' to 'transaction_id'

alter table coffee_shop
change column ï»¿transaction_id transaction_id int;

--------------------------------------------------------
-- Calculation Quaries

select 
	concat((round(sum(transaction_qty * unit_price)))/1000,"K")Total_Sales
from coffee_shop
where 
	month(transaction_date)=3;
    
 /* MOM SALES % */ 
 
SELECT 
    MONTH(transaction_date) AS Month_Num,

    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales,

    (
        SUM(unit_price * transaction_qty)
        -
        LAG(SUM(unit_price * transaction_qty), 1)
        OVER (ORDER BY MONTH(transaction_date))
    )
    /
    LAG(SUM(unit_price * transaction_qty), 1)
    OVER (ORDER BY MONTH(transaction_date)) *100
    AS MOM_INCREASE_PERCENTAGE

FROM coffee_shop
WHERE MONTH(transaction_date) IN (4,5)
GROUP BY MONTH(transaction_date)
ORDER BY MONTH(transaction_date);
 
/* total orders for each month */

select 
	count(*) TotalOrders,
	month(transaction_date) datenum
from coffee_shop
group by 
	month(transaction_date);
    
 /* MOM ORDERS differance and MOM ORDERS growth*/
 
with ORDERS_DIFF as 
(
select 
	month(transaction_date) DATE_NUM,
    count(transaction_id) as Total_Orders
from 
	coffee_shop
group by
	month(transaction_date)
)
select 
	date_num,
    Total_orders,
    (
    total_orders-lag(total_orders) over (order by date_num)
    )
    / lag(total_orders) over(order by date_num) * 100
    as DIFF_ORDERS
from 
	ORDERS_DIFF
    where 
	DATE_NUM in (4,5)
order by 
	DATE_NUM;

/* TOTAL QUANTITY FOR EACH MONTH */

select
month(transaction_date) date_num,
sum(transaction_qty) total_qty
from coffee_shop
group by month(transaction_date);

 /* MOM QTY differance and MOM QTY growth*/

WITH QTY_DIFF AS 
(
SELECT
	MONTH(transaction_date) DATE_NUM,
	SUM(transaction_qty) TOTAL_QTY
FROM
	coffee_shop
group by 
	MONTH(transaction_date)
)
SELECT
	DATE_NUM,
	TOTAL_QTY,
	(
	TOTAL_QTY - LAG(TOTAL_QTY) OVER (ORDER BY DATE_NUM)
	)
	/LAG(TOTAL_QTY) OVER (ORDER BY DATE_NUM) * 100 AS 'QTY %'
FROM 
	QTY_DIFF
WHERE
	DATE_NUM
	IN (5,4)
ORDER BY 
	DATE_NUM;	

/* total sales,order and qty by days */

select 
	concat(round(sum(transaction_qty * unit_price)/1000,1),'K') as total_sales,
    concat(round(count(transaction_id)/1000,1),'K') as total_orders,
    concat(round(sum(transaction_qty)/1000,1),'K') as total_qty
from 
	coffee_shop
where
	transaction_date = '2023-01-01'	;
    
/* 
weekday and weekend sales
(1,7) represent the weekends 
6-FRIDAY
7-Saturday
*/

select 
	case
		when dayofweek(transaction_date) in (6,7) then 'Weekends'
        else 'Weekdays'
	end day_type,
concat(round(sum(transaction_qty * unit_price)/1000,2),' ','K') as total_sales
from 
	coffee_shop
where
	month(transaction_date) = 5
group by 
	case
		when dayofweek(transaction_date) in (6,7) then 'Weekends'
        else 'Weekdays'
	end	;
    
 -- another method by using cte
 
WITH day_type AS (
    SELECT 
        MONTH(transaction_date) AS date_num,
        transaction_qty,
        unit_price,
        CASE
            WHEN DAYOFWEEK(transaction_date) IN (6,7) THEN 'Weekends'
            ELSE 'Weekdays'
        END AS day_type
    FROM coffee_shop
)

SELECT
    day_type,
    CONCAT(
        ROUND(SUM(transaction_qty * unit_price) / 1000, 2),
        ' K'
    ) AS total_sales
FROM day_type
WHERE date_num = 5
GROUP BY day_type;

/* sales by store location */

select 
	monthname(transaction_date) Month_Name,
	store_location,
	concat(round(sum(transaction_qty * unit_price)/1000,2),' ','K') total_sale 
from coffee_shop
where month
	(transaction_date) = 5
group by 
	store_location,
    monthname(transaction_date)
order by 
	concat(round(sum(transaction_qty * unit_price)/1000,2),'K');
    
 /* AVG sales by Month for each day */
 /* avg sales for each month*/
 
WITH total_sales AS (
    SELECT 
        transaction_date,
        SUM(unit_price * transaction_qty) AS total_sales
    FROM coffee_shop
    GROUP BY transaction_date
)
SELECT
   concat(round(AVG(total_sales)/1000,2),' ','K') AS avg_sales
FROM total_sales
WHERE MONTH(transaction_date) = 5;

/* comparing sales of the day with the averger sales of the month */

SELECT 
    day_of_month,
    CASE 
        WHEN total_sales > avg_sales THEN 'Above Average'
        WHEN total_sales < avg_sales THEN 'Below Average'
        ELSE 'Average'
    END AS sales_status,
    total_sales
FROM (
    SELECT 
        DAY(transaction_date) AS day_of_month,
        SUM(unit_price * transaction_qty) AS total_sales,
        AVG(SUM(unit_price * transaction_qty)) OVER () AS avg_sales
    FROM 
        coffee_shop
    WHERE 
        MONTH(transaction_date) = 5  -- Filter for May
    GROUP BY 
        DAY(transaction_date)
) AS sales_data
ORDER BY 
    day_of_month;

/* total sales by category */

select 
	product_category,
	sum(unit_price * transaction_qty) total_sales
from coffee_shop
group by 
	product_category
order by
	sum(unit_price * transaction_qty);

/* top 10 product_type*/

select 
	product_type,
	round(sum(unit_price * transaction_qty),2) total_sales
from coffee_shop
group by 
	product_type
order by
	sum(unit_price * transaction_qty) desc 
limit 10 ;

/* sales,qty,orders detailes by month,day and hours */

SELECT 
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales,
    SUM(transaction_qty) AS Total_Quantity,
    COUNT(*) AS Total_Orders
FROM 
    coffee_shop
WHERE 
    DAYOFWEEK(transaction_date) = 3 -- Filter for Tuesday (1 is Sunday, 2 is Monday, ..., 7 is Saturday)
    AND HOUR(transaction_time) = 8 -- Filter for hour number 8
    AND MONTH(transaction_date) = 5; -- Filter for May (month number 5)


/* sales for each hours */

select 
	hour(transaction_time) 'Hour',
	sum(transaction_qty * unit_price) totalsales
from coffee_shop
where
	month(transaction_date) = 5
group by 
	hour(transaction_time)
order by 
	sum(transaction_qty * unit_price) desc;

/* total sales for each day by month */

WITH sales_by_day AS (
    SELECT
        DAYOFWEEK(transaction_date) AS day_num,
        SUM(unit_price * transaction_qty) AS total_sales
    FROM coffee_shop
    WHERE MONTH(transaction_date) = 5
    GROUP BY DAYOFWEEK(transaction_date)
)

SELECT
    CASE day_num
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
        ELSE 'Sunday'
    END AS day_of_week,
    ROUND(total_sales) AS total_sales
FROM sales_by_day
ORDER BY day_num;

/* another way */

select distinct
	dayname(transaction_date),
	round(sum(transaction_qty*unit_price))
from coffee_shop
where 
	month(transaction_date)=5
group by 
	dayname(transaction_date);







