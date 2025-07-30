-- =====================================================
-- ROLLBACK Multi-Tenant Migration Script
-- =====================================================
-- WARNING: This will remove all company data and settings!
-- Make sure to backup your database before running this script

PRINT '========================================='
PRINT 'ROLLBACK Multi-Tenant Migration'
PRINT 'WARNING: This will delete all company data!'
PRINT '========================================='
PRINT ''

-- Confirm rollback
DECLARE @Confirm CHAR(1)
PRINT 'Are you sure you want to rollback? This will:'
PRINT '- Remove CompanyId from all users'
PRINT '- Delete all company material settings'
PRINT '- Delete all companies'
PRINT ''
PRINT 'To continue, manually change @ConfirmRollback to 1 in the script'

DECLARE @ConfirmRollback BIT = 0  -- Change to 1 to confirm rollback

IF @ConfirmRollback = 0
BEGIN
    PRINT ''
    PRINT 'Rollback cancelled. Change @ConfirmRollback to 1 to proceed.'
    RETURN
END

PRINT 'Starting rollback...'
PRINT ''

BEGIN TRY
    BEGIN TRANSACTION

    -- Step 1: Remove foreign key constraint from Users
    IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Users_Companies')
    BEGIN
        ALTER TABLE [dbo].[Users] DROP CONSTRAINT [FK_Users_Companies]
        PRINT '✓ Dropped FK_Users_Companies constraint'
    END

    -- Step 2: Drop CompanyId column from Users
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'CompanyId')
    BEGIN
        -- First remove the index
        IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Users_CompanyId' AND object_id = OBJECT_ID(N'[dbo].[Users]'))
        BEGIN
            DROP INDEX [IX_Users_CompanyId] ON [dbo].[Users]
            PRINT '✓ Dropped index IX_Users_CompanyId'
        END
        
        ALTER TABLE [dbo].[Users] DROP COLUMN [CompanyId]
        PRINT '✓ Dropped CompanyId column from Users table'
    END

    -- Step 3: Drop company-related tables
    IF EXISTS (SELECT * FROM sys.tables WHERE name = 'CompanyMaterialPatterns')
    BEGIN
        DROP TABLE [dbo].[CompanyMaterialPatterns]
        PRINT '✓ Dropped CompanyMaterialPatterns table'
    END

    IF EXISTS (SELECT * FROM sys.tables WHERE name = 'CompanyMbeIdMappings')
    BEGIN
        DROP TABLE [dbo].[CompanyMbeIdMappings]
        PRINT '✓ Dropped CompanyMbeIdMappings table'
    END

    IF EXISTS (SELECT * FROM sys.tables WHERE name = 'CompanyMaterialTypes')
    BEGIN
        DROP TABLE [dbo].[CompanyMaterialTypes]
        PRINT '✓ Dropped CompanyMaterialTypes table'
    END

    IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Companies')
    BEGIN
        DROP TABLE [dbo].[Companies]
        PRINT '✓ Dropped Companies table'
    END

    -- Step 4: Drop stored procedures
    IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'sp_CopyCompanySettings')
    BEGIN
        DROP PROCEDURE sp_CopyCompanySettings
        PRINT '✓ Dropped sp_CopyCompanySettings procedure'
    END

    -- Step 5: Drop tenant registry tables (if they exist)
    IF EXISTS (SELECT * FROM sys.tables WHERE name = 'TenantUsageLogs')
    BEGIN
        DROP TABLE [dbo].[TenantUsageLogs]
        PRINT '✓ Dropped TenantUsageLogs table'
    END

    IF EXISTS (SELECT * FROM sys.tables WHERE name = 'TenantRegistries')
    BEGIN
        DROP TABLE [dbo].[TenantRegistries]
        PRINT '✓ Dropped TenantRegistries table'
    END

    COMMIT TRANSACTION

    PRINT ''
    PRINT '========================================='
    PRINT 'Rollback Completed Successfully!'
    PRINT '========================================='
    PRINT ''
    PRINT 'The database has been restored to pre-migration state.'
    PRINT 'Material type settings will now need to be configured in appsettings.json'
    
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION
    
    PRINT ''
    PRINT 'ERROR: Rollback failed!'
    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10))
    PRINT 'Error Message: ' + ERROR_MESSAGE()
    PRINT ''
    PRINT 'Transaction has been rolled back. No changes were made.'
    
    THROW;
END CATCH