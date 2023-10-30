-- Create a database "la"
CREATE DATABASE la; 

-- Set la database as default for this project
USE la;



-- Import ethnicty table
-- Create new column "tract" in ethnicity
ALTER TABLE ethnicity
ADD COLUMN tract int(6) AFTER geoid20;

-- Assign six right-most digits from "geoid20" as "tract"
SET SQL_SAFE_UPDATES = 0;
UPDATE ethnicity
SET tract = RIGHT(geoid20, 6)
WHERE geoid IS NOT NULL;
SET SQL_SAFE_UPDATES = 1;

-- View all tracts that are duplicate in ethnicity table
SELECT COUNT(tract) AS count, tract
FROM ethnicity
GROUP BY tract
HAVING count > 1;  -- Each tract is entered 12 times because there is 12 years of data



-- In tracts table, rename "Tract Number" to "tract" and set as primary key
ALTER TABLE tracts
RENAME COLUMN `Tract Number` TO tract;
ALTER TABLE tracts
ADD CONSTRAINT
PRIMARY KEY(tract);

-- In ethnicity table, set tract as foreign key that will reference tract in tracts table
ALTER TABLE ethnicity
ADD CONSTRAINT fk_ethnicity_tract
FOREIGN KEY (tract) 
REFERENCES tracts(tract);
-- doesnt work because maybe there are tracts in ethnicity that arent in tracts

-- How many distinct tracts are in each table?
SELECT COUNT(DISTINCT(tract))
FROM tracts; -- result = 2,344 distinct tracts in tracts table
SELECT COUNT(DISTINCT(tract))
FROM ethnicity; -- result = 2,487 distinct tracts in ethnicity table

-- How many distinct tracts are in one table, but not the other?
SELECT COUNT(DISTINCT(tract))
FROM ethnicity
WHERE tract NOT IN (SELECT tract FROM tracts); -- result = 476 distinct tracts in ethnicty that ARE NOT in tracts
SELECT COUNT(DISTINCT(tract))
FROM tracts
WHERE tract NOT IN (SELECT tract FROM ethnicity); -- result = 333 tracts in tracts that ARE NOT in ethnicty

-- How many people are in the 476 tracts identified above?
SELECT SUM(denom_total_pop)
FROM ethnicity
WHERE year = 2021 AND tract NOT IN (SELECT tract FROM tracts); -- 1,653,137 people are counted in ethnicity, but not tracts (in year 2021)
-- With a total population of 10,019,635 in 2021, 16.5% of total population would be omtted if the 476 distinct tracts (identified above) are dropped

-- What tracts are missing in tracts table?
SELECT DISTINCT(tract)
FROM ethnicity
WHERE year = 2021 AND tract NOT IN (SELECT tract FROM tracts); 

-- View neighborhoods in tracts, but not ethnicity
SELECT DISTINCT(tract), Neighborhood
FROM tracts
WHERE tract NOT IN (SELECT tract FROM ethnicity);

-- View tracts from ethnicity table and neighborhoods from tracts table
SELECT DISTINCT(ethnicity.tract), tracts.Neighborhood
FROM ethnicity LEFT JOIN tracts
ON ethnicity.tract = tracts.tract;

-- View tracts from ethnicity table and neighborhoods from tracts table
SELECT tracts.Neighborhood, sum(ethnicity.asian_count) AS asian_count
FROM ethnicity LEFT JOIN tracts
ON ethnicity.tract = tracts.tract
WHERE ethnicity.year = 2021
GROUP BY tracts.Neighborhood
ORDER BY asian_count DESC;



-- Create new table, "tracts2", that takes distinct tracts from ethnicity and corresponsding neighborhoods from tracts, 
-- then fills null values in neighborhood column with nearest non-null neighborhood
CREATE TABLE tracts2 (
    tract INT PRIMARY KEY,
    Neighborhood VARCHAR(255)
);
INSERT INTO tracts2 (tract, Neighborhood)
SELECT e.tract,
       COALESCE(t.Neighborhood, (
           SELECT t2.Neighborhood
           FROM tracts t2
           WHERE t2.tract IS NOT NULL
           ORDER BY ABS(t2.tract - e.tract)
           LIMIT 1
       )) AS Neighborhood
FROM (
    SELECT DISTINCT tract
    FROM ethnicity
) e
LEFT JOIN tracts t ON e.tract = t.tract;

