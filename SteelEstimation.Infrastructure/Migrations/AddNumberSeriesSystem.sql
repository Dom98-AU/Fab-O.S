-- Add NumberSeries table for auto-numbering system
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'NumberSeries')
BEGIN
    CREATE TABLE NumberSeries (
        Id INT PRIMARY KEY IDENTITY(1,1),
        CompanyId INT NOT NULL,
        EntityType NVARCHAR(50) NOT NULL,
        Prefix NVARCHAR(20),
        Suffix NVARCHAR(20),
        CurrentNumber INT NOT NULL DEFAULT 0,
        StartingNumber INT NOT NULL DEFAULT 1,
        IncrementBy INT NOT NULL DEFAULT 1,
        MinDigits INT NOT NULL DEFAULT 5,
        Format NVARCHAR(100),
        IncludeYear BIT NOT NULL DEFAULT 0,
        IncludeMonth BIT NOT NULL DEFAULT 0,
        IncludeCompanyCode BIT NOT NULL DEFAULT 0,
        ResetYearly BIT NOT NULL DEFAULT 0,
        ResetMonthly BIT NOT NULL DEFAULT 0,
        LastResetYear INT,
        LastResetMonth INT,
        IsActive BIT NOT NULL DEFAULT 1,
        AllowManualEntry BIT NOT NULL DEFAULT 1,
        Description NVARCHAR(200),
        PreviewExample NVARCHAR(50),
        LastUsed DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        LastModified DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        CreatedByUserId INT,
        LastModifiedByUserId INT,
        CONSTRAINT UK_NumberSeries UNIQUE(CompanyId, EntityType),
        CONSTRAINT FK_NumberSeries_Company FOREIGN KEY (CompanyId) REFERENCES Companies(Id),
        CONSTRAINT FK_NumberSeries_CreatedByUser FOREIGN KEY (CreatedByUserId) REFERENCES Users(Id),
        CONSTRAINT FK_NumberSeries_LastModifiedByUser FOREIGN KEY (LastModifiedByUserId) REFERENCES Users(Id)
    );
    
    PRINT 'NumberSeries table created successfully';
END
ELSE
BEGIN
    PRINT 'NumberSeries table already exists';
END
GO

-- Create index for faster lookups
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_NumberSeries_CompanyId_EntityType')
BEGIN
    CREATE INDEX IX_NumberSeries_CompanyId_EntityType ON NumberSeries(CompanyId, EntityType);
    PRINT 'Index IX_NumberSeries_CompanyId_EntityType created';
END
GO

-- Insert default number series configurations for each company
-- Only insert if no configurations exist for the company
INSERT INTO NumberSeries (CompanyId, EntityType, Prefix, CurrentNumber, StartingNumber, MinDigits, Description)
SELECT DISTINCT c.Id, 'Customer', 'CUST-', 0, 1, 5, 'Customer numbering'
FROM Companies c
WHERE NOT EXISTS (SELECT 1 FROM NumberSeries ns WHERE ns.CompanyId = c.Id AND ns.EntityType = 'Customer');

INSERT INTO NumberSeries (CompanyId, EntityType, Prefix, CurrentNumber, StartingNumber, MinDigits, Description)
SELECT DISTINCT c.Id, 'Project', 'PROJ-', 0, 1, 5, 'Project numbering'
FROM Companies c
WHERE NOT EXISTS (SELECT 1 FROM NumberSeries ns WHERE ns.CompanyId = c.Id AND ns.EntityType = 'Project');

INSERT INTO NumberSeries (CompanyId, EntityType, Prefix, CurrentNumber, StartingNumber, MinDigits, Description)
SELECT DISTINCT c.Id, 'Package', 'PKG-', 0, 1, 5, 'Package numbering'
FROM Companies c
WHERE NOT EXISTS (SELECT 1 FROM NumberSeries ns WHERE ns.CompanyId = c.Id AND ns.EntityType = 'Package');

INSERT INTO NumberSeries (CompanyId, EntityType, Prefix, CurrentNumber, StartingNumber, MinDigits, Description)
SELECT DISTINCT c.Id, 'WorkCenter', 'WC-', 0, 1, 3, 'Work center codes'
FROM Companies c
WHERE NOT EXISTS (SELECT 1 FROM NumberSeries ns WHERE ns.CompanyId = c.Id AND ns.EntityType = 'WorkCenter');

INSERT INTO NumberSeries (CompanyId, EntityType, Prefix, CurrentNumber, StartingNumber, MinDigits, Description)
SELECT DISTINCT c.Id, 'MachineCenter', 'MC-', 0, 1, 3, 'Machine center codes'
FROM Companies c
WHERE NOT EXISTS (SELECT 1 FROM NumberSeries ns WHERE ns.CompanyId = c.Id AND ns.EntityType = 'MachineCenter');

