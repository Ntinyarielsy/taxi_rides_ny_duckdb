{{ config(materialized='table') }}

with trips_data as (
select * from {{ ref('fact_trips') }}
)
select
-- Reveneue grouping
pickup_zone as revenue_zone,
EXTRACT(MONTH FROM pickup_datetime) AS revenue_month,

service_type,

-- Additional calculations
count(tripid) as total_monthly_trips,
avg(passenger_count) as avg_montly_passenger_count,
avg(trip_distance) as avg_montly_trip_distance

from trips_data
group by 1,2,3