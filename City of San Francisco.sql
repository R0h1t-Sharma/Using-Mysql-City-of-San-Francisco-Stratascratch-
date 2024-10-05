create database CityofSanFrancisco;
use CityofSanFrancisco;

describe sf_public_salaries;
ALTER TABLE sf_public_salaries
CHANGE COLUMN `ï»¿"id"` `id` INT; -- Replace 'INT' with the actual data type of the column
-- 1 Make a pivot table to find the highest payment in each year for each employee.
-- Find payment details for 2011, 2012, 2013, and 2014.
--- Output payment details along with the corresponding employee name.
-- Order records by the employee name in ascending order.
WITH RankedPayments AS (
SELECT employeename, year, totalpay, ROW_NUMBER() OVER (PARTITION BY employeename, year ORDER BY totalpay DESC) AS rnk
FROM sf_public_salaries
WHERE year IN (2011, 2012, 2013, 2014))
SELECT employeename, year, totalpay AS highest_payment
FROM RankedPayments
WHERE rnk = 1
ORDER BY employeename, year;

describe sf_crime_incidents_2014_01;
ALTER TABLE sf_crime_incidents_2014_01
CHANGE COLUMN `ï»¿"incidnt_num"` `incident_number` INT; -- Replace 'INT' with the actual data type of the column

-- 2 Find the number of crime occurrences for each day of the week.
-- Output the day alongside the corresponding crime count.
SELECT day_of_week, COUNT(*) AS crime_count
FROM sf_crime_incidents_2014_01
GROUP BY day_of_week
ORDER BY day_of_week;

describe sf_restaurant_health_violations;
ALTER TABLE sf_restaurant_health_violations
CHANGE COLUMN `ï»¿"business_id"` `business_id` INT; -- Replace 'INT' with the actual data type of the column

-- 3 Find the number of words in each business name. Avoid counting special symbols as words (e.g. &).
--  Output the business name and its count of words.
SELECT business_name, 
       LENGTH(REGEXP_REPLACE(business_name, '[^A-Za-z0-9 ]', '')) - 
       LENGTH(REPLACE(REGEXP_REPLACE(business_name, '[^A-Za-z0-9 ]', ''), ' ', '')) + 1 AS word_count
FROM sf_restaurant_health_violations;

-- 4 Find the number of inspections that resulted in each risk category per each inspection type.
-- Consider the records with no risk category value belongs to a separate category.
-- Output the result along with the corresponding inspection type and the corresponding total number of inspections per that type. The output should be pivoted, meaning that each risk category + total number should be a separate column.
-- Order the result based on the number of inspections per inspection type in descending order.
SELECT 
    inspection_type,
    SUM(CASE WHEN risk_category IS NULL THEN 1 ELSE 0 END) AS no_risk_results,
    SUM(CASE WHEN risk_category = 'Low Risk' THEN 1 ELSE 0 END) AS low_risk_results,
    SUM(CASE WHEN risk_category = 'Moderate Risk' THEN 1 ELSE 0 END) AS medium_risk_results,
    SUM(CASE WHEN risk_category = 'High Risk' THEN 1 ELSE 0 END) AS high_risk_results,
    COUNT(*) AS total_inspections
FROM sf_restaurant_health_violations
GROUP BY inspection_type
ORDER BY total_inspections DESC;

describe  sf_employee;
ALTER TABLE sf_employee
CHANGE COLUMN `ï»¿"id"` `id` INT; -- Replace 'INT' with the actual data type of the column

describe sf_bonus;
ALTER TABLE sf_bonus
CHANGE COLUMN `ï»¿"worker_ref_id"` `worker_ref_id` INT; -- Replace 'INT' with the actual data type of the column

