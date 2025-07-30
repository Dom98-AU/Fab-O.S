-- Migration: Add Multi-Tenant Support
-- Description: Adds Companies table and company-specific material settings
-- Date: 2025-01-04

-- 1. Create Companies table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Companies' AND xtype='U')
BEGIN
    CREATE TABLE Companies (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(200) NOT NULL,
        Code NVARCHAR(50) NOT NULL UNIQUE,
        IsActive BIT NOT NULL DEFAULT 1,
        SubscriptionLevel NVARCHAR(50) DEFAULT 'Standard',
        MaxUsers INT DEFAULT 10,
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        LastModified DATETIME2 NOT NULL DEFAULT GETUTCDATE()
    );
    PRINT 'Created Companies table';
END
GO

-- 2. Add CompanyId to Users table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'CompanyId')
BEGIN
    -- First add as nullable
    ALTER TABLE Users ADD CompanyId INT NULL;
    
    -- Create a default company
    IF NOT EXISTS (SELECT * FROM Companies WHERE Code = 'default')
    BEGIN
        INSERT INTO Companies (Name, Code, IsActive) 
        VALUES ('Default Company', 'default', 1);
    END
    
    -- Set all existing users to the default company
    UPDATE Users 
    SET CompanyId = (SELECT TOP 1 Id FROM Companies WHERE Code = 'default')
    WHERE CompanyId IS NULL;
    
    -- Now make it NOT NULL
    ALTER TABLE Users ALTER COLUMN CompanyId INT NOT NULL;
    
    -- Add foreign key constraint
    ALTER TABLE Users ADD CONSTRAINT FK_Users_Companies 
        FOREIGN KEY (CompanyId) REFERENCES Companies(Id);
    
    PRINT 'Added CompanyId to Users table';
END
GO

-- 3. Create CompanyMaterialTypes table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='CompanyMaterialTypes' AND xtype='U')
BEGIN
    CREATE TABLE CompanyMaterialTypes (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId INT NOT NULL,
        TypeName NVARCHAR(50) NOT NULL,
        MaxBundleWeight INT NOT NULL DEFAULT 2000,
        Color NVARCHAR(20) NOT NULL DEFAULT 'secondary',
        ShowInQuickFilter BIT NOT NULL DEFAULT 1,
        DisplayOrder INT NOT NULL DEFAULT 0,
        IsSystemDefault BIT NOT NULL DEFAULT 0,
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        LastModified DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT FK_CompanyMaterialTypes_Companies FOREIGN KEY (CompanyId) REFERENCES Companies(Id),
        CONSTRAINT UQ_CompanyMaterialTypes_CompanyId_TypeName UNIQUE (CompanyId, TypeName)
    );
    
    -- Create index for performance
    CREATE INDEX IX_CompanyMaterialTypes_CompanyId ON CompanyMaterialTypes(CompanyId);
    
    PRINT 'Created CompanyMaterialTypes table';
END
GO

-- 4. Create CompanyMbeIdMappings table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='CompanyMbeIdMappings' AND xtype='U')
BEGIN
    CREATE TABLE CompanyMbeIdMappings (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId INT NOT NULL,
        MbeId NVARCHAR(20) NOT NULL,
        MaterialType NVARCHAR(50) NOT NULL,
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        LastModified DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT FK_CompanyMbeIdMappings_Companies FOREIGN KEY (CompanyId) REFERENCES Companies(Id),
        CONSTRAINT UQ_CompanyMbeIdMappings_CompanyId_MbeId UNIQUE (CompanyId, MbeId)
    );
    
    -- Create index for performance
    CREATE INDEX IX_CompanyMbeIdMappings_CompanyId ON CompanyMbeIdMappings(CompanyId);
    
    PRINT 'Created CompanyMbeIdMappings table';
END
GO