-- How many distinct tracts are in one table, but not the other?
SELECT COUNT(DISTINCT(tract))
FROM ethnicity
WHERE tract NOT IN (SELECT tract FROM tracts2); -- result = 0, the tables are now ready to join

-- Create "ethnicity_neighborhood" table that joins tracts and ethnicty tables
CREATE TABLE ethnicity_neighborhood AS
SELECT 	t.Neighborhood, e.year, SUM(e.denom_total_pop) AS total_pop, SUM(e.american_indian_native_count) AS native_american, SUM(e.asian_count) AS asian,
		SUM(e.black_count) AS black, SUM(e.latino_count) AS latino, SUM(e.native_hawaiian_other_count) AS native_hawaiian, 
		SUM(other_race_count) AS other, SUM(pop_two_or_more_count) AS multiple, SUM(white_count) AS white
FROM tracts2 t INNER JOIN ethnicity e
ON t.tract = e.tract
GROUP BY t.Neighborhood, e.year;

SELECT * FROM ethnicity_neighborhood


-- Import "immigration" table and preview data
SELECT * FROM immigration LIMIT 50;

-- Drop columns "geoid" and "denom_tot_immigrant" from immigration table
ALTER TABLE immigration
DROP COLUMN geoid, DROP COLUMN denom_tot_immigrant;

-- Create new column "tract" in immigration
ALTER TABLE immigration
ADD COLUMN tract bigint AFTER geoid20;

-- Assign six right-most digits from "geoid20" as "tract"
SET SQL_SAFE_UPDATES = 0;
UPDATE immigration
SET tract = RIGHT(geoid20, 6);
SET SQL_SAFE_UPDATES = 1;

-- Drop column "geoid20" now that "tract" is created
ALTER TABLE immigration
DROP COLUMN geoid20;

-- Create table that joins tracts2 and immigration tables
CREATE TABLE immigration_neighborhood AS
SELECT 	t.Neighborhood, i.year, SUM(i.denom_tot_pop) AS total_pop, SUM(i.tot_immigrant_count) AS immigrant_count,
		SUM(i.immigrant_citizen_count) AS immigrant_citizen, SUM(i.immigrant_noncitizen_count) AS immigrant_noncitizen
FROM tracts2 t INNER JOIN immigration i
ON t.tract = i.tract
GROUP BY t.Neighborhood, i.year;

-- View immigration_neighborhood table
SELECT * FROM immigration_neighborhood
ORDER BY immigrant_count DESC;


-- Import "incomegroups" table and preview data
SELECT * FROM incomegroups LIMIT 50;

-- Create new column "tract" in incomegroups
ALTER TABLE incomegroups
ADD COLUMN tract bigint AFTER geoid20;

-- Assign six right-most digits from "geoid20" as "tract"
SET SQL_SAFE_UPDATES = 0;
UPDATE incomegroups
SET tract = RIGHT(geoid20, 6);
SET SQL_SAFE_UPDATES = 1;

-- Drop column "geoid20" now that "tract" is created
ALTER TABLE incomegroups
DROP COLUMN geoid20;

-- Create table that joins tracts2 and incomegroups tables
CREATE TABLE incomegroups_neighborhood AS
SELECT 	t.Neighborhood, i.year, SUM(i.denom_all_households) AS total_households, SUM(i.eli_count) AS extremely_low, SUM(i.vli_count) AS very_low, 
		SUM(i.li_count) AS low, SUM(i.mi_count) AS middle, SUM(i.abmi_count) AS above_middle
FROM tracts2 t INNER JOIN incomegroups i
ON t.tract = i.tract
GROUP BY t.Neighborhood, i.year;

-- View incomegroups_neighborhood table
SELECT * FROM incomegroups_neighborhood
ORDER BY Neighborhood, year;



-- Import "linguisticisolation" table and preview data
SELECT * FROM linguisticisolation LIMIT 50;

-- Create new column "tract" in linguisticisolation
ALTER TABLE linguisticisolation
ADD COLUMN tract bigint AFTER geoid20;

-- Assign six right-most digits from "geoid20" as "tract" and then drop column "geoid20"
SET SQL_SAFE_UPDATES = 0;
UPDATE linguisticisolation
SET tract = RIGHT(geoid20, 6);
SET SQL_SAFE_UPDATES = 1;
ALTER TABLE linguisticisolation
DROP COLUMN geoid20;

