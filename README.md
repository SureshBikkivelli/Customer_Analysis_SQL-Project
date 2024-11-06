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


<pre>'''sqlselect 
	customer_id,
	sum(price) as total_amount
from sales s join menu m
on s.product_id = m.product_id
group by customer_id;'''</pre>