-- 5 Find the average total compensation based on employee titles and gender. 
--- Total compensation is calculated by adding both the salary and bonus of each employee.
---  However, not every employee receives a bonus so disregard employees without bonuses in your calculation.
--  Employee can receive more than one bonus.
-- Output the employee title, gender (i.e., sex), along with the average total compensation.
SELECT e.employee_title, e.sex, AVG(e.salary + b.ttl_bonus) AS avg_compensation
FROM sf_employee e
INNER JOIN (SELECT worker_ref_id, SUM(bonus) AS ttl_bonus
FROM sf_bonus
GROUP BY worker_ref_id)
b ON e.id = b.worker_ref_id
GROUP BY e.employee_title, e.sex
ORDER BY e.employee_title, e.sex;

-- 6 Find the top 2 highest paid City employees for each job title. Use totalpaybenefits column for their ranking.
--  Output the job title along with the corresponding highest and second-highest paid employees.
WITH RankedEmployees AS (
    SELECT jobtitle, employeename, totalpaybenefits, 
           ROW_NUMBER() OVER (PARTITION BY jobtitle ORDER BY totalpaybenefits DESC) AS rnk
    FROM sf_public_salaries
)
SELECT jobtitle, employeename, totalpaybenefits
FROM RankedEmployees
WHERE rnk <= 2
ORDER BY jobtitle, rnk;
-- 7 Get the job titles of the 3 employees who received the most overtime pay
-- Output the job title of selected records.
SELECT jobtitle 
FROM (
    SELECT jobtitle, RANK() OVER (ORDER BY overtimepay DESC) AS rnk
    FROM sf_public_salaries
    WHERE overtimepay IS NOT NULL AND overtimepay <> 0
) AS ranked_employees
WHERE rnk <= 3;

--- 8 Find the employee who earned most from working overtime. Output the employee name.
SELECT employeename
FROM (
    SELECT employeename, 
           RANK() OVER (ORDER BY overtimepay DESC) AS rnk
    FROM sf_public_salaries
) AS ranked_employees
WHERE rnk = 1;

-- 9 Find the top 5 least paid employees for each job title.
-- Output the employee name, job title and total pay with benefits for the first 5 least paid employees. Avoid gaps in ranking.
WITH RankedEmployees AS (
    SELECT employeename, jobtitle, totalpaybenefits,
           RANK() OVER (PARTITION BY jobtitle ORDER BY totalpaybenefits ASC) AS rnk
    FROM sf_public_salaries
)
SELECT employeename, jobtitle, totalpaybenefits
FROM RankedEmployees
WHERE rnk <= 5
ORDER BY jobtitle, rnk;

-- 10 Find all people who earned more than the average in 2013 for their designation but were not amongst the top 5 earners for their job title. 
--- Use the totalpay column to calculate total earned and output the employee name(s) as the result.
WITH AverageEarnings AS (
    SELECT jobtitle, AVG(totalpay) AS avg_pay
    FROM sf_public_salaries
    WHERE year = 2013
    GROUP BY jobtitle
)
SELECT e.employeename, e.jobtitle, e.totalpay, a.avg_pay
FROM sf_public_salaries e
JOIN AverageEarnings a ON e.jobtitle = a.jobtitle
WHERE e.year = 2013 AND e.totalpay > a.avg_pay
ORDER BY e.jobtitle, e.totalpay DESC;

-- 11 Find the ratio and the difference between the highest and lowest total pay for each job title.
--   Another condition is to remove rows total pay equal to zero from the calculation. 
-- Output the job title along with the corresponding difference, ratio, highest total pay, and the lowest total pay. 
-- Sort records based on the ratio in descending order.
SELECT jobtitle,
       MAX(totalpay) - MIN(totalpay) AS difference,
       MAX(totalpay) / NULLIF(MIN(totalpay), 0) AS ratio,
       MAX(totalpay) AS highest_total_pay,
       MIN(totalpay) AS lowest_total_pay
FROM sf_public_salaries
WHERE totalpay <> 0
GROUP BY jobtitle
ORDER BY ratio DESC;