-- Create table that joins tracts2 and linguisticisolation tables
CREATE TABLE linguisticisolation_neighborhood AS
SELECT 	t.Neighborhood, l.year, SUM(l.denom_tot_hh) AS total_households, SUM(l.ling_iso_hh_count) AS limited_english_hh
FROM tracts2 t INNER JOIN linguisticisolation l
ON t.tract = l.tract
GROUP BY t.Neighborhood, l.year;

-- View linguisticisolation_neighborhood table
SELECT * FROM linguisticisolation_neighborhood;



-- Import "homeownership" table and preview data
SELECT * FROM homeownership LIMIT 50;

-- Create new column "tract" in homeownership
ALTER TABLE homeownership
ADD COLUMN tract bigint AFTER geoid20;

-- Assign six right-most digits from "geoid20" as "tract" and then drop column "geoid20"
SET SQL_SAFE_UPDATES = 0;
UPDATE homeownership
SET tract = RIGHT(geoid20, 6);
SET SQL_SAFE_UPDATES = 1;
ALTER TABLE homeownership
DROP COLUMN geoid20;

-- Create table that joins tracts2 and homeownership tables
CREATE TABLE homeownership_neighborhood AS
SELECT 	t.Neighborhood, h.year, SUM(h.denom_total_hh) AS total_households, SUM(h.homeownership_count) AS homeowners, SUM(h.rentership_count) AS renters
FROM tracts2 t INNER JOIN homeownership h
ON t.tract = h.tract
GROUP BY t.Neighborhood, h.year;

-- View linguisticisolation_neighborhood table
SELECT * FROM linguisticisolation_neighborhood;



-- Import "homelessness" table and preview data
SELECT * FROM homelessness LIMIT 50;

-- Create new column "tract" in homelessness
ALTER TABLE homelessness
ADD COLUMN tract bigint AFTER geoid20;

-- Assign six right-most digits from "geoid20" as "tract" and then drop column "geoid20"
SET SQL_SAFE_UPDATES = 0;
UPDATE homelessness
SET tract = RIGHT(geoid20, 6);
SET SQL_SAFE_UPDATES = 1;
ALTER TABLE homelessness
DROP COLUMN geoid20;

-- Create table that joins tracts2 and homeownership tables
CREATE TABLE homelessness_neighborhood AS
SELECT 	t.Neighborhood, h.year, SUM(h.denom_total_pop) AS total_households, SUM(h.tothomeless_count) AS total_homeless, 
		SUM(h.totshelt_count) AS sheltered_homeless, SUM(h.totunshelt_count) AS unsheltered_homeless
FROM tracts2 t INNER JOIN homelessness h
ON t.tract = h.tract
GROUP BY t.Neighborhood, h.year;

-- View linguisticisolation_neighborhood table
SELECT * FROM homelessness_neighborhood
ORDER BY Neighborhood, year;



-- Import "medianincome" table and preview data
SELECT * FROM medianincome LIMIT 50;

-- Create new column "tract" in medianincome
ALTER TABLE medianincome
ADD COLUMN tract bigint AFTER geoid20;

-- Assign six right-most digits from "geoid20" as "tract" and then drop column "geoid20"
SET SQL_SAFE_UPDATES = 0;
UPDATE medianincome
SET tract = RIGHT(geoid20, 6);
SET SQL_SAFE_UPDATES = 1;
ALTER TABLE medianincome
DROP COLUMN geoid20;

-- Create new column ,"pop_income", that multiplies denom_total_hh by med_hh_inc
ALTER TABLE medianincome
ADD COLUMN pop_income bigint;
SET SQL_SAFE_UPDATES = 0;
UPDATE medianincome
SET pop_income = denom_total_hh * med_hh_inc;
SET SQL_SAFE_UPDATES = 1;

-- Create table that joins tracts2 and medianincome tables
CREATE TABLE medianincome_neighborhood AS
SELECT 	t.Neighborhood, m.year, SUM(m.denom_total_hh) AS total_households, SUM(m.med_hh_inc_adj) AS median_income_adj, 
		SUM(m.med_hh_inc) AS median_income, SUM(m.pop_income) AS pop_income
FROM tracts2 t INNER JOIN medianincome m
ON t.tract = m.tract
GROUP BY t.Neighborhood, m.year;

