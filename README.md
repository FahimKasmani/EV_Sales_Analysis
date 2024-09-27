Here’s the updated README content with SQL queries included as requested:

---

# 📊 AtliQ Motors EV Market Analysis

---

### 🚗 Overview

AtliQ Motors, a USA-based automotive giant, is looking to expand its electric and hybrid vehicle market in India. With a market share of less than 2% in India, the company's chief for the India region, Bruce Haryali, assigned the data analytics team to conduct a detailed market study to evaluate the current state of the EV/Hybrid market.

Peter Pandey, a data analyst on the team, was tasked with this project. This analysis covers various aspects of the EV market for the fiscal years 2022 to 2024, including:

- Top and bottom makers for 2-wheeler sales
- Penetration rates in different states
- EV sales trends by quarter
- Revenue projections

---

## 🛠️ **Technologies Used**
- **SQL**: PostgreSQL database for running queries and performing analysis.
- **Git**: Used Git for version control

## 🔍 **Analysis Details**

### 1. 🏅 Top & Bottom Makers for 2-Wheelers Sold (FY 2023 & 2024)
**Objective**: Identify the top 3 and bottom 3 EV makers in terms of sales volume for 2-wheelers.

- **Query**:
```sql
-- Top 3 Makers
SELECT maker, SUM(electric_vehicles_sold) AS total_sales
FROM ev_sales_data
WHERE fiscal_year IN ('2023', '2024') AND vehicle_category = '2-wheeler'
GROUP BY maker
ORDER BY total_sales DESC
LIMIT 3;

-- Bottom 3 Makers
SELECT maker, SUM(electric_vehicles_sold) AS total_sales
FROM ev_sales_data
WHERE fiscal_year IN ('2023', '2024') AND vehicle_category = '2-wheeler'
GROUP BY maker
ORDER BY total_sales ASC
LIMIT 3;
```

---

### 2. 📈 Top 5 States with Highest Penetration Rate in FY 2024
**Objective**: Identify states with the highest EV penetration rates for 2-wheelers and 4-wheelers.

- **Query**:
```sql
SELECT state, vehicle_category, 
       (SUM(electric_vehicles_sold)::NUMERIC / SUM(total_vehicles_sold)) * 100 AS penetration_rate
FROM ev_sales_data
WHERE fiscal_year = '2024'
GROUP BY state, vehicle_category
ORDER BY penetration_rate DESC
LIMIT 5;
```

---

### 3. 📉 States with Negative Penetration from 2022 to 2024
**Objective**: Identify states with a decline in EV penetration over the years.

- **Query**:
```sql
WITH penetration_data AS (
    SELECT state, fiscal_year,
           (SUM(electric_vehicles_sold)::NUMERIC / SUM(total_vehicles_sold)) * 100 AS penetration_rate
    FROM ev_sales_data
    WHERE fiscal_year IN ('2022', '2023', '2024')
    GROUP BY state, fiscal_year
)
SELECT state, fiscal_year, penetration_rate
FROM penetration_data
WHERE fiscal_year = '2024' AND penetration_rate < (
    SELECT penetration_rate 
    FROM penetration_data pd2 
    WHERE pd2.state = penetration_data.state AND pd2.fiscal_year = '2022'
);
```

---

### 4. 📊 Quarterly Sales Trends for Top 5 EV Makers (4-Wheelers) (2022-2024)
**Objective**: Analyze quarterly sales trends for the top 5 EV makers based on sales volume for 4-wheelers.

- **Query**:
```sql
WITH top_5_makers AS (
    SELECT maker
    FROM ev_sales_data
    WHERE vehicle_category = '4-wheeler'
    GROUP BY maker
    ORDER BY SUM(electric_vehicles_sold) DESC
    LIMIT 5
)
SELECT maker, fiscal_year, quarter, SUM(electric_vehicles_sold) AS quarterly_sales
FROM ev_sales_data
WHERE maker IN (SELECT maker FROM top_5_makers) AND vehicle_category = '4-wheeler'
GROUP BY maker, fiscal_year, quarter
ORDER BY maker, fiscal_year, quarter;
```

---

### 5. 🆚 EV Sales & Penetration Rate Comparison Between Delhi and Karnataka (FY 2024)
**Objective**: Compare EV sales and penetration rates for Delhi and Karnataka.

- **Query**:
```sql
SELECT state, 
       SUM(electric_vehicles_sold) AS ev_sales, 
       (SUM(electric_vehicles_sold)::NUMERIC / SUM(total_vehicles_sold)) * 100 AS penetration_rate
FROM ev_sales_data
WHERE state IN ('Delhi', 'Karnataka') AND fiscal_year = '2024'
GROUP BY state;
```

