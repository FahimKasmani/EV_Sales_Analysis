CREATE TABLE dim_date (
    date DATE PRIMARY KEY,
    fiscal_year INT,
    quarter TEXT
);

CREATE TABLE makers (
    date DATE,
    vehicle_category TEXT,
    maker TEXT,
    electric_vehicles_sold INT
);

CREATE TABLE state (
    date DATE,
    state TEXT,
    vehicle_category TEXT,
    electric_vehicles_sold INT,
    total_vehicles_sold INT
);

/* 1. List the top 3 and bottom 3 makers for the fiscal years 2023 and 2024 in 
terms of the number of 2-wheelers sold.*/

-- Top 3 makers 
Select * from (
    Select m.maker, sum(m.electric_vehicles_sold) as total_sales
    From makers as m 
    Left Join dim_date as d ON 
    m.date = d.date
    Where d.fiscal_year IN (2024,  2023) AND m.vehicle_category = '2-Wheelers'
    Group By m.maker
    Order by total_sales DESC
    LIMIT 3
) as top_2024_2023
	
--Bottom3 

Select m.maker, sum(m.electric_vehicles_sold) as total_sales
From makers as m 
Left JOIN states as s On 
m.date=s.date 
Left Join dim_date as d ON 
s.date = d.date
Where d.fiscal_year IN (2024, 2023) AND m.vehicle_category = '2-Wheelers'
Group By m.maker
Order by total_sales ASC
LIMIT 3


/*2. Identify the top 5 states with the highest penetration rate in 2-wheeler 
and 4-wheeler EV sales in FY 2024.
*/
--2 wheelers
Select s.state, vehicle_category, CAST(Sum(electric_vehicles_sold)AS FLOAT)/ CAST(SUM (Total_vehicles_sold)AS FLOAT)*100 as Penetration_rate
From states as s
Join dim_date as d
ON d.date = s.date
Where d.fiscal_year = 2024 and vehicle_category In ('2-Wheelers') --Change it to 2wheelers to get records of the same
Group by s.state, vehicle_category
Order by Penetration_rate DESC
Limit 5

--4 Wheelers
Select s.state, vehicle_category, CAST(Sum(electric_vehicles_sold)AS FLOAT)/ CAST(SUM (Total_vehicles_sold)AS FLOAT)*100 as Penetration_rate
From states as s
Join dim_date as d
ON d.date = s.date
Where d.fiscal_year = 2024 and vehicle_category In ('4-Wheelers') --Change it to 2wheelers to get records of the same
Group by s.state, vehicle_category
Order by Penetration_rate DESC
Limit 5


/*3.  List the states with negative penetration (decline) in EV sales from 2022 
to 2024?*/


With yearly_pen AS (select s.state, Extract(YEAR From d.date) as Year, CAST(Sum(electric_vehicles_sold)AS FLOAT)/ CAST(SUM (Total_vehicles_sold)AS FLOAT)*100 as Penetration_rate
From states as s
LEFT JOIN dim_date as d On 
s.date =d.date
Where Extract(YEAR From d.date) Between '2022' AND '2024'
GROUP BY s.state, Extract(YEAR From d.date)
)
Select state, 
	SUM(case when Year = 2022 Then Penetration_rate Else 0 END)As y2022,
	SUM(case when Year = 2023 Then Penetration_rate Else 0 END)As y2023,
	SUM(case when Year = 2024 Then Penetration_rate Else 0 END)As y2024
From yearly_pen
Group By state

/*4. What are the quarterly trends based on sales volume for the top 5 EV 
makers (4-wheelers) from 2022 to 2024? */ 

WITH top5 as (
	Select m.maker, 
	SUM(electric_vehicles_sold) as ev_sold
From 
	makers as m 
LEFT JOIN 
	dim_date as d ON 
	m.date=d.date
where 
	Extract(YEAR From d.date) Between '2022' AND '2024'
	And vehicle_category = '4-Wheelers'
Group By 
	m.maker
Order By 
	ev_sold DESC
LIMIT 5
	),
quarterly_sales as (
	Select t.maker, d.quarter, d.fiscal_year as year ,SUM(m.electric_vehicles_sold) as quarterlysales
	from makers as m
	Join dim_date as d ON
	m.date =d.date
	JOIN top5 as t ON
	m.maker =t.maker
	Where Extract(YEAR From d.date) Between '2022' AND '2024'
	Group BY t.maker, d.quarter, d.fiscal_year
)
Select maker, quarter, quarterlysales, year
From quarterly_sales


/*
5. How do the EV sales and penetration rates in Delhi compare to 
Karnataka for 2024?
*/

SELECT
	SUM(ELECTRIC_VEHICLES_SOLD) AS TOTAL,
	(SUM(S.ELECTRIC_VEHICLES_SOLD::NUMERIC)) / (SUM(S.TOTAL_VEHICLES_SOLD::NUMERIC)) * 100 AS PENETRATION_RATE,
	STATE
FROM
	STATES AS S
	JOIN DIM_DATE AS D ON S.DATE = D.DATE
