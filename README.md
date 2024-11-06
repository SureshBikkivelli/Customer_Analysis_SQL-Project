# Customer_Analysis_SQL-Project
This project analyzes customer behavior, spending patterns, and menu preferences in a restaurant, focusing on visit frequency and loyalty program impact. It leverages data to optimize customer engagement, identify popular items, and calculate loyalty points for personalized rewards.



* We have these below 3 Tables

  				
		
				
				
![image](https://github.com/user-attachments/assets/d4498a1c-6126-42b4-aa98-c8a95b0ae146)


<pre>
Now we are getting insights from this data by finding solutions for below questions ?

 1. What is the total amount each customer spent at the restaurant?
 2. How many days has each customer visited the restaurant?
 3. What was the first item from the menu purchased by each customer?
 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
 5. Which item was the most popular for each customer?
 6. Which item was purchased first by the customer after they became a member?
 7. Which item was purchased just before the customer became a member?
 8. What is the total items and amount spent for each member before they became a member?
 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

</pre>



###  Q1. What is the total amount each customer spent at the restaurant? 


```sql
select 
	customer_id,
	sum(price) as total_amount
from sales s join menu m
on s.product_id = m.product_id
group by customer_id;

Result:	
customer_id	total_amount
B	74
C	36
A	76
![image](https://github.com/user-attachments/assets/7187dfb1-3a75-453c-87af-4a28bcf267c5)

```


### Q1. What is the total amount each customer spent at the restaurant?  

```sql
select 
	customer_id,
	sum(price) as total_amount
from sales s join menu m
on s.product_id = m.product_id
group by customer_id;
```


### Q2. How many days has each customer visited the restaurant?

```sql
select  
	count (distinct order_date) as Total_Days_Visited,
	customer_id 
from sales
group by customer_id
order by customer_id;
```


### Q3. What was the first item from the menu purchased by each customer?
```sql
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
```


### Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?
```sql
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
```

 

### Q5. Which item was the most popular for each customer?
```sql
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
```




### Q6. Which item was purchased first by the customer after they became a member?
```sql
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
```



### Q7. Which item was purchased just before the customer became a member?
```sql
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
```



### Q8. What is the total items and amount spent for each member before they became a member?
```sql
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
```



### Q9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
```sql
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
```




### /*  Q10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
###         not just sushi - how many points do customer A and B have at the end of January?  */
```sql
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
```




### /* Q11.This Query is for calculating that how many points do customer A and B have with 
###        conditions are item 'sushi' have 2x points and remaining items are before membership is 1x and after membership is 2x.   */
```sql
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
```

