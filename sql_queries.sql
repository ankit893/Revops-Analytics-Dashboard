============================================================
-- REVOPS ANALYTICS DASHBOARD - COMPLETE SQL SCRIPT
============================================================
-- Author: Ankit Sharma
-- Dataset: Online Retail
-- Purpose: Revenue Operations Analytics
-- ============================================================

-- ============================================================
-- SECTION 1: DATABASE & TABLE SETUP
-- ============================================================

-- Create Database
CREATE DATABASE RevOpsAnalytics;

-- Use Database
USE RevOpsAnalytics;

-- Create Main Transactions Table
CREATE TABLE transactions (
    TransactionID INT PRIMARY KEY IDENTITY(1,1),
    InvoiceNo VARCHAR(10),
    InvoiceDate DATETIME,
    CustomerID INT,
    Quantity INT,
    UnitPrice DECIMAL(10,2),
    Country VARCHAR(50),
    Revenue DECIMAL(10,2)
);

-- Create Indexes for Performance
CREATE INDEX idx_InvoiceDate ON transactions(InvoiceDate);
CREATE INDEX idx_CustomerID ON transactions(CustomerID);
CREATE INDEX idx_Country ON transactions(Country);
CREATE INDEX idx_InvoiceNo ON transactions(InvoiceNo);

-- ============================================================
-- SECTION 2: VERIFICATION QUERIES
-- ============================================================

-- Check total rows loaded
SELECT COUNT(*) as TotalRows FROM transactions;

-- Check data quality
SELECT 
    COUNT(*) as TotalRecords,
    COUNT(DISTINCT InvoiceNo) as UniqueInvoices,
    COUNT(DISTINCT CustomerID) as UniqueCustomers,
    COUNT(DISTINCT Country) as UniqueCountries,
    MIN(InvoiceDate) as FirstDate,
    MAX(InvoiceDate) as LastDate,
    SUM(Revenue) as TotalRevenue,
    AVG(Revenue) as AvgRevenue,
    MIN(Revenue) as MinRevenue,
    MAX(Revenue) as MaxRevenue
FROM transactions;

-- ============================================================
-- SECTION 3: RFM CUSTOMER SEGMENTATION
-- ============================================================

-- RFM Analysis - Customer Segmentation
SELECT 
    CustomerID,
    MAX(InvoiceDate) as LastPurchaseDate,
    DATEDIFF(DAY, MAX(InvoiceDate), GETDATE()) as RecencyDays,
    COUNT(DISTINCT InvoiceNo) as PurchaseFrequency,
    SUM(Revenue) as MonetaryValue,
    ROUND(AVG(Revenue), 2) as AvgPurchaseValue,
    DATEDIFF(MONTH, MIN(InvoiceDate), MAX(InvoiceDate)) as CustomerLifetimeMonths,
    CASE 
        WHEN DATEDIFF(DAY, MAX(InvoiceDate), GETDATE()) > 180 THEN 'At Risk'
        WHEN DATEDIFF(DAY, MAX(InvoiceDate), GETDATE()) > 90 THEN 'Dormant'
        WHEN DATEDIFF(DAY, MAX(InvoiceDate), GETDATE()) > 30 THEN 'Inactive'
        ELSE 'Active'
    END as ActivityStatus,
    CASE 
        WHEN SUM(Revenue) >= 2000 AND COUNT(DISTINCT InvoiceNo) >= 50 THEN 'Champions'
        WHEN SUM(Revenue) >= 1000 AND COUNT(DISTINCT InvoiceNo) >= 20 THEN 'Loyal Customers'
        WHEN SUM(Revenue) >= 500 AND COUNT(DISTINCT InvoiceNo) >= 10 THEN 'High Value'
        WHEN SUM(Revenue) >= 200 AND COUNT(DISTINCT InvoiceNo) >= 5 THEN 'Medium Value'
        WHEN SUM(Revenue) >= 50 THEN 'Low Value'
        ELSE 'Very Low Value'
    END as CustomerSegment
FROM transactions
GROUP BY CustomerID
HAVING COUNT(DISTINCT InvoiceNo) > 0
ORDER BY MonetaryValue DESC;

-- ============================================================
-- SECTION 4: MONTHLY REVENUE ANALYSIS
-- ============================================================

