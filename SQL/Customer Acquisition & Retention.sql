-- Cohort Analysis (Customer Retention)
WITH customer_cohorts AS (
    SELECT 
        CustomerID,
        CONVERT(DATE, EOMONTH(MIN(InvoiceDate), -1)) as CohortMonth,
        DATEDIFF(MONTH, MIN(InvoiceDate), InvoiceDate) as MonthsSinceAcquisition,
        SUM(Revenue) as CohortRevenue
    FROM transactions
    GROUP BY CustomerID, DATEDIFF(MONTH, MIN(InvoiceDate), InvoiceDate), 
             CONVERT(DATE, EOMONTH(MIN(InvoiceDate), -1))
)
SELECT 
    CohortMonth,
    MonthsSinceAcquisition,
    COUNT(DISTINCT CustomerID) as CustomersRetained,
    ROUND(SUM(CohortRevenue), 2) as CohortRevenue,
    ROUND(AVG(CohortRevenue), 2) as AvgCustomerValue
FROM customer_cohorts
WHERE MonthsSinceAcquisition <= 12
GROUP BY CohortMonth, MonthsSinceAcquisition
ORDER BY CohortMonth DESC, MonthsSinceAcquisition ASC;