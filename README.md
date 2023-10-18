## Maximizing Confidence in Your Data Model Changes with dbt and PipeRider

This project covers an introduction to Piperide and its relevance in capturing data changes.
This project builds on the dbt project created by data talks club  [week_4_analytics](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/week_4_analytics_engineering)


This workshop project will run you through the following steps:

### PipeRider Walkthrough

- Piperider overview
- Initialize PipeRider inside a dbt project
- Run PipeRider to create a data report
- Compare data reports
- Use a compare recipe
- Define dbt metrics and view in report
- Compare dbt metrics


## Prequisites

- Ideally, you have completed the [Week 4 module on Analytics Engineering](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/week_4_analytics_engineering) of the DataTalksClub [Data Engineering Zoomcamp](https://github.com/DataTalksClub/data-engineering-zoomcamp)
- A basic understanding of [dbt](https://docs.getdbt.com/)
- Install, or update to, [DuckDB](https://duckdb.org/#quickinstall) 0.7.0

## what is piperider
Piperider is an open-source data impact analysis tool,specifically during pull request for dbt projects.

PipeRider compares the data in your dbt project from before and after making data modeling changes and generates Impact Reports and Summaries.

Impact reports are HTML reports that contains the following:
- data profile diff-A detailed comparison of data profile statistics about your data.
- Lineage Diff - A visualization in the form of a directed acyclic graph (DAG) that shows the impact to the data pipeline after changes.
- Metrics diff - A graph-based comparison of how dbt metrics have been impacted.

:dart:The goal is to generate impact summary that compares development and production environments and give and use the summary in our PR.This helps the peple reviewing the code to easily see the changes that have been made.
## Workshop Steps

### 1. Initial setup

1. Fork this repo
   ```
   https://github.com/InfuseAI/taxi_rides_ny_duckdb/tree/main
   ```
2. Clone your forked repo

    ```bash
	git clone <your-repo-url>
 	cd taxi_rides_ny_duckdb
   ```

3. Download the DuckDB database file

	```bash
	wget https://dtc-workshop.s3.ap-northeast-1.amazonaws.com/nyc_taxi.duckdb
	``` 
4. Set up a new venv

	```bash
	python -m venv ./venv
	source ./venv/Scripts/activate
	```
5. Update pip and install the neccessary dbt packages and PipeRider

	```bash
	pip install -U pip
	pip install dbt-core dbt-duckdb 'piperider[duckdb]'
	```
6. Create a new branch to work on and switch to it

	```bash
	git branch data-modeling

	git checkout data-modelling
	```
	
7. Install dbt deps and build dbt models

	```bash
	dbt deps
	dbt build
	```
	
8. Initialize PipeRider

	```bash
	piperider init
	```
	
9.  Check PipeRider settings

	```bash
	piperider diagnose
	```
	
### 2. Run PipeRider and data model changes
	
1. Run PipeRider

	```bash
	piperider run
	```
	
	PipeRider will profile the database and output the path to your data report, e.g.
	
	```
	Generating reports from: /project/path/.piperider/outputs/latest/run.json
	Report generated in /project/path/.piperider/outputs/latest/index.html
	```
	
	View the HTML report to see the full statistical report of your data source.
	
2. Make data model changes (move statistics to their own model)

	a. Create a new model `models/core/dm_monthly_zone_statistics.sql`

	```sql
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
	```

	b. Comment out lines 26-28 of `models/core/dm_monthly_zone_revenue.sql`
	
	```sql
	-- Additional calculations
	-- count(tripid) as total_monthly_trips,
	-- avg(passenger_count) as avg_montly_passenger_count,
	-- avg(trip_distance) as avg_montly_trip_distance
	```
    c. Create a new model `models/core/average_trip_distance.sql`
   ```sql
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
   ```




3. Rebuild the dbt models

	```bash
	dbt build
	```
	
4. Run PipeRider again to generate the second data report with the new models

	```bash
	piperider run
	```
	
5. Use the `compare-reports` function to compare the data profile reports

	```bash
	piperider compare-reports --last
	```
	
	The `compare-reports` outputs two files:
	- Comparison report: An HTML report comparing the two data profiles
	- Comparison summary: A Markdown file with a summary of changes.

	The comparison summary markdown is used to insert into a pull request (PR) comment in a later step.
	
6. Commit your changes and push your branch

	```bash
	git add .
	git commit -m "Added statistics model and average distance trip model, updated revenue model"
	git push origin data-modeling
	```
	
7. Create a pull request.

	a. Visit your repo on GitHub and clck `Compare & pull request`
	
	b. Copy the contents of the comparison summary Markdown file into your pull request comment box
	
	c. Click `preview` to see how the comparison looks 
	
	d. Click `Create pull request` to submit your changes
	
	
### 3. PipeRider Compare Recipe

In the above example we used the `compare-reports` command. PipeRider also has a separate `compare` command that uses the concept of compare 'recipes'. Recipes are a powerful way to define the specifics of how the compare will run, such as:

- The branches to compare
- The datasource/target to compare
- The dbt commands to run prior to the compare

When PipeRider is initialized a default compare recipe is created. For our project this looks like:

```yaml
base:
  branch: main
  dbt:
    commands:
    - dbt deps
    - dbt build
  piperider:
    command: piperider run
target:
  branch: data-modeling
  dbt:
    commands:
    - dbt deps
    - dbt build
  piperider:
    command: piperider run
```

Run the following command to run the above recipe:

```bash
piperider compare
```

As per the recipe, PipeRider will **automatically** do the following:

1. Check out the `main` branch
2. Build the models
3. Run PipeRider
4. Check out the `data-modeling` branch
4. Build the models
5. Run PipeRider
6. Compare the data reports of `main` and `data-modeling`
7. Output the compare report and summary


## PipeRider resources:
- Learn more about PipeRider [in the docs](https://docs.piperider.io)
- Visit the PipeRider [homepage](https://piperider.io)
- Join the PipeRider [Discord](https://discord.gg/328QcXnkKD) for help and discussion
- Read the PipeRider [blog](https://blog.piperider.io) for articles about PipeRider