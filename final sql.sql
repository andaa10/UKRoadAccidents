CREATE TABLE accidents (
    Accident_Index VARCHAR(20),
    Accident_Date VARCHAR(20),     
    Day_of_Week VARCHAR(20),
    Junction_Control VARCHAR(50),
    Junction_Detail VARCHAR(50),
    Accident_Severity VARCHAR(20),
    Latitude DECIMAL(9,6),
    Light_Conditions VARCHAR(50),
    Local_Authority_District VARCHAR(50),
    Carriageway_Hazards VARCHAR(50),
    Longitude DECIMAL(9,6),
    Number_of_Casualties INT,
    Number_of_Vehicles INT,
    Police_Force VARCHAR(50),
    Road_Surface_Conditions VARCHAR(50),
    Road_Type VARCHAR(50),
    Speed_limit INT,
    Time VARCHAR(20),
    Urban_or_Rural_Area VARCHAR(20),
    Weather_Conditions VARCHAR(50),
    Vehicle_Type VARCHAR(50)
);

-- رفع البيانات من ملف CSV
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Road Accident Data.csv'
INTO TABLE accidents
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(Accident_Index, Accident_Date, Day_of_Week, Junction_Control, Junction_Detail,
 Accident_Severity, Latitude, Light_Conditions, Local_Authority_District,
 Carriageway_Hazards, Longitude, Number_of_Casualties, Number_of_Vehicles,
 Police_Force, Road_Surface_Conditions, Road_Type, Speed_limit, Time,
 Urban_or_Rural_Area, Weather_Conditions, Vehicle_Type);

select count(*) from accidents;

DESCRIBE accidents;

SELECT *
FROM accidents;

#CHANGE DATE COLUMN DATA TYPE
ALTER TABLE accidents
ADD COLUMN Accident_Date_New DATE;

UPDATE accidents
SET Accident_Date_New = 
    CASE 
        WHEN Accident_Date LIKE '%/%/%' THEN STR_TO_DATE(Accident_Date, '%m/%d/%Y')
        ELSE CAST(Accident_Date AS DATE)
    END
WHERE Accident_Date IS NOT NULL AND TRIM(Accident_Date) <> '';

ALTER TABLE accidents
DROP COLUMN Accident_Date;

#change time column data type
ALTER TABLE accidents
ADD Time_New TIME;

UPDATE accidents
SET Time_New = STR_TO_DATE(Time, '%H:%i');

ALTER TABLE accidents
DROP COLUMN Time;

#show duplicates
SELECT 
    Accident_Index,
    COUNT(*) AS duplicate_count
FROM accidents
GROUP BY Accident_Index
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

#drop junction control column
ALTER TABLE accidents
DROP COLUMN Junction_Control;

#rename fetal to fatal
UPDATE accidents
SET Accident_Severity = 'fatal'
WHERE Accident_Severity = 'fetal';

