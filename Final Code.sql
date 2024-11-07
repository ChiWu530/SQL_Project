WITH county AS (
  SELECT 
    SUBSTRING(poi_cbg, 1, 5) AS full_fips, 
    COUNT(DISTINCT street_address) AS numbers
  FROM `team18-fa24-mgmt58200-final.team18data.visits`
  WHERE safegraph_brand_ids = "SG_BRAND_4a453a402f10c481d2fe4cefaa1d2b09"
  GROUP BY full_fips
),
--income index
income AS (
  SELECT 
    SUBSTRING(cbg, 1, 5) AS full_fips,  
    SUM(
      (inc_lt10 * 7.5) +   -- Use midpoint to calculate the total income number
      (`inc_10-15` * 12.5) +  
      (`inc_15-20` * 17.5) + 
      (`inc_20-25` * 22.5) + 
      (`inc_25-30` * 27.5) + 
      (`inc_30-35` * 32.5) + 
      (`inc_35-40` * 37.5) + 
      (`inc_40-45` * 42.5) + 
      (`inc_45-50` * 47.5) + 
      (`inc_50-60` * 55) + 
      (`inc_60-75` * 67.5) + 
      (`inc_75-100` * 87.5) + 
      (`inc_100-125` * 112.5) + 
      (`inc_125-150` * 137.5) + 
      (`inc_150-200` * 175) + 
      (inc_gte200 * 200)  -- Assuming $200k for >200k range
    ) / NULLIF(inc_total, 0) AS average_income  -- Use `inc_total` as the denominator
  FROM `team18-fa24-mgmt58200-final.team18data.cbg_demographics`
  GROUP BY full_fips, inc_total
),
--age index
age AS (
  SELECT 
    SUBSTRING(cbg, 1, 5) AS full_fips,  
    SUM(
      (`pop_m_10-14` * 12) +  --Use the midpoint to calculate the total age number
      (`pop_m_15-17` * 16) +  
      (`pop_m_18-19` * 18.5) +  
      (pop_m_20 * 20) +  
      (pop_m_21 * 21) +  
      (`pop_m_22-24` * 23) +  
      (`pop_m_25-29` * 27) +  
      (`pop_m_30-34` * 32) +  
      (`pop_m_35-39` * 37) +  
      (`pop_m_40-44` * 42) +  
      (`pop_m_45-49` * 47) +  
      (`pop_m_50-54` * 52) +  
      (`pop_m_55-59` * 57) +  
      (`pop_m_60-61` * 60.5) +  
      (`pop_m_62-64` * 63) +  
      (`pop_m_65-66` * 65.5) + 
      (`pop_m_67-69` * 68) +  
      (`pop_m_70-74` * 72) +  
      (`pop_m_75-79` * 77) +  
      (`pop_m_80-84` * 82) +  
      (pop_m_gte85 * 90) +  
      (`pop_f_lt5` * 2.5) +  
      (`pop_f_5-9` * 7) + 
      (`pop_f_10-14` * 12) + 
      (`pop_f_15-17` * 16) + 
      (`pop_f_18-19` * 18.5) + 
      (pop_f_20 * 20) + 
      (pop_f_21 * 21) +
      (`pop_f_22-24` * 23) + 
      (`pop_f_25-29` * 27) +  
      (`pop_f_30-34` * 32) +  
      (`pop_f_35-39` * 37) +  
      (`pop_f_40-44` * 42) +  
      (`pop_f_45-49` * 47) +  
      (`pop_f_50-54` * 52) +  
      (`pop_f_55-59` * 57) +  
      (`pop_f_60-61` * 60.5) + 
      (`pop_f_62-64` * 63) +  
      (`pop_f_65-66` * 65.5) +  
      (`pop_f_67-69` * 68) +  
      (`pop_f_70-74` * 72) + 
      (`pop_f_75-79` * 77) +  
      (`pop_f_80-84` * 82) +  
      (pop_f_gte85 * 90)  
    ) / NULLIF(pop_total, 0) AS average_age 
  FROM `team18-fa24-mgmt58200-final.team18data.cbg_demographics`
  GROUP BY full_fips, pop_total
),


cbg_population AS (
  SELECT 
    SUBSTRING(cbg, 1, 5) AS full_fips,
    SUM(pop_total) AS total_population
  FROM `team18-fa24-mgmt58200-final.team18data.cbg_demographics`
  GROUP BY full_fips
),

