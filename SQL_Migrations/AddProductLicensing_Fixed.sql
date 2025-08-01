-- =============================================
-- Migration: Add Product Licensing for Fab.OS (Fixed for int UserId)
-- Description: Adds tables for product-based licensing and access control
-- Date: 2025-08-01
-- Fixed: Changed UserId from uniqueidentifier to int to match existing schema
-- =============================================

BEGIN TRANSACTION;

-- 1. Create ProductLicenses table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ProductLicenses')
BEGIN
    CREATE TABLE ProductLicenses (
        Id int IDENTITY(1,1) PRIMARY KEY,
        CompanyId int NOT NULL,
        ProductName nvarchar(50) NOT NULL,
        LicenseType nvarchar(20) NOT NULL DEFAULT 'Standard',
        MaxConcurrentUsers int NOT NULL DEFAULT 5,
        ValidFrom datetime2 NOT NULL DEFAULT GETUTCDATE(),
        ValidUntil datetime2 NOT NULL,
        IsActive bit NOT NULL DEFAULT 1,
        Features nvarchar(max), -- JSON array of enabled features
        CreatedDate datetime2 NOT NULL DEFAULT GETUTCDATE(),
        LastModified datetime2 NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT FK_ProductLicenses_Companies FOREIGN KEY (CompanyId) REFERENCES Companies(Id)
    );

    CREATE INDEX IX_ProductLicenses_CompanyId_ProductName 
    ON ProductLicenses(CompanyId, ProductName);

    PRINT 'Created ProductLicenses table';
END
ELSE
BEGIN
    PRINT 'ProductLicenses table already exists';
END

-- 2. Create UserProductAccess table for tracking user access (FIXED: UserId as int)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserProductAccess')
BEGIN
    CREATE TABLE UserProductAccess (
        Id int IDENTITY(1,1) PRIMARY KEY,
        UserId int NOT NULL,  -- Changed from uniqueidentifier to int
        ProductLicenseId int NOT NULL,
        LastAccessDate datetime2 NOT NULL DEFAULT GETUTCDATE(),
        IsCurrentlyActive bit NOT NULL DEFAULT 0,
        CONSTRAINT FK_UserProductAccess_Users FOREIGN KEY (UserId) REFERENCES Users(Id),
        CONSTRAINT FK_UserProductAccess_ProductLicenses FOREIGN KEY (ProductLicenseId) REFERENCES ProductLicenses(Id)
    );

    CREATE INDEX IX_UserProductAccess_UserId ON UserProductAccess(UserId);
    CREATE INDEX IX_UserProductAccess_ProductLicenseId ON UserProductAccess(ProductLicenseId);

    PRINT 'Created UserProductAccess table';
END
ELSE
BEGIN
    PRINT 'UserProductAccess table already exists';
END

-- 3. Create ProductRoles table for product-specific roles
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ProductRoles')
BEGIN
    CREATE TABLE ProductRoles (
        Id int IDENTITY(1,1) PRIMARY KEY,
        ProductName nvarchar(50) NOT NULL,
        RoleName nvarchar(50) NOT NULL,
        Description nvarchar(500),
        Permissions nvarchar(max) -- JSON permissions object
    );

    CREATE UNIQUE INDEX IX_ProductRoles_ProductName_RoleName 
    ON ProductRoles(ProductName, RoleName);

    PRINT 'Created ProductRoles table';
END
ELSE
BEGIN
    PRINT 'ProductRoles table already exists';
END

-- 4. Create UserProductRoles table (FIXED: UserId as int)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserProductRoles')
BEGIN
    CREATE TABLE UserProductRoles (
        Id int IDENTITY(1,1) PRIMARY KEY,
        UserId int NOT NULL,  -- Changed from uniqueidentifier to int
        ProductRoleId int NOT NULL,
        AssignedDate datetime2 NOT NULL DEFAULT GETUTCDATE(),
        AssignedBy int,  -- Changed from uniqueidentifier to int
        CONSTRAINT FK_UserProductRoles_Users FOREIGN KEY (UserId) REFERENCES Users(Id),
        CONSTRAINT FK_UserProductRoles_ProductRoles FOREIGN KEY (ProductRoleId) REFERENCES ProductRoles(Id),
        CONSTRAINT FK_UserProductRoles_AssignedBy FOREIGN KEY (AssignedBy) REFERENCES Users(Id)
    );

    CREATE INDEX IX_UserProductRoles_UserId ON UserProductRoles(UserId);
    CREATE INDEX IX_UserProductRoles_ProductRoleId ON UserProductRoles(ProductRoleId);

    PRINT 'Created UserProductRoles table';
END
ELSE
BEGIN
    PRINT 'UserProductRoles table already exists';
END

-- 5. Migrate existing companies to have "Estimate" product license
PRINT 'Migrating existing companies to Estimate product license...';

INSERT INTO ProductLicenses (CompanyId, ProductName, LicenseType, MaxConcurrentUsers, ValidFrom, ValidUntil, IsActive, Features)
SELECT 
    c.Id,
    'Estimate',
    'Standard',
    ISNULL(c.MaxUsers, 10), -- Use company's MaxUsers or default to 10
    GETUTCDATE(),
    DATEADD(YEAR, 10, GETUTCDATE()), -- 10 year license
    1,
    '["BasicEstimation","TimeTracking","ProjectManagement","WeldingDashboard","PackBundles","EfficiencyRates"]'