#show missing
SELECT
    -- Missing values for text/date/time columns
    COUNT(CASE WHEN NULLIF(Accident_Index, '') IS NULL THEN 1 END) AS missing_Accident_Index,
    COUNT(CASE WHEN Accident_Date_New IS NULL THEN 1 END) AS missing_Accident_Date,
    COUNT(CASE WHEN NULLIF(Day_of_Week, '') IS NULL THEN 1 END) AS missing_Day_of_Week,
    COUNT(CASE WHEN NULLIF(Junction_Detail, '') IS NULL THEN 1 END) AS missing_Junction_Detail,
    COUNT(CASE WHEN NULLIF(Light_Conditions, '') IS NULL THEN 1 END) AS missing_Light_Conditions,
    COUNT(CASE WHEN NULLIF(Local_Authority_District, '') IS NULL THEN 1 END) AS missing_Local_Authority_District,
    COUNT(CASE WHEN NULLIF(Carriageway_Hazards, '') IS NULL THEN 1 END) AS missing_Carriageway_Hazards,
    COUNT(CASE WHEN NULLIF(Police_Force, '') IS NULL THEN 1 END) AS missing_Police_Force,
    COUNT(CASE WHEN NULLIF(Road_Surface_Conditions, '') IS NULL THEN 1 END) AS missing_Road_Surface_Conditions,
    COUNT(CASE WHEN NULLIF(Road_Type, '') IS NULL THEN 1 END) AS missing_Road_Type,
    COUNT(CASE WHEN Time_New IS NULL THEN 1 END) AS missing_Time,
    COUNT(CASE WHEN NULLIF(Urban_or_Rural_Area, '') IS NULL THEN 1 END) AS missing_Urban_or_Rural_Area,
    COUNT(CASE WHEN NULLIF(Weather_Conditions, '') IS NULL THEN 1 END) AS missing_Weather_Conditions,
    COUNT(CASE WHEN NULLIF(Vehicle_Type, '') IS NULL THEN 1 END) AS missing_Vehicle_Type,
    -- Missing values for numeric/coordinate columns
    COUNT(CASE WHEN Accident_Severity IS NULL OR Accident_Severity < 0 THEN 1 END) AS missing_Accident_Severity,
    COUNT(CASE WHEN Latitude IS NULL OR Latitude = 0 THEN 1 END) AS missing_Latitude,
    COUNT(CASE WHEN Longitude IS NULL OR Longitude = 0 THEN 1 END) AS missing_Longitude,
    COUNT(CASE WHEN Number_of_Casualties IS NULL OR Number_of_Casualties < 0 THEN 1 END) AS missing_Number_of_Casualties,
    COUNT(CASE WHEN Number_of_Vehicles IS NULL OR Number_of_Vehicles < 0 THEN 1 END) AS missing_Number_of_Vehicles,
    COUNT(CASE WHEN Speed_limit IS NULL OR Speed_limit < 0 THEN 1 END) AS missing_Speed_limit
FROM
    accidents;

#delete null 
DELETE FROM accidents
WHERE Carriageway_Hazards IS NULL OR Carriageway_Hazards = '';
DELETE FROM accidents
WHERE Time_New IS NULL OR Time_New = '';
DELETE FROM accidents
WHERE  Road_Surface_Conditions IS NULL OR  Road_Surface_Conditions = '';
DELETE FROM accidents
WHERE    Road_Type IS NULL OR   Road_Type  = '';
DELETE FROM accidents
WHERE    Weather_Conditions  IS NULL OR  Weather_Conditions   = '';

#modelling

CREATE TABLE Dim_Date (
    Date_Key INT AUTO_INCREMENT PRIMARY KEY,
    Accident_Date DATE,
    Day_of_Week VARCHAR(20),
    Time_New TIME,
    Month INT,
    Year INT,
    Hour INT
);

CREATE TABLE Dim_Location (
    Location_Key INT AUTO_INCREMENT PRIMARY KEY,
    Latitude DECIMAL(10, 6),
    Longitude DECIMAL(10, 6),
    Local_Authority_District VARCHAR(100),
    Urban_or_Rural_Area VARCHAR(50)
);

CREATE TABLE Dim_Conditions (
    Conditions_Key INT AUTO_INCREMENT PRIMARY KEY,
    Junction_Detail VARCHAR(100),
    Light_Conditions VARCHAR(100),
    Carriageway_Hazards VARCHAR(100),
    Road_Type VARCHAR(100),
    Road_Surface_Conditions VARCHAR(100),
    Speed_limit INT,
    Weather_Conditions VARCHAR(100)
);

CREATE TABLE Dim_Vehicle (
    Vehicle_Key INT AUTO_INCREMENT PRIMARY KEY,
    Vehicle_Type VARCHAR(100)
);