-- 5. Create CompanyMaterialPatterns table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='CompanyMaterialPatterns' AND xtype='U')
BEGIN
    CREATE TABLE CompanyMaterialPatterns (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId INT NOT NULL,
        MaterialType NVARCHAR(50) NOT NULL,
        Pattern NVARCHAR(100) NOT NULL,
        PatternType NVARCHAR(20) NOT NULL, -- 'Beam', 'Plate', 'Purlin', etc.
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        LastModified DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT FK_CompanyMaterialPatterns_Companies FOREIGN KEY (CompanyId) REFERENCES Companies(Id)
    );
    
    -- Create indexes for performance
    CREATE INDEX IX_CompanyMaterialPatterns_CompanyId ON CompanyMaterialPatterns(CompanyId);
    CREATE INDEX IX_CompanyMaterialPatterns_CompanyId_PatternType ON CompanyMaterialPatterns(CompanyId, PatternType);
    
    PRINT 'Created CompanyMaterialPatterns table';
END
GO

-- 6. Initialize default company settings
DECLARE @DefaultCompanyId INT;
SELECT @DefaultCompanyId = Id FROM Companies WHERE Code = 'default';

IF @DefaultCompanyId IS NOT NULL
BEGIN
    -- Insert default material types if they don't exist
    IF NOT EXISTS (SELECT * FROM CompanyMaterialTypes WHERE CompanyId = @DefaultCompanyId)
    BEGIN
        INSERT INTO CompanyMaterialTypes (CompanyId, TypeName, MaxBundleWeight, Color, ShowInQuickFilter, DisplayOrder, IsSystemDefault)
        VALUES 
            (@DefaultCompanyId, 'Beam', 3000, 'primary', 1, 0, 1),
            (@DefaultCompanyId, 'Plate', 3000, 'info', 1, 1, 1),
            (@DefaultCompanyId, 'Purlin', 2000, 'success', 1, 2, 1),
            (@DefaultCompanyId, 'Misc', 2000, 'secondary', 1, 3, 1),
            (@DefaultCompanyId, 'Fastener', 1000, 'warning', 0, 4, 0);
        
        PRINT 'Initialized default material types';
    END
    
    -- Insert default MBE ID mappings if they don't exist
    IF NOT EXISTS (SELECT * FROM CompanyMbeIdMappings WHERE CompanyId = @DefaultCompanyId)
    BEGIN
        INSERT INTO CompanyMbeIdMappings (CompanyId, MbeId, MaterialType)
        VALUES 
            (@DefaultCompanyId, 'B', 'Beam'),
            (@DefaultCompanyId, 'C', 'Beam'),
            (@DefaultCompanyId, 'PL', 'Plate'),
            (@DefaultCompanyId, 'P', 'Purlin'),
            (@DefaultCompanyId, 'F', 'Fastener'),
            (@DefaultCompanyId, 'M', 'Misc');
        
        PRINT 'Initialized default MBE ID mappings';
    END
    
    -- Insert default material patterns if they don't exist
    IF NOT EXISTS (SELECT * FROM CompanyMaterialPatterns WHERE CompanyId = @DefaultCompanyId)
    BEGIN
        -- Beam patterns
        INSERT INTO CompanyMaterialPatterns (CompanyId, MaterialType, Pattern, PatternType)
        VALUES 
            (@DefaultCompanyId, 'Beam', 'BEAM', 'Beam'),
            (@DefaultCompanyId, 'Beam', 'UB', 'Beam'),
            (@DefaultCompanyId, 'Beam', 'UC', 'Beam'),
            (@DefaultCompanyId, 'Beam', 'PFC', 'Beam'),
            (@DefaultCompanyId, 'Beam', 'RSJ', 'Beam'),
            (@DefaultCompanyId, 'Beam', 'HE', 'Beam'),
            (@DefaultCompanyId, 'Beam', 'IPE', 'Beam'),
            (@DefaultCompanyId, 'Beam', 'UKB', 'Beam'),
            (@DefaultCompanyId, 'Beam', 'UKC', 'Beam');
        
        -- Plate patterns
        INSERT INTO CompanyMaterialPatterns (CompanyId, MaterialType, Pattern, PatternType)
        VALUES 
            (@DefaultCompanyId, 'Plate', 'PLATE', 'Plate'),
            (@DefaultCompanyId, 'Plate', 'FL', 'Plate'),
            (@DefaultCompanyId, 'Plate', 'PL', 'Plate'),
            (@DefaultCompanyId, 'Plate', 'FLT', 'Plate'),
            (@DefaultCompanyId, 'Plate', 'PLT', 'Plate');
        
        -- Purlin patterns
        INSERT INTO CompanyMaterialPatterns (CompanyId, MaterialType, Pattern, PatternType)
        VALUES 
            (@DefaultCompanyId, 'Purlin', 'PURLIN', 'Purlin'),
            (@DefaultCompanyId, 'Purlin', 'C15', 'Purlin'),
            (@DefaultCompanyId, 'Purlin', 'C20', 'Purlin'),
            (@DefaultCompanyId, 'Purlin', 'C25', 'Purlin'),
            (@DefaultCompanyId, 'Purlin', 'C30', 'Purlin'),
            (@DefaultCompanyId, 'Purlin', 'Z15', 'Purlin'),
            (@DefaultCompanyId, 'Purlin', 'Z20', 'Purlin'),
            (@DefaultCompanyId, 'Purlin', 'Z25', 'Purlin'),
            (@DefaultCompanyId, 'Purlin', 'Z30', 'Purlin');
        
        -- Fastener patterns
        INSERT INTO CompanyMaterialPatterns (CompanyId, MaterialType, Pattern, PatternType)
        VALUES 
            (@DefaultCompanyId, 'Fastener', 'BOLT', 'Fastener'),
            (@DefaultCompanyId, 'Fastener', 'NUT', 'Fastener'),
            (@DefaultCompanyId, 'Fastener', 'WASHER', 'Fastener'),
            (@DefaultCompanyId, 'Fastener', 'SCREW', 'Fastener'),
            (@DefaultCompanyId, 'Fastener', 'FASTENER', 'Fastener');
        
        PRINT 'Initialized default material patterns';
    END