WHERE
	STATE IN ('Delhi', 'Karnataka')
	AND D.FISCAL_YEAR = 2024
GROUP BY
	STATE
/*
6. List down the compounded annual growth rate (CAGR) in 4-wheeler 
units for the top 5 makers from 2022 to 2024. 
*/

WITH totals as (select maker, SUM(electric_vehicles_sold) as total, d.fiscal_year
From makers as m 
left join dim_date as d ON 
m.date = d.date
where d.fiscal_year IN (2022, 2023, 2024) AND m.vehicle_category = '4-Wheelers'
Group By maker, d.fiscal_year
Order by total desc
),
years as (Select maker,
	MAX(Case when fiscal_year = 2022 then total Else 0 End) as y2022,
	MAX(Case when fiscal_year = 2023 then total Else 0 End )as y2023,
	MAX(Case when fiscal_year = 2024 then total Else 0 End) as y2024
From totals
Group by maker),
CAGRS as (Select maker,  
    Case when y2022 = 0 Then Null Else ROUND((((y2024 :: NUMERIC / y2022 :: NUMERIC)^(1.0/2))-1)*100, 2) END as year_22_24,
	Case when y2022 = 0 Then Null Else ROUND((((y2023 :: NUMERIC / y2022 :: NUMERIC)^(1.0/2))-1)*100, 2) END as year_22_23,
	Case when y2022 = 0 Then Null Else ROUND((((y2024 :: NUMERIC / y2023 :: NUMERIC)^(1.0/2))-1)*100, 2) END as year_23_24
from years
)
Select * From CAGRS
where year_22_24 is Not Null AND year_22_23 is Not Null AND year_23_24 is Not Null
Order BY year_22_24 desc
Limit 5 


/*
7. List down the top 10 states that had the highest compounded annual 
growth rate (CAGR) from 2022 to 2024 in total vehicles sold.
*/
WITH totals as (Select 
	s.state as states, 
	SUM (total_vehicles_sold) as total, 
	d.fiscal_year
From states as s 
Left Join dim_date as d On 
s.date = d.date
Where d.fiscal_year IN ('2022', '2023', '2024')
Group By  state, fiscal_year
),
years as (
select states,
	MAX(Case when fiscal_year = '2022' then total else 0 End) as y2022,
	MAX(Case when fiscal_year = '2023' then total else 0 End) as y2023,
	MAX(Case when fiscal_year = '2024' then total else 0 End) as y2024
From totals 
Group by states
),
CAGRS AS (Select states, 
	Case when y2022 = 0 Then Null Else ROUND((((y2024 :: NUMERIC / y2022 :: NUMERIC)^(1.0/2))-1)*100, 2) END as year_22_24,
	Case when y2022 = 0 Then Null Else ROUND((((y2023 :: NUMERIC / y2022 :: NUMERIC)^(1.0/2))-1)*100, 2) END as year_22_23,
	Case when y2022 = 0 Then Null Else ROUND((((y2024 :: NUMERIC / y2023 :: NUMERIC)^(1.0/2))-1)*100, 2) END as year_23_24

From years)
Select *
From CAGRS 
where year_22_24 is Not Null AND year_22_23 is Not Null AND year_23_24 is Not Null
Order BY year_22_24 desc
Limit 10

/*
8. What are the peak and low season months for EV sales based on the 
data from 2022 to 2024?

*/
WITH totalevs as (
SELECT
	TO_CHAR(m.DATE, 'MONTH') AS MONTHS,
	SUM(ELECTRIC_VEHICLES_SOLD) AS EVSALES, fiscal_year
FROM
	MAKERS as m
JOIN dim_date as d ON
m.date =d.date
GROUP BY
	TO_CHAR(m.DATE, 'MONTH'), fiscal_year
),
years as 

(
Select MONTHS,
	EVSALES,
	Case WHEN fiscal_year = 2022 Then EVSALES Else 0 End as year2022,
	Case WHEN fiscal_year = 2023 Then EVSALES Else 0 End as year2023,
	Case WHEN fiscal_year = 2024 Then EVSALES Else 0 End as year2024
fROM totalevs 
)
Select months, evsales
From years 

Order By evsales desc


/*
9.  What is the projected number of EV sales (including 2-wheelers and 4-
wheelers) for the top 10 states by penetration rate in 2030, based on the 
compounded annual growth rate (CAGR) from previous years?
*/


	
WITH sumevs as 
	(Select state, Sum(electric_vehicles_sold) as ev_sold, Extract(Year From date) as years
from states
Group by state,  Extract(Year From date) ),