-- 12 Find the median total pay for each job. Output the job title and the corresponding total pay,
--  and sort the results from highest total pay to lowest.
SELECT jobtitle,
AVG(totalpay) AS median_total_pay
FROM (SELECT jobtitle, totalpay,
           ROW_NUMBER() OVER (PARTITION BY jobtitle ORDER BY totalpay) AS rn,
           COUNT(*) OVER (PARTITION BY jobtitle) AS cnt
    FROM sf_public_salaries
    WHERE totalpay > 0
) AS ranked
WHERE rn IN (FLOOR((cnt + 1) / 2), CEIL((cnt + 1) / 2))
GROUP BY jobtitle
ORDER BY median_total_pay DESC;

-- 13 Find the ratio between the number of employees without benefits to total employees. 
-- Output the job title, number of employees without benefits, total employees relevant to that job title, 
-- and the corresponding ratio. Order records based on the ratio in ascending order.
SELECT jobtitle,
       SUM(CASE WHEN benefits = 0 THEN 1 ELSE 0 END) AS employees_without_benefits,
       COUNT(*) AS total_employees,
       IF(COUNT(*) = 0, 0, SUM(CASE WHEN benefits = 0 THEN 1 ELSE 0 END) / COUNT(*)) AS ratio
FROM sf_public_salaries
GROUP BY jobtitle
HAVING total_employees > 0
ORDER BY ratio ASC;

-- 14 Find the employee who earned the lowest total payment with benefits from a list of employees who earned more from other payments compared to their base pay. 
-- Output the first name of the employee along with the corresponding total payment with benefits.
SELECT SUBSTRING_INDEX(employeename, ' ', 1) AS first_name,
       totalpaybenefits
FROM sf_public_salaries
WHERE (overtimepay + otherpay) > basepay
ORDER BY totalpaybenefits ASC
LIMIT 1;

-- 15 Find the top 5 highest paid and top 5 least paid employees in 2012.
-- Output the employee name along with the corresponding total pay with benefits.
-- Sort records based on the total payment with benefits in ascending order.
WITH RankedSalaries AS (
    SELECT employeename, totalpaybenefits,
           ROW_NUMBER() OVER (ORDER BY totalpaybenefits ASC) AS rank_asc,
           ROW_NUMBER() OVER (ORDER BY totalpaybenefits DESC) AS rank_desc
    FROM sf_public_salaries
    WHERE year = 2012
)

SELECT employeename, totalpaybenefits
FROM RankedSalaries
WHERE rank_asc <= 5 OR rank_desc <= 5
ORDER BY totalpaybenefits ASC;

--- 16 Find employees who earned the highest and the lowest total pay without any benefits.
-- Output the employee name along with the total pay.
-- Order records based on the total pay in descending order.
WITH RankedSalaries AS (
    SELECT employeename, totalpay,
           ROW_NUMBER() OVER (ORDER BY totalpay DESC) AS rank_desc,
           ROW_NUMBER() OVER (ORDER BY totalpay ASC) AS rank_asc
    FROM sf_public_salaries
)

SELECT employeename, totalpay
FROM RankedSalaries
WHERE rank_desc = 1 OR rank_asc = 1
ORDER BY totalpay DESC;

-- 17 Find the number of police officers (job title contains substring police), firefighters (job title contains substring fire), 
-- and medical staff employees (job title contains substring medical) based on the employee name.
-- Output each job title along with the corresponding number of employees.
SELECT 
    SUM(CASE WHEN jobtitle LIKE '%police%' THEN 1 ELSE 0 END) AS police_officers,
    SUM(CASE WHEN jobtitle LIKE '%fire%' THEN 1 ELSE 0 END) AS firefighters,
    SUM(CASE WHEN jobtitle LIKE '%medical%' THEN 1 ELSE 0 END) AS medical_staff
FROM sf_public_salaries;