-- Monthly Revenue & Growth
WITH monthly_revenue AS (
    SELECT 
        CONVERT(DATE, EOMONTH(InvoiceDate, -1)) as MonthEnd,
        DATEFROMPARTS(YEAR(InvoiceDate), MONTH(InvoiceDate), 1) as MonthStart,
        SUM(Revenue) as MonthlyRevenue,
        COUNT(DISTINCT InvoiceNo) as TransactionCount,
        COUNT(DISTINCT CustomerID) as UniqueCustomers,
        ROUND(AVG(Revenue), 2) as AvgTransactionValue
    FROM transactions
    GROUP BY CONVERT(DATE, EOMONTH(InvoiceDate, -1)), DATEFROMPARTS(YEAR(InvoiceDate), MONTH(InvoiceDate), 1)
)
SELECT 
    MonthEnd,
    MonthStart,
    MonthlyRevenue,
    LAG(MonthlyRevenue) OVER (ORDER BY MonthEnd) as PreviousMonthRevenue,
    MonthlyRevenue - LAG(MonthlyRevenue) OVER (ORDER BY MonthEnd) as RevenueChange,
    ROUND(
        ((MonthlyRevenue - LAG(MonthlyRevenue) OVER (ORDER BY MonthEnd)) / 
         LAG(MonthlyRevenue) OVER (ORDER BY MonthEnd)) * 100, 2
    ) as MoM_Growth_Pct,
    TransactionCount,
    LAG(TransactionCount) OVER (ORDER BY MonthEnd) as PreviousMonthTransactions,
    UniqueCustomers,
    LAG(UniqueCustomers) OVER (ORDER BY MonthEnd) as PreviousMonthCustomers,
    AvgTransactionValue
FROM monthly_revenue
ORDER BY MonthEnd DESC;

-- ============================================================
-- SECTION 5: GEOGRAPHIC ANALYSIS
-- ============================================================

-- Revenue by Country
SELECT TOP 50
    Country,
    COUNT(DISTINCT InvoiceNo) as TotalTransactions,
    COUNT(DISTINCT CustomerID) as UniqueCustomers,
    SUM(Revenue) as TotalRevenue,
    ROUND(AVG(Revenue), 2) as AvgTransactionValue,
    ROUND(SUM(Revenue) * 100.0 / (SELECT SUM(Revenue) FROM transactions), 2) as RevenueShare_Pct,
    MIN(InvoiceDate) as FirstSaleDate,
    MAX(InvoiceDate) as LastSaleDate,
    DATEDIFF(DAY, MIN(InvoiceDate), MAX(InvoiceDate)) as DaysSinceFirstSale
FROM transactions
GROUP BY Country
ORDER BY TotalRevenue DESC;

-- ============================================================
-- SECTION 6: COHORT RETENTION ANALYSIS
-- ============================================================

-- Cohort Analysis - Customer Retention by Acquisition Month
WITH customer_cohorts AS (
    SELECT 
        CustomerID,
        CONVERT(DATE, EOMONTH(MIN(InvoiceDate), -1)) as CohortMonth,
        DATEDIFF(MONTH, MIN(InvoiceDate), InvoiceDate) as MonthsSinceAcquisition,
        SUM(Revenue) as CohortRevenue,
        COUNT(DISTINCT InvoiceNo) as CohortTransactions
    FROM transactions
    GROUP BY CustomerID, DATEDIFF(MONTH, MIN(InvoiceDate), InvoiceDate)
)
SELECT 
    CohortMonth,
    MonthsSinceAcquisition,
    COUNT(DISTINCT CustomerID) as CustomersInCohort,
    SUM(CohortRevenue) as TotalCohortRevenue,
    ROUND(AVG(CohortRevenue), 2) as AvgCustomerValue,
    ROUND(SUM(CohortTransactions) * 1.0 / COUNT(DISTINCT CustomerID), 2) as TransactionsPerCustomer,
    ROUND(
        COUNT(DISTINCT CustomerID) * 100.0 / 
        (SELECT COUNT(DISTINCT CustomerID) FROM customer_cohorts WHERE MonthsSinceAcquisition = 0 AND CohortMonth = customer_cohorts.CohortMonth GROUP BY CohortMonth),
        2
    ) as RetentionRate_Pct
FROM customer_cohorts
WHERE MonthsSinceAcquisition <= 12
GROUP BY CohortMonth, MonthsSinceAcquisition
ORDER BY CohortMonth DESC, MonthsSinceAcquisition ASC;

-- ============================================================
-- SECTION 7: CUSTOMER LIFETIME VALUE
-- ============================================================

