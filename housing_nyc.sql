-- ========================= Load the files that we are going to do =======================================================================


USE nyc_airbnb;


SHOW VARIABLES LIKE 'secure_file_priv';

CREATE TABLE listing (
  id INT,
  name VARCHAR(255),
  host_id INT,
  host_name VARCHAR(100),
  neighbourhood_group VARCHAR(100),
  neighbourhood VARCHAR(100),
  latitude DECIMAL(10,6),
  longitude DECIMAL(10,6),
  room_type VARCHAR(100),
  price INT,
  minimum_nights INT,
  number_of_reviews INT,
  last_review DATE NULL,
  reviews_per_month DECIMAL(5,2) NULL,
  calculated_host_listings_count INT,
  availability_365 INT
);


LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\new_york_listings_clean.csv'
INTO TABLE nyc_airbnb.listings
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

CREATE TABLE housing (
  brokertitle VARCHAR(255),
  type VARCHAR(100),
  price INT,
  beds INT,
  bath DECIMAL(3,1),
  propertysqft INT,
  address VARCHAR(255),
  state VARCHAR(100),
  main_address VARCHAR(255),
  administrative_area_level_2 VARCHAR(100),
  locality VARCHAR(100),
  sublocality VARCHAR(100),
  street_name VARCHAR(150),
  long_name VARCHAR(255),
  formatted_address VARCHAR(255),
  latitude DECIMAL(10,6),
  longitude DECIMAL(10,6)
);

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/new_york_housing_fixed.csv'
INTO TABLE housing
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES;



SELECT COUNT(*) FROM housing;
SELECT * FROM housing;

