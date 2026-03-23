USE ROLE GIRAFFE_DATA5035_ROLE;
USE DATABASE DATA5035;
USE SCHEMA GIRAFFE;

-- Assignment 08: Serving Models — Manufacturing Production Cost Data
-- DATA-5035
-- Jay Kline



-- DELIVERABLE 1: BUS MATRIX
-- Cost per batch, cost per unit,
-- and variance from standard — by facility, product, and cost category.

/**

| Metric                     | Description                                         | Batch Date | Facility | Product | Cost Category | Batch |
|----------------------------|-----------------------------------------------------|------------|----------|---------|---------------|-------|
| Total Batch Cost           | Sum of all cost categories for a batch              | X          | X        | X       | X             | X     |
| Cost Per Unit Produced     | Total batch cost / units produced                   | X          | X        | X       |               | X     |
| Standard Cost Variance $   | Actual minus standard in dollars                    | X          | X        | X       | X             | X     |
| Standard Cost Variance %   | Variance as pct of standard cost                    | X          | X        | X       | X             | X     |
| Direct Material Cost       | Raw ingredient cost per batch                       | X          | X        | X       |               | X     |
| Direct Labor Cost          | Operator hours * rate per batch                     | X          | X        | X       |               | X     |
| Manufacturing Overhead     | Allocated overhead from line hours                  | X          | X        | X       |               | X     |
| QC Testing Cost            | Routine testing + any failure investigations        | X          | X        | X       |               | X     |

**/


-- DELIVERABLE 2: STAR SCHEMA

CREATE OR REPLACE TABLE DIM_DATE (
    date_key        INTEGER         NOT NULL PRIMARY KEY,  -- YYYYMMDD surrogate key
    full_date       DATE            NOT NULL,
    year            INTEGER         NOT NULL,
    quarter         INTEGER         NOT NULL,
    month           INTEGER         NOT NULL,
    month_name      VARCHAR(10)     NOT NULL,
    day_of_week     INTEGER         NOT NULL,
    day_name        VARCHAR(10)     NOT NULL,
    fiscal_year     INTEGER         NOT NULL,
    fiscal_quarter  INTEGER         NOT NULL,
    is_weekend      BOOLEAN         NOT NULL
);

-- Each site has its own overhead rate, shift rates, and cleanroom setup
CREATE OR REPLACE TABLE DIM_FACILITY (
    facility_key              INTEGER       NOT NULL PRIMARY KEY,
    facility_id               VARCHAR(20)   NOT NULL,
    facility_name             VARCHAR(100)  NOT NULL,
    city                      VARCHAR(50)   NOT NULL,
    state                     VARCHAR(2)    NOT NULL,
    facility_type             VARCHAR(50)   NOT NULL,       -- Solid Dose, Sterile Fill-Finish, Topical
    overhead_rate_per_hour    DECIMAL(10,2) NOT NULL,       -- $/hr for line time
    cleanroom_classification  VARCHAR(20),
    day_shift_rate            DECIMAL(10,2) NOT NULL,
    night_shift_rate          DECIMAL(10,2) NOT NULL,
    sterile_premium_pct       DECIMAL(5,2)  DEFAULT 0       -- Columbus gets 10%
);

CREATE OR REPLACE TABLE DIM_PRODUCT (
    product_key           INTEGER       NOT NULL PRIMARY KEY,
    product_id            VARCHAR(20)   NOT NULL,
    product_name          VARCHAR(100)  NOT NULL,
    dosage_form           VARCHAR(50)   NOT NULL,           -- Tablet, Sterile Drops, Ointment
    therapeutic_area      VARCHAR(50)   NOT NULL,
    standard_batch_size   INTEGER       NOT NULL,
    material_count        INTEGER       NOT NULL            -- how many raw materials in the formulation
);

-- Four categories: materials, labor, overhead, QC
CREATE OR REPLACE TABLE DIM_COST_CATEGORY (
    cost_category_key       INTEGER       NOT NULL PRIMARY KEY,
    category_code           VARCHAR(10)   NOT NULL,             -- MAT, LAB, OH, QC
    category_name           VARCHAR(50)   NOT NULL,
    is_direct_cost          BOOLEAN       NOT NULL,
    allocation_method       VARCHAR(100)  NOT NULL,             -- per unit consumed, per labor hour, per line hour, per test
    typical_cost_pct        DECIMAL(5,2)                        -- rough share of total batch cost, useful for benchmarking
);

