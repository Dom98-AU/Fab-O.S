-- =============================================
-- New Connection Test
-- Run this in a BRAND NEW query window
-- =============================================

-- Confirm database
USE [sqldb-steel-estimation-sandbox];
GO

-- Simple select
SELECT 
    Email,
    PasswordSalt,
    AuthProvider,
    ExternalUserId
FROM dbo.Users
WHERE Email = 'admin@steelestimation.com';
GO

-- If the above works, update the password
UPDATE dbo.Users 
SET 
    PasswordSalt = 'nsYnK4MNzdfPHSCR3MbQnQ==',
    PasswordHash = 'QLl0gbsufEANZI3gpGe+qfEoQ+GER6+lom/s/IL5XajgxXJC0qNsLa1qZt6fqKT3TrcFARkDi4bh7j02bnSEsA==',
    AuthProvider = 'Local'
WHERE Email = 'admin@steelestimation.com';

PRINT 'Update completed. Rows affected: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
GO