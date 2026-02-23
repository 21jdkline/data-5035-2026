-- DATA 5035 - Exercise 06: Unit Testing in SQL
-- Jay Kline
-- Testing data quality checks from Exercise 02 (donations table)

USE SCHEMA data5035.giraffe;

-- CHECK 1: dq_reversed_name
-- From exercise 02: CASE WHEN CONTAINS(name, ',') THEN 1 ELSE 0 END
-- This flags names that look like "Last, First" format

CREATE OR REPLACE TEMPORARY TABLE test_reversed_name
    (name VARCHAR, expected INT NOT NULL);

INSERT INTO test_reversed_name VALUES
    ('Kline, Jay',       1),  -- clearly reversed
    ('Jay Kline',        0),  -- normal first-last
    ('Smith, John Jr.',  1),  -- reversed with a suffix
    ('Madonna',          0),  -- single name
    ('',                 0),  -- empty string
    (NULL,               0),  -- null
    ('O''Brien, Conan',  1),  -- apostrophe in last name
    ('Jay, Jr.',         1);  -- has a comma but isn't really "last, first" - still flags though


-- CHECK 2: dq_unclear_category
-- From exercise 02: flags NULL, blank, 'N/A', or 'Unknown' categories

CREATE OR REPLACE TEMPORARY TABLE test_unclear_category
    (category VARCHAR, expected INT NOT NULL);

INSERT INTO test_unclear_category VALUES
    (NULL,             1),  -- null
    ('',               1),  -- empty
    ('   ',            1),  -- just spaces, TRIM will make it empty
    ('N/A',            1),  -- not applicable
    ('Unknown',        1),  -- unknown
    ('Education',      0),  -- legit category
    ('Health',         0),  -- another legit one
    ('n/a',            0),  -- lowercase doesn't match (case sensitive!)
    ('unknown',        0),  -- same deal, lowercase
    ('N/A ',           0);  -- trailing space means it doesn't match 'N/A' exactly


-- CHECK 3: dq_phone_has_extension
-- From exercise 02: CASE WHEN CONTAINS(PHONE, 'x') OR CONTAINS(PHONE, 'X') THEN 1 ELSE 0 END

CREATE OR REPLACE TEMPORARY TABLE test_phone_extension
    (phone VARCHAR, expected INT NOT NULL);

INSERT INTO test_phone_extension VALUES
    ('555-123-4567',       0),  -- normal dash format
    ('(555) 123-4567',     0),  -- parentheses format
    ('555.123.4567',       0),  -- dot format
    ('555-123-4567 x100',  1),  -- lowercase x extension
    ('555-123-4567 X100',  1),  -- uppercase X extension
    ('555-123-4567x100',   1),  -- extension with no space
    (NULL,                 0),  -- null
    ('',                   0),  -- empty
    ('555-123-4567 ext 5', 1);  -- interesting one: 'ext' has an x in it so it flags too



-- CHECK 4: dq_extreme_amount
-- From exercise 02: CASE WHEN AMOUNT > 1000 THEN 1 ELSE 0 END
-- Anything over $1000 gets flagged as a possible data entry error


CREATE OR REPLACE TEMPORARY TABLE test_extreme_amount
    (amount NUMBER(12,2), expected INT NOT NULL);

INSERT INTO test_extreme_amount VALUES
    (50.00,         0),  -- typical small donation
    (259.00,        0),  -- around the median from the actual data
    (999.99,        0),  -- just under the cutoff
    (1000.00,       0),  -- right at 1000 (> not >=, so this should pass)
    (1000.01,       1),  -- one cent over
    (3460853.93,    1),  -- one of the real outliers from the dataset
    (4900000.00,    1),  -- biggest outlier we found
    (0.00,          0),  -- zero
    (-50.00,        0);  -- negative, like a refund


-- RUN ALL TESTS
-- Output: test_name, input_value, actual, expected, match (T/F)

SELECT
    'dq_reversed_name' AS test_name,
    name AS input_value,
    CASE WHEN CONTAINS(name, ',') THEN 1 ELSE 0 END AS actual,
    expected,
    actual = expected AS match
FROM test_reversed_name

UNION ALL

SELECT
    'dq_unclear_category',
    category,
    CASE
        WHEN category IS NULL
            OR TRIM(category) = ''
            OR category = 'N/A'
            OR category = 'Unknown'
        THEN 1 ELSE 0
    END AS actual,
    expected,
    actual = expected AS match
FROM test_unclear_category

UNION ALL

SELECT
    'dq_phone_has_extension',
    phone,
    CASE WHEN CONTAINS(phone, 'x') OR CONTAINS(phone, 'X') THEN 1 ELSE 0 END AS actual,
    expected,
    actual = expected AS match
FROM test_phone_extension

UNION ALL

SELECT
    'dq_extreme_amount',
    amount::VARCHAR,
    CASE WHEN amount > 1000 THEN 1 ELSE 0 END AS actual,
    expected,
    actual = expected AS match
FROM test_extreme_amount

ORDER BY test_name, input_value;
