-- Seed Multi-Tenant Data
-- This script creates a default company and copies material settings from appsettings

-- Check if Companies table exists
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Companies')
BEGIN
    PRINT 'Companies table does not exist. Please run AddMultiTenantSupport.sql first.'
    RETURN
END

-- Create default company if it doesn't exist
IF NOT EXISTS (SELECT 1 FROM Companies WHERE Code = 'DEFAULT')
BEGIN
    INSERT INTO Companies (Name, Code, IsActive, SubscriptionLevel, MaxUsers, CreatedDate, LastModified)
    VALUES ('Default Company', 'DEFAULT', 1, 'Standard', 10, GETUTCDATE(), GETUTCDATE())
    
    PRINT 'Created default company'
END

DECLARE @DefaultCompanyId INT
SELECT @DefaultCompanyId = Id FROM Companies WHERE Code = 'DEFAULT'

-- Update existing users to belong to default company
UPDATE Users 
SET CompanyId = @DefaultCompanyId 
WHERE CompanyId IS NULL

-- Seed material types if none exist
IF NOT EXISTS (SELECT 1 FROM CompanyMaterialTypes WHERE CompanyId = @DefaultCompanyId)
BEGIN
    INSERT INTO CompanyMaterialTypes (CompanyId, TypeName, Description, HourlyRate, DefaultWeightPerFoot, DefaultColor, DisplayOrder, IsActive, CreatedDate, LastModified)
    VALUES 
        (@DefaultCompanyId, 'Beam', 'Structural beams and columns', 65.00, NULL, '#007bff', 1, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'Plate', 'Steel plates and flat materials', 65.00, NULL, '#17a2b8', 2, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'Purlin', 'Roof and wall purlins', 65.00, NULL, '#28a745', 3, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'Fastener', 'Bolts, nuts, and fasteners', 65.00, NULL, '#ffc107', 4, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'Misc', 'Miscellaneous steel items', 65.00, NULL, '#6c757d', 5, 1, GETUTCDATE(), GETUTCDATE())
    
    PRINT 'Created default material types'
END

-- Seed MBE ID mappings if none exist
IF NOT EXISTS (SELECT 1 FROM CompanyMbeIdMappings WHERE CompanyId = @DefaultCompanyId)
BEGIN
    INSERT INTO CompanyMbeIdMappings (CompanyId, MbeId, MaterialType, WeightPerFoot, Notes, CreatedDate, LastModified)
    VALUES 
        (@DefaultCompanyId, 'B', 'Beam', NULL, 'Beam materials', GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'C', 'Beam', NULL, 'Column materials', GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'PL', 'Plate', NULL, 'Plate materials', GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'P', 'Purlin', NULL, 'Purlin materials', GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'F', 'Fastener', NULL, 'Fastener materials', GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'M', 'Misc', NULL, 'Miscellaneous materials', GETUTCDATE(), GETUTCDATE())
    
    PRINT 'Created default MBE ID mappings'
END

-- Seed material patterns if none exist
IF NOT EXISTS (SELECT 1 FROM CompanyMaterialPatterns WHERE CompanyId = @DefaultCompanyId)
BEGIN
    INSERT INTO CompanyMaterialPatterns (CompanyId, Pattern, MaterialType, PatternType, Priority, IsActive, CreatedDate, LastModified)
    VALUES 
        -- Beam patterns
        (@DefaultCompanyId, 'BEAM', 'Beam', 'Contains', 10, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'UB', 'Beam', 'StartsWith', 10, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'UC', 'Beam', 'StartsWith', 10, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'PFC', 'Beam', 'StartsWith', 10, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'RSJ', 'Beam', 'StartsWith', 10, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'HE', 'Beam', 'StartsWith', 10, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'IPE', 'Beam', 'StartsWith', 10, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'UKB', 'Beam', 'StartsWith', 10, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'UKC', 'Beam', 'StartsWith', 10, 1, GETUTCDATE(), GETUTCDATE()),
        
        -- Plate patterns
        (@DefaultCompanyId, 'PLATE', 'Plate', 'Contains', 20, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'FL', 'Plate', 'StartsWith', 20, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'PL', 'Plate', 'StartsWith', 20, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'FLT', 'Plate', 'StartsWith', 20, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'PLT', 'Plate', 'StartsWith', 20, 1, GETUTCDATE(), GETUTCDATE()),
        
        -- Purlin patterns
        (@DefaultCompanyId, 'PURLIN', 'Purlin', 'Contains', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'C15', 'Purlin', 'StartsWith', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'C20', 'Purlin', 'StartsWith', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'C25', 'Purlin', 'StartsWith', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'C30', 'Purlin', 'StartsWith', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'Z15', 'Purlin', 'StartsWith', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'Z20', 'Purlin', 'StartsWith', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'Z25', 'Purlin', 'StartsWith', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'Z30', 'Purlin', 'StartsWith', 30, 1, GETUTCDATE(), GETUTCDATE()),
        
        -- Fastener patterns
        (@DefaultCompanyId, 'BOLT', 'Fastener', 'Contains', 40, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'NUT', 'Fastener', 'Contains', 40, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'WASHER', 'Fastener', 'Contains', 40, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'SCREW', 'Fastener', 'Contains', 40, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'FASTENER', 'Fastener', 'Contains', 40, 1, GETUTCDATE(), GETUTCDATE())
    
    PRINT 'Created default material patterns'
END

PRINT 'Multi-tenant seed data completed successfully'