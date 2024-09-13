use HR
go

select * from [HR Data]

-- Update format fate of termdate
update [HR Data]
set termdate = FORMAT(CONVERT(datetime, left(termdate, 19), 120), 'yyyy-mm-dd')

alter table [HR Data]
add new_termdate date;

UPDATE [HR Data]
SET new_termdate = CASE
    WHEN termdate IS NOT NULL AND ISDATE(termdate) = 1
        THEN CAST(termdate AS DATETIME)
        ELSE NULL
    END;

-- Add column age
alter table [HR Data]
add age int;

update [HR Data]
set age = DATEDIFF(YEAR, birthdate, GETDATE());

--  Query

-- 1) What's the age distribution in the company?
select min(age) as Youngest, max(age) as Oldest, avg(age) as 'Average age'
from [HR Data]

-- 2) Age group 
select age_group, count(*) as Count
from
(select
case 
WHEN age >=21 AND age <=30 THEN '21 to 30'
WHEN age >=31 AND age <=40 THEN '31 to 40'
WHEN age >=41 AND age <=50 THEN '41 to 50'
when age >= 51 then 'Over 50'
end as age_group
from [HR Data]
where new_termdate is null or new_termdate > convert(date, GETDATE())
) as sub_query
group by age_group
order by age_group

-- 3) Age group distribution by gender 
select age_group, gender, count(*) as Count
from
(select
case 
WHEN age >=21 AND age <=30 THEN '21 to 30'
WHEN age >=31 AND age <=40 THEN '31 to 40'
WHEN age >=41 AND age <=50 THEN '41 to 50'
when age >= 51 then 'Over 50'
end as age_group, gender
from [HR Data]
where new_termdate is null or new_termdate > CONVERT(date, GETDATE())
) as sub_query
group by age_group, gender
order by age_group, gender

-- 3) What's the gender breakdown in the company?
select gender, count(*) as Count
from [HR Data]
where new_termdate is null or new_termdate > CONVERT(date, GETDATE())
group by gender
order by gender

-- 4) Genders vary across departments ?
select department, gender, count(*) as Count
from [HR Data]
where new_termdate is null or new_termdate > CONVERT(date, GETDATE())
group by department, gender
order by department

-- 5) How does gender vary across departments and job titles?
select department, jobtitle, gender, count(*) as Count
from [HR Data]
where new_termdate is null or new_termdate > CONVERT(date, GETDATE())
group by department, jobtitle, gender
order by department, jobtitle, gender

-- 6) What's the race distribution in the company?
select race, count(*) as Count
from [HR Data]
where new_termdate is null or new_termdate > CONVERT(date, GETDATE())
group by race

-- 7) What's the average length of employment in the company?
SELECT
 AVG(DATEDIFF(year, hire_date, new_termdate)) AS tenure
 FROM [HR Data]
 WHERE new_termdate IS NOT NULL AND new_termdate <= GETDATE();

-- 8) Which department has the highest turnover rate?
select department, Total, terminated_count, cast(terminated_count as float)/Total as turnover_rate
from (
select department, count(*) as Total, sum(case when new_termdate is not null and new_termdate <= getdate() then 1 else 0 end) as terminated_count
from [HR Data]
group by department
) as sub_query
order by turnover_rate

-- 9) What is the tenure distribution for each department?
SELECT department,
 AVG(DATEDIFF(year, hire_date, new_termdate)) AS tenure
 FROM [HR Data]
 WHERE new_termdate IS NOT NULL AND new_termdate <= GETDATE()
 group by department;

 -- 10) How many employees work remotely or in headquarters for each department?
 select location, count (*) as Count
 from [HR Data]
 where new_termdate is null or new_termdate > GETDATE()
 group by location

 -- 11) What's the distribution of employees across different states?
select location_state, count(*) as No_Of_Emps
from [HR Data]
where new_termdate is null or new_termdate > GETDATE()
group by location_state

-- 12) How are job titles distributed in the company?
select jobtitle, count(*) as No_Of_Emps
from [HR Data]
where new_termdate is null or new_termdate > GETDATE()
group by jobtitle 
order by count(*) asc

-- 13) How have employee hire counts varied over time?
SELECT
    hire_yr,
    hires,
    terminations,
    hires - terminations AS net_change,
    (round(CAST(hires - terminations AS FLOAT) / NULLIF(hires, 0), 2)) *100 AS percent_hire_change
FROM  
    (SELECT
        YEAR(hire_date) AS hire_yr,
        COUNT(*) AS hires,
        SUM(CASE WHEN new_termdate IS NOT NULL AND new_termdate <= GETDATE() THEN 1 ELSE 0 END) terminations
    FROM [HR Data]
    GROUP BY YEAR(hire_date)
    ) AS subquery
ORDER BY hire_yr ASC;