-- 18 Find all employees with a job title that contains 'METROPOLITAN TRANSIT AUTHORITY' and output the employee's name 
-- along with the corresponding total pay with benefits.
SELECT DISTINCT jobtitle
FROM sf_public_salaries
WHERE jobtitle LIKE '%TRANSIT%' OR jobtitle LIKE '%AUTHORITY%';
--- 19 Find benefits that people with the name 'Patrick' have.
-- Output the full employee name along with the corresponding benefits.
SELECT employeename, benefits
FROM sf_public_salaries
WHERE employeename LIKE '%Patrick%';

-- 20 Find the base pay for Police Captains. Output the employee name along with the corresponding base pay.

SELECT DISTINCT jobtitle
FROM sf_public_salaries
ORDER BY jobtitle;
SELECT DISTINCT jobtitle
FROM sf_public_salaries
WHERE jobtitle LIKE '%Officer%' OR jobtitle LIKE '%Chief%' OR jobtitle LIKE '%Firefighter%';

describe library_usage;
ALTER TABLE library_usage 
CHANGE COLUMN `ï»¿"patron_type_code"` patron_type_code INT;

--- 21 Find libraries with the highest number of total renewals.
-- Output all home library definitions along with the corresponding total renewals.
-- Order records by total renewals in descending order.
SELECT home_library_definition, SUM(total_renewals) AS total_renewals
FROM library_usage
GROUP BY home_library_definition
ORDER BY total_renewals DESC;

--- 22 Find the average total checkouts from Chinatown libraries in 2016.
SELECT
    AVG(total_checkouts) AS avg_total_checkouts
FROM library_usage
WHERE home_library_definition = 'Chinatown' AND 
circulation_active_year = 2016;
-- 23 Find months with the highest number of checkouts for main libraries in 2013.
-- Output the circulation active month along with the corresponding total monthly checkouts.
-- Order results based on total monthly checkouts in descending order.
SELECT 
    circulation_active_month,
    sum(total_checkouts) AS monthly_checkouts
FROM library_usage
WHERE home_library_definition = 'Main Library' AND 
circulation_active_year = 2013
GROUP BY circulation_active_month
ORDER BY monthly_checkouts DESC;

-- 24 Find library types with the highest total checkouts in April made by patrons who had registered in 2015 and 
-- whose age was between 65 and 74 years.Output the year patron registered and the home library definition along with the 
-- corresponding highest total checkouts. Sort records based on the highest total checkouts in descending order.
SELECT year_patron_registered,
home_library_definition,
MAX(total_checkouts) AS max_total_checkouts
FROM library_usage
WHERE age_range = '65 to 74 years' AND 
year_patron_registered = 2015 AND
circulation_active_month = 'April'
GROUP BY home_library_definition,year_patron_registered
ORDER BY max_total_checkouts DESC;

-- 25 Find library types with the highest total checkouts made by adults registered in 2010.
-- Output the year patron registered, home library definition along with the corresponding highest total checkouts.
WITH cte AS
  (SELECT year_patron_registered,
          home_library_definition,
          max(total_checkouts) AS total_checkouts_number
   FROM library_usage
   WHERE patron_type_definition = 'ADULT'
     AND year_patron_registered = 2010
   GROUP BY home_library_definition,
            year_patron_registered
   ORDER BY total_checkouts_number DESC)
SELECT *
FROM cte
WHERE total_checkouts_number =
    (SELECT max(total_checkouts_number)
     FROM cte);
	-- 26 Find how many people registered in libraries in the year 2016.
--- Output the total patrons. Keep in mind that each row represents different patron.
SELECT 
    count(*) AS total_patrons
FROM 
    library_usage
WHERE 
    year_patron_registered = 2016;
    
    -- 27 Find libraries who haven't provided the email address in circulation year 2016 but their notice preference definition is set to email.
-- Output the library code.
SELECT DISTINCT
    home_library_code
FROM
    library_usage
WHERE 
    notice_preference_definition = 'email' AND 
    provided_email_address = FALSE AND 
    circulation_active_year = 2016;
    -- 28 Find the number of libraries that had 100 or more of total checkouts in February 2015.
    -- Be aware that there could be more than one row for certain library on monthly basis.
    SELECT COUNT(DISTINCT home_library_code)
