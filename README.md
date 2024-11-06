# Customer_Analysis_SQL-Project
This project analyzes customer behavior, spending patterns, and menu preferences in a restaurant, focusing on visit frequency and loyalty program impact. It leverages data to optimize customer engagement, identify popular items, and calculate loyalty points for personalized rewards.



##### We have these below 3 Tables

  				
		
				
				
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




### Q1. What is the total amount each customer spent at the restaurant?  

```sql
select 
	customer_id,
	sum(price) as total_amount
from sales s join menu m
on s.product_id = m.product_id
group by customer_id;
```

![image](https://github.com/user-attachments/assets/5295a355-bb6d-4467-b0d9-517aa2d67dbc)


### Q2. How many days has each customer visited the restaurant?

```sql
select  
	count (distinct order_date) as Total_Days_Visited,
	customer_id 
from sales
group by customer_id
order by customer_id;
```

![image](https://github.com/user-attachments/assets/5a738777-28d1-4139-b6e5-72b7be4bf639)


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

![image](https://github.com/user-attachments/assets/c72ccb36-a41b-48c8-b367-77c972dc3b9b)


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


![image](https://github.com/user-attachments/assets/e53f7d6d-bb0d-4f9c-b7d2-5539c3d2a272)


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



![image](https://github.com/user-attachments/assets/65927b2e-e0c5-4699-9d50-8bbee645b578)


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


![image](https://github.com/user-attachments/assets/f6dfb8f2-2eab-4222-bb77-b5cf039aa3cd)



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

![image](https://github.com/user-attachments/assets/a51ccbd8-eddd-457e-9fa5-b8803f85e618)



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

![image](https://github.com/user-attachments/assets/d8caad0c-7f2f-4b53-b1fc-9e1e563582b0)




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

![image](https://github.com/user-attachments/assets/96305842-5726-44cc-98ae-cc67f5f8bd9c)



###  Q10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?  
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

![image](https://github.com/user-attachments/assets/3cbb3ab4-7229-4491-9879-91aba6fd9626)



###  Q11. This Query is for calculating that how many points do customer A and B have with conditions are item 'sushi' have 2x points and remaining items are before membership is 1x and after membership is 2x.  
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

![image](https://github.com/user-attachments/assets/50bf512d-0ab3-416f-a099-e9b4c5161fbf)







# Insights and some key points 


### 1. Total Spending by Customers
- **Insight:** I calculated the total amount each customer spent at the restaurant by joining the `sales` and `menu` tables, multiplying the number of times each item was ordered by its price. This provides a clear view of customer value.

### 2. Frequency of Visits
- **Insight:** I determined how many unique days each customer visited by counting distinct `order_date` entries in the `sales` table, which can help in understanding customer engagement and loyalty.

### 3. First Item Purchased
- **Insight:** By ordering the sales records by date, I identified the first menu item purchased by each customer. This can give insights into customer preferences right at the start of their relationship with the diner.

### 4. Most Purchased Item
- **Insight:** I aggregated purchase counts across all customers to identify the most popular item on the menu. This helps to understand product performance and can inform inventory and marketing strategies.

### 5. Popularity by Customer
- **Insight:** I analyzed the purchase data to find out which item was most frequently bought by each customer, revealing individual preferences that could help tailor marketing efforts.

### 6. First Purchase After Membership
- **Insight:** I tracked purchases made by customers after their join date to find the first item they bought as members, which could indicate the effectiveness of membership incentives.

### 7. Purchase Just Before Membership
- **Insight:** I identified which item each customer purchased just before becoming a member, potentially highlighting their interests and helping design targeted promotions for new members.

### 8. Total Items and Spending Before Membership
- **Insight:** I aggregated the total number of items and amount spent by each customer before they joined, providing a pre-membership value assessment which could inform retention strategies.

### 9. Customer Points Calculation
- **Insight:** I calculated the points each customer earned based on their spending, considering special multipliers for certain items. This is important for understanding loyalty program dynamics.

### 10. Points Accumulation in First Week
- **Insight:** I evaluated how many points customers A and B accumulated in the first week after joining, applying a points multiplier for that period. This metric can help assess the immediate impact of loyalty programs on customer behavior.

### Conclusion
These insights not only demonstrate my ability to manipulate and analyze SQL data effectively, but also show how SQL queries can drive business decisions and enhance customer relationships. I can leverage these findings to suggest strategies for customer engagement, retention, and product offerings. 

