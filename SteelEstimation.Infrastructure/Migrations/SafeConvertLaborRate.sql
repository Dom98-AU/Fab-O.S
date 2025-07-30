-- Safe conversion of LaborRatePerHour from int to decimal
-- This handles the case where the column might already be decimal

-- First check the current data type
DECLARE @DataType NVARCHAR(50)
DECLARE @SQL NVARCHAR(MAX)

SELECT @DataType = ty.name
FROM sys.columns c
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE c.object_id = OBJECT_ID(N'[dbo].[Packages]') 
    AND c.name = 'LaborRatePerHour';

PRINT 'Current data type for Packages.LaborRatePerHour: ' + ISNULL(@DataType, 'Column not found');

IF @DataType = 'int'
BEGIN
    PRINT 'Converting from int to decimal...';
    
    -- Show current values before conversion
    PRINT 'Current values:';
    SELECT Id, PackageName, LaborRatePerHour FROM Packages;
    
    -- Method 1: Direct conversion (if no constraints)
    BEGIN TRY
        ALTER TABLE [dbo].[Packages]
        ALTER COLUMN [LaborRatePerHour] decimal(18,2) NOT NULL;
        PRINT 'Direct conversion successful!';
    END TRY
    BEGIN CATCH
        PRINT 'Direct conversion failed, trying alternative method...';
        PRINT ERROR_MESSAGE();
        
        -- Method 2: Using a temporary column
        BEGIN TRY
            -- Add temporary column
            ALTER TABLE [dbo].[Packages] ADD [LaborRatePerHour_NEW] decimal(18,2) NULL;
            
            -- Copy data
            UPDATE [dbo].[Packages] SET [LaborRatePerHour_NEW] = CAST([LaborRatePerHour] AS decimal(18,2));
            
            -- Drop old column
            ALTER TABLE [dbo].[Packages] DROP COLUMN [LaborRatePerHour];
            
            -- Rename new column
            EXEC sp_rename '[dbo].[Packages].[LaborRatePerHour_NEW]', 'LaborRatePerHour', 'COLUMN';
            
            -- Make it NOT NULL
            ALTER TABLE [dbo].[Packages] ALTER COLUMN [LaborRatePerHour] decimal(18,2) NOT NULL;
            
            PRINT 'Alternative conversion successful!';
        END TRY
        BEGIN CATCH
            PRINT 'Alternative conversion also failed:';
            PRINT ERROR_MESSAGE();
        END CATCH
    END CATCH
    
    -- Verify the conversion
    PRINT '';
    PRINT 'Values after conversion:';
    SELECT Id, PackageName, LaborRatePerHour FROM Packages;
END
ELSE IF @DataType = 'decimal'
BEGIN
    PRINT 'Column is already decimal type. No conversion needed.';
    
    -- But let's check for any other int columns that might be the issue
    PRINT '';
    PRINT 'Checking for other potential int columns that should be decimal...';
    
    SELECT 
        t.name AS TableName,
        c.name AS ColumnName,
        ty.name AS DataType
    FROM sys.tables t
    INNER JOIN sys.columns c ON t.object_id = c.object_id
    INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
    WHERE t.name = 'Packages'
        AND ty.name = 'int'
        AND c.name NOT IN ('Id', 'ProjectId', 'CreatedBy', 'LastModifiedBy')
    ORDER BY c.name;
END
ELSE
BEGIN
    PRINT 'Unexpected data type: ' + ISNULL(@DataType, 'NULL');
END

-- Final verification
PRINT '';
PRINT 'Final column information:';
SELECT 
    c.name AS ColumnName,
    ty.name AS DataType,
    c.precision,
    c.scale,
    c.is_nullable
FROM sys.columns c
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE c.object_id = OBJECT_ID(N'[dbo].[Packages]') 
    AND c.name = 'LaborRatePerHour';