END
GO

-- 7. Create stored procedure for copying settings between companies
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_CopyCompanySettings')
    DROP PROCEDURE sp_CopyCompanySettings
GO

CREATE PROCEDURE sp_CopyCompanySettings
    @SourceCompanyId INT,
    @TargetCompanyId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Copy Material Types
        INSERT INTO CompanyMaterialTypes (CompanyId, TypeName, MaxBundleWeight, Color, ShowInQuickFilter, DisplayOrder, IsSystemDefault)
        SELECT @TargetCompanyId, TypeName, MaxBundleWeight, Color, ShowInQuickFilter, DisplayOrder, IsSystemDefault
        FROM CompanyMaterialTypes
        WHERE CompanyId = @SourceCompanyId
        AND NOT EXISTS (
            SELECT 1 FROM CompanyMaterialTypes t2 
            WHERE t2.CompanyId = @TargetCompanyId AND t2.TypeName = CompanyMaterialTypes.TypeName
        );
        
        -- Copy MBE ID Mappings
        INSERT INTO CompanyMbeIdMappings (CompanyId, MbeId, MaterialType)
        SELECT @TargetCompanyId, MbeId, MaterialType
        FROM CompanyMbeIdMappings
        WHERE CompanyId = @SourceCompanyId
        AND NOT EXISTS (
            SELECT 1 FROM CompanyMbeIdMappings t2 
            WHERE t2.CompanyId = @TargetCompanyId AND t2.MbeId = CompanyMbeIdMappings.MbeId
        );
        
        -- Copy Material Patterns
        INSERT INTO CompanyMaterialPatterns (CompanyId, MaterialType, Pattern, PatternType)
        SELECT @TargetCompanyId, MaterialType, Pattern, PatternType
        FROM CompanyMaterialPatterns
        WHERE CompanyId = @SourceCompanyId
        AND NOT EXISTS (
            SELECT 1 FROM CompanyMaterialPatterns t2 
            WHERE t2.CompanyId = @TargetCompanyId 
            AND t2.Pattern = CompanyMaterialPatterns.Pattern
            AND t2.PatternType = CompanyMaterialPatterns.PatternType
        );
        
        COMMIT TRANSACTION;
        PRINT 'Successfully copied settings from Company ' + CAST(@SourceCompanyId AS VARCHAR) + ' to Company ' + CAST(@TargetCompanyId AS VARCHAR);
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

PRINT 'Multi-tenant support migration completed successfully';