FROM
  (SELECT home_library_code,
          SUM(total_checkouts)
   FROM library_usage
   WHERE circulation_active_month = 'February'
     AND circulation_active_year = 2015
   GROUP BY home_library_code
   HAVING SUM(total_checkouts) >= 100) sub;
   -- 29 Find library types with the highest total checkouts made by adults registered in 2010.
-- Output the year patron registered, home library definition along with the corresponding highest total checkouts.
WITH cte AS
  (SELECT year_patron_registered,
          home_library_definition,
          max(total_checkouts) AS total_checkouts_number
   FROM library_usage
   WHERE patron_type_definition = 'ADULT'
     AND year_patron_registered = 2010
   GROUP BY home_library_definition,
            year_patron_registered
   ORDER BY total_checkouts_number DESC)
SELECT *
FROM cte
WHERE total_checkouts_number =
    (SELECT max(total_checkouts_number)
     FROM cte);
     
     -- 30 Find the number of patrons that have made the highest checkouts up to 10 (excluding 10).
-- Output the number of patrons along with the corresponding total checkouts. Sort records based on the total checkouts in descending order.
SELECT 
    count(*) AS n_patrons,
    total_checkouts
FROM library_usage
WHERE total_checkouts < 10
GROUP BY total_checkouts
ORDER BY total_checkouts DESC;
-- 31 Find the most dangerous places in SF based on the crime count per address and district combination.
-- Output the number of incidents alongside the corresponding address and the district.
-- Order records based on the number of occurrences in descending order.
SELECT address,pd_district,
count(category) AS n_occurences
FROM sf_crime_incidents_2014_01
GROUP BY address, pd_district
ORDER BY n_occurences DESC;

-- 32 Find districts alongside their incidents.
-- Output the district name alongside the number of incident occurrences.
-- Order records based on the number of occurrences in descending order.
SELECT
    pd_district,
    count(category) AS n_occurences
FROM sf_crime_incidents_2014_01
GROUP BY 
    pd_district
ORDER BY 
    n_occurences DESC;
    
    -- 33 Find top crime categories in 2014 based on the number of occurrences.
-- Output the number of crime occurrences alongside the corresponding category name.
-- Order records based on the number of occurrences in descending order.
SELECT
    category,
    count(category) AS n_occurences
FROM sf_crime_incidents_2014_01
WHERE 
    date >= '2014-01-01' AND 
    date <= '2014-12-31'
GROUP BY 
    category
ORDER BY 
    n_occurences DESC;
    -- 34 Find the median inspection score of each business and output the result along with the business name. 
    -- Order records based on the inspection score in descending order.
-- Try to come up with your own precise median calculation. In Postgres there is percentile_disc function available, however it's only approximation.
WITH ranked_scores AS (
    SELECT 
        business_id,
        business_name,
        inspection_score,
        ROW_NUMBER() OVER (PARTITION BY business_id ORDER BY inspection_score) AS rn,
        COUNT(*) OVER (PARTITION BY business_id) AS cnt
    FROM 
        sf_restaurant_health_violations
)

SELECT business_name,
AVG(inspection_score) AS median_inspection_score
FROM ranked_scores
WHERE rn IN ((cnt + 1) / 2, (cnt + 2) / 2)  -- Handle both odd and even counts
GROUP BY business_name
ORDER BY median_inspection_score DESC;

-- 35 Determine the change in the number of daily violations by calculating the difference between the count of current and 
-- previous violations by inspection date.
-- Output the inspection date and the change in the number of daily violations. Order your results by the earliest inspection date first.
SELECT DATE(inspection_date),
       COUNT(violation_id) - LAG(COUNT(violation_id)) OVER(
                                     ORDER BY DATE(inspection_date)) diff
FROM sf_restaurant_health_violations
GROUP BY 1
ORDER BY 1;