FROM Companies c
WHERE NOT EXISTS (
    SELECT 1 FROM ProductLicenses pl 
    WHERE pl.CompanyId = c.Id AND pl.ProductName = 'Estimate'
);

PRINT 'Migrated ' + CAST(@@ROWCOUNT AS nvarchar(10)) + ' companies to Estimate product';

-- 6. Grant all existing active users access to Estimate product
PRINT 'Granting existing users access to Estimate product...';

INSERT INTO UserProductAccess (UserId, ProductLicenseId, LastAccessDate, IsCurrentlyActive)
SELECT 
    u.Id,
    pl.Id,
    ISNULL(u.LastLoginDate, GETUTCDATE()),
    0
FROM Users u
INNER JOIN Companies c ON u.CompanyId = c.Id
INNER JOIN ProductLicenses pl ON pl.CompanyId = c.Id AND pl.ProductName = 'Estimate'
WHERE u.IsActive = 1
AND NOT EXISTS (
    SELECT 1 FROM UserProductAccess upa 
    WHERE upa.UserId = u.Id AND upa.ProductLicenseId = pl.Id
);

PRINT 'Granted access to ' + CAST(@@ROWCOUNT AS nvarchar(10)) + ' users';

-- 7. Create default product roles
PRINT 'Creating default product roles...';

-- Estimate product roles
INSERT INTO ProductRoles (ProductName, RoleName, Description, Permissions)
VALUES 
    ('Estimate', 'Administrator', 'Full access to Estimate features', '{"all": true}'),
    ('Estimate', 'Manager', 'Manage projects and teams in Estimate', '{"projects": ["create","read","update","delete"], "teams": ["read","update"], "reports": ["read"]}'),
    ('Estimate', 'Estimator', 'Create and edit estimations', '{"estimations": ["create","read","update"], "projects": ["read"], "reports": ["read"]}'),
    ('Estimate', 'Viewer', 'View-only access to Estimate', '{"estimations": ["read"], "projects": ["read"], "reports": ["read"]}');

-- Trace product roles (for future)
INSERT INTO ProductRoles (ProductName, RoleName, Description, Permissions)
VALUES 
    ('Trace', 'Administrator', 'Full access to Trace features', '{"all": true}'),
    ('Trace', 'Takeoff Specialist', 'Create and manage takeoffs', '{"takeoffs": ["create","read","update","delete"], "drawings": ["read","upload"]}'),
    ('Trace', 'Viewer', 'View-only access to Trace', '{"takeoffs": ["read"], "drawings": ["read"]}');

-- Fabmate product roles (for future)
INSERT INTO ProductRoles (ProductName, RoleName, Description, Permissions)
VALUES 
    ('Fabmate', 'Administrator', 'Full access to Fabmate features', '{"all": true}'),
    ('Fabmate', 'Production Manager', 'Manage production and inventory', '{"production": ["create","read","update","delete"], "inventory": ["read","update"], "scheduling": ["create","read","update"]}'),
    ('Fabmate', 'Shop Floor', 'Shop floor operations', '{"production": ["read","update"], "inventory": ["read"], "scheduling": ["read"]}'),
    ('Fabmate', 'Viewer', 'View-only access to Fabmate', '{"production": ["read"], "inventory": ["read"], "scheduling": ["read"]}');

-- QDocs product roles (for future)
INSERT INTO ProductRoles (ProductName, RoleName, Description, Permissions)
VALUES 
    ('QDocs', 'Administrator', 'Full access to QDocs features', '{"all": true}'),
    ('QDocs', 'Quality Manager', 'Manage quality documentation', '{"documents": ["create","read","update","delete"], "compliance": ["read","update"], "training": ["create","read","update"]}'),
    ('QDocs', 'Inspector', 'Create inspection records', '{"documents": ["create","read"], "compliance": ["read"], "training": ["read"]}'),
    ('QDocs', 'Viewer', 'View-only access to QDocs', '{"documents": ["read"], "compliance": ["read"], "training": ["read"]}');

PRINT 'Created default product roles';

-- 8. Add audit columns to track changes (FIXED: UserId as int)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('ProductLicenses') AND name = 'CreatedBy')
BEGIN
    ALTER TABLE ProductLicenses ADD 
        CreatedBy int NULL,
        ModifiedBy int NULL;

    ALTER TABLE ProductLicenses ADD 
        CONSTRAINT FK_ProductLicenses_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Users(Id),
        CONSTRAINT FK_ProductLicenses_ModifiedBy FOREIGN KEY (ModifiedBy) REFERENCES Users(Id);

    PRINT 'Added audit columns to ProductLicenses';
END

COMMIT TRANSACTION;

PRINT '=============================================';
PRINT 'Product Licensing migration completed successfully';
PRINT '=============================================';

-- Show summary of what was created
SELECT 'Product Licenses' as [Table], COUNT(*) as [Count] FROM ProductLicenses
UNION ALL
SELECT 'Product Roles', COUNT(*) FROM ProductRoles
UNION ALL
SELECT 'User Product Access', COUNT(*) FROM UserProductAccess
UNION ALL
SELECT 'User Product Roles', COUNT(*) FROM UserProductRoles;