-- Create new "med_income" column and calculate true median income by neighborhood
ALTER TABLE medianincome_neighborhood
ADD COLUMN med_income bigint;
SET SQL_SAFE_UPDATES = 0;
UPDATE medianincome_neighborhood
SET med_income = pop_income/total_households;
SET SQL_SAFE_UPDATES = 1;

-- Drop unneccessary columns
ALTER TABLE medianincome_neighborhood
DROP COLUMN pop_income,
DROP COLUMN median_income, 
DROP COLUMN median_income_adj;

-- View medianincome_neighborhood table
SELECT * FROM medianincome_neighborhood;



-- Import "trees" table and preview data
SELECT * FROM trees LIMIT 50;

-- Create new column "tract" in trees, assign six right-most digits from "geoid20" as "tract", and drop column "geoid20"
ALTER TABLE trees
ADD COLUMN tract bigint AFTER geoid20;
SET SQL_SAFE_UPDATES = 0;
UPDATE trees
SET tract = RIGHT(geoid20, 6);
SET SQL_SAFE_UPDATES = 1;
ALTER TABLE trees
DROP COLUMN geoid20;

-- Create table that joins tracts2 and trees tables
CREATE TABLE trees_neighborhood AS
SELECT 	t.Neighborhood, tr.year, SUM(tr.denom_totalarea) AS total_area, SUM(tr.existing_canopy_count) AS existing_canopy, 
		SUM(tr.possible_canopy_count) AS possible_canopy
FROM tracts2 t INNER JOIN trees tr
ON t.tract = tr.tract
GROUP BY t.Neighborhood, tr.year;

-- View trees_neighborhood table
SELECT * FROM trees_neighborhood
ORDER BY Neighborhood, year;



-- Import "languages" table and preview data
SELECT * FROM languages LIMIT 50;

-- Create new column "tract" in languages, assign six right-most digits from "geoid20" as "tract", and drop column "geoid20"
ALTER TABLE languages
ADD COLUMN tract bigint AFTER geoid20;
SET SQL_SAFE_UPDATES = 0;
UPDATE languages
SET tract = RIGHT(geoid20, 6);
SET SQL_SAFE_UPDATES = 1;
ALTER TABLE languages
DROP COLUMN geoid20;

-- Create table that joins tracts2 and languages tables
CREATE TABLE languages_neighborhood AS
SELECT 	t.Neighborhood, l.year, SUM(l.denom_pop_over5) AS total_pop_over5, SUM(l.only_english_count) AS only_english, 
		SUM(l.spanish_count) AS spanish, SUM(l.french_count) AS french, SUM(l.german_count) AS german, 
        SUM(l.russian_count) AS russian, SUM(l.indoeuro_count) AS indoeuro, SUM(l.korean_count) AS korean,
        SUM(l.chinese_count) AS chinese, SUM(l.vietnamese_count) AS vietnamese, SUM(l.tagalog_count) AS tagalog,
        SUM(l.otherapi_count) AS other_api, SUM(l.arabic_count) AS arabic, SUM(l.otherunspec_count) AS other_unspecified,
        SUM(l.spanish_lep_count) spanish_lep, SUM(l.korean_lep_count) AS korean_lep, SUM(l.tagalog_lep_count) AS tagalog_lep,
        SUM(l.chinese_lep_count) AS chinese_lep
FROM tracts2 t INNER JOIN languages l
ON t.tract = l.tract
GROUP BY t.Neighborhood, l.year;

-- View languages_neighborhood table
SELECT * FROM languages_neighborhood
ORDER BY Neighborhood, year;



-- Import "education" table and preview data
SELECT * FROM education LIMIT 50;

-- Create new column "tract" in education, assign six right-most digits from "geoid20" as "tract", and drop column "geoid20"
ALTER TABLE education
ADD COLUMN tract bigint AFTER geoid20;
SET SQL_SAFE_UPDATES = 0;
UPDATE education
SET tract = RIGHT(geoid20, 6);
SET SQL_SAFE_UPDATES = 1;
ALTER TABLE education
DROP COLUMN geoid20;

-- Create table that joins tracts2 and education tables
CREATE TABLE education_neighborhood AS
SELECT 	t.Neighborhood, e.year, SUM(e.denom_pop_25_over) AS pop_over25, SUM(e.college_grad_count) AS bachelors, 
		SUM(e.less_than_highschool_count) AS less_than_highschool, SUM(e.assoc_grad_count) AS associates
