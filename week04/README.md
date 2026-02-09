# Week 04 — SEC Winter Weather Impact

Analyzed how the January 2026 winter storms affected students across the 16 SEC universities. Combined enrollment data scraped from Wikipedia with daily weather pulled from the Open-Meteo API, then flagged severe days and calculated student-days impacted.

## Data Sources

**Enrollment** — Scraped from the [SEC Wikipedia page](https://en.wikipedia.org/wiki/Southeastern_Conference) (Fall 2023 numbers). Had to hardcode this into a placeholder DataFrame because Databricks serverless compute blocks outbound requests to Wikipedia. Working with the instructor to get it whitelisted. The scraping code is still in the notebook, just commented out.

**Weather** — [Open-Meteo API](https://open-meteo.com/). Pulled daily min/max temp, snowfall, rain, wind speed, wind gusts, and weather codes for all 16 campuses across January 2026.

## Severe Weather Definition

A day is flagged as severe if any of these are true:

- Min temp ≤ 20°F
- Snowfall ≥ 1 inch
- Wind gusts ≥ 40 mph

These thresholds are calibrated for the south. 20 degrees in Tuscaloosa is not the same as 20 degrees in Columbia — most SEC schools don't have the infrastructure for it.

## Results

Around 3.2 million student-days impacted across 15 of 16 SEC schools. Kentucky had the most severe days (18), Florida had zero. Missouri hit -6°F on January 26th. The Jan 23-27 storm window drove most of the impact.

## How to Run

1. Import `exercise04.ipynb` into Databricks
2. Run `%pip install beautifulsoup4`, then `%restart_python`, then imports
3. Run remaining cells top to bottom
4. Skip the commented-out Wikipedia scrape cell until access is fixed, tested it in a different IDe and it worked fine. 

## Databricks Note

Ran into a networking issue on serverless compute — Open-Meteo API works fine but Wikipedia fails with a DNS resolution error. Emailed the instructor about it. Built the placeholder table so the rest of the pipeline runs while that gets sorted out.

## Files

- `exercise04.ipynb` — Main notebook
- `README.md` — This file