CREATE TABLE Fact_Accident (
    Accident_Index VARCHAR(50) PRIMARY KEY,
    Accident_Severity VARCHAR(50),
    Number_of_Casualties INT,
    Number_of_Vehicles INT,
    Police_Force VARCHAR(100),
    Date_Key INT,
    Location_Key INT,
    Conditions_Key INT,
    Vehicle_Key INT,
    FOREIGN KEY (Date_Key) REFERENCES Dim_Date(Date_Key),
    FOREIGN KEY (Location_Key) REFERENCES Dim_Location(Location_Key),
    FOREIGN KEY (Conditions_Key) REFERENCES Dim_Conditions(Conditions_Key),
    FOREIGN KEY (Vehicle_Key) REFERENCES Dim_Vehicle(Vehicle_Key)
);


INSERT INTO Dim_Date (Accident_Date, Day_of_Week, Time_New, Month, Year, Hour)
SELECT DISTINCT 
    Accident_Date_New,
    Day_of_Week,
    Time_New,
    MONTH(Accident_Date_New),
    YEAR(Accident_Date_New),
    HOUR(Time_New)
FROM accidents;

INSERT INTO Dim_Location (Latitude, Longitude, Local_Authority_District, Urban_or_Rural_Area)
SELECT DISTINCT 
    Latitude, Longitude, Local_Authority_District, Urban_or_Rural_Area
FROM accidents;

INSERT INTO Dim_Conditions (Junction_Detail, Light_Conditions, Carriageway_Hazards, Road_Type, Road_Surface_Conditions, Speed_limit, Weather_Conditions)
SELECT DISTINCT 
    Junction_Detail, Light_Conditions, Carriageway_Hazards, Road_Type, Road_Surface_Conditions, Speed_limit, Weather_Conditions
FROM accidents;

INSERT INTO Dim_Vehicle (Vehicle_Type)
SELECT DISTINCT Vehicle_Type
FROM accidents;

CREATE TEMPORARY TABLE Bad_Accidents AS
SELECT Accident_Index
FROM accidents
GROUP BY Accident_Index
HAVING COUNT(DISTINCT CONCAT_WS('|',
    Accident_Severity,
    Number_of_Casualties,
    Number_of_Vehicles,
    Police_Force,
    Accident_Date_New,
    Day_of_Week,
    Time_New,
    Latitude,
    Longitude,
    Local_Authority_District,
    Urban_or_Rural_Area,
    Junction_Detail,
    Light_Conditions,
    Carriageway_Hazards,
    Road_Type,
    Road_Surface_Conditions,
    Speed_limit,
    Weather_Conditions,
    Vehicle_Type
)) > 1;

INSERT INTO Fact_Accident (
    Accident_Index, 
    Accident_Severity, 
    Number_of_Casualties, 
    Number_of_Vehicles, 
    Police_Force, 
    Date_Key, 
    Location_Key, 
    Conditions_Key, 
    Vehicle_Key
)
SELECT DISTINCT
    a.Accident_Index,
    a.Accident_Severity,
    a.Number_of_Casualties,
    a.Number_of_Vehicles,
    a.Police_Force,
    d.Date_Key,
    l.Location_Key,
    c.Conditions_Key,
    v.Vehicle_Key
FROM accidents a
JOIN Dim_Date d 
    ON d.Accident_Date = a.Accident_Date_New 
   AND d.Day_of_Week = a.Day_of_Week 
   AND d.Time_New = a.Time_New
JOIN Dim_Location l 
    ON l.Latitude = a.Latitude 
   AND l.Longitude = a.Longitude 
   AND l.Local_Authority_District = a.Local_Authority_District 
   AND l.Urban_or_Rural_Area = a.Urban_or_Rural_Area
JOIN Dim_Conditions c 
    ON c.Junction_Detail = a.Junction_Detail 
   AND c.Light_Conditions = a.Light_Conditions 
   AND c.Carriageway_Hazards = a.Carriageway_Hazards 
   AND c.Road_Type = a.Road_Type 
   AND c.Road_Surface_Conditions = a.Road_Surface_Conditions 
   AND c.Speed_limit = a.Speed_limit 
   AND c.Weather_Conditions = a.Weather_Conditions
