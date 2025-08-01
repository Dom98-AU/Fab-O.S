-- =============================================
-- Refresh Metadata and Clear Cache
-- Description: Forces SQL Server to refresh metadata
-- Date: 2025-08-01
-- =============================================

-- Clear procedure cache for this database
DBCC FREEPROCCACHE;
PRINT 'Cleared procedure cache';

-- Refresh metadata for Users table
EXEC sp_refreshview 'sys.all_columns';
PRINT 'Refreshed column metadata';

-- Force recompile of the table
EXEC sp_recompile 'dbo.Users';
PRINT 'Marked Users table for recompile';

-- Now try a direct query using EXEC to force fresh compilation
PRINT '';
PRINT 'Testing column access with dynamic SQL:';
EXEC('SELECT TOP 1 Email, AuthProvider, PasswordSalt FROM dbo.Users');

-- Alternative: Try selecting using system functions
PRINT '';
PRINT 'Testing with column IDs:';
SELECT TOP 1
    COL_NAME(OBJECT_ID('dbo.Users'), 3) AS Col3_Email,
    COL_NAME(OBJECT_ID('dbo.Users'), 23) AS Col23_AuthProvider,
    COL_NAME(OBJECT_ID('dbo.Users'), 22) AS Col22_PasswordSalt
FROM dbo.Users;

-- Try updating using dynamic SQL
PRINT '';
PRINT 'Attempting update with dynamic SQL:';
DECLARE @sql NVARCHAR(MAX) = '
UPDATE dbo.Users 
SET PasswordSalt = ''nsYnK4MNzdfPHSCR3MbQnQ=='',
    PasswordHash = ''QLl0gbsufEANZI3gpGe+qfEoQ+GER6+lom/s/IL5XajgxXJC0qNsLa1qZt6fqKT3TrcFARkDi4bh7j02bnSEsA=='',
    AuthProvider = ''Local''
WHERE Email = ''admin@steelestimation.com''';

EXEC sp_executesql @sql;
PRINT 'Rows updated: ' + CAST(@@ROWCOUNT AS VARCHAR(10));