-- 36 For every year, find the worst business in the dataset. The worst business has the most violations during the year. 
-- You should output the year, business name, and number of violations.
WITH annual_violations AS (
SELECT YEAR(inspection_date) AS year,business_name,COUNT(*) AS violation_count
FROM sf_restaurant_health_violations
GROUP BY year, business_name)
SELECT year,business_name,violation_count
FROM (SELECT year, business_name, violation_count,
RANK() OVER (PARTITION BY year ORDER BY violation_count DESC) AS rnk
FROM annual_violations) AS ranked
WHERE rnk = 1
ORDER BY year;


-- 37 Verify that the first 4 digits are equal to 1415 for all phone numbers. 
-- Output the number of businesses with a phone number that does not start with 1415. 
-- It's expected such number should be 0
SELECT 
    COUNT(*) AS non_matching_count
FROM sf_restaurant_health_violations
WHERE CAST(business_phone_number AS CHAR) NOT LIKE '1415%';
-- 38 Find details of the business with the highest number of high-risk violations. 
-- Output all columns from the dataset considering business_id which consist 'high risk' phrase in risk_category column.
WITH high_risk_violations AS (
SELECT business_id,COUNT(*) AS violation_count
FROM sf_restaurant_health_violations
WHERE risk_category LIKE '%high risk%'
GROUP BY business_id)
SELECT sv.*
FROM sf_restaurant_health_violations sv
JOIN high_risk_violations hr ON sv.business_id = hr.business_id
WHERE hr.violation_count = (
SELECT MAX(violation_count) 
FROM high_risk_violations);
-- 39 Find the number of inspections that happened in the municipality with postal code 94102 during January, May or November in each year.
-- Output the count of each month separately.
SELECT YEAR(inspection_date) AS year,
MONTH(inspection_date) AS month,
COUNT(*) AS inspection_count
FROM sf_restaurant_health_violations
WHERE business_postal_code = 94102
AND MONTH(inspection_date) IN (1, 5, 11)
GROUP BY YEAR(inspection_date), MONTH(inspection_date)
ORDER BY year, month;

-- 40 Find the number of complaints that ended in a violation.
SELECT 
COUNT(DISTINCT inspection_id) AS violation_complaints_count
FROM 
sf_restaurant_health_violations
WHERE 
violation_id IS NOT NULL;

-- 41 Find the first and last inspections for vermin infestations per municipality.
-- Output the result along with the business postal code.
WITH vermin_inspections AS (
    SELECT 
        business_postal_code,
        inspection_date,
        ROW_NUMBER() OVER (PARTITION BY business_postal_code ORDER BY inspection_date) AS first_inspection,
        ROW_NUMBER() OVER (PARTITION BY business_postal_code ORDER BY inspection_date DESC) AS last_inspection
    FROM 
        sf_restaurant_health_violations
    WHERE 
        violation_description LIKE '%vermin%'
)

SELECT 
    business_postal_code,
    MIN(CASE WHEN first_inspection = 1 THEN inspection_date END) AS first_inspection_date,
    MIN(CASE WHEN last_inspection = 1 THEN inspection_date END) AS last_inspection_date
FROM 
    vermin_inspections
GROUP BY 
    business_postal_code;
    -- 42 Find all businesses whose lowest and highest inspection scores are different.
-- Output the corresponding business name and the lowest and highest scores of each business. HINT: you can assume there are no different businesses that share the same business name
-- Order the result based on the business name in ascending order.
WITH score_summary AS (
SELECT business_name,
MIN(inspection_score) AS lowest_score,
MAX(inspection_score) AS highest_score
FROM sf_restaurant_health_violations
GROUP BY business_name)
SELECT business_name,lowest_score,highest_score
FROM score_summary
WHERE lowest_score <> highest_score
ORDER BY business_name ASC;

-- 43 Count the number of inspections per each risk category.
-- Categorize records with null values under the 'No Risk' category.
-- Sort the result based on the number of inspections in descending order.
SELECT 
COALESCE(risk_category, 'No Risk') AS risk_category,
COUNT(*) AS inspection_count
FROM 
sf_restaurant_health_violations
GROUP BY 
COALESCE(risk_category, 'No Risk')
ORDER BY 
inspection_count DESC;

