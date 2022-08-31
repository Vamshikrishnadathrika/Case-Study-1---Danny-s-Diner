-- 1.What is the total amount each customer spent at the restaurant?
Select s.customer_id, sum(price) as total_amount_spent
From sales s
Left Join menu m
On s.product_id = m.product_id
Group By s.customer_id



-- 2.How many days has each customer visited the restaurant?
Select customer_id, Count( distinct order_date) as number_of_days_visited
From sales
Group By customer_id



-- 3.What was the first item from the menu purchased by each customer?
Select distinct(s.customer_id), product_name as first_item_purchased
From sales s
Left Join menu m
On s.product_id = m.product_id
Where order_date = (Select min(order_date) 
                    From sales s1 
					Where s1.customer_id=s.customer_id)



-- 4.What is the most purchased item on the menu and how many times was it purchased by each customers?
Select customer_id, m.product_name, count(s.product_id) as number_of_times_purchased,
(select Top(1) count(*) from sales Group By product_id Order by count(*) desc) total_purchases
From sales s
Left Join menu m
On s.product_id = m.product_id
Where s.product_id = (select Top(1) product_id from sales Group By product_id Order by count(*) desc)
Group By customer_id, m.product_name
Order By customer_id



-- 5.Which item was the most popular for each customer?
Select customer_id, m.product_name, count(s.product_id) as number_of_times_purchased
From sales s
Left Join menu m
On s.product_id = m.product_id
Where s.product_id in (Select product_id 
					   From (Select customer_id, product_id,
					         DENSE_RANK() Over(PARTITION By customer_id Order By Count(product_id) desc) r 
					         From sales
							 GROUP BY customer_id, product_id) as s1
					   Where r=1 And customer_id =s.customer_id ) 
Group By customer_id, m.product_name
Order By customer_id



-- 6.Which item was purchased first by the customer after they became a member?
Select s.customer_id, order_date, m.product_name
From sales s
Left Join menu m
On s.product_id = m.product_id
Where order_date = (Select min(order_date)
                    From sales s2
					Inner Join members m 
					On s2.customer_id = m.customer_id
					Where order_date >= join_date And s2.customer_id = s.customer_id)



-- 7.Which item was purchased just before the customer became a member?
Select  Distinct s.customer_id, order_date, m.product_name
From sales s
Left Join menu m
On s.product_id = m.product_id
Where order_date = (Select max(order_date)
                    From sales s2
					Inner Join members m 
					On s2.customer_id = m.customer_id
					Where order_date < join_date And s2.customer_id = s.customer_id)


-- 8.What is the total items and amount spent for each member before they became a member?
Select s.customer_id, count(*) as total_items, sum(price) as total_amount_spend
From sales s
Inner Join members m1
On m1.customer_id = s.customer_id
Left Join menu m2
On s.product_id = m2.product_id
Where order_date < join_date
Group By s.customer_id


-- 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
-- how many points would each customer have?
Select customer_id, sum(price*multiplier*10) as points
From (Select s.customer_id, price, 
      Case
	    When s.product_id = 1 Then 2 
		Else 1
		End as multiplier
	  From sales s
	  Left Join menu m
	  On s.product_id = m.product_id ) as S
Group By customer_id



-- 10.In the first week after a customer joins the program (including their join date) they earn 2x points 
--on all items, not just sushi - how many points do customer A and B have at the end of January?
Select customer_id, sum(price*multiplier*10) as points
From (Select s.customer_id, price, order_date,
      Case
	    When s.product_id = 1 Then 2 
		When  DATEDIFF(day, join_date, order_date) <7 And DATEDIFF(day, join_date, order_date) >=0  Then 2
		Else 1
		End as multiplier
	  From sales s
	  Inner Join members 
	  On members.customer_id = s.customer_id
	  Left Join menu m
	  On s.product_id = m.product_id ) as S
Where order_date < '2021-02-01'
Group By customer_id



-- Bonus Questions
-- Rank All The Things
With all_ranked as
(
Select s.customer_id, s.order_date, m1.product_name, m1.price,
Case
When m2.join_date > s.order_date Then 'N'
When m2.join_date <= s.order_date Then 'Y'
Else 'N' END AS member
From sales s
LEFT JOIN menu m1
On s.product_id = m1.product_id
LEFT JOIN members m2
ON s.customer_id = m2.customer_id
)
Select *,
CASE
WHEN member = 'N' then NULL
ELSE
RANK () OVER(PARTITION BY customer_id, member
ORDER BY order_date) END AS ranking
From all_ranked