FROM tracts2 t INNER JOIN education e
ON t.tract = e.tract
GROUP BY t.Neighborhood, e.year;

-- View education_neighborhood table
SELECT * FROM education_neighborhood
ORDER BY Neighborhood, year;



-- Import "parks" table and preview data
SELECT * FROM parks LIMIT 50;

-- Create new column "tract" in parks, assign six right-most digits from "geoid20" as "tract", and drop column "geoid20"
ALTER TABLE parks
ADD COLUMN tract bigint AFTER geoid20;
SET SQL_SAFE_UPDATES = 0;
UPDATE parks
SET tract = RIGHT(geoid20, 6);
SET SQL_SAFE_UPDATES = 1;
ALTER TABLE parks
DROP COLUMN geoid20;

-- Create table that joins tracts2 and parks tables
CREATE TABLE parks_neighborhood AS
SELECT 	t.Neighborhood, p.year, SUM(p.denom_total_pop) AS total_pop, SUM(p.park_access_count) AS park_access, 
		SUM(p.good_park_access_count) AS good_park_access
FROM tracts2 t INNER JOIN parks p
ON t.tract = p.tract
GROUP BY t.Neighborhood, p.year;

-- View parks_neighborhood table
SELECT * FROM parks_neighborhood
ORDER BY Neighborhood, year;



-- Import "health" table and preview data
SELECT * FROM health LIMIT 50;

-- Create new column "tract" in health, assign six right-most digits from "geoid20" as "tract", and drop column "geoid20"
ALTER TABLE health
ADD COLUMN tract bigint AFTER geoid20;
SET SQL_SAFE_UPDATES = 0;
UPDATE health
SET tract = RIGHT(geoid20, 6);
SET SQL_SAFE_UPDATES = 1;
ALTER TABLE health
DROP COLUMN geoid20;

-- Create table that joins tracts2 and health tables
CREATE TABLE health_neighborhood AS
SELECT 	t.Neighborhood, h.year, SUM(h.denom_pop_18_over) AS denom_pop_18_over, SUM(h.mental_health_count) AS mental_health_count, 
		SUM(h.physical_health_count) AS physical_health_count, SUM(h.obesity_count) AS obesity_count, SUM(h.no_phys_act_count) AS no_phys_act_count, 
        SUM(h.asthma_count) AS asthma_count, SUM(h.cancer_count) AS cancer_count, SUM(smoking_count) AS smoking_count, 
        SUM(h.binge_drinking_count) AS binge_drinking_count
FROM tracts2 t INNER JOIN health h
ON t.tract = h.tract
GROUP BY t.Neighborhood, h.year;

-- View health_neighborhood table
SELECT * FROM health_neighborhood
ORDER BY Neighborhood, year;



-- Import "frpl" table and preview data
SELECT * FROM frpl LIMIT 50;

-- Create new column "tract" in frpl, assign six right-most digits from "geoid20" as "tract", and drop column "geoid20"
ALTER TABLE frpl
ADD COLUMN tract bigint AFTER geoid20;
SET SQL_SAFE_UPDATES = 0;
UPDATE frpl
SET tract = RIGHT(geoid20, 6);
SET SQL_SAFE_UPDATES = 1;
ALTER TABLE frpl
DROP COLUMN geoid20;

-- Create table that joins tracts2 and frpl tables
CREATE TABLE frpl_neighborhood AS
SELECT 	t.Neighborhood, f.year, SUM(f.denom_enrolled) AS denom_enrolled, SUM(f.frpl_count) AS frpl_count 
FROM tracts2 t INNER JOIN frpl f
ON t.tract = f.tract
GROUP BY t.Neighborhood, f.year;

-- View frpl_neighborhood table
SELECT * FROM frpl_neighborhood
ORDER BY Neighborhood, year;



-- Import "age" table and preview data
SELECT * FROM age LIMIT 50;

-- Create new column "tract" in age, assign six right-most digits from "geoid20" as "tract", and drop column "geoid20"
ALTER TABLE age
ADD COLUMN tract bigint AFTER geoid20;
SET SQL_SAFE_UPDATES = 0;
UPDATE age
SET tract = RIGHT(geoid20, 6);
SET SQL_SAFE_UPDATES = 1;
ALTER TABLE age
DROP COLUMN geoid20;

