-- Check Pack Bundle table structure
-- This script verifies all tables and columns are properly set up

-- Check if PackBundles table exists
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'PackBundles')
BEGIN
    PRINT 'PackBundles table exists';
    
    -- Check columns in PackBundles table
    SELECT 
        c.name AS ColumnName,
        t.name AS DataType,
        c.max_length,
        c.is_nullable
    FROM sys.columns c
    INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
    WHERE c.object_id = OBJECT_ID('PackBundles')
    ORDER BY c.column_id;
END
ELSE
BEGIN
    PRINT 'ERROR: PackBundles table does not exist!';
END

PRINT '';
PRINT 'Checking ProcessingItems columns:';

-- Check pack bundle related columns in ProcessingItems
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('ProcessingItems') AND name = 'PackBundleId')
    PRINT '✓ PackBundleId column exists';
ELSE
    PRINT '✗ PackBundleId column MISSING';

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('ProcessingItems') AND name = 'IsParentInPackBundle')
    PRINT '✓ IsParentInPackBundle column exists';
ELSE
    PRINT '✗ IsParentInPackBundle column MISSING';

PRINT '';
PRINT 'Checking foreign key constraint:';

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ProcessingItems_PackBundles_PackBundleId')
    PRINT '✓ Foreign key constraint exists';
ELSE
    PRINT '✗ Foreign key constraint MISSING';

PRINT '';
PRINT 'Checking indexes:';

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ProcessingItems_PackBundleId')
    PRINT '✓ PackBundleId index exists';
ELSE
    PRINT '✗ PackBundleId index MISSING';

-- Check if Package table has PackBundles navigation property (this is handled by EF Core, not in DB)
PRINT '';
PRINT 'Package table structure check complete.';
PRINT 'Note: Navigation properties (Package.PackBundles) are handled by Entity Framework, not stored in the database.';