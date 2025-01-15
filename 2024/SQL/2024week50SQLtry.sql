with inner_join as (
SELECT * FROM `preppindata-443311.preppindata2024week50.life_expectanry` le
LEFT OUTER JOIN `preppindata-443311.preppindata2024week50.countries_continents` cc
ON le.Entity = cc.country)

,countries_avg as (
  SELECT
    Continent,
    Country,
    Year,
    AVG(period_life_expectancy) as countries_avg
  FROM inner_join
  WHERE Year BETWEEN 1950 and 2020
  GROUP BY 
    Continent,
    Country,
    Year
)
,continents_avg as (
  SELECT
    Year,
    Entity as Continent,
    AVG(period_life_expectancy) as continents_avg
  FROM inner_join
  WHERE Year BETWEEN 1950 and 2020
  AND Code IS NULL
  GROUP BY 
    Year,
    Entity
)
,countries_continents_join as (
 SELECT 
  ct.Continent,
  ct.Country,
  ct.Year,
  ct.countries_avg,
  cn.continents_avg
 FROM countries_avg ct
 INNER JOIN continents_avg cn
 ON ct.Year = cn.Year
 AND ct.Continent = cn.Continent
)
,calc_add as(
  SELECT 
  *,
  if(countries_avg > continents_avg,1,0) as Flag,
  if(Year=1950,countries_avg,NULL) as avg1950,
  if(Year=2020,countries_avg,NULL) as avg2020
  FROM countries_continents_join
)
,agg_flag as (
  SELECT 
    Continent,
    Country,
    MIN(avg1950) as avg1950,
    MIN(avg2020) as avg2020,
    SUM(Flag) as sum_of_years,
    COUNT(*) as numberOfRow
  FROM calc_add
  GROUP BY
    Continent,
    Country
)
,percent_calc as (
  SELECT 
    Continent,
    Country,
    ROUND((sum_of_years/numberOfRow)*100,1)as PYearsAboveContinentAvg,
    ROUND(((avg2020 - avg1950)/avg1950)*100,1) as PChange
  FROM
  agg_Flag
)
,rank_calc as (
  SELECT
    RANK() over(partition by Continent order by PChange DESC) as PChange_rank,
    Continent,
    Country,
    PYearsAboveContinentAvg,
    PChange
  FROM percent_calc
)
,rank_filter as (
  SELECT
   Continent,
   Pchange_rank,
   Country,
   PYearsAboveContinentAvg,
   PChange
  FROM rank_calc
  WHERE PChange_rank <= 3
)
--検算
SELECT
  *
FROM
  (SELECT * FROM rank_filter EXCEPT DISTINCT SELECT * FROM `preppindata-443311.preppindata2024week50.2024week50answer`
)
UNION ALL
SELECT
  *
FROM
  (SELECT * FROM `preppindata-443311.preppindata2024week50.2024week50answer`
 EXCEPT DISTINCT SELECT * FROM rank_filter)