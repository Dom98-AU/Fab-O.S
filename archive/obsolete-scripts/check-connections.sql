-- Check welding connections status
SELECT 
    Id,
    Name,
    Category,
    IsActive,
    PackageId,
    DisplayOrder,
    CreatedDate,
    LastModified
FROM WeldingConnections
ORDER BY DisplayOrder;

-- Check if there are any welding items with connections
SELECT 
    wi.Id AS WeldingItemId,
    wi.DrawingNumber,
    wi.ItemDescription,
    wc.Name AS ConnectionName,
    wi.ConnectionQty
FROM WeldingItems wi
LEFT JOIN WeldingConnections wc ON wi.WeldingConnectionId = wc.Id
WHERE wi.ConnectionQty > 0 OR wi.WeldingConnectionId IS NOT NULL;

-- Check welding item connections (many-to-many)
SELECT 
    wic.Id,
    wic.WeldingItemId,
    wic.WeldingConnectionId,
    wc.Name AS ConnectionName,
    wic.Quantity
FROM WeldingItemConnections wic
JOIN WeldingConnections wc ON wic.WeldingConnectionId = wc.Id;

-- Summary of inactive connections
SELECT 
    COUNT(*) AS TotalConnections,
    SUM(CASE WHEN IsActive = 1 THEN 1 ELSE 0 END) AS ActiveConnections,
    SUM(CASE WHEN IsActive = 0 THEN 1 ELSE 0 END) AS InactiveConnections
FROM WeldingConnections;