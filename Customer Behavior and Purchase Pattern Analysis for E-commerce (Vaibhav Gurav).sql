-- Project : Customer Behavior and Purchase Pattern Analysis for E-commerce (MySQL)

-- 1. Question: Which age group of customers contributes the highest revenue, and how does gender distribution affect purchase behavior?
select 
    case 
        when age between 18 and 25 then '18-25'
        when age between 26 and 35 then '26-35'
        when age between 36 and 45 then '36-45'
        when age between 46 and 55 then '46-55'
        else '56+' 
    end as age_group,
    gender, sum(o.totalamount) as total_revenue
from customers c join orders o on c.customerid = o.customerid group by age_group, gender
order by total_revenue desc;
-- Insight: Identify top-earning age groups and gender to guide targeted marketing campaigns.

-- 2. Question: What percentage of customers place multiple orders vs. those who shop only once?
select 
    case when order_count > 1 then 'repeat' else 'one-time' end as customer_type,
    count(*) as customer_count,
    round(count(*)*100/(select count(*) from customers),2) as percentage
from (
    select customerid, count(*) as order_count
    from orders
    group by customerid
) t
group by customer_type;
-- Insight: Understand customer retention by comparing repeat buyers vs. one-time buyers.

-- 3. Question: Who are the top 10 customers by total spending, and what is their average order frequency?
select 
    c.customerid,
    c.fullname,
    count(o.orderid) as total_orders,
    sum(o.totalamount) as total_spent,
    avg(o.totalamount) as avg_order_value
from customers c
join orders o on c.customerid = o.customerid
group by c.customerid, c.fullname
order by total_spent desc
limit 10;
-- Insight: Identify VIP customers to implement loyalty programs and personalized marketing.

-- 4. Question: Which products and categories generate the highest sales volume and revenue?
select 
    p.category,
    p.subcategory,
    p.productname,
    sum(od.quantity) as total_quantity_sold,
    sum(od.quantity * od.unitprice - od.discount) as total_revenue
from orderdetails od
join products p on od.productid = p.productid
group by p.category, p.subcategory, p.productname
order by total_revenue desc;
-- Insight: Highlight best-selling products and categories to optimize inventory and promotions.

-- 5. Question: How many customers who registered in the last 12 months did not place a second order?
select count(*) as customers_no_second_order
from (
    select c.customerid, count(o.orderid) as orders_count
    from customers c
    left join orders o on c.customerid = o.customerid
    where c.registrationdate >= date_sub(curdate(), interval 12 month)
    group by c.customerid
    having orders_count < 2
) t;
-- Insight: Identify new customers at risk of churn to improve retention campaigns.

-- 6. Question: What percentage of orders are canceled or returned, and which product categories are most affected?
select 
    p.category,
    count(*) as affected_orders,
    round(count(*)*100/(select count(*) from orders where orderstatus in ('Canceled','Returned')),2) as percentage
from orders o
join orderdetails od on o.orderid = od.orderid
join products p on od.productid = p.productid
where o.orderstatus in ('Canceled','Returned')
group by p.category
order by affected_orders desc;
-- Insight: Monitor problem categories and reduce cancellations or returns.

-- 7. Question: Which payment methods are most popular, and how do they relate to order success/failure rates?
select 
    paymentmethod,
    count(*) as total_orders,
    round(sum(case when orderstatus='Completed' then 1 else 0 end)/count(*)*100,2) as completion_rate
from orders
group by paymentmethod
order by total_orders desc;
-- Insight: Determine preferred payment methods and their effectiveness in completing orders.

-- 8. Question: Which months or seasons have the highest order volume, and does browsing activity spike before big sales?
select 
    month(orderdate) as order_month,
    count(*) as total_orders
from orders
group by order_month
order by total_orders desc;
-- Insight: Identify seasonal trends to plan promotions and sales events.

-- 9. Question: How many customers browsed products but did not purchase, and which categories have the lowest conversion rates?
select 
    p.category,
    count(distinct bh.customerid) as browsing_customers,
    count(distinct o.customerid) as purchasing_customers,
    round((count(distinct o.customerid)/count(distinct bh.customerid))*100,2) as conversion_rate_percentage
from browsinghistory bh
join products p on bh.productid = p.productid
left join orders o on bh.customerid = o.customerid
group by p.category
order by conversion_rate_percentage asc;
-- Insight: Identify low-conversion categories to improve product pages or offers.

-- 10. Question: What percentage of Add to Cart actions do not result in completed purchases, and which customer segment has the highest drop-off?
select 
    case 
        when age between 18 and 25 then '18-25'
        when age between 26 and 35 then '26-35'
        when age between 36 and 45 then '36-45'
        when age between 46 and 55 then '46-55'
        else '56+' 
    end as age_group,
    count(*) as addtocart_count,
    sum(case when o.orderstatus='Completed' then 1 else 0 end) as completed_orders,
    round((count(*) - sum(case when o.orderstatus='Completed' then 1 else 0 end))/count(*)*100,2) as dropoff_percentage
from browsinghistory bh
join customers c on bh.customerid = c.customerid
left join orders o on bh.customerid = o.customerid
where bh.actiontype='AddToCart'
group by age_group
order by dropoff_percentage desc;
-- Insight: Highlight customer segments with high cart abandonment for targeted engagement.


-- 11. Question: What is the average product rating per category, and which brands consistently receive negative feedback?
select 
    p.category,
    p.brand,
    round(avg(f.rating),2) as avg_rating,
    count(case when f.rating<=2 then 1 end) as negative_feedback_count
from feedback f
join products p on f.productid = p.productid
group by p.category, p.brand
order by avg_rating asc;
-- Insight: Understand brand and category performance from customer feedback for quality improvement.

-- 12. Question: Which products are frequently purchased together, and how can this inform bundle offers?
select 
    od1.productid as product1,
    od2.productid as product2,
    count(*) as times_purchased_together
from orderdetails od1
join orderdetails od2 on od1.orderid = od2.orderid and od1.productid < od2.productid
group by od1.productid, od2.productid
order by times_purchased_together desc
limit 20;
-- Insight: Detect cross-selling opportunities to create product bundles.

-- 13. Question: Which locations/cities generate the highest revenue, and where should we focus marketing campaigns?
select 
    c.location,
    sum(o.totalamount) as total_revenue
from customers c
join orders o on c.customerid = o.customerid
group by c.location
order by total_revenue desc
limit 20;
-- Insight: Focus marketing campaigns in top-revenue locations for maximum ROI.

-- 14. Question: Based on order frequency and average spend, which customers are most likely to be long-term valuable customers?
select 
    c.customerid,
    c.fullname,
    count(o.orderid) as order_count,
    avg(o.totalamount) as avg_order_value,
    count(o.orderid)*avg(o.totalamount) as customer_lifetime_value
from customers c
join orders o on c.customerid = o.customerid
group by c.customerid, c.fullname
order by customer_lifetime_value desc
limit 20;
-- Insight: Identify high CLV customers for loyalty programs and personalized marketing.
