--1.
-- Write a query that returns each genre, with the number of tracks sold in the USA:
--     in absolute numbers
--     in percentages.
with invoice_usa as
         (
             select *
             from invoice
             where billing_country = 'USA'
         )
select t.genre_id,
       g.name,
       count(*) tracks_sold,
       round(count(*) * 100.0 / sum(count(*)) over (), 2) percentage
from invoice_usa us
         left join invoice_line il on il.invoice_id = us.invoice_id
         left join track t on il.track_id = t.track_id
         left join genre g on t.genre_id = g.genre_id
group by t.genre_id
order by 4 desc;

-- The results show that the most popular genre in USA is
-- Rock with percentage of %53.38, and it is followed by Alternative & Punk
-- with %12.37.


select a2.name,
       count(*)
                              times_purchased,
       round(sum(i.total), 2) revenue
from invoice i
         left join invoice_line il on i.invoice_id = il.invoice_id
         left join track t on il.track_id = t.track_id
         left join album a on t.album_id = a.album_id
         left join artist a2 on a.artist_id = a2.artist_id
where t.genre_id in (1, 4)
group by a2.name
order by 2 desc;

--The songs from Queen, Jim Hendrix and Red Hot Chilli Peppers
-- can be recommended to the users in USA.


-- 2.
--     Write a query that finds the total dollar amount of sales assigned to each
--     sales support agent within the company. Add any extra attributes for that
--     employee that you find are relevant to the analysis.
-------------------------
--     Write a short statement describing your results, and providing a possible interpretation.


select e.employee_id,
       e.first_name || ' ' || e.last_name                             employee_name,
       round(sum(invoice.total), 2)                                   total_revenue,
       round(sum(invoice.total) / sum(sum(invoice.total)) over (), 3) share,
       count(*)                                                       total_sales
from invoice
         left join customer c on invoice.customer_id = c.customer_id
         left join employee e on c.support_rep_id = e.employee_id
where e.title = 'Sales Support Agent'
group by 1;

-- The sales share of each Support Agent are almost same,
-- Jane Peacock's share is 0.368, Margaret Park's 0.336,
-- and  Steve Johnson's 0.296.

--3.
-- Write a query that collates data on purchases from different countries.
--
--     Where a country has only one customer, collect them into an "Other" group.
--     The results should be sorted by the total sales from highest to lowest, with the "Other"
--     group at the very bottom.
--     For each country, include:
--         -total number of customers
--         -total value of sales
--         -average value of sales per customer
--         -average order value

with country_one_cust as
         (
             select country, count(customer_id) cust_count
             from customer
             group by country
             having cust_count = 1
         ),
     country_other as
         (
             select case
                        when c.country in
                             (select country from country_one_cust) then 'Other'
                        else country
                        end
                        as country,
                    i.*
             from customer c
                      inner join invoice i on c.customer_id = i.customer_id
         )
         select
            country,
            customers,
            total_sales,
            avg_customer_sales,
            avg_order
          from
          (
           select
            country,
            count(distinct customer_id) customers,
            sum(total) total_sales,
            sum(total)/count(distinct customer_id) avg_customer_sales,
            sum(total)/count(distinct invoice_id) avg_order,
            case
              when country = 'Other' then 1
              else 0
            end as sort
          from country_other
          group by country
          order by sort, total_sales desc
          );

--4.
--     Write a query that categorizes each invoice as either an album
--     purchase or not, and calculates the following summary statistics:
--     -Number of invoices
--     -Percentage of invoices
--     Write one to two sentences explaining your findings, and making a
--     prospective recommendation on whether the Chinook store should
--     continue to buy full albums from record companies


WITH albums_tracks
         AS
         (
             select il.invoice_id,
                    group_concat(il.track_id)           as tracks,
                    group_concat(DISTINCT (t.album_id)) as albums
             from invoice_line il
                      left join track t on il.track_id = t.track_id
             group by il.invoice_id
         ),
     albums_tracks2
         AS
         (
             select album_id, group_concat(track_id) tracks2
             from track
             group by album_id
         )

select case
           when tracks = tracks2 then 'Yes'
           else 'No'
           end as                                         whole_album_purchase,
       count(*)                                           num_of_invoice,
       round(count(*) * 100.0 / sum(count(*)) over (), 2) percentage

from albums_tracks at1
         left join albums_tracks2 at2 ON at2.album_id = at1.albums
group by whole_album_purchase;

-- The results show that a little over 18% of all purchases are
-- whole albums indicating that customers prefer buying a
-- collection rather than buying whole albums. Chinook sales department
-- should focus on promoting popular collections.