JOIN Dim_Vehicle v 
    ON v.Vehicle_Type = a.Vehicle_Type
LEFT JOIN Bad_Accidents b
    ON b.Accident_Index = a.Accident_Index
WHERE b.Accident_Index IS NULL;

select * from fact_accident;

#EXPLORATION QUERIES
#exploration schema 2

SHOW COLUMNS FROM accidents;

#عدد القيم الفريدة لكل عمود مهم (cardinality)
SELECT 
    COUNT(DISTINCT Accident_Index)       AS unique_accident_index,
    COUNT(DISTINCT Day_of_Week)   AS DISTINCT_Day_of_Week,
    COUNT(DISTINCT Junction_Detail)        AS DISTINCT_Junction_Detail,
    COUNT(DISTINCT Accident_Severity)                 AS Accident_Severity,
    COUNT(DISTINCT Latitude)            AS DISTINCT_Latitude,
    COUNT(DISTINCT Light_Conditions)     AS DISTINCT_Light_Conditions,
    COUNT(DISTINCT Local_Authority_District)             AS DISTINCT_Local_Authority_District,
    COUNT(DISTINCT Carriageway_Hazards)    AS DISTINCT_Carriageway_Hazards,
    COUNT(DISTINCT Longitude)           AS DISTINCT_Longitude,
    COUNT(DISTINCT Number_of_Casualties)            AS DISTINCT_Number_of_Casualties,
    COUNT(DISTINCT Number_of_Vehicles)     AS DISTINCT_Number_of_Vehicles,
    COUNT(DISTINCT Police_Force)             AS DISTINCT_Police_Force,
    COUNT(DISTINCT Road_Surface_Conditions)    AS DISTINCT_Road_Surface_Conditions,
    COUNT(DISTINCT Road_Type)           AS DISTINCT_Road_Type,
    COUNT(DISTINCT Speed_limit)     AS DISTINCT_Speed_limit,
    COUNT(DISTINCT Urban_or_Rural_Area)      AS DISTINCT_Urban_or_Rural_Area,
    COUNT(DISTINCT Weather_Conditions)    AS DISTINCT_Weather_Conditions,
    COUNT(DISTINCT Vehicle_Type)           AS DISTINCT_Vehicle_Type,
    COUNT(DISTINCT Accident_Date)            AS DISTINCT_Accident_Date,
    COUNT(DISTINCT Time_New)     AS DISTINCT_Time_New
FROM fact_accident f
JOIN Dim_Date d ON f.Date_Key = d.Date_Key
JOIN Dim_Vehicle v ON f.Vehicle_Key = v.Vehicle_Key
JOIN dim_location l ON f.Location_Key = l.Location_Key
JOIN Dim_Conditions c ON c.Conditions_Key = f.Conditions_Key ;


#Geographic sanity check (Latitude/Longitude) 
SELECT MIN(Latitude) AS min_lat, MAX(Latitude) AS max_lat,
       MIN(Longitude) AS min_lon, MAX(Longitude) AS max_lon
FROM accidents;

#exploration content 

#Total accidents
SELECT COUNT(DISTINCT Accident_Index) AS total_accidents FROM accidents;

#total accidents per year (2021 > 2022)
SELECT d.Year, COUNT(*) AS Total_Accidents
FROM Fact_Accident f
JOIN Dim_Date d ON f.Date_Key = d.Date_Key
GROUP BY d.Year
ORDER BY d.Year;

#total accidents per day (Saturday & Sunday are more safe)
SELECT d.Day_of_Week, COUNT(*) AS Total_Accidents
FROM Fact_Accident f
JOIN Dim_Date d ON f.Date_Key = d.Date_Key
GROUP BY d.Day_of_Week
ORDER BY Total_Accidents DESC;

#total accidents per hour (3-5 P.M are more dangerous)
SELECT d.Hour, COUNT(*) AS Total_Accidents
FROM Fact_Accident f
JOIN Dim_Date d ON f.Date_Key = d.Date_Key
GROUP BY d.Hour
ORDER BY Total_Accidents DESC;

