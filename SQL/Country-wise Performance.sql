-- Revenue by Country
SELECT 
    Country,
    COUNT(DISTINCT CustomerID) as TotalCustomers,
    COUNT(DISTINCT InvoiceNo) as TotalOrders,
    SUM(Revenue) as TotalRevenue,
    ROUND(AVG(Revenue), 2) as AvgOrderValue,
    ROUND(SUM(Revenue) * 100.0 / (SELECT SUM(Revenue) FROM transactions), 2) as RevenueShare
FROM transactions
GROUP BY Country
ORDER BY TotalRevenue DESC;