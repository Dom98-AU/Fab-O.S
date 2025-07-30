-- Add Settings table for application configuration
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Settings')
BEGIN
    CREATE TABLE Settings (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        [Key] NVARCHAR(100) NOT NULL UNIQUE,
        Value NVARCHAR(MAX) NOT NULL,
        ValueType NVARCHAR(50) NOT NULL DEFAULT 'string',
        Description NVARCHAR(500) NULL,
        Category NVARCHAR(50) NULL,
        IsSystemSetting BIT NOT NULL DEFAULT 0,
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        LastModified DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        LastModifiedBy INT NULL,
        CONSTRAINT FK_Settings_LastModifiedBy FOREIGN KEY (LastModifiedBy) REFERENCES Users(Id)
    );

    -- Create index on Key for faster lookups
    CREATE INDEX IX_Settings_Key ON Settings([Key]);
    
    -- Insert default settings
    INSERT INTO Settings ([Key], Value, ValueType, Description, Category, IsSystemSetting)
    VALUES 
    ('ShowEstimationNumbers', 'false', 'bool', 'Show unique estimation numbers in the estimation list', 'Display', 1),
    ('ShowCustomerNumbers', 'false', 'bool', 'Show unique customer numbers in the customer list', 'Display', 1),
    ('DefaultEstimationStage', 'Preliminary', 'string', 'Default stage for new estimations', 'Defaults', 1),
    ('DefaultLaborRate', '75.00', 'decimal', 'Default labor rate per hour for new packages', 'Defaults', 1),
    ('DefaultContingencyPercentage', '10.00', 'decimal', 'Default contingency percentage for new projects', 'Defaults', 1),
    ('EnableAutoSave', 'true', 'bool', 'Enable automatic saving of changes', 'System', 1),
    ('AutoSaveInterval', '30', 'int', 'Auto-save interval in seconds', 'System', 1);
    
    PRINT 'Settings table created successfully';
END
ELSE
BEGIN
    PRINT 'Settings table already exists';
END