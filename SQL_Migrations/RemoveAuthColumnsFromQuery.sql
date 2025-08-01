-- =============================================
-- Temporary Workaround: Create a view without auth columns
-- Description: Creates a view that EF can query without the new columns
-- Date: 2025-08-01
-- =============================================

-- Create a backup of the current admin user data
SELECT 
    Email,
    PasswordHash,
    PasswordSalt,
    AuthProvider
INTO #AdminBackup
FROM dbo.Users
WHERE Email = 'admin@steelestimation.com';

-- Show what we backed up
SELECT * FROM #AdminBackup;

-- Option 1: Remove the columns temporarily (DANGEROUS - only for testing)
-- This would break the columns we just added
-- ALTER TABLE dbo.Users DROP COLUMN PasswordSalt;
-- ALTER TABLE dbo.Users DROP COLUMN AuthProvider;
-- ALTER TABLE dbo.Users DROP COLUMN ExternalUserId;

-- Option 2: Check if there's a way to update the EF model
-- The real solution is to update the Entity Framework model

PRINT '';
PRINT 'The issue is that Entity Framework expects different columns than what exists.';
PRINT 'The application needs to be updated to match the database schema.';
PRINT '';
PRINT 'Current admin user has:';
PRINT '  - PasswordHash: ' + (SELECT CASE WHEN PasswordHash IS NOT NULL THEN 'SET' ELSE 'NULL' END FROM #AdminBackup);
PRINT '  - PasswordSalt: ' + (SELECT CASE WHEN PasswordSalt IS NOT NULL THEN 'SET' ELSE 'NULL' END FROM #AdminBackup);
PRINT '  - AuthProvider: ' + (SELECT ISNULL(AuthProvider, 'NULL') FROM #AdminBackup);

DROP TABLE #AdminBackup;