-- Check the current state of users and their companies
SELECT 'Current Users and Companies:' as Info;

SELECT 
    u.Id,
    u.Username,
    u.Email,
    u.CompanyId,
    c.Name as CompanyName,
    c.Code as CompanyCode,
    c.Id as ActualCompanyId
FROM Users u
LEFT JOIN Companies c ON u.CompanyId = c.Id
ORDER BY u.Id;

-- Check if there are any users with CompanyId that doesn't exist
SELECT 'Users with invalid CompanyId:' as Info;
SELECT 
    u.Id,
    u.Username,
    u.CompanyId,
    'Company does not exist' as Issue
FROM Users u
WHERE u.CompanyId NOT IN (SELECT Id FROM Companies);

-- Check the Companies table
SELECT 'All Companies:' as Info;
SELECT * FROM Companies;