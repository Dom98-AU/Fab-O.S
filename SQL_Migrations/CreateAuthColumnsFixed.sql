-- =============================================
-- Create Authentication Columns (Fixed)
-- Description: Creates all required authentication columns before updating data
-- Date: 2025-08-01
-- =============================================

-- Step 1: Add PasswordSalt column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'PasswordSalt')
BEGIN
    ALTER TABLE Users ADD PasswordSalt nvarchar(100) NULL;
    PRINT 'Added PasswordSalt column to Users table';
END

-- Step 2: Add AuthProvider column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'AuthProvider')
BEGIN
    ALTER TABLE Users ADD AuthProvider nvarchar(50) NOT NULL DEFAULT 'Local';
    PRINT 'Added AuthProvider column to Users table';
END

-- Step 3: Add ExternalUserId column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'ExternalUserId')
BEGIN
    ALTER TABLE Users ADD ExternalUserId nvarchar(256) NULL;
    PRINT 'Added ExternalUserId column to Users table';
END

-- Step 4: Verify columns and update admin user
PRINT '';
PRINT 'Checking column existence...';

DECLARE @HasPasswordSalt bit = 0;
DECLARE @HasAuthProvider bit = 0;
DECLARE @HasExternalUserId bit = 0;

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'PasswordSalt')
    SET @HasPasswordSalt = 1;

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'AuthProvider')
    SET @HasAuthProvider = 1;

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'ExternalUserId')
    SET @HasExternalUserId = 1;

-- Display status
IF @HasPasswordSalt = 1 PRINT 'PasswordSalt column: EXISTS';
ELSE PRINT 'PasswordSalt column: MISSING';

IF @HasAuthProvider = 1 PRINT 'AuthProvider column: EXISTS';
ELSE PRINT 'AuthProvider column: MISSING';

IF @HasExternalUserId = 1 PRINT 'ExternalUserId column: EXISTS';
ELSE PRINT 'ExternalUserId column: MISSING';

-- Step 5: Update admin user if all columns exist
IF @HasPasswordSalt = 1 AND @HasAuthProvider = 1
BEGIN
    PRINT '';
    PRINT 'Updating admin user with salted password...';
    
    -- Password: Admin@123
    -- Salt and Hash generated using HMACSHA512
    UPDATE Users 
    SET 
        PasswordSalt = 'nsYnK4MNzdfPHSCR3MbQnQ==',
        PasswordHash = 'QLl0gbsufEANZI3gpGe+qfEoQ+GER6+lom/s/IL5XajgxXJC0qNsLa1qZt6fqKT3TrcFARkDi4bh7j02bnSEsA==',
        AuthProvider = 'Local'
    WHERE Email = 'admin@steelestimation.com';
    
    IF @@ROWCOUNT > 0
    BEGIN
        PRINT 'SUCCESS: Updated admin user';
        PRINT '';
        PRINT 'Login credentials:';
        PRINT '  Email: admin@steelestimation.com';
        PRINT '  Password: Admin@123';
    END
    ELSE
    BEGIN
        PRINT 'WARNING: Admin user not found in database';
        PRINT 'Creating admin user...';
        
        -- Get or create company
        DECLARE @CompanyId int;
        SELECT TOP 1 @CompanyId = Id FROM Companies WHERE IsActive = 1;
        
        IF @CompanyId IS NULL
        BEGIN
            INSERT INTO Companies (Name, Code, IsActive, CreatedDate)
            VALUES ('NWI Group', 'NWI', 1, GETUTCDATE());
            SET @CompanyId = SCOPE_IDENTITY();
        END
        
        -- Create admin user
        INSERT INTO Users (
            Username,
            Email,
            PasswordHash,
            PasswordSalt,
            FirstName,
            LastName,
            CompanyId,
            IsActive,
            IsEmailConfirmed,
            AuthProvider,
            CreatedAt
        )
        VALUES (
            'admin',
            'admin@steelestimation.com',
            'QLl0gbsufEANZI3gpGe+qfEoQ+GER6+lom/s/IL5XajgxXJC0qNsLa1qZt6fqKT3TrcFARkDi4bh7j02bnSEsA==',
            'nsYnK4MNzdfPHSCR3MbQnQ==',
            'System',
            'Administrator',
            @CompanyId,
            1,
            1,
            'Local',
            GETUTCDATE()
        );
        
        PRINT 'SUCCESS: Created admin user';
        PRINT '';
        PRINT 'Login credentials:';
        PRINT '  Email: admin@steelestimation.com';
        PRINT '  Password: Admin@123';
    END
END
ELSE
BEGIN
    PRINT '';
    PRINT 'ERROR: Cannot update admin user - required columns are missing';
    PRINT 'Please check the error messages above and resolve any issues';
END

PRINT '';
PRINT 'Script completed';