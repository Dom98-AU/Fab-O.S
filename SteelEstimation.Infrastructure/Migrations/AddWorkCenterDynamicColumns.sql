-- Migration: Add WorkCenter Dynamic Columns and Dependencies
-- Date: 2025-01-08
-- Description: Adds support for dynamic WorkCenter columns in worksheets with manual time entry and automatic cost calculation

-- 1. Create ProcessingItemWorkCenterTime table for manual time entries per WorkCenter
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ProcessingItemWorkCenterTimes')
BEGIN
    CREATE TABLE ProcessingItemWorkCenterTimes (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ProcessingItemId INT NOT NULL,
        WorkCenterId INT NOT NULL,
        ManualTimeMinutes DECIMAL(10,2) NOT NULL DEFAULT 0,
        OverrideHourlyRate DECIMAL(10,2) NULL,
        DependencyFactor DECIMAL(5,2) NOT NULL DEFAULT 1.0,
        Notes NVARCHAR(500) NULL,
        CalculatedCost DECIMAL(12,2) NOT NULL DEFAULT 0,
        EffectiveTimeMinutes DECIMAL(10,2) NOT NULL DEFAULT 0,
        IsCompleted BIT NOT NULL DEFAULT 0,
        CompletedDate DATETIME2 NULL,
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        LastModified DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        LastModifiedByUserId INT NULL,
        RowVersion ROWVERSION,
        
        CONSTRAINT FK_ProcessingItemWorkCenterTimes_ProcessingItem 
            FOREIGN KEY (ProcessingItemId) REFERENCES ProcessingItems(Id) ON DELETE CASCADE,
        CONSTRAINT FK_ProcessingItemWorkCenterTimes_WorkCenter 
            FOREIGN KEY (WorkCenterId) REFERENCES WorkCenters(Id),
        CONSTRAINT FK_ProcessingItemWorkCenterTimes_User 
            FOREIGN KEY (LastModifiedByUserId) REFERENCES Users(Id)
    );
    
    CREATE INDEX IX_ProcessingItemWorkCenterTimes_ProcessingItem 
        ON ProcessingItemWorkCenterTimes(ProcessingItemId);
    CREATE INDEX IX_ProcessingItemWorkCenterTimes_WorkCenter 
        ON ProcessingItemWorkCenterTimes(WorkCenterId);
    
    PRINT 'Created ProcessingItemWorkCenterTimes table';
END

-- 2. Create WorkCenterDependencies table for defining operation dependencies
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'WorkCenterDependencies')
BEGIN
    CREATE TABLE WorkCenterDependencies (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        DependentWorkCenterId INT NOT NULL,
        RequiredWorkCenterId INT NOT NULL,
        RoutingId INT NULL,
        DependencyType NVARCHAR(50) NOT NULL DEFAULT 'Sequential',
        TimeMultiplier DECIMAL(5,2) NOT NULL DEFAULT 1.0,
        QualityFactor DECIMAL(5,2) NOT NULL DEFAULT 1.0,
        MinimumGapMinutes DECIMAL(10,2) NOT NULL DEFAULT 0,
        MaximumGapMinutes DECIMAL(10,2) NOT NULL DEFAULT 0,
        ConditionExpression NVARCHAR(1000) NULL,
        IsMandatory BIT NOT NULL DEFAULT 1,
        Description NVARCHAR(500) NULL,
        CompanyId INT NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        CreatedByUserId INT NULL,
        LastModified DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        LastModifiedByUserId INT NULL,
        
        CONSTRAINT FK_WorkCenterDependencies_DependentWorkCenter 
            FOREIGN KEY (DependentWorkCenterId) REFERENCES WorkCenters(Id),
        CONSTRAINT FK_WorkCenterDependencies_RequiredWorkCenter 
            FOREIGN KEY (RequiredWorkCenterId) REFERENCES WorkCenters(Id),
        CONSTRAINT FK_WorkCenterDependencies_Routing 
            FOREIGN KEY (RoutingId) REFERENCES RoutingTemplates(Id) ON DELETE CASCADE,
        CONSTRAINT FK_WorkCenterDependencies_Company 
            FOREIGN KEY (CompanyId) REFERENCES Companies(Id),
        CONSTRAINT FK_WorkCenterDependencies_CreatedByUser 
            FOREIGN KEY (CreatedByUserId) REFERENCES Users(Id),
        CONSTRAINT FK_WorkCenterDependencies_LastModifiedByUser 
            FOREIGN KEY (LastModifiedByUserId) REFERENCES Users(Id)
    );
    
    CREATE INDEX IX_WorkCenterDependencies_DependentWorkCenter 
        ON WorkCenterDependencies(DependentWorkCenterId);
    CREATE INDEX IX_WorkCenterDependencies_RequiredWorkCenter 
        ON WorkCenterDependencies(RequiredWorkCenterId);
    CREATE INDEX IX_WorkCenterDependencies_Routing 
        ON WorkCenterDependencies(RoutingId);
    CREATE INDEX IX_WorkCenterDependencies_Company 
        ON WorkCenterDependencies(CompanyId);
    
    PRINT 'Created WorkCenterDependencies table';
END

-- 3. Add new cost structure fields to WorkCenters table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('WorkCenters') AND name = 'DirectLaborRate')
BEGIN
    ALTER TABLE WorkCenters ADD DirectLaborRate DECIMAL(10,2) NOT NULL DEFAULT 0;
    PRINT 'Added DirectLaborRate to WorkCenters';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('WorkCenters') AND name = 'IndirectLaborRate')