-- Batch-level stuff that doesn't change per cost category
CREATE OR REPLACE TABLE DIM_BATCH (
    batch_key           INTEGER       NOT NULL PRIMARY KEY,
    batch_id            VARCHAR(20)   NOT NULL,
    batch_status        VARCHAR(20)   NOT NULL,             -- Released, Quarantined, Rejected
    production_date     DATE          NOT NULL,
    line_hours_actual   DECIMAL(6,2)  NOT NULL,
    line_hours_standard DECIMAL(6,2)  NOT NULL,
    units_produced      INTEGER       NOT NULL,
    yield_pct           DECIMAL(5,2)  NOT NULL,
    has_deviation       BOOLEAN       NOT NULL DEFAULT FALSE,
    deviation_count     INTEGER       NOT NULL DEFAULT 0,
    qc_hold_days        INTEGER       DEFAULT 0
);

-- Grain: one row per batch per cost category (so 4 rows per batch).
-- Sum actual_cost across all 4 rows to get total batch cost.
CREATE OR REPLACE TABLE FACT_BATCH_COST (
    batch_cost_key      INTEGER       NOT NULL PRIMARY KEY,
    date_key            INTEGER       NOT NULL REFERENCES DIM_DATE(date_key),
    facility_key        INTEGER       NOT NULL REFERENCES DIM_FACILITY(facility_key),
    product_key         INTEGER       NOT NULL REFERENCES DIM_PRODUCT(product_key),
    cost_category_key   INTEGER       NOT NULL REFERENCES DIM_COST_CATEGORY(cost_category_key),
    batch_key           INTEGER       NOT NULL REFERENCES DIM_BATCH(batch_key),

    -- measures
    actual_cost         DECIMAL(12,2) NOT NULL,
    standard_cost       DECIMAL(12,2) NOT NULL,
    variance_amount     DECIMAL(12,2) NOT NULL,             -- actual_cost - standard_cost
    driver_quantity     DECIMAL(10,2),                      -- depends on category: lbs, hours, line-hrs, test count
    units_produced      INTEGER       NOT NULL              -- repeated here for easy per-unit math
);


-- DELIVERABLE 3: REVERSE ETL ALERT TABLE
-- When a batch goes over its standard cost by more than a threshold (like the
-- CFO's 15% rule), a row gets written here with details in a JSON payload.
-- A reverse ETL process pushes these out to Slack, email, dashboards, etc.

CREATE OR REPLACE TABLE ALERT_COST_OVERRUN (
    alert_id            INTEGER         NOT NULL PRIMARY KEY,
    alert_timestamp     TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    batch_id            VARCHAR(20)     NOT NULL,
    facility_name       VARCHAR(100)    NOT NULL,
    product_name        VARCHAR(100)    NOT NULL,
    alert_type          VARCHAR(50)     NOT NULL,           -- COST_OVERRUN, QC_FAILURE_COST, OVERTIME_EXCESS
    severity            VARCHAR(10)     NOT NULL,           -- LOW, MEDIUM, HIGH, CRITICAL
    variance_pct        DECIMAL(7,2)    NOT NULL,
    alert_payload       VARIANT         NOT NULL,
    acknowledged        BOOLEAN         NOT NULL DEFAULT FALSE,
    acknowledged_by     VARCHAR(100),
    acknowledged_at     TIMESTAMP_NTZ
);

-- Example payload for B-10454 — the problem batch from the scenario.
-- Two QC failures, 14 hrs overtime rework, 13.5 hrs on the line vs 12 hr standard,
-- plus a 9-day cold-storage hold. Ended up ~28% over standard.

/*
{
  "alert_type": "COST_OVERRUN",
  "severity": "CRITICAL",
  "batch_id": "B-10454",
  "facility": "Columbus BioCenter",
  "product": "OptiClear Sterile Drops",
  "production_date": "2024-04-08",
  "threshold_pct": 15.0,
  "variance_pct": 28.3,
  "cost_summary": {
    "actual_total": 48720.00,
    "standard_total": 37980.00,
    "variance_total": 10740.00
  },
  "cost_breakdown": [
    {
      "category": "Direct Materials",
      "actual": 9850.00,
      "standard": 9200.00,
      "variance": 650.00,
      "note": "Sterile saline lot came in above standard pricing"
    },
    {
      "category": "Direct Labor",
      "actual": 12480.00,
      "standard": 8640.00,
      "variance": 3840.00,
      "note": "14 overtime hours for rework after QC failures, night shift at $52/hr + 10% sterile premium"
    },
    {
      "category": "Manufacturing Overhead",
      "actual": 16320.00,
      "standard": 13440.00,
      "variance": 2880.00,
      "note": "13.5 hrs on the line vs 12 hr standard at $320/hr, plus cold-storage holding costs from 9-day QA hold"
    },
    {
      "category": "QC Testing",
      "actual": 10070.00,
      "standard": 6700.00,
      "variance": 3370.00,
      "note": "Fill volume and assay failures triggered two investigations, ~$4k unplanned"
    }
  ]
}
*/