-- Customer Lifetime Value Projection
SELECT 
    CustomerID,
    MAX(InvoiceDate) as LastPurchaseDate,
    MIN(InvoiceDate) as FirstPurchaseDate,
    DATEDIFF(MONTH, MIN(InvoiceDate), MAX(InvoiceDate)) as LifetimeMonths,
    COUNT(DISTINCT InvoiceNo) as TotalOrders,
    SUM(Revenue) as TotalRevenue,
    ROUND(AVG(Revenue), 2) as AvgOrderValue,
    ROUND(SUM(Revenue) / NULLIF(DATEDIFF(MONTH, MIN(InvoiceDate), MAX(InvoiceDate)), 0), 2) as AvgMonthlyRevenue,
    ROUND((SUM(Revenue) / NULLIF(DATEDIFF(MONTH, MIN(InvoiceDate), MAX(InvoiceDate)), 0)) * 12, 2) as ProjectedAnnualValue,
    ROUND(SUM(Revenue) / COUNT(DISTINCT InvoiceNo), 2) as RevenuePerTransaction
FROM transactions
GROUP BY CustomerID
HAVING SUM(Revenue) > 0
ORDER BY TotalRevenue DESC;

-- ============================================================
-- SECTION 8: CHURN RISK ANALYSIS
-- ============================================================

-- Customers at Risk of Churn
WITH customer_activity AS (
    SELECT 
        CustomerID,
        MAX(InvoiceDate) as LastPurchaseDate,
        DATEDIFF(DAY, MAX(InvoiceDate), GETDATE()) as DaysSinceLastPurchase,
        SUM(Revenue) as TotalSpent,
        COUNT(DISTINCT InvoiceNo) as OrderCount,
        AVG(Revenue) as AvgOrderValue
    FROM transactions
    GROUP BY CustomerID
)
SELECT 
    CustomerID,
    LastPurchaseDate,
    DaysSinceLastPurchase,
    TotalSpent,
    OrderCount,
    AvgOrderValue,
    CASE 
        WHEN DaysSinceLastPurchase > 180 THEN 'HIGH RISK'
        WHEN DaysSinceLastPurchase > 90 THEN 'MEDIUM RISK'
        WHEN DaysSinceLastPurchase > 30 THEN 'LOW RISK'
        ELSE 'ACTIVE'
    END as ChurnRisk,
    ROUND((TotalSpent * 100.0) / (SELECT SUM(Revenue) FROM transactions), 4) as RevenueShare_Pct
FROM customer_activity
WHERE TotalSpent > 100
ORDER BY DaysSinceLastPurchase DESC;

-- ============================================================
-- SECTION 9: PRODUCT ANALYSIS
-- ============================================================

-- Top Products by Revenue
SELECT TOP 50
    StockCode,
    COUNT(DISTINCT InvoiceNo) as TimesOrdered,
    SUM(Quantity) as TotalQuantitySold,
    ROUND(AVG(Quantity), 2) as AvgQuantityPerOrder,
    SUM(Revenue) as TotalRevenue,
    ROUND(AVG(Revenue), 2) as AvgRevenue,
    ROUND(SUM(Revenue) * 100.0 / (SELECT SUM(Revenue) FROM transactions), 2) as RevenueShare_Pct,
    COUNT(DISTINCT CustomerID) as UniqueCustomersBought,
    MIN(InvoiceDate) as FirstSaleDate,
    MAX(InvoiceDate) as LastSaleDate
FROM transactions
GROUP BY StockCode
ORDER BY TotalRevenue DESC;

-- ============================================================
-- SECTION 10: SUMMARY STATISTICS
-- ============================================================

-- Overall Business Metrics
SELECT 
    'Revenue' as Metric, CAST(SUM(Revenue) as VARCHAR(20)) as Value FROM transactions
UNION ALL
SELECT 'Transactions', CAST(COUNT(DISTINCT InvoiceNo) as VARCHAR(20)) FROM transactions
UNION ALL
SELECT 'Customers', CAST(COUNT(DISTINCT CustomerID) as VARCHAR(20)) FROM transactions
UNION ALL
SELECT 'Countries', CAST(COUNT(DISTINCT Country) as VARCHAR(20)) FROM transactions
UNION ALL
SELECT 'Avg Order Value', CAST(ROUND(AVG(Revenue), 2) as VARCHAR(20)) FROM transactions
UNION ALL
SELECT 'Avg Customer Value', CAST(ROUND(SUM(Revenue) / COUNT(DISTINCT CustomerID), 2) as VARCHAR(20)) FROM transactions;
