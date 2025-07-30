-- Add missing columns to fix the welding worksheet error
-- This script adds columns that Entity Framework expects but are missing from the database

-- 1. Add UploadedBy to ImageUploads table (already exists as UploadedByUserId)
-- This might be a naming mismatch - let's check first
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ImageUploads]') AND name = 'UploadedBy')
BEGIN
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ImageUploads]') AND name = 'UploadedByUserId')
    BEGIN
        -- Rename UploadedByUserId to UploadedBy to match the entity
        EXEC sp_rename '[dbo].[ImageUploads].[UploadedByUserId]', 'UploadedBy', 'COLUMN';
        PRINT 'Renamed UploadedByUserId to UploadedBy in ImageUploads table'
    END
    ELSE
    BEGIN
        -- Add the column if it doesn't exist at all
        ALTER TABLE [dbo].[ImageUploads]
        ADD [UploadedBy] int NULL;
        PRINT 'Added UploadedBy column to ImageUploads table'
    END
END

-- 2. Add DefaultWeldTest to WeldingConnections table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingConnections]') AND name = 'DefaultWeldTest')
BEGIN
    ALTER TABLE [dbo].[WeldingConnections]
    ADD [DefaultWeldTest] decimal(10,2) NOT NULL DEFAULT 0;
    PRINT 'Added DefaultWeldTest column to WeldingConnections table'
END

-- 3. Add LastModified to WeldingConnections table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingConnections]') AND name = 'LastModified')
BEGIN
    ALTER TABLE [dbo].[WeldingConnections]
    ADD [LastModified] datetime2 NOT NULL DEFAULT GETUTCDATE();
    PRINT 'Added LastModified column to WeldingConnections table'
END

-- 4. Add PackageId to WeldingConnections table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingConnections]') AND name = 'PackageId')
BEGIN
    ALTER TABLE [dbo].[WeldingConnections]
    ADD [PackageId] int NULL;
    
    -- Add foreign key constraint
    ALTER TABLE [dbo].[WeldingConnections]
    ADD CONSTRAINT [FK_WeldingConnections_Packages] 
    FOREIGN KEY ([PackageId]) REFERENCES [dbo].[Packages] ([Id]) 
    ON DELETE SET NULL;
    
    PRINT 'Added PackageId column to WeldingConnections table with foreign key'
END

-- 5. Add Size to WeldingConnections table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingConnections]') AND name = 'Size')
BEGIN
    ALTER TABLE [dbo].[WeldingConnections]
    ADD [Size] nvarchar(20) NOT NULL DEFAULT 'Small';
    PRINT 'Added Size column to WeldingConnections table'
END

-- Verify all columns exist
PRINT ''
PRINT 'Verification of columns:'
PRINT '======================='

-- Check ImageUploads
SELECT 
    c.name AS ColumnName,
    ty.name AS DataType,
    c.is_nullable
FROM sys.columns c
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE c.object_id = OBJECT_ID(N'[dbo].[ImageUploads]') 
    AND c.name IN ('UploadedBy', 'UploadedByUserId')
ORDER BY c.name;

-- Check WeldingConnections
SELECT 
    c.name AS ColumnName,
    ty.name AS DataType,
    c.precision,
    c.scale,
    c.is_nullable
FROM sys.columns c
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE c.object_id = OBJECT_ID(N'[dbo].[WeldingConnections]') 
    AND c.name IN ('DefaultWeldTest', 'LastModified', 'PackageId', 'Size')
ORDER BY c.name;

PRINT ''
PRINT 'Migration completed successfully!'