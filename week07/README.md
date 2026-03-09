# Week 07 — EV Charging Lane Pilot Location Selection

## Overview
This solution identifies the four best 10-mile highway segments for piloting
an in-motion charging lane technology along two distinct Midwest highway corridors:
I-70 between St. Louis and Kansas City, and the STL-Chicago corridor via
I-55, I-57, I-64, and I-80.

The selection balances demand, technical feasibility, safety, and strategic
pilot value using two programming paradigms.

## How to Run
### Prerequisites
- Databricks workspace with Unity Catalog
- Python 3.x with PySpark

### Step 1 — Generate Source Data
Run notebook 01_generate_data. Creates seven Delta tables in your default schema:
road_segments, traffic_counts, power_infra, interchanges, env_constraints, weather_risk, and incidents.

### Step 2 — Score All Segments
Run notebook 02_score_segments. Executes a declarative SQL pipeline using CTEs
to score all 103 segments across nine dimensions and saves results as segment_scores.

### Step 3 — Select Pilot Locations
Run notebook 03_select_pilots. Applies a diversity-constrained selection algorithm
to pick the four best pilots and saves them as pilot_recommendations.

## Scoring Weights
| Dimension | Weight | Notes |
|-----------|--------|-------|
| EV Demand | 20% | Daily EV vehicle count |
| Crash Safety | 15% | Inverted crash rate per mile |
| Power Infrastructure | 12% | Distance to nearest substation |
| Road Geometry | 10% | Straightness score |
| Weather Safety | 10% | Inverted winter risk score |
| Interchange Density | 10% | Fewer interchanges = better |
| Pilot Visibility | 8% | AADT as proxy for public exposure |
| Environmental | 8% | Distance from wetlands/protected areas |
| Speed Suitability | 7% | Optimal band 60-75 mph |

## Programming Paradigms

### Imperative (Python)
Used for data generation and pilot selection. Both require explicit
ordered steps and stateful logic that SQL cannot express naturally.
Data generation builds each segment in order using position-dependent calculations.
Pilot selection iterates through candidates and checks each one against
previously selected sites for distance and corridor diversity.

### Declarative (SQL)
Used for scoring all 103 segments. SQL CTEs describe what each scoring
dimension should look like without specifying how to compute it row by row.
The query engine handles execution. Each CTE layer is independently testable.

## Assumptions
- Source data is synthetic, generated to match assignment schema and value ranges
- Substation proximity uses equirectangular approximation for distance
- Minimum 30-mile separation enforced between selected pilot sites
- One pilot per corridor enforced to ensure geographic diversity