-- 44 You're given a dataset of health inspections. Count the number of violation in an inspection in 'Roxanne Cafe' for each year. If an inspection resulted in a violation, 
-- there will be a value in the 'violation_id' column. Output the number of violations by year in ascending order.
SELECT YEAR(inspection_date) AS year,
COUNT(violation_id) AS violation_count
FROM sf_restaurant_health_violations
WHERE business_name = 'Roxanne Cafe'
AND violation_id IS NOT NULL
GROUP BY YEAR(inspection_date)
ORDER BY year ASC;

-- 45 Find the number of violations that each school had. Any inspection is considered a violation if its risk category is not null.
-- Output the corresponding business name along with the result.
-- Order the result based on the number of violations in descending order.
SELECT 
    business_name,
    sum(CASE WHEN risk_category IS NOT NULL THEN 1 ELSE 0 END) AS number_of_violations
FROM sf_restaurant_health_violations
WHERE business_name LIKE '%school%' AND risk_category IS NOT NULL
GROUP BY business_name
ORDER BY number_of_violations desc;
-- 46 Classify each business as either a restaurant, cafe, school, or other.
-- •	A restaurant should have the word 'restaurant' in the business name.
-- •	A cafe should have either 'cafe', 'café', or 'coffee' in the business name.
-- •	A school should have the word 'school' in the business name.
-- •	All other businesses should be classified as 'other'.
-- Output the business name and their classification.
SELECT DISTINCT business_name,
       CASE
           WHEN business_name LIKE '%school%' THEN 'school'
           WHEN lower(business_name) LIKE '%restaurant%' THEN 'restaurant'
           WHEN lower(business_name) LIKE '%cafe%' OR lower(business_name) LIKE '%coffee%' THEN 'cafe'
           ELSE 'other'
       END AS business_type
FROM sf_restaurant_health_violations;

-- 47 Find the postal code which has the highest average inspection score.
-- Output the corresponding postal code along with the result.
WITH avg_score_table AS
  (SELECT business_postal_code,
          AVG(inspection_score) AS avg_score
   FROM sf_restaurant_health_violations
   WHERE inspection_score IS NOT NULL
   GROUP BY business_postal_code
   ORDER BY avg_score DESC)

SELECT business_postal_code,
       avg_score
FROM avg_score_table
WHERE avg_score =
    (SELECT MAX(avg_score)
     FROM avg_score_table);
     -- 48 Find all inspections made on restaurants and output the business name and the inspection score. 
     -- For this question business is considered as a restaurant if it contains string "restaurant" inside its name.
     SELECT 
    business_name,
    inspection_score
FROM sf_restaurant_health_violations
WHERE business_name LIKE '%Restaurant%';
-- 49 Find the business names that scored less than 50 in inspections.
-- Output the result along with the corresponding inspection date and the score.

    SELECT COUNT(*)
FROM sf_restaurant_health_violations;
SELECT MIN(inspection_score) AS min_score, MAX(inspection_score) AS max_score
FROM sf_restaurant_health_violations;

SELECT DISTINCT business_name, inspection_score
FROM sf_restaurant_health_violations
WHERE inspection_score >= 61;

-- 50 Find all businesses which have a phone number.
SELECT DISTINCT business_name
FROM sf_restaurant_health_violations
WHERE business_phone_number IS NOT NULL;

-- 51 Find all business postal codes of restaurants with issues related to the water (violation description contains substring "water").
SELECT 
    distinct business_postal_code
FROM sf_restaurant_health_violations
WHERE 
    violation_description LIKE '%water%';
    -- 52 Find all businesses which have low-risk safety violations.
    SELECT 
    DISTINCT business_name
FROM sf_restaurant_health_violations
WHERE 
    risk_category = 'Low Risk';




































