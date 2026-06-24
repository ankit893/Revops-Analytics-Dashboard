-- Monthly Revenue & MoM Growth
WITH monthly_revenue AS (
    SELECT 
        CONVERT(DATE, EOMONTH(InvoiceDate, -1)) as MonthEnd,
        SUM(Revenue) as MonthlyRevenue,
        COUNT(DISTINCT CustomerID) as UniqueCustomers,
        COUNT(DISTINCT InvoiceNo) as TotalTransactions,
        AVG(Revenue) as AvgTransactionValue
    FROM transactions
    WHERE InvoiceDate >= '2021-01-01'
    GROUP BY CONVERT(DATE, EOMONTH(InvoiceDate, -1))
)
SELECT 
    MonthEnd,
    MonthlyRevenue,
    LAG(MonthlyRevenue) OVER (ORDER BY MonthEnd) as PreviousMonthRevenue,
    ROUND(((MonthlyRevenue - LAG(MonthlyRevenue) OVER (ORDER BY MonthEnd)) / 
           LAG(MonthlyRevenue) OVER (ORDER BY MonthEnd)) * 100, 2) as MoM_Growth_Pct,
    UniqueCustomers,
    TotalTransactions,
    AvgTransactionValue
FROM monthly_revenue
ORDER BY MonthEnd DESC;