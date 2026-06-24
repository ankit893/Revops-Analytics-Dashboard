-- Top Products & Categories
SELECT TOP 20
    ProductCategory,
    COUNT(DISTINCT InvoiceNo) as SalesCount,
    SUM(Quantity) as TotalQuantitySold,
    SUM(Revenue) as TotalRevenue,
    ROUND(AVG(Revenue), 2) as AvgSaleValue,
    ROUND(SUM(Revenue) * 100.0 / (SELECT SUM(Revenue) FROM transactions), 2) as PercentageOfTotalRevenue
FROM transactions
GROUP BY ProductCategory
ORDER BY TotalRevenue DESC;