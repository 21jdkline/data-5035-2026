USE ROLE GIRAFFE_DATA5035_ROLE;
USE DATABASE DATA5035;
USE SCHEMA GIRAFFE;

-- Exercise 09C: Manufacturing Quality
-- Approach: SQL (Snowflake)


-- Setup tables

CREATE OR REPLACE TABLE batches (
    batch_id VARCHAR(10),
    product  VARCHAR(50),
    facility VARCHAR(50)
);

INSERT INTO batches VALUES
    ('B1', 'DrugA', 'Plant1'),
    ('B2', 'DrugA', 'Plant2'),
    ('B3', 'DrugB', 'Plant1');

CREATE OR REPLACE TABLE quality_tests (
    test_id   VARCHAR(10),
    batch_id  VARCHAR(10),
    test_type VARCHAR(50),
    result    VARCHAR(10)
);

INSERT INTO quality_tests VALUES
    ('T1', 'B1', 'purity',    'pass'),
    ('T2', 'B1', 'stability', 'fail'),
    ('T3', 'B2', 'purity',    'pass');

CREATE OR REPLACE TABLE deviations (
    deviation_id VARCHAR(10),
    batch_id     VARCHAR(10),
    description  VARCHAR(100)
);

INSERT INTO deviations VALUES
    ('D1', 'B1', 'temperature excursion');


-- Q1: Show all batches and their quality test results
-- Inner join — only B1 and B2 have tests, B3 drops off
SELECT b.batch_id, qt.test_type, qt.result
FROM batches b
INNER JOIN quality_tests qt ON qt.batch_id = b.batch_id;


-- Q2: Show all batches, including those without tests
-- Left join — B3 stays with NULLs for test columns
SELECT b.batch_id, qt.test_type, qt.result
FROM batches b
LEFT JOIN quality_tests qt ON qt.batch_id = b.batch_id;


-- Q3: Find batches with both a failed test AND a deviation
-- Inner join failed tests to deviations on batch_id
SELECT DISTINCT qt.batch_id
FROM quality_tests qt
INNER JOIN deviations d ON d.batch_id = qt.batch_id
WHERE qt.result = 'fail';


-- Q4: Batch-level counts of tests and deviations
-- Left join both, then count distinct to avoid inflation from the cross
SELECT b.batch_id,
       COUNT(DISTINCT qt.test_id) AS test_count,
       COUNT(DISTINCT d.deviation_id) AS deviation_count
FROM batches b
LEFT JOIN quality_tests qt ON qt.batch_id = b.batch_id
LEFT JOIN deviations d ON d.batch_id = b.batch_id
GROUP BY b.batch_id;


-- Q5: Find batches with no deviations
-- Anti-join
SELECT b.batch_id
FROM batches b
LEFT JOIN deviations d ON d.batch_id = b.batch_id
WHERE d.deviation_id IS NULL;
