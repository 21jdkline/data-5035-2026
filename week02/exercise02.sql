-- Get row count and basic table structure
SELECT COUNT(*) as total_records 
FROM data5035.spring26.donations;

-- View sample records 
SELECT * 
FROM data5035.spring26.donations 
LIMIT 10;

-- Explore NAME field - check for inconsistencies
SELECT 
    NAME,
    CASE WHEN CONTAINS(NAME, ',') THEN 'Last, First' ELSE 'First Last' END as name_format
FROM data5035.spring26.donations
LIMIT 20;

-- Check name format distribution
SELECT 
    CASE WHEN CONTAINS(NAME, ',') THEN 'Last, First' ELSE 'First Last' END as name_format,
    COUNT(*) as count
FROM data5035.spring26.donations
GROUP BY name_format;

-- Explore ZIP code field - check for issues
SELECT 
    ZIP,
    LENGTH(ZIP::VARCHAR) as zip_length,
    STATE
FROM data5035.spring26.donations
WHERE LENGTH(ZIP::VARCHAR) < 5
ORDER BY zip_length;

-- Explore CATEGORY field - identify missing/unclear values
SELECT 
    CATEGORY,
    COUNT(*) as count
FROM data5035.spring26.donations
GROUP BY CATEGORY
ORDER BY count DESC;

-- Check for NULL and blank categories
SELECT 
    COUNT(*) as total_unclear_categories
FROM data5035.spring26.donations
WHERE CATEGORY IS NULL 
   OR TRIM(CATEGORY) = '' 
   OR CATEGORY = 'N/A' 
   OR CATEGORY = 'Unknown';

-- Explore PHONE field - check format variations
SELECT 
    PHONE,
    LENGTH(PHONE) as phone_length,
    CASE 
        WHEN CONTAINS(PHONE, 'x') OR CONTAINS(PHONE, 'X') THEN 'Has Extension'
        WHEN CONTAINS(PHONE, '.') THEN 'Dot Format'
        WHEN CONTAINS(PHONE, '(') THEN 'Parentheses Format'
        ELSE 'Dash Format'
    END as phone_format
FROM data5035.spring26.donations
LIMIT 20;

-- Explore AMOUNT field - check for outliers
SELECT 
    MIN(AMOUNT) as min_amount,
    MAX(AMOUNT) as max_amount,
    AVG(AMOUNT) as avg_amount,
    MEDIAN(AMOUNT) as median_amount
FROM data5035.spring26.donations;

-- Find extreme amounts
SELECT 
    NAME,
    AMOUNT,
    PHONE
FROM data5035.spring26.donations
WHERE AMOUNT > 10000
ORDER BY AMOUNT DESC;


SELECT
    DONATION_ID,
    NAME,
    AGE,
    DATE_OF_BIRTH,
    STREET_ADDRESS,
    CITY,
    STATE,
    ZIP,
    PHONE,
    CATEGORY,
    ORGANIZATION,
    AMOUNT,
    
/**
DQ Check #1: Inconsistent Name Formats
Names should follow a consistent format across the dataset.  In my previous career this was a major issue when undergoing routing projects. 
, customer mailer campaigns, and organizing sales blitzes for instance. This flags records using the "Last, First" format which 
represents 45% of the dataset.
**/
    CASE 
        WHEN CONTAINS(NAME, ',') THEN 1 
        ELSE 0 
    END AS dq_reversed_name_format,
    
/**
DQ Check #2: Truncated ZIP Codes
ZIP codes should be 5 digits for proper geographic analysis and postal routing.Truncated ZIPs (things as simple as excel 
auto formatting in my experience) prevent accurate geographic mapping, can lead to incorrect data (zip 06780 is in New York,
where 67801 is Dodge City Kansas)  This affects approximately 5.5% of records and is especially problematic for New England 
and northeastern states.
**/
    CASE 
        WHEN LENGTH(ZIP::VARCHAR) < 5 THEN 1 
        ELSE 0 
    END AS dq_truncated_zip,
    
/**
DQ Check #3: Unclear/Missing Categories
Category field should contain meaningful (and unambiguous) values to support donor segmentation,
and campaign targeting, (double down on marketing efforts to people aged 65-80 in Kansas for instance) 
and impact reporting. Records with NULL, blank strings, 'N/A', or 'Unknown' values (31.5% of dataset)
cannot be properly categorized for analytics thus preventing optimization across the organization.
**/
    CASE 
        WHEN CATEGORY IS NULL 
            OR TRIM(CATEGORY) = '' 
            OR CATEGORY = 'N/A' 
            OR CATEGORY = 'Unknown' 
        THEN 1 
        ELSE 0 
    END AS dq_unclear_category,
    
/**DQ Check #4: Inconsistent Phone Number Formats
Phone numbers should follow a standardized format to enable automated dialing in CRM software (something I wish I had
when I was sales), to text campaigns, and porting data from one system to another (download from billing system to populate SalesForce
or Databricks for instance). The dataset contains at least 4 different formats (dash-separated, dot-separated, parentheses, and
extensions with 'x'). This check flags phone numbers with extensions, which represent 22% of records and may indicate incorrect data entry
or business lines rather than personal contact numbers suitable for donor outreach.
**/
    CASE 
        WHEN CONTAINS(PHONE, 'x') OR CONTAINS(PHONE, 'X') THEN 1 
        ELSE 0 
    END AS dq_phone_has_extension,
    
/**
DQ Check #5: Extreme Outlier Donation Amounts
Donation amounts should be reviewed for data entry errors. Using statistical outlier detection (values > Q3 + 3*IQR, where IQR ≈ 230),
we identify amounts over $10,000 as potential errors. The dataset contains 8 donations ranging from $1.4M to $4.9M - amounts that are
way outside the median.These likely represent data entry errors (e.g., decimal point misplacement or duplicate digits) and should be 
validated before financial reporting. In addition, they may need to be categorized permanently as "High Value Donation" so they can be 
easily removed from reporting that they may skew in marketing campaigns. 
**/
    CASE 
        WHEN AMOUNT > 1000 THEN 1 
        ELSE 0 
    END AS dq_extreme_amount

FROM 
    data5035.spring26.donations;


/**
SUMMARY OF DATA QUALITY FINDINGS

This donations dataset contains systematic quality issues affecting nearly every field except 
DONATION_ID. 

KEY FINDINGS:

1. NAME CONSISTENCY - Mixed formatting between "First Last" and "Last, First" 
   creates challenges for mail merge, deduplication, and CRM integration.

2. GEOGRAPHIC DATA INTEGRITY - ZIP codes missing leading zeros prevent accurate 
   geographic mapping and demographic overlays. 

3. CATEGORICAL DATA QUALIT - Nearly one-third of records have unclear categories 
   (NULL, blank, 'N/A', 'Unknown'), preventing donor segmentation and campaign targeting.

4. CONTACT INFORMATION - Multiple phone formats with extensions suggest business 
   lines rather than personal contact numbers suitable for donor outreach.

5. FINANCIAL DATA ANOMALIES- 8 donations between $1.4M-$4.9M with 
   a median of only $259. These are likely errors that could have lasting impacts.

BUSINESS IMPACT:

The most critical issues are the extreme donation amounts (potentially $14M+ in erroneous financial 
data) and unclear categories (limiting records from meaningful analysis). These quality 
issues require input validation at data entry (approvals for amounts above 10k BEFORE they are input for instance)
, automated quality checks before production loads, and regular auditing of outlier values.
**/