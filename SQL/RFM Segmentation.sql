-- RFM Segmentation
SELECT 
    CustomerID,
    MAX(InvoiceDate) as LastPurchaseDate,
    COUNT(DISTINCT InvoiceNo) as PurchaseFrequency,
    SUM(Revenue) as TotalRevenue,
    DATEDIFF(DAY, MAX(InvoiceDate), '2023-12-31') as DaysSinceLastPurchase,
    CASE 
        WHEN SUM(Revenue) > 1000 AND COUNT(DISTINCT InvoiceNo) > 10 THEN 'VIP Customer'
        WHEN SUM(Revenue) > 500 AND COUNT(DISTINCT InvoiceNo) > 5 THEN 'High Value'
        WHEN SUM(Revenue) > 100 THEN 'Medium Value'
        ELSE 'Low Value'
    END as CustomerSegment,
    CASE 
        WHEN DATEDIFF(DAY, MAX(InvoiceDate), '2023-12-31') > 180 THEN 'At Risk'
        WHEN DATEDIFF(DAY, MAX(InvoiceDate), '2023-12-31') > 90 THEN 'Dormant'
        ELSE 'Active'
    END as CustomerStatus
FROM transactions
GROUP BY CustomerID
ORDER BY TotalRevenue DESC;