--Use the average of the top ten counties with lowest population/restaurant ratio (which mean the restaurant is more dense) as the current Panda Express customer demographic profolio 
dem_profile AS (SELECT 
  AVG(inc.average_income) AS avg_income_per_county,
  AVG(a.average_age) AS avg_age_per_county,
  cf.state, cf.county,
  cp.total_population / c.numbers AS ratio
FROM county AS c
JOIN cbg_population AS cp ON c.full_fips = cp.full_fips
JOIN `team18-fa24-mgmt58200-final.team18data.cbg_fips` AS cf 
  ON c.full_fips = CONCAT(cf.state_fips, cf.county_fips)  
JOIN income AS inc
ON cp.full_fips = inc.full_fips
JOIN age AS a
ON cp.full_fips = a.full_fips
GROUP BY cf.state, cf.county, cp.total_population, c.numbers
ORDER BY ratio
LIMIT 10
)

--Find average number of these counties as the demographic profile 
SELECT AVG(avg_income_per_county) AS income_index, AVG(avg_age_per_county) AS age_index
FROM dem_profile;

WITH county AS (
  SELECT 
    SUBSTRING(poi_cbg, 1, 5) AS full_fips, 
    COUNT(DISTINCT street_address) AS numbers
  FROM `team18-fa24-mgmt58200-final.team18data.visits`
  WHERE safegraph_brand_ids = "SG_BRAND_4a453a402f10c481d2fe4cefaa1d2b09"
  GROUP BY full_fips
),
income AS (
  SELECT 
    SUBSTRING(cbg, 1, 5) AS full_fips,  -- Extract county FIPS code
    SUM(
      (inc_lt10 * 7.5) +   -- Midpoint for <10k range
      (`inc_10-15` * 12.5) +  -- Midpoint for 10-15k
      (`inc_15-20` * 17.5) + 
      (`inc_20-25` * 22.5) + 
      (`inc_25-30` * 27.5) + 
      (`inc_30-35` * 32.5) + 
      (`inc_35-40` * 37.5) + 
      (`inc_40-45` * 42.5) + 
      (`inc_45-50` * 47.5) + 
      (`inc_50-60` * 55) + 
      (`inc_60-75` * 67.5) + 
      (`inc_75-100` * 87.5) + 
      (`inc_100-125` * 112.5) + 
      (`inc_125-150` * 137.5) + 
      (`inc_150-200` * 175) + 
      (inc_gte200 * 200)  -- Assuming $200k for >200k range
    ) / NULLIF(inc_total, 0) AS average_income  -- Use `inc_total` as the denominator
  FROM `team18-fa24-mgmt58200-final.team18data.cbg_demographics`
  GROUP BY full_fips, inc_total
),
age AS (
  SELECT 
    SUBSTRING(cbg, 1, 5) AS full_fips,  
    SUM(
      (`pop_m_10-14` * 12) +  
      (`pop_m_15-17` * 16) +  
      (`pop_m_18-19` * 18.5) +  
      (pop_m_20 * 20) +  
      (pop_m_21 * 21) +  
      (`pop_m_22-24` * 23) +  
      (`pop_m_25-29` * 27) +  
      (`pop_m_30-34` * 32) +  
      (`pop_m_35-39` * 37) +  
      (`pop_m_40-44` * 42) +  
      (`pop_m_45-49` * 47) +  
      (`pop_m_50-54` * 52) +  
      (`pop_m_55-59` * 57) +  
      (`pop_m_60-61` * 60.5) +  
      (`pop_m_62-64` * 63) +  
      (`pop_m_65-66` * 65.5) + 
      (`pop_m_67-69` * 68) +  
      (`pop_m_70-74` * 72) +  
      (`pop_m_75-79` * 77) +  
      (`pop_m_80-84` * 82) +  
      (pop_m_gte85 * 90) +  
      (`pop_f_lt5` * 2.5) +  
      (`pop_f_5-9` * 7) + 
      (`pop_f_10-14` * 12) + 
      (`pop_f_15-17` * 16) + 
      (`pop_f_18-19` * 18.5) + 
      (pop_f_20 * 20) + 
      (pop_f_21 * 21) +
      (`pop_f_22-24` * 23) + 
      (`pop_f_25-29` * 27) +  
      (`pop_f_30-34` * 32) +  
      (`pop_f_35-39` * 37) +  
      (`pop_f_40-44` * 42) +  
      (`pop_f_45-49` * 47) +  
      (`pop_f_50-54` * 52) +  
      (`pop_f_55-59` * 57) +  
      (`pop_f_60-61` * 60.5) + 
      (`pop_f_62-64` * 63) +  
      (`pop_f_65-66` * 65.5) +  
      (`pop_f_67-69` * 68) +  
      (`pop_f_70-74` * 72) + 
      (`pop_f_75-79` * 77) +  
      (`pop_f_80-84` * 82) +  
      (pop_f_gte85 * 90)  
    ) / NULLIF(pop_total, 0) AS average_age 
  FROM `team18-fa24-mgmt58200-final.team18data.cbg_demographics`
  GROUP BY full_fips, pop_total
),
cbg_population AS (
  SELECT 
    SUBSTRING(cbg, 1, 5) AS full_fips,
    SUM(pop_total) AS total_population
  FROM `team18-fa24-mgmt58200-final.team18data.cbg_demographics`
  GROUP BY full_fips
),
-- there is no visit data in jan
feb_visits AS (
  SELECT 
    SUBSTRING(poi_cbg, 1, 5) AS full_fips,  
    SUM(raw_visitor_counts) AS feb_visitors
  FROM `team18-fa24-mgmt58200-final.team18data.visits`
  WHERE FORMAT_TIMESTAMP("%Y-%m", date_range_end) = '2020-02'
    AND safegraph_brand_ids = "SG_BRAND_4a453a402f10c481d2fe4cefaa1d2b09"
  GROUP BY full_fips
),
may_visits AS (
  SELECT 
    SUBSTRING(poi_cbg, 1, 5) AS full_fips,  
    SUM(raw_visitor_counts) AS may_visitors
  FROM `team18-fa24-mgmt58200-final.team18data.visits`
  WHERE FORMAT_TIMESTAMP("%Y-%m", date_range_end) = '2020-05'
    AND safegraph_brand_ids = "SG_BRAND_4a453a402f10c481d2fe4cefaa1d2b09"
  GROUP BY full_fips
)

