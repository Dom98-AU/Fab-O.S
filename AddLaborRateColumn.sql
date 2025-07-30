-- Add LaborRatePerHour column to Packages table
-- Run this script against your Steel Estimation database

IF NOT EXISTS (
    SELECT * 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[Packages]') 
    AND name = 'LaborRatePerHour'
)
BEGIN
    ALTER TABLE [dbo].[Packages]
    ADD [LaborRatePerHour] DECIMAL(10,2) NOT NULL CONSTRAINT DF_Packages_LaborRatePerHour DEFAULT 0;
    
    PRINT 'LaborRatePerHour column added successfully.';
END
ELSE
BEGIN
    PRINT 'LaborRatePerHour column already exists.';
END

-- Optional: Update __EFMigrationsHistory table to record the migration
IF NOT EXISTS (
    SELECT * 
    FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = '20250702134221_AddLaborRateToPackage'
)
BEGIN
    INSERT INTO [dbo].[__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES ('20250702134221_AddLaborRateToPackage', '8.0.0');
    
    PRINT 'Migration history updated.';
END