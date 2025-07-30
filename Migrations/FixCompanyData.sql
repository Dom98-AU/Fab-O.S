-- Check if Companies table exists and has data
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Companies')
BEGIN
    -- Check if default company exists
    IF NOT EXISTS (SELECT 1 FROM Companies WHERE Code = 'DEFAULT')
    BEGIN
        -- Insert default company
        INSERT INTO Companies (Name, Code, IsActive, CreatedDate)
        VALUES ('Default Company', 'DEFAULT', 1, GETUTCDATE());
        
        PRINT 'Default company created';
    END
    ELSE
    BEGIN
        PRINT 'Default company already exists';
    END
    
    -- Get the default company ID
    DECLARE @DefaultCompanyId INT;
    SELECT @DefaultCompanyId = Id FROM Companies WHERE Code = 'DEFAULT';
    
    -- Update users with CompanyId = 0 or NULL
    UPDATE Users 
    SET CompanyId = @DefaultCompanyId 
    WHERE CompanyId = 0 OR CompanyId IS NULL;
    
    PRINT 'Updated users with missing CompanyId';
    
    -- Show current state
    SELECT 'Companies' as TableName, COUNT(*) as RecordCount FROM Companies
    UNION ALL
    SELECT 'Users with CompanyId', COUNT(*) FROM Users WHERE CompanyId IS NOT NULL AND CompanyId > 0
    UNION ALL
    SELECT 'Users without CompanyId', COUNT(*) FROM Users WHERE CompanyId IS NULL OR CompanyId = 0;
    
    -- Show company details
    SELECT Id, Name, Code, IsActive FROM Companies;
    
    -- Show admin user details
    SELECT Id, Username, Email, CompanyId FROM Users WHERE Email = 'admin@steelestimation.com';
END
ELSE
BEGIN
    PRINT 'Companies table does not exist. Please run the multi-tenant migration first.';
END