INSERT INTO NumberSeries (CompanyId, EntityType, Prefix, CurrentNumber, StartingNumber, MinDigits, Description)
SELECT DISTINCT c.Id, 'RoutingTemplate', 'RT-', 0, 1, 3, 'Routing template codes'
FROM Companies c
WHERE NOT EXISTS (SELECT 1 FROM NumberSeries ns WHERE ns.CompanyId = c.Id AND ns.EntityType = 'RoutingTemplate');

INSERT INTO NumberSeries (CompanyId, EntityType, Prefix, CurrentNumber, StartingNumber, MinDigits, Description)
SELECT DISTINCT c.Id, 'Estimation', 'EST-', 0, 1, 5, 'Estimation numbering'
FROM Companies c
WHERE NOT EXISTS (SELECT 1 FROM NumberSeries ns WHERE ns.CompanyId = c.Id AND ns.EntityType = 'Estimation');

INSERT INTO NumberSeries (CompanyId, EntityType, Prefix, CurrentNumber, StartingNumber, MinDigits, Description)
SELECT DISTINCT c.Id, 'User', 'USR-', 0, 1, 4, 'User codes'
FROM Companies c
WHERE NOT EXISTS (SELECT 1 FROM NumberSeries ns WHERE ns.CompanyId = c.Id AND ns.EntityType = 'User');

INSERT INTO NumberSeries (CompanyId, EntityType, Prefix, CurrentNumber, StartingNumber, MinDigits, Description)
SELECT DISTINCT c.Id, 'Material', 'MAT-', 0, 1, 3, 'Material codes'
FROM Companies c
WHERE NOT EXISTS (SELECT 1 FROM NumberSeries ns WHERE ns.CompanyId = c.Id AND ns.EntityType = 'Material');

INSERT INTO NumberSeries (CompanyId, EntityType, Prefix, CurrentNumber, StartingNumber, MinDigits, Description)
SELECT DISTINCT c.Id, 'ProcessingItem', 'PI-', 0, 1, 6, 'Processing item numbering'
FROM Companies c
WHERE NOT EXISTS (SELECT 1 FROM NumberSeries ns WHERE ns.CompanyId = c.Id AND ns.EntityType = 'ProcessingItem');

INSERT INTO NumberSeries (CompanyId, EntityType, Prefix, CurrentNumber, StartingNumber, MinDigits, Description)
SELECT DISTINCT c.Id, 'WeldingItem', 'WI-', 0, 1, 6, 'Welding item numbering'
FROM Companies c
WHERE NOT EXISTS (SELECT 1 FROM NumberSeries ns WHERE ns.CompanyId = c.Id AND ns.EntityType = 'WeldingItem');

PRINT 'Default number series configurations created';
GO

-- Update preview examples for all series
UPDATE NumberSeries
SET PreviewExample = 
    CASE EntityType
        WHEN 'Customer' THEN 'CUST-00001'
        WHEN 'Project' THEN 'PROJ-00001'
        WHEN 'Package' THEN 'PKG-00001'
        WHEN 'WorkCenter' THEN 'WC-001'
        WHEN 'MachineCenter' THEN 'MC-001'
        WHEN 'RoutingTemplate' THEN 'RT-001'
        WHEN 'Estimation' THEN 'EST-00001'
        WHEN 'User' THEN 'USR-0001'
        WHEN 'Material' THEN 'MAT-001'
        WHEN 'ProcessingItem' THEN 'PI-000001'
        WHEN 'WeldingItem' THEN 'WI-000001'
        ELSE NULL
    END
WHERE PreviewExample IS NULL;

PRINT 'Number series preview examples updated';
GO

-- Create stored procedure for getting next number (with locking to prevent duplicates)
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'sp_GetNextNumber')
    DROP PROCEDURE sp_GetNextNumber;
GO

CREATE PROCEDURE sp_GetNextNumber
    @CompanyId INT,
    @EntityType NVARCHAR(50),
    @NextNumber NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
    
    -- Lock the row to prevent concurrent access
    UPDATE NumberSeries WITH (ROWLOCK, UPDLOCK)
    SET CurrentNumber = CurrentNumber + IncrementBy,
        LastUsed = GETUTCDATE()
    WHERE CompanyId = @CompanyId AND EntityType = @EntityType AND IsActive = 1;
    
    -- Get the formatted number
    SELECT @NextNumber = 
        ISNULL(Prefix, '') + 
        RIGHT(REPLICATE('0', MinDigits) + CAST(CurrentNumber AS NVARCHAR), MinDigits) +
        ISNULL(Suffix, '')
    FROM NumberSeries
    WHERE CompanyId = @CompanyId AND EntityType = @EntityType;
    
    COMMIT TRANSACTION;
    
    RETURN 0;
END
GO

PRINT 'Stored procedure sp_GetNextNumber created';
PRINT 'Number Series migration completed successfully';