---

### 6. 📉 Compound Annual Growth Rate (CAGR) for Top 5 4-Wheeler Makers (2022-2024)
**Objective**: Calculate CAGR for top 5 makers for 4-wheeler sales from 2022 to 2024.

- **Query**:
```sql
WITH sales_data AS (
    SELECT maker, 
           SUM(CASE WHEN fiscal_year = '2022' THEN electric_vehicles_sold ELSE 0 END) AS sales_2022,
           SUM(CASE WHEN fiscal_year = '2024' THEN electric_vehicles_sold ELSE 0 END) AS sales_2024
    FROM ev_sales_data
    WHERE vehicle_category = '4-wheeler'
    GROUP BY maker
    ORDER BY sales_2024 DESC
    LIMIT 5
)
SELECT maker,
       ((sales_2024::NUMERIC / sales_2022::NUMERIC) ^ (1 / 2.0) - 1) * 100 AS CAGR
FROM sales_data;
```

---

### 7. 📈 CAGR for Total Vehicles Sold in Top 10 States (2022-2024)
**Objective**: Find states with the highest growth in total vehicle sales.

- **Query**:
```sql
WITH total_sales AS (
    SELECT state, 
           SUM(CASE WHEN fiscal_year = '2022' THEN total_vehicles_sold ELSE 0 END) AS sales_2022,
           SUM(CASE WHEN fiscal_year = '2024' THEN total_vehicles_sold ELSE 0 END) AS sales_2024
    FROM ev_sales_data
    GROUP BY state
)
SELECT state,
       ((sales_2024::NUMERIC / sales_2022::NUMERIC) ^ (1 / 2.0) - 1) * 100 AS CAGR
FROM total_sales
ORDER BY CAGR DESC
LIMIT 10;
```

---

### 8. 📅 Peak & Low Season Months for EV Sales (2022-2024)
**Objective**: Identify the months with the highest and lowest sales for EVs.

- **Query**:
```sql
SELECT fiscal_year, month, SUM(electric_vehicles_sold) AS total_sales
FROM ev_sales_data
GROUP BY fiscal_year, month
ORDER BY total_sales DESC;
```

---

### 9. 📊 Projected EV Sales for Top 10 States by 2030
**Objective**: Predict future EV sales for the top 10 states by penetration rate in 2024.

- **Query**:
```sql
WITH sales_growth AS (
    SELECT state, 
           SUM(CASE WHEN fiscal_year = '2024' THEN electric_vehicles_sold ELSE 0 END) AS sales_2024,
           ((SUM(CASE WHEN fiscal_year = '2024' THEN electric_vehicles_sold ELSE 0 END)::NUMERIC / 
             SUM(CASE WHEN fiscal_year = '2022' THEN electric_vehicles_sold ELSE 0 END)) ^ (1 / 2.0) - 1) AS CAGR
    FROM ev_sales_data
    GROUP BY state
    ORDER BY sales_2024 DESC
    LIMIT 10
)
SELECT state, 
       sales_2024, 
       sales_2024 * (1 + CAGR) ^ (2030 - 2024) AS projected_sales_2030
FROM sales_growth;
```

---

### 10. 💰 Revenue Growth Rate for 4-Wheelers and 2-Wheelers in India (2022 vs 2024, 2023 vs 2024)
**Objective**: Calculate revenue growth for 2-wheelers and 4-wheelers based on vehicle category and average prices.

- **Query**:
```sql
WITH revenue_data AS (
    SELECT vehicle_category, fiscal_year,
           SUM(electric_vehicles_sold) * CASE 
               WHEN vehicle_category = '2-wheeler' THEN 85000 
               WHEN vehicle_category = '4-wheeler' THEN 1500000 
           END AS total_revenue
    FROM ev_sales_data
    WHERE fiscal_year IN ('2022', '2023', '2024')
    GROUP BY vehicle_category, fiscal_year
)
SELECT vehicle_category, fiscal_year, 
       (total_revenue / LAG(total_revenue, 1) OVER (PARTITION BY vehicle_category ORDER BY fiscal_year)) * 100 - 100 AS revenue_growth
FROM revenue_data;
```

---

## 🧑‍💼 **Key Learnings & Insights**
- Top manufacturers in the EV market continue to dominate in 2-wheeler and 4-wheeler categories.
- States with high EV penetration are leading the way in transitioning to electric mobility.
- Seasonal trends show higher EV sales in specific months, which can be targeted for marketing and promotions.
- Revenue growth projections show a promising future for EV sales in India, with a significant CAGR in both 2-wheeler and 4-wheeler segments.

---