#total accidents depend on accident severity(slight > serious > fatal)
SELECT Accident_Severity, COUNT(DISTINCT Accident_Index) AS total_accidents
FROM fact_accident
GROUP BY Accident_Severity
ORDER BY total_accidents DESC;

#total accidents depend on Area (Urban more dangerous)
SELECT Urban_or_Rural_Area, COUNT(DISTINCT Accident_Index) AS total
FROM fact_accident f
JOIN dim_location l ON f.Location_Key = l.Location_Key
GROUP BY Urban_or_Rural_Area;

#total accidents depend on light conditions (During Daylight, the accident rate is higher)
SELECT Light_Conditions, COUNT(DISTINCT Accident_Index) AS total
FROM fact_accident f
JOIN dim_conditions c ON f.Conditions_Key = c.Conditions_Key
GROUP BY Light_Conditions
ORDER BY total DESC;

#total accidents depend on weather conditions (more accidents happened in Fine no high winds weather)
SELECT c.Weather_Conditions, COUNT(*) AS Total_Accidents
FROM Fact_Accident f
JOIN Dim_Conditions c ON f.Conditions_Key = c.Conditions_Key
GROUP BY c.Weather_Conditions
ORDER BY Total_Accidents DESC;

#total accidents depend on road surface conditions (Dry road surface was more dangerous)
SELECT c.Road_Surface_Conditions, COUNT(*) AS Total_Accidents
FROM Fact_Accident f
JOIN Dim_Conditions c ON f.Conditions_Key = c.Conditions_Key
GROUP BY c.Road_Surface_Conditions;

#total accidents depend on road type (single carriageway was more dangerous)
SELECT c.Road_Type, COUNT(*) AS Total_Accidents
FROM Fact_Accident f
JOIN Dim_Conditions c ON f.Conditions_Key = c.Conditions_Key
GROUP BY c.Road_Type
ORDER BY Total_Accidents DESC;

#total accidents depend on Vehicle type (Cars drivers are less careful)
SELECT v.Vehicle_Type, COUNT(*) AS Total_Accidents 
FROM Fact_Accident f
JOIN Dim_Vehicle v ON f.Vehicle_Key = v.Vehicle_Key
GROUP BY v.Vehicle_Type
ORDER BY Total_Accidents DESC;

#Analysis Queries

#Average number of vehicles and casualties per accident.
SELECT d.Year, CEIL(AVG(f.Number_of_Vehicles)) AS Avg_Vehicles_Per_Accident, CEIL(AVG(f.Number_of_Casualties)) AS Avg_Casualties_Per_Accident
FROM Fact_Accident f
JOIN Dim_Date d ON f.Date_Key = d.Date_Key
WHERE d.Year IN (2021, 2022)
GROUP BY d.Year
ORDER BY d.Year;

#average number of casualties per accident by severity.
SELECT f.Accident_Severity, CEIL(AVG(f.Number_of_Casualties)) AS Avg_Casualties_Per_Accident
FROM Fact_Accident f
GROUP BY f.Accident_Severity
ORDER BY f.Accident_Severity;

# 5 most dangerous Local Authority District.
SELECT l.Local_Authority_District, COUNT(*) AS Total_Accidents,
       CONCAT(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Fact_Accident)), '%') AS Percent_Of_Total
FROM Fact_Accident f
JOIN Dim_Location l ON f.Location_Key = l.Location_Key
GROUP BY l.Local_Authority_District
ORDER BY Total_Accidents DESC
LIMIT 5;

#5 most dangerous Police Force (Metropolitan Police has the most accident rate as a police force)
SELECT f.Police_Force, COUNT(DISTINCT Accident_Index) AS total,
       CONCAT(ROUND(COUNT(DISTINCT Accident_Index) * 100.0 / (SELECT COUNT(*) FROM Fact_Accident)), '%') AS Percent_Of_Total