-- Create table that joins tracts2 and age tables
CREATE TABLE age_neighborhood AS
SELECT 	t.Neighborhood, a.year, SUM(a.denom_total_pop) AS denom_total_pop, SUM(a.pop_under_age_18_count) AS pop_under_age_18_count,
		SUM(a.pop_ages_18_24_count) AS pop_ages_18_24_count, SUM(a.pop_ages_25_34_count) AS pop_ages_25_34_count, 
        SUM(a.pop_ages_35_44_count) AS pop_ages_35_44_count, SUM(a.pop_ages_45_54_count) AS pop_ages_45_54_count,
        SUM(a.pop_ages_55_64_count) AS pop_ages_55_64_count, SUM(a.pop_ages_65_older_count) AS pop_ages_65_older_count
FROM tracts2 t INNER JOIN age a
ON t.tract = a.tract
GROUP BY t.Neighborhood, a.year;

-- View age_neighborhood table
SELECT * FROM age_neighborhood
ORDER BY Neighborhood, year;



-- Import "poverty" table and preview data
SELECT * FROM poverty LIMIT 50;

-- Create new column "tract" in poverty, assign six right-most digits from "geoid20" as "tract", and drop column "geoid20"
ALTER TABLE poverty
ADD COLUMN tract bigint AFTER geoid20;
SET SQL_SAFE_UPDATES = 0;
UPDATE poverty
SET tract = RIGHT(geoid20, 6);
SET SQL_SAFE_UPDATES = 1;
ALTER TABLE poverty
DROP COLUMN geoid20;

-- Create table that joins tracts2 and poverty tables
CREATE TABLE poverty_neighborhood AS
SELECT 	t.Neighborhood, p.year, SUM(p.denom_known_poverty) AS denom_known_poverty, SUM(p.pop_below_100_count) AS pop_below_100_count, 
		SUM(p.pop_below_200_count) AS pop_below_200_count
FROM tracts2 t INNER JOIN poverty p
ON t.tract = p.tract
GROUP BY t.Neighborhood, p.year;

-- View poverty_neighborhood table
SELECT * FROM poverty_neighborhood
ORDER BY Neighborhood, year;



-- Import "crime" table and preview data
SELECT * FROM crime LIMIT 50;

-- Create new column "tract" in crime, assign six right-most digits from "geoid20" as "tract", and drop column "geoid20"
ALTER TABLE crime
ADD COLUMN tract bigint AFTER geoid20;
SET SQL_SAFE_UPDATES = 0;
UPDATE crime
SET tract = RIGHT(geoid20, 6);
SET SQL_SAFE_UPDATES = 1;
ALTER TABLE crime
DROP COLUMN geoid20;

-- Create table that joins tracts2 and crime tables
CREATE TABLE crime_neighborhood AS
SELECT 	t.Neighborhood, c.year, SUM(c.denom_total_pop) AS denom_total_pop, SUM(c.all_crime_count) AS all_crime_count, 
SUM(c.parti_violent_count) AS parti_violent_count,SUM(c.parti_property_count) AS parti_property_count, SUM(c.partii_count) AS partii_count
FROM tracts2 t INNER JOIN crime c
ON t.tract = c.tract
GROUP BY t.Neighborhood, c.year;

-- View crime_neighborhood table
SELECT * FROM crime_neighborhood
ORDER BY Neighborhood, year;



-- Import "business" table and preview data
SELECT * FROM business LIMIT 50;

-- Create new column "tract" in business, assign six right-most digits from "geoid20" as "tract", and drop column "geoid20"
ALTER TABLE business
ADD COLUMN tract bigint AFTER geoid20;
SET SQL_SAFE_UPDATES = 0;
UPDATE business
SET tract = RIGHT(geoid20, 6);
SET SQL_SAFE_UPDATES = 1;
ALTER TABLE business
DROP COLUMN geoid20;

-- Create table that joins tracts2 and business tables
CREATE TABLE business_neighborhood AS
SELECT 	t.Neighborhood, b.year, SUM(b.total_active_business_count) AS active_businesses, SUM(b.businesses_started) AS businesses_started,
		SUM(b.businesses_stopped) AS businesses_closed
FROM tracts2 t INNER JOIN business b
ON t.tract = b.tract
GROUP BY t.Neighborhood, b.year;

-- View business_neighborhood table
SELECT * FROM business_neighborhood
ORDER BY Neighborhood, year;