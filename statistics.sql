## Statistics 
-- 1- Descriptive Statistics

--  AVG, Min, Max, STDDEV
SELECT 
    CEIL(AVG(Number_of_Casualties)) AS avg_casualties,
    MIN(Number_of_Casualties) AS min_casualties,
    MAX(Number_of_Casualties) AS max_casualties,
    STDDEV(Number_of_Casualties) AS stddev_casualties,
    CEIL(AVG(Number_of_Vehicles)) AS avg_vehicles,
    MIN(Number_of_Vehicles) AS min_vehicles,
    MAX(Number_of_Vehicles) AS max_vehicles,
    STDDEV(Number_of_Vehicles) AS stddev_vehicles,
    AVG(Speed_limit) AS avg_speed,
    MIN(Speed_limit) AS min_speed,
    MAX(Speed_limit) AS max_speed,
    STDDEV(Speed_limit) AS stddev_speed
FROM Fact_Accident f
JOIN Dim_Conditions c ON f.Conditions_Key = c.Conditions_Key
JOIN Dim_Location l ON f.Location_Key = l.Location_Key;

-- Get the Day with Most and Least Accidents
SELECT * FROM (
    SELECT 'Most Accidents' AS category,
           Day_of_Week,
           COUNT(*) AS accidents_count,
           ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_accident), 2) AS percentage
    FROM fact_accident f
    JOIN Dim_Date d ON f.Date_Key = d.Date_Key
    GROUP BY Day_of_Week
    ORDER BY accidents_count DESC
    LIMIT 1
) AS most
UNION ALL
SELECT * FROM (
    SELECT 'Least Accidents' AS category,
           Day_of_Week,
           COUNT(*) AS accidents_count,
           ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_accident), 2) AS percentage
    FROM fact_accident f
    JOIN Dim_Date d ON f.Date_Key = d.Date_Key
    GROUP BY Day_of_Week
    ORDER BY accidents_count ASC
    LIMIT 1
) AS least;

## Inferential statistics 
-- Correlation
SELECT 
    (AVG(Number_of_Vehicles * Number_of_Casualties) - AVG(Number_of_Vehicles) * AVG(Number_of_Casualties)) /
    (STDDEV(Number_of_Vehicles) * STDDEV(Number_of_Casualties)) AS corr_vehicles_casualties
FROM fact_accident;
# result = '0.23553744524722253' weak positive correlation

SELECT 
    (AVG(Speed_limit * Number_of_Casualties) - AVG(Speed_limit) * AVG(Number_of_Casualties)) /
    (STDDEV(Speed_limit) * STDDEV(Number_of_Casualties)) AS corr_speed_casualties
FROM fact_accident f
JOIN Dim_Conditions c ON f.Conditions_Key = c.Conditions_Key;
# result = '0.13726387871771345' Weak and very positive correlation