FROM fact_accident f
GROUP BY Police_Force
ORDER BY total DESC
LIMIT 5;

##Which weather conditions and road surfaces are most likely to cause accidents?
SELECT c.Weather_Conditions, c.Road_Surface_Conditions, COUNT(*) AS Total_Accidents,
       CONCAT(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Fact_Accident)), '%') AS Percent_Of_Total
FROM Fact_Accident f
JOIN Dim_Conditions c ON f.Conditions_Key = c.Conditions_Key
GROUP BY c.Weather_Conditions, c.Road_Surface_Conditions
ORDER BY Total_Accidents DESC
LIMIT 10;

##What are the most dangerous times (day and hour)?
SELECT d.Day_of_Week, d.Hour, COUNT(*) AS Total_Accidents,
       CONCAT(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Fact_Accident)), '%') AS Percent_Of_Total
FROM Fact_Accident f
JOIN Dim_Date d ON f.Date_Key = d.Date_Key
GROUP BY d.Day_of_Week, d.Hour
ORDER BY Total_Accidents DESC
LIMIT 10;

## Accidents in bad weather conditions vs. good weather conditions
SELECT 
    CASE 
        WHEN c.Weather_Conditions = 'Other' THEN 'Other'
        WHEN c.Weather_Conditions IN ('Raining no high winds','Snowing no high winds','Fog or mist') THEN 'Bad'
        ELSE 'Good'
    END AS Weather_Group,
    COUNT(*) AS Total_Accidents,
    CONCAT(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Fact_Accident)), '%') AS Percent_Of_Total
FROM Fact_Accident f
JOIN Dim_Conditions c ON f.Conditions_Key = c.Conditions_Key
GROUP BY Weather_Group
ORDER BY Total_Accidents DESC;

#Weather, Light conditions impact on total accidents (Accidents occur mainly due to human behavior)
SELECT c.Weather_Conditions, c.Light_Conditions, f.Accident_Severity, COUNT(*) AS Total_Accidents,
       CONCAT(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Fact_Accident)), '%') AS Percent_Of_Total
FROM Fact_Accident f
JOIN Dim_Conditions c ON f.Conditions_Key = c.Conditions_Key
GROUP BY c.Weather_Conditions, c.Light_Conditions, f.Accident_Severity
ORDER BY Total_Accidents DESC
LIMIT 5;

#Road type and speed limit analysis (Single carriageway roads cause most accidents)
SELECT c.Road_Type, c.Speed_limit, f.Accident_Severity, COUNT(*) AS Total_Accidents,
       CONCAT(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Fact_Accident)), '%') AS Percent_Of_Total
FROM Fact_Accident f
JOIN Dim_Conditions c ON f.Conditions_Key = c.Conditions_Key
GROUP BY c.Road_Type, c.Speed_limit, f.Accident_Severity
ORDER BY Total_Accidents DESC
LIMIT 5;

#Vehicle type impact on fatal accidents (Cars were involved in most fatal crashes)
SELECT v.Vehicle_Type, COUNT(*) AS Fatal_Accidents,
       CONCAT(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Fact_Accident WHERE Accident_Severity = 'Fatal')), '%') AS Percent_Of_Total
FROM Fact_Accident f
JOIN Dim_Vehicle v ON f.Vehicle_Key = v.Vehicle_Key
WHERE f.Accident_Severity = 'Fatal'
GROUP BY v.Vehicle_Type
ORDER BY Fatal_Accidents DESC;

#impact of junction detail and speed limit on total accidents
SELECT c.Junction_Detail, c.Speed_limit, COUNT(*) AS Total_Accidents,
       CONCAT(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Fact_Accident)), '%') AS Percent_Of_Total
FROM Fact_Accident f
JOIN Dim_Conditions c ON f.Conditions_Key = c.Conditions_Key
GROUP BY c.Junction_Detail, c.Speed_limit
ORDER BY Total_Accidents DESC
LIMIT 10;
