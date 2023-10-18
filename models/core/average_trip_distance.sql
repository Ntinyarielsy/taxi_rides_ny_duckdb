{{ config(materialized='table') }}

WITH trips AS (
  SELECT
    EXTRACT(MONTH FROM pickup_datetime) AS pickup_month,
    EXTRACT(quarter FROM pickup_datetime) AS pickup_quarter,
    EXTRACT(year FROM pickup_datetime) AS pickup_year,
    AVG(trip_distance) AS avg_trip_distance
  from {{ ref('fact_trips') }}
  
  GROUP BY pickup_month, pickup_quarter, pickup_year
)

SELECT
  pickup_month AS pickup_month,
  pickup_quarter AS pickup_quarter,
  pickup_year AS pickup_year,
  avg_trip_distance AS average_distance
FROM trips

    