DROP TABLE IF EXISTS nypd_complaints;
CREATE TABLE nypd_complaints (
  cmplnt_num        BIGINT PRIMARY KEY,
  cmplnt_fr_dt      DATE NULL,
  pd_desc           VARCHAR(255),
  boro_nm           VARCHAR(50),
  loc_of_occur_desc VARCHAR(255),
  latitude          DECIMAL(10,6),
  longitude         DECIMAL(10,6),
  lat_lon           VARCHAR(100),
  patrol_boro       VARCHAR(100)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;


LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/nypd_complaints.csv'
INTO TABLE nypd_complaints
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

select lat_lon from nypd_complaints;

--  ============================================== Retrieve data from LISTINGS (airbnb) ================================================

SELECT * FROM listings;

-- Which borough has the biggest number of airbnbs booked

SELECT 
     neighbourhood_group, 
     COUNT(*) AS bookings
FROM listings
GROUP BY neighbourhood_group;



-- which borough is the most expensive:

SELECT 
	ROUND(AVG(price),2) AS price, 
	neighbourhood_group
FROM listings
GROUP BY neighbourhood_group;

#OUTPUT: Manhattan

-- which borough has the lowest availability (it has most of the days of the year booked)

SELECT 
    neighbourhood_group,
    AVG(availability_365) AS avg_availability
FROM listings
GROUP BY neighbourhood_group
ORDER BY avg_availability ASC
LIMIT 1;

#OUTPUT: Brooklyn

SELECT last_review FROM listings;


-- Retrieve the ratings from name column

WITH listings_rated AS (
  SELECT
    l.id,
    l.neighbourhood_group,
    CAST(REGEXP_SUBSTR(l.name, '[0-9]+(\\.[0-9]+)?') AS DECIMAL(4,2)) AS rating
  FROM listings l
)
SELECT
  neighbourhood_group,
  ROUND(AVG(rating), 2) AS avg_rating,
  COUNT(*) AS listings_count
FROM listings_rated
WHERE rating IS NOT NULL
GROUP BY neighbourhood_group
ORDER BY avg_rating DESC;




-- ========================================== Retrieve data from COMPLAINTS ============================================


SELECT * FROM nypd_complaints;

-- Average crimes per borough:

SELECT boro_nm,
COUNT(pd_desc) AS number_complaints
FROM nypd_complaints
WHERE boro_nm IN ('BROOKLYN','QUEENS','MANHATTAN','BRONX','STATEN ISLAND')
GROUP BY boro_nm;

-- Instead of doing the following code for retrieve the number of certain crimes by borough we use case_when to simplify the code.

-- SELECT 
--     boro_nm,
--    COUNT(*) AS number_assault
-- FROM nypd_complaints
-- WHERE pd_desc LIKE '%ASSAULT%'
-- GROUP BY boro_nm
-- ORDER BY number_assault DESC;

-- CRIMES BY BORO / RATE
WITH scored AS (
  SELECT
    c.BORO_NM,
    CASE
      WHEN PD_DESC LIKE '%MURDER%' THEN 10
      WHEN PD_DESC LIKE '%TERRORISM%' OR PD_DESC LIKE '%SUPP. ACT TERR%' THEN 10
      WHEN PD_DESC LIKE '%RAPE%' THEN 10
      WHEN PD_DESC LIKE '%SODOMY%' THEN 10
      WHEN PD_DESC LIKE '%KIDNAPPING 1%' THEN 10
      WHEN PD_DESC LIKE '%KIDNAPPING 2%' THEN 9
      WHEN PD_DESC LIKE '%SEX TRAFFICKING%' THEN 9
      WHEN PD_DESC LIKE '%USE OF A CHILD IN A SEXUAL PER%' THEN 9
      WHEN PD_DESC LIKE '%AGGRAVATED SEXUAL%' THEN 9
      WHEN PD_DESC LIKE '%ARSON 1%' THEN 9
      WHEN PD_DESC LIKE '%AGGRAVATED CRIMINAL CONTEMPT%' THEN 8
      WHEN PD_DESC LIKE '%ASSAULT POLICE%' OR PD_DESC LIKE '%ASSAULT OTHER PUBLIC%' THEN 8
      WHEN PD_DESC LIKE '%STRANGULATION%' THEN 8
      WHEN PD_DESC LIKE '%ASSAULT TRAFFIC%' OR PD_DESC LIKE '%ASSAULT SCHOOL SAFETY%' THEN 7
      WHEN PD_DESC LIKE '%ASSAULT%' THEN 7
      WHEN PD_DESC LIKE '%RECKLESS ENDANGERMENT%' THEN 7
      WHEN PD_DESC LIKE '%COERCION 1%' THEN 7
      WHEN PD_DESC LIKE '%RAPE 3%' THEN 7
      WHEN PD_DESC LIKE '%CRIMINAL DISPOSAL FIREARM%' THEN 7
      WHEN PD_DESC LIKE '%WEAPONS POSSESSION%' OR PD_DESC LIKE '%CRIM POS WEAP%' THEN 7
      WHEN PD_DESC LIKE '%OBSTR BREATH%' THEN 6
      WHEN PD_DESC LIKE '%CRIMINAL CONTEMPT%' THEN 6
      WHEN PD_DESC LIKE '%AGGRAVATED HARASSMENT%' THEN 6
      WHEN PD_DESC LIKE '%RESISTING ARREST%' THEN 5
      WHEN PD_DESC LIKE '%RECKLESS DRIVING%' THEN 5
      WHEN PD_DESC LIKE '%BAIL JUMPING%' THEN 5
      WHEN PD_DESC LIKE '%FALSE REPORT%' OR PD_DESC LIKE '%FALSE ALARM%' THEN 5
      WHEN PD_DESC LIKE '%MENACING%' THEN 5
      WHEN PD_DESC LIKE '%OBSCENE MATERIAL%' THEN 5
      WHEN PD_DESC LIKE '%PROMOTING A SEXUAL PERFORMANCE%' THEN 5
      WHEN PD_DESC LIKE '%VIOLATION OF ORDER%' THEN 5
      WHEN PD_DESC LIKE '%TORTURE/INJURE ANIMAL%' THEN 5
      WHEN PD_DESC LIKE '%CAUSE SPI/KILL ANIMAL%' THEN 5
      WHEN PD_DESC LIKE '%COURSE OF SEXUAL CONDUCT%' THEN 5
      WHEN PD_DESC LIKE '%CRIMINAL MIS%' THEN 4
      WHEN PD_DESC LIKE '%PETIT LARCENY%' OR PD_DESC LIKE '%LARCENY%' THEN 4
      WHEN PD_DESC LIKE '%LEAVING THE SCENE%' OR PD_DESC LIKE '%LEAVING SCENE%' THEN 4
      WHEN PD_DESC LIKE '%CRIMINAL POSSESSION WEAPON%' THEN 4
      WHEN PD_DESC LIKE '%UNAUTHORIZED USE VEHICLE%' THEN 4
      WHEN PD_DESC LIKE '%PROSTITUTION%' THEN 3
      WHEN PD_DESC LIKE '%DISORDERLY CONDUCT%' THEN 3
      WHEN PD_DESC LIKE '%CANNABIS%' OR PD_DESC LIKE '%MARIJUANA%' THEN 3
      WHEN PD_DESC LIKE '%TAX LAW%' THEN 3
      WHEN PD_DESC LIKE '%ALCOHOLIC BEVERAGE CONTROL%' THEN 3
      WHEN PD_DESC LIKE '%JOSTLING%' THEN 3
      WHEN PD_DESC LIKE '%EDUCATION LAW%' THEN 3
      WHEN PD_DESC LIKE '%BUILDING MATERIAL%' THEN 3
      WHEN PD_DESC LIKE '%GENERAL BUSINESS LAW%' THEN 3
      WHEN PD_DESC LIKE '%FIREWORKS%' THEN 2
      WHEN PD_DESC LIKE '%FIREARMS LICENSING%' THEN 2
      WHEN PD_DESC LIKE '%GRAFFITI%' THEN 2
      WHEN PD_DESC LIKE '%THEFT OF SERVICES%' THEN 2
      WHEN PD_DESC LIKE '%SALE SCHOOL GROUNDS%' THEN 2
      WHEN PD_DESC LIKE '%UNAUTH. SALE OF TRANS. SERVICE%' THEN 2
      WHEN PD_DESC LIKE '%UNLAWFUL SALE SYNTHETIC MARIJUANA%' THEN 2
      WHEN PD_DESC LIKE '%AIRPOLLUTION%' THEN 2
      WHEN PD_DESC LIKE '%HEALTHCARE%' OR PD_DESC LIKE '%RENT.REG%' THEN 2
      WHEN PD_DESC LIKE '%POSSESSION HYPODERMIC%' THEN 2
      WHEN PD_DESC LIKE '%COMPUTER%' THEN 2
      WHEN PD_DESC LIKE '%RIOT%' THEN 2
      WHEN PD_DESC LIKE '%POSTING ADVERTISEMENTS%' THEN 2
      WHEN PD_DESC LIKE '%OBSCENITY%' THEN 2
      WHEN PD_DESC LIKE '%BREED/TRAIN/HOST ANIMAL FIGHTING%' THEN 2
      WHEN PD_DESC LIKE '%EAVESDROPPING%' THEN 2
      WHEN PD_DESC LIKE '%POSSES OR CARRY A KNIFE%' THEN 2
      WHEN PD_DESC LIKE '%IMITATION PISTOL%' THEN 2
      WHEN PD_DESC LIKE '%INAPPROPIATE SHELTER DOG LEFT%' THEN 2
      WHEN PD_DESC LIKE '%ABANDON ANIMAL%' THEN 2
      WHEN PD_DESC LIKE '%CONFINING ANIMAL%' THEN 2
      WHEN PD_DESC LIKE '%NEGLECT/POISON ANIMAL%' THEN 2
      WHEN PD_DESC LIKE '%EXPOSURE OF A PERSON%' THEN 2
      WHEN PD_DESC LIKE '%MATERIAL OFFENSIV%' THEN 2
      WHEN PD_DESC LIKE '%N.Y.C. TRANSIT AUTH. R&R%' THEN 2
      WHEN PD_DESC LIKE '%SEXUAL ABUSE%' THEN 6
      WHEN PD_DESC LIKE '%OBSCENITY%' THEN 5
      WHEN PD_DESC LIKE '%MENACING 1ST%' THEN 6
      WHEN PD_DESC LIKE '%COERCION 2%' THEN 6
      WHEN PD_DESC LIKE '%STALKING%' THEN 7
      WHEN PD_DESC LIKE '%PROMOTING SUICIDE%' THEN 7
      WHEN PD_DESC LIKE '%CRIM USE BIO OR CHEM WEAPON%' THEN 10
      WHEN PD_DESC LIKE '%ENTERPRISE CORRUPTION%' THEN 8
      WHEN PD_DESC LIKE '%MONEY LAUNDERING%' THEN 5
      WHEN PD_DESC LIKE '%FORTUNE TELLING%' THEN 1
      WHEN PD_DESC LIKE '%GYPSY CAB%' THEN 1
      WHEN PD_DESC LIKE '%ABSCONDING FROM WORK RELEASE%' THEN 3
      ELSE 1
    END AS severity
  FROM nypd_complaints c
  WHERE c.BORO_NM IN ('BROOKLYN','QUEENS','MANHATTAN','BRONX','STATEN ISLAND')
)
SELECT BORO_NM, severity, COUNT(*) AS crimes
FROM scored
GROUP BY BORO_NM, severity
ORDER BY BORO_NM, severity DESC;

WITH scored AS (
  SELECT 
    c.BORO_NM,
    CASE
      WHEN PD_DESC LIKE '%MURDER%' THEN 10
      WHEN PD_DESC LIKE '%RAPE%' THEN 10
      WHEN PD_DESC LIKE '%ASSAULT%' THEN 7
      WHEN PD_DESC LIKE '%LARCENY%' THEN 4
      WHEN PD_DESC LIKE '%DISORDERLY CONDUCT%' THEN 3
      ELSE 1
    END AS severity
  FROM nypd_complaints c
  WHERE c.BORO_NM IN ('BROOKLYN','QUEENS','MANHATTAN','BRONX','STATEN ISLAND')
)
SELECT
  severity,
  SUM(CASE WHEN BORO_NM = 'BROOKLYN' THEN 1 ELSE 0 END) AS brooklyn,
  SUM(CASE WHEN BORO_NM = 'MANHATTAN' THEN 1 ELSE 0 END) AS manhattan,
  SUM(CASE WHEN BORO_NM = 'QUEENS' THEN 1 ELSE 0 END) AS queens,
  SUM(CASE WHEN BORO_NM = 'BRONX' THEN 1 ELSE 0 END) AS bronx,
  SUM(CASE WHEN BORO_NM = 'STATEN ISLAND' THEN 1 ELSE 0 END) AS staten_island,
  COUNT(*) AS total
FROM scored
GROUP BY severity
ORDER BY severity DESC;


-- SEXUAL OFENSES
SELECT
  c.BORO_NM,
  COUNT(*) AS total_sexual_offenses
FROM nypd_complaints AS c
WHERE c.BORO_NM IN ('BROOKLYN','QUEENS','MANHATTAN','BRONX','STATEN ISLAND')
  AND (
    c.PD_DESC LIKE '%RAPE%' OR
    c.PD_DESC LIKE '%SODOMY%' OR
    c.PD_DESC LIKE '%SEXUAL ABUSE%' OR
    c.PD_DESC LIKE '%AGGRAVATED SEXUAL%' OR
    c.PD_DESC LIKE '%SEX TRAFFICKING%' OR
    c.PD_DESC LIKE '%USE OF A CHILD IN A SEXUAL PER%' OR
    c.PD_DESC LIKE '%PROMOTING A SEXUAL PERFORMANCE%' OR
    c.PD_DESC LIKE '%STALKING COMMIT SEX OFFENSE%' OR
    c.PD_DESC LIKE '%LURING A CHILD%' OR
    c.PD_DESC LIKE '%OBSCENITY%' OR
    c.PD_DESC LIKE '%EXPOSURE OF A PERSON%' OR
    c.PD_DESC LIKE '%UNLAWFUL DISCLOSURE OF AN INTIMATE IMAGE%' OR
    c.PD_DESC LIKE '%SEX CRIMES%'
  )
GROUP BY c.BORO_NM
ORDER BY total_sexual_offenses DESC;



-- ======================================= Retrieve data from HOUSING ==========================================

SELECT * FROM housing;



-- Average houses prices per borough

SELECT 
	h.sublocality, 
    ROUND(AVG(h.price),2) AS housing_price, 
    AVG(l.price) AS airbnb_price
FROM housing h
JOIN listings l 
	ON h.sublocality LIKE CONCAT('%',l.neighbourhood_group,'%')
WHERE h.sublocality IN ('The Bronx','Queens' ,'Staten Island' ,'Brooklyn' ,'Manhattan')
GROUP BY h.sublocality
ORDER BY housing_price DESC, airbnb_price DESC;


-- Do the boroughs that have more bookings 

#The one that has the % in JOINON has to be at the end


SELECT 
     l.neighbourhood_group, 
     COUNT(l.id) AS bookings,
     COUNT(c.pd_desc) AS avg_crimes,
     ROUND(AVG(h.price),2) AS housing_price
FROM listings l
JOIN housing h
JOIN nypd_complaints c
  ON TRIM(LEADING 'the ' FROM LOWER(h.sublocality))
     = LOWER(l.neighbourhood_group) = c.boro_nm
WHERE c.boro_nm IN ('Bronx','Queens' ,'Staten Island' ,'Brooklyn' ,'Manhattan')
GROUP BY l.neighbourhood_group
ORDER BY bookings DESC, housing_price DESC;


#Added TRIM to get rid of the 'The' on front of Bronx in the housing table.

SELECT AVG(price) AS avg_price, sublocality
FROM housing
WHERE sublocality IN ('The Bronx','Queens' ,'Staten Island' ,'Brooklyn' ,'Manhattan')
GROUP BY sublocality;