BEGIN
    ALTER TABLE WorkCenters ADD IndirectLaborRate DECIMAL(10,2) NOT NULL DEFAULT 0;
    PRINT 'Added IndirectLaborRate to WorkCenters';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('WorkCenters') AND name = 'OverheadPercentage')
BEGIN
    ALTER TABLE WorkCenters ADD OverheadPercentage DECIMAL(10,2) NOT NULL DEFAULT 0;
    PRINT 'Added OverheadPercentage to WorkCenters';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('WorkCenters') AND name = 'OtherCostsRate')
BEGIN
    ALTER TABLE WorkCenters ADD OtherCostsRate DECIMAL(10,2) NOT NULL DEFAULT 0;
    PRINT 'Added OtherCostsRate to WorkCenters';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('WorkCenters') AND name = 'ProfitCalculationType')
BEGIN
    ALTER TABLE WorkCenters ADD ProfitCalculationType NVARCHAR(20) NOT NULL DEFAULT 'Percentage';
    PRINT 'Added ProfitCalculationType to WorkCenters';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('WorkCenters') AND name = 'ProfitValue')
BEGIN
    ALTER TABLE WorkCenters ADD ProfitValue DECIMAL(10,2) NOT NULL DEFAULT 30;
    PRINT 'Added ProfitValue to WorkCenters';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('WorkCenters') AND name = 'CostingMethod')
BEGIN
    ALTER TABLE WorkCenters ADD CostingMethod NVARCHAR(20) NOT NULL DEFAULT 'Simple';
    PRINT 'Added CostingMethod to WorkCenters';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('WorkCenters') AND name = 'DependencyFactor')
BEGIN
    ALTER TABLE WorkCenters ADD DependencyFactor DECIMAL(5,2) NOT NULL DEFAULT 1.0;
    PRINT 'Added DependencyFactor to WorkCenters';
END

-- 4. Rename RoutingTemplateId to RoutingId in Packages table
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Packages') AND name = 'RoutingTemplateId')
BEGIN
    -- Drop the existing foreign key constraint
    IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Packages_RoutingTemplate')
    BEGIN
        ALTER TABLE Packages DROP CONSTRAINT FK_Packages_RoutingTemplate;
    END
    
    -- Rename the column
    EXEC sp_rename 'Packages.RoutingTemplateId', 'RoutingId', 'COLUMN';
    
    -- Re-add the foreign key constraint with new name
    ALTER TABLE Packages 
        ADD CONSTRAINT FK_Packages_Routing 
        FOREIGN KEY (RoutingId) REFERENCES RoutingTemplates(Id);
    
    PRINT 'Renamed RoutingTemplateId to RoutingId in Packages table';
END

-- 5. Create sample WorkCenter dependencies for existing companies (optional demo data)
-- This creates a simple sequential dependency chain for demonstration
DECLARE @CompanyId INT;
DECLARE company_cursor CURSOR FOR 
    SELECT Id FROM Companies WHERE IsActive = 1;

OPEN company_cursor;
FETCH NEXT FROM company_cursor INTO @CompanyId;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Check if this company has work centers
    IF EXISTS (SELECT 1 FROM WorkCenters WHERE CompanyId = @CompanyId)
    BEGIN
        -- Create a sample dependency: Cutting must happen before Welding
        DECLARE @CuttingId INT, @WeldingId INT;
        
        SELECT TOP 1 @CuttingId = Id FROM WorkCenters 
            WHERE CompanyId = @CompanyId AND Name LIKE '%Cut%';
        
        SELECT TOP 1 @WeldingId = Id FROM WorkCenters 
            WHERE CompanyId = @CompanyId AND Name LIKE '%Weld%';
        
        IF @CuttingId IS NOT NULL AND @WeldingId IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM WorkCenterDependencies 
                          WHERE DependentWorkCenterId = @WeldingId 
                          AND RequiredWorkCenterId = @CuttingId)
            BEGIN
                INSERT INTO WorkCenterDependencies (
                    DependentWorkCenterId, RequiredWorkCenterId, CompanyId,
                    DependencyType, TimeMultiplier, Description
                ) VALUES (
                    @WeldingId, @CuttingId, @CompanyId,
                    'Sequential', 1.0, 'Cutting must be completed before welding'
                );
                
                PRINT 'Created sample dependency for Company ' + CAST(@CompanyId AS VARCHAR);
            END
        END
    END
    
    FETCH NEXT FROM company_cursor INTO @CompanyId;
END

CLOSE company_cursor;
DEALLOCATE company_cursor;

-- 6. Update existing WorkCenters with sample cost structure (if they only have simple rates)
UPDATE WorkCenters
SET 
    DirectLaborRate = HourlyRate * 0.6,  -- 60% of hourly rate as direct labor
    IndirectLaborRate = HourlyRate * 0.2, -- 20% as indirect labor
    OverheadPercentage = 20,              -- 20% overhead on labor
    CostingMethod = 'Detailed'
WHERE DirectLaborRate = 0 
    AND HourlyRate > 0;

PRINT 'Updated existing WorkCenters with detailed cost structure';

-- 7. Create indexes for performance
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ProcessingItemWorkCenterTimes_Composite')
BEGIN
    CREATE INDEX IX_ProcessingItemWorkCenterTimes_Composite 
        ON ProcessingItemWorkCenterTimes(ProcessingItemId, WorkCenterId)
        INCLUDE (ManualTimeMinutes, CalculatedCost);
    PRINT 'Created composite index on ProcessingItemWorkCenterTimes';
END

PRINT 'Migration completed successfully';