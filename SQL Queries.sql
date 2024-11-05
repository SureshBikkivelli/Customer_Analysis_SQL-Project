
/*  Tables Creation and Data insertion  */

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');




/* ----------------------
   Questions for Insights
   ---------------------- */



-- 1. What is the total amount each customer spent at the restaurant?  

select 
	customer_id,
	sum(price) as total_amount
from sales s join menu m
on s.product_id = m.product_id
group by customer_id;

-- 2. How many days has each customer visited the restaurant?

select  
	count (distinct order_date) as Total_Days_Visited,
	customer_id 
from sales
group by customer_id
order by customer_id;




-- 3. What was the first item from the menu purchased by each customer?

with cte as(
select s.customer_id,
       s.order_date,
       m.product_name, 
       s.product_id, row_number() over (partition by customer_id order by order_date) as Rnumber
from sales s
join menu m
on s.product_id = m.product_id)
select customer_id, order_date, product_name
from cte 
where Rnumber = 1;



-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

 select 
	customer_id, 
	m.product_name, 
	count(s.product_id)
 from sales s 
 join menu m 
 on s.product_id = m.product_id
 where 
 s.product_id = (select s.product_id --, m.product_name, count(m.product_name)
 from sales s 
 join menu m 
 on s.product_id = m.product_id
 group by s.product_id, m.product_name
 order by count(m.product_name) desc
 limit 1)
 group by s.customer_id, m.product_name
 order by s.customer_id;


 

-- 5. Which item was the most popular for each customer?

with popular_product as(
with CTE as(
select  s.customer_id,
        s.product_id,
        m.product_name,
        count(m.product_name) as customer_wise_item_count
 from sales s 
 join menu m 
 on s.product_id = m.product_id
 group by s.customer_id, m.product_name, s.product_id
 order by  s.customer_id, customer_wise_item_count desc 
 )
select customer_id,
       product_id,
       product_name,
       customer_wise_item_count,
       dense_rank() over (partition by customer_id order by customer_id, customer_wise_item_count desc) as product_rank
from CTE 
)
select customer_id,
	   product_id,
       product_name,
       customer_wise_item_count
from popular_product
where product_rank = 1;





-- 6. Which item was purchased first by the customer after they became a member?

With Purchased_After_Member as (
SELECT
	s.customer_id,
    s.product_id,
    s.order_date,
    mem.join_date,
    m.product_name,
    m.price,
    row_number() over( partition by s.customer_id order by s.customer_id, s.order_date ) as Rnumber
FROM sales s
 JOIN menu m
      on s.product_id = m.product_id 
 JOIN members mem
       on s.customer_id = mem.customer_id
where s.order_date >= mem.join_date
)
select 
	customer_id,
    product_name
FROM Purchased_After_Member
where Rnumber = 1;




-- 7. Which item was purchased just before the customer became a member?

With Purchased_Before_Member as (
SELECT
	s.customer_id,
    s.product_id,
    s.order_date,
    mem.join_date,
    m.product_name,
    m.price,
    row_number() over( partition by s.customer_id order by s.customer_id, s.order_date Desc) as Rnumber
FROM sales s
 JOIN menu m
      on s.product_id = m.product_id 
 JOIN members mem
       on s.customer_id = mem.customer_id
where s.order_date < mem.join_date
)
select 
	customer_id,
    product_name
FROM Purchased_Before_Member
where Rnumber = 1;




-- 8. What is the total items and amount spent for each member before they became a member?

SELECT
	s.customer_id,
    count(s.product_id) as Total_items,
    sum(m.price) as Spent_amount
FROM sales s
 JOIN menu m
      on s.product_id = m.product_id 
 JOIN members mem
       on s.customer_id = mem.customer_id
where s.order_date < mem.join_date      -- orders before member
group by s.customer_id
order by s.customer_id;




-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

With Each_item_Points as (
select 
	s.customer_id,
    m.product_id,
	m.product_name, 
    m.price,
   	Case 
    	When m.product_name = 'sushi' Then m.price*20 
       	Else m.price*10
    End as Points
FROM sales s
 JOIN menu m
      on s.product_id = m.product_id 
order by s.customer_id
)
select 
	customer_id,
    sum(Points) as Total_Points
From Each_item_Points
Group by customer_id;





/*  10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
not just sushi - how many points do customer A and B have at the end of January?  */

With Order_Points AS(
SELECT  
  	s.customer_id,
    s.product_id,
    s.order_date,
    mem.join_date,
    m.product_name,
    m.price,
	Case 
    	When s.order_date between mem.join_date and DATEADD(DAY, 6, mem.join_date)  Then m.price*20    -- Fetching 7 Days including join_date
  		When m.product_name = 'sushi'  Then m.price*20
        Else m.price*10
    End as Points
FROM sales s
JOIN menu m
	on s.product_id = m.product_id
JOIN members mem
	on s.customer_id = mem.customer_id
Where DATEPART(MONTH, s.order_date) = 1     -- here we are giving condtions fetch January(1st month) order_date only
)
SELECT 
	customer_id, 
	Sum(Points) as Total_Points
FROM Order_Points
GROUP BY customer_id;





/* -- 11.This Query is for calculating that how many points do customer A and B have with 
conditions are item 'sushi' have 2x points and remaining items are before membership is 1x and after membership is 2x.   */

With Order_Points AS(
SELECT  
  	s.customer_id,
    s.product_id,
    s.order_date,
    mem.join_date,
    m.product_name,
    m.price,
	Case 
    	When s.order_date < mem.join_date and m.product_name != 'sushi' 
        Then m.price*10
        Else m.price*20 
    End as Points
FROM sales s
JOIN menu m
	on s.product_id = m.product_id
JOIN members mem
	on s.customer_id = mem.customer_id
)
SELECT 
	customer_id, 
	Sum(Points) as Total_Points
FROM Order_Points
GROUP BY customer_id;