Maxevs as
(Select state, 
	SUm(Case When years = 2021 then ev_sold Else 0 End) as y2021,
	SUm(Case When years = 2022 then ev_sold Else 0 End) as y2022,
	SUM(Case When years = 2023 then ev_sold Else 0 End) as y2023,
	SUM(Case When years = 2024 then ev_sold Else 0 End) as y2024
	
FROM sumevs
group by state
),
CAGR AS 
	(Select state,
	Case when y2021 = 0 then Null Else ROUND((((y2024 :: NUMERIC / y2021 :: NUMERIC )^(1.0/3))-1),2) END as cagr_21_24,
	Case when y2021 = 0 then Null Else ROUND((((y2022 :: NUMERIC / y2021 :: NUMERIC )^(1.0/1))-1),2) END as cagr_21_22,
	Case when y2021 = 0 then Null Else ROUND((((y2023 :: NUMERIC / y2021 :: NUMERIC )^(1.0/2))-1),2) END as cagr_21_23
FROM Maxevs),
	
totals as 
	(Select c.state, SUM(s.electric_vehicles_sold)as ev_sold, SUM(total_vehicles_sold) as total_sold, c.cagr_21_24 as cagr
	From states as s
	Left Join CAGR as c On
	s.state = c.state
	where   c.cagr_21_24 is Not Null
	Group by c.state, c.cagr_21_24
	),
pen as 
	(Select t.state, (ev_sold :: NUMERIC / total_sold :: NUMERIC) as penetration_rate, cagr, Extract(YEAR FROM date) as years, SUM(electric_vehicles_sold) as evsales
	From totals as t 
	Join states as s ON 
	t.state = s.state
	WHERE Extract(YEAR FROM date) = 2024
	Group By t.state, (ev_sold :: NUMERIC / total_sold :: NUMERIC), Extract(YEAR FROM date), cagr
	Order By penetration_rate DESC),
	
roundedpen as 
	(Select state, ROUND(penetration_rate *100, 2) as penetration_rate, cagr, evsales, years as year
	FROM pen
	)
Select state, ROUND((evsales*((1+cagr)^(2030-2024))), 2 )as proj_sale2030, penetration_rate, cagr
From roundedpen

/*
10. Estimate the revenue growth rate of 4-wheeler and 2-wheelers 
EVs in India for 2022 vs 2024 and 2023 vs 2024, assuming an average 
unit price	
*/
Select * From
(WITH CTE AS 
	(Select vehicle_category, sum(electric_vehicles_sold) as ev_sales, Extract(Year From date) as year
	From makers as m 
	Where Extract(Year From date) In (2022, 2024)
	Group by Extract(Year From date), vehicle_category
	), 
revenue as 
	(Select year,
		SUM(Case when vehicle_category = '2-Wheelers' then (ev_sales * 85000) Else 0 End) as two_wheelers_revenue,
		SUM(Case when vehicle_category = '4-Wheelers' then (ev_sales * 1500000) Else 0 End) as four_wheelers_revenue
	From CTE 
	Group by year
	)
Select 
	year,
	two_wheelers_revenue,
	Lag(two_wheelers_revenue) Over (order by year),
	ROUND(Case when Lag(two_wheelers_revenue) Over (order by year) IS NULL Then Null  
		Else ((two_wheelers_revenue - Lag(two_wheelers_revenue) Over (order by year))/
		Lag(two_wheelers_revenue) Over (order by year)) *100 END, 2) AS two_wheelers_revenue_growth,
	four_wheelers_revenue,
	ROUND(Case when Lag(four_wheelers_revenue) Over (order by year) IS NULL Then Null  
		Else ((four_wheelers_revenue - Lag(four_wheelers_revenue) Over (order by year))/
	Lag(four_wheelers_revenue) Over (order by year)) *100 END , 2) AS four_wheelers_revenue_growth
from revenue) 
as first_query_2022_2024

Union ALL
	
Select * FROM 
(WITH CTE AS 
	(Select vehicle_category, sum(electric_vehicles_sold) as ev_sales, Extract(Year From date) as year
	From makers as m 
	Where Extract(Year From date) In (2023, 2024)
	Group by Extract(Year From date), vehicle_category
	), 
revenue as 
	(Select year,
		SUM(Case when vehicle_category = '2-Wheelers' then (ev_sales * 85000) Else 0 End) as two_wheelers_revenue,
		SUM(Case when vehicle_category = '4-Wheelers' then (ev_sales * 1500000) Else 0 End) as four_wheelers_revenue
	From CTE 
	Group by year
	)
Select 
	year,
	two_wheelers_revenue,
	Lag(two_wheelers_revenue) Over (order by year),
	ROUND(Case when Lag(two_wheelers_revenue) Over (order by year) IS NULL Then Null  
		Else ((two_wheelers_revenue - Lag(two_wheelers_revenue) Over (order by year))/
		Lag(two_wheelers_revenue) Over (order by year)) *100 END, 2) AS two_wheelers_revenue_growth,
	four_wheelers_revenue,
	ROUND(Case when Lag(four_wheelers_revenue) Over (order by year) IS NULL Then Null  
		Else ((four_wheelers_revenue - Lag(four_wheelers_revenue) Over (order by year))/
	Lag(four_wheelers_revenue) Over (order by year)) *100 END , 2) AS four_wheelers_revenue_growth
from revenue
) as second_query_2023_2024