SELECT 
  cf.state, cf.county,
  COALESCE(feb_visits.feb_visitors, 0) AS feb_visitors,
  COALESCE(may_visits.may_visitors, 0) AS may_visitors,
  COALESCE(may_visits.may_visitors, 0) - COALESCE(feb_visits.feb_visitors, 0) AS visitor_difference,
  cp.total_population / c.numbers AS ratio,
  AVG(inc.average_income) - 61.2294514666073 AS income_difference,
  AVG(a.average_age)-38.846217052179739 AS age_difference,
  c.numbers
FROM county AS c
JOIN cbg_population AS cp ON c.full_fips = cp.full_fips
JOIN `team18-fa24-mgmt58200-final.team18data.cbg_fips` AS cf 
  ON c.full_fips = CONCAT(cf.state_fips, cf.county_fips)  
JOIN income AS inc ON cp.full_fips = inc.full_fips
JOIN age AS a
ON cp.full_fips = a.full_fips
LEFT JOIN feb_visits ON c.full_fips = feb_visits.full_fips
LEFT JOIN may_visits ON c.full_fips = may_visits.full_fips
GROUP BY cf.state, cf.county, cp.total_population, c.numbers, feb_visits.feb_visitors, may_visits.may_visitors
ORDER BY ratio DESC
LIMIT 10;
WITH county AS (
  SELECT 
    SUBSTRING(poi_cbg, 1, 5) AS full_fips, 
    COUNT(DISTINCT street_address) AS numbers
  FROM `team18-fa24-mgmt58200-final.team18data.visits`
  WHERE safegraph_brand_ids = "SG_BRAND_4a453a402f10c481d2fe4cefaa1d2b09"
  GROUP BY full_fips
),
income AS (
  SELECT 
    SUBSTRING(cbg, 1, 5) AS full_fips,  -- Extract county FIPS code
    SUM(
      (inc_lt10 * 7.5) +   -- Midpoint for <10k range
      (`inc_10-15` * 12.5) +  -- Midpoint for 10-15k
      (`inc_15-20` * 17.5) + 
      (`inc_20-25` * 22.5) + 
      (`inc_25-30` * 27.5) + 
      (`inc_30-35` * 32.5) + 
      (`inc_35-40` * 37.5) + 
      (`inc_40-45` * 42.5) + 
      (`inc_45-50` * 47.5) + 
      (`inc_50-60` * 55) + 
      (`inc_60-75` * 67.5) + 
      (`inc_75-100` * 87.5) + 
      (`inc_100-125` * 112.5) + 
      (`inc_125-150` * 137.5) + 
      (`inc_150-200` * 175) + 
      (inc_gte200 * 200)  -- Assuming $200k for >200k range
    ) / NULLIF(inc_total, 0) AS average_income  -- Use `inc_total` as the denominator
  FROM `team18-fa24-mgmt58200-final.team18data.cbg_demographics`
  GROUP BY full_fips, inc_total
),
age AS (
  SELECT 
    SUBSTRING(cbg, 1, 5) AS full_fips,  
    SUM(
      (`pop_m_10-14` * 12) +  
      (`pop_m_15-17` * 16) +  
      (`pop_m_18-19` * 18.5) +  
      (pop_m_20 * 20) +  
      (pop_m_21 * 21) +  
      (`pop_m_22-24` * 23) +  
      (`pop_m_25-29` * 27) +  
      (`pop_m_30-34` * 32) +  
      (`pop_m_35-39` * 37) +  
      (`pop_m_40-44` * 42) +  
      (`pop_m_45-49` * 47) +  
      (`pop_m_50-54` * 52) +  
      (`pop_m_55-59` * 57) +  
      (`pop_m_60-61` * 60.5) +  
      (`pop_m_62-64` * 63) +  
      (`pop_m_65-66` * 65.5) + 
      (`pop_m_67-69` * 68) +  
      (`pop_m_70-74` * 72) +  
      (`pop_m_75-79` * 77) +  
      (`pop_m_80-84` * 82) +  
      (pop_m_gte85 * 90) +  
      (`pop_f_lt5` * 2.5) +  
      (`pop_f_5-9` * 7) + 
      (`pop_f_10-14` * 12) + 
      (`pop_f_15-17` * 16) + 
      (`pop_f_18-19` * 18.5) + 
      (pop_f_20 * 20) + 
      (pop_f_21 * 21) +
      (`pop_f_22-24` * 23) + 
      (`pop_f_25-29` * 27) +  
      (`pop_f_30-34` * 32) +  
      (`pop_f_35-39` * 37) +  
      (`pop_f_40-44` * 42) +  
      (`pop_f_45-49` * 47) +  
      (`pop_f_50-54` * 52) +  
      (`pop_f_55-59` * 57) +  
      (`pop_f_60-61` * 60.5) + 
      (`pop_f_62-64` * 63) +  
      (`pop_f_65-66` * 65.5) +  
      (`pop_f_67-69` * 68) +  
      (`pop_f_70-74` * 72) + 
      (`pop_f_75-79` * 77) +  
      (`pop_f_80-84` * 82) +  
      (pop_f_gte85 * 90)  
    ) / NULLIF(pop_total, 0) AS average_age 
  FROM `team18-fa24-mgmt58200-final.team18data.cbg_demographics`
  GROUP BY full_fips, pop_total
),
cbg_population AS (
  SELECT 
    SUBSTRING(cbg, 1, 5) AS full_fips,
    SUM(pop_total) AS total_population
  FROM `team18-fa24-mgmt58200-final.team18data.cbg_demographics`
  GROUP BY full_fips
),
-- there is no visit data in jan
feb_visits AS (
  SELECT 
    SUBSTRING(poi_cbg, 1, 5) AS full_fips,  
    SUM(raw_visitor_counts) AS feb_visitors
  FROM `team18-fa24-mgmt58200-final.team18data.visits`
  WHERE FORMAT_TIMESTAMP("%Y-%m", date_range_end) = '2020-02'
    AND safegraph_brand_ids = "SG_BRAND_4a453a402f10c481d2fe4cefaa1d2b09"
  GROUP BY full_fips
),
may_visits AS (
  SELECT 
    SUBSTRING(poi_cbg, 1, 5) AS full_fips,  
    SUM(raw_visitor_counts) AS may_visitors
  FROM `team18-fa24-mgmt58200-final.team18data.visits`
  WHERE FORMAT_TIMESTAMP("%Y-%m", date_range_end) = '2020-05'
    AND safegraph_brand_ids = "SG_BRAND_4a453a402f10c481d2fe4cefaa1d2b09"
  GROUP BY full_fips
)

