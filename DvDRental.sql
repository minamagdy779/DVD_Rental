	

/* shows the actor's movie's name and its description and the length of it  */

select concat(first_name,' ',last_name) full_name, title, description, length
from film_actor fa
join actor act on fa.actor_id = act.actor_id 
join film fm on fa.film_id = fm.film_id 


/* list of actor's and movies they particpated in where the length of the movie is more than 60 minuites */

Select concat(first_name,' ',last_name) full_name, title, description, length
from film_actor fa
join actor act on fa.actor_id = act.actor_id 
join film fm on fa.film_id = fm.film_id 
where length > 60 


/* The most actor who appeared in movies */

select act_id , full_name, count(title)
from(
select act.actor_id act_id , concat(act.first_name,' ',act.last_name) full_name, fm.title title
from film_actor fa
join actor act on fa.actor_id = act.actor_id 
join film fm on fa.film_id = fm.film_id 
) list
group by 1, 2
order by 3 desc

/* category the movies by thier lengths */


select concat(act.first_name,' ',act.last_name) full_name, fm.title title, fm.length len,
CASE 
when fm.length <= 60 then '1 hour or less' 
when fm.length between 60 and 120 then 'from 1-2 hours'
when fm.length between 121 and 180 then 'from 2-3 hours'
else 'More than 3 hours'
END as filmlen_groups
from film_actor fa
join actor act on fa.actor_id = act.actor_id 
join film fm on fa.film_id = fm.film_id  

--First question
/*  count the movies by their length group from the above query */

select distinct(filmlen_groups) , Count(title) over (partition by filmlen_groups) as film_count
from(select fm.title , fm.length,
	 case 
	 when fm.length <= 60 then '1 hour or less' 
	 when fm.length > 60 and fm.length <= 120 then 'from 1-2 hours'
	 when fm.length > 120 and  fm.length <=180 then 'from 2-3 hours'
	 else 'More than 3 hours'
	 END as filmlen_groups
	 from film fm ) t1 
order by filmlen_groups	


/* sort out the family movies and how many times each movie was rented out  */

select title , name , count_rentals
from(
Select fm.title title, cat.name name , Count(ren.inventory_id) as count_rentals 
from film_category fc
join film fm on fc.film_id = fm.film_id
join category cat on fc.category_id = cat.category_id
join inventory inv on fm.film_id = inv.film_id
join rental ren on inv.inventory_id = ren.inventory_id 
group by 1,2
order by cat.name
) category_sorted
where name in ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')

/* The average of rental duration (25%, 50%, 75%, 100%)  */
-- category name rental duration percentile

select title, name, rental_duration, Quartiles
from(
select fm.title title, cat.name name, fm.rental_duration rental_duration, ntile(4) over (order by rental_duration) as Quartiles
from film_category fc
join film fm on fc.film_id = fm.film_id
join category cat on fc.category_id = cat.category_id
order by cat.name 
	) category_quartiles_sorted
where name in ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
order by rental_duration , name


/* Count of movies per quartile per category  */
-- film_category film category

with CTE as(
select fm.title title, cat.name name,  ntile(4) over (order by rental_duration) as 	Quartiles
from film_category fc
join film fm on fc.film_id = fm.film_id
join category cat on fc.category_id = cat.category_id
where name in ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music') 
) 
Select name, Quartiles, Count(title) 
from CTE
group by name , Quartiles
order by 1, 2

select name, rental_duration , count (title)
from (select f.title as title,c.name as name,ntile (4) over  (order by f.rental_duration) as rental_duration 
from film f
join film_category
on f.film_id=film_category.film_id
join category c
on c.category_id=film_category.category_id
where c.name in ('Animation','Children','Classics','Comedy', 'Family', 'Music' ) )t1
group by name, rental_duration
order by name,rental_duration

/* show the difference between the count of rentals of the two stores */
-- tables >> store, staff , rental

select StoreID, Year, Month, Count(rental)
from(
select st.store_id as StoreID, DATE_PART('YEAR', rental_date) as Year, DATE_PART('month', rental_date) as Month, rental_id as rental
from store st 
join staff stf on st.store_id = stf.store_id
join rental ren on stf.staff_id = ren.staff_id 
) count_rental
group by  StoreID, Year, Month
order by Year , Month 

/* Top 10 paying customers during 2007 by monthly payments */
-- tables >> customer, payment

with Payment_month as (
select concat(first_name, ' ', last_name) fullname , pay.amount as amount, pay.payment_date as date
from customer cus
join payment pay on cus.customer_id = pay.customer_id
)
Select fullname , date_trunc('month', date), count(amount) count_payments,  SUM(amount) Total_Payments
from Payment_month
group by  fullname, 2
order by  Total_Payments desc
LIMIT 10

/* show the difference across the top 10 paying customers monthly payments during 2007 */
-- tables >> customer, payment

with Payment_month as (
select concat(first_name, ' ', last_name) fullname , DATE_TRUNC('month', payment_date) as month, SUM(amount) Total_Payments
from customer cus
join payment pay on cus.customer_id = pay.customer_id
group by month, fullname
)
select fullname, Max(amount_difference) as Max_Differ
from(
Select fullname , month , 
Total_Payments - lag(Total_Payments) over (partition by fullname order by month) as amount_difference
from Payment_month
) subquery 
group by fullname
order by Max_Differ desc
LIMIT 10

-- Second Question
/* What is the most Film Categories rented out from the two stores? */
-- tables >> store , staff, rental , film , film_category, category 
-- category name , store id, number of rentals for each category

select ID, category, count(rental) as Most_Rented_Category
from(
select str.Store_id as ID , cat.name as category, ren.rental_id as rental
from store str 
join staff stf on str.store_id = stf.store_id
join rental ren on stf.staff_id = ren.staff_id
join inventory inv on inv.inventory_id = ren.inventory_id
join film fm on fm.film_id = inv.film_id
join film_category fc on fm.film_id = fc.film_id
join category cat on cat.category_id = fc.category_id
	) Category_sort
	group by ID, category
	order by 3 desc

--Third Question
/* What is the total sales for each store */
-- table >> store , staff, payment

select sto.store_id StoreID, add.address, Date_trunc('year', pay.payment_date) as Year, SUM(pay.amount) Total_Sales 
from address add 
join store sto on add.address_id = sto.address_id
join staff stf on sto.store_id = stf.store_id
join payment pay on stf.staff_id = pay.staff_id
group by 1 , 2 , 3
order by 4 desc

--Fourth Question
/* Top 10 rented movies */
-- tables >> film , inventory, rental
	
	select full_name ,  Count(full_name)
from(
select fm.title film_title, concat(first_name, ' ', last_name) as full_name ,Count(ren.rental_id) 
from film_actor fa
join actor act on fa.actor_id = act.actor_id
join film fm on fa.film_id = fm.film_id
join inventory inv on fm.film_id = inv.film_id
join rental ren on inv.inventory_id = ren.inventory_id
group by 1, 2
order by 3 desc
	) sub
	group by 1
	order by 2 desc
	Limit 10

/* All The Tables */

select * from actor
select * from address
select * from category
select * from city
select * from country
select * from customer
select * from film
select * from film_actor
select * from film_category
select * from inventory
select * from language
select * from payment
select * from rental
select * from staff
select * from store

