SELECT 
  cf.state, cf.county,
  COALESCE(feb_visits.feb_visitors, 0) AS feb_visitors,
  COALESCE(may_visits.may_visitors, 0) AS may_visitors,
  COALESCE(may_visits.may_visitors, 0) - COALESCE(feb_visits.feb_visitors, 0) AS visitor_difference,
  cp.total_population / c.numbers AS ratio,
  AVG(inc.average_income) - 61.2294514666073 AS income_difference,
  AVG(a.average_age)-38.846217052179739 AS age_difference,
  c.numbers
FROM county AS c
JOIN cbg_population AS cp ON c.full_fips = cp.full_fips
JOIN `team18-fa24-mgmt58200-final.team18data.cbg_fips` AS cf 
  ON c.full_fips = CONCAT(cf.state_fips, cf.county_fips)  
JOIN income AS inc ON c.full_fips = inc.full_fips
JOIN age AS a
ON c.full_fips = a.full_fips
LEFT JOIN feb_visits ON c.full_fips = feb_visits.full_fips
LEFT JOIN may_visits ON c.full_fips = may_visits.full_fips
GROUP BY cf.state, cf.county, cp.total_population, c.numbers, feb_visits.feb_visitors, may_visits.may_visitors
ORDER BY visitor_difference DESC
LIMIT 10;
