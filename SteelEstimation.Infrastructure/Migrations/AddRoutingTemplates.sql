-- ===========================================
-- Routing Templates Migration Script
-- ===========================================
-- This script adds routing templates and operations 
-- for production workflow management
-- Date: 2025
-- ===========================================

-- Check if migration has already been run
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RoutingTemplates')
BEGIN
    PRINT 'Creating Routing Templates tables...';
    
    -- Create RoutingTemplates table
    CREATE TABLE [dbo].[RoutingTemplates] (
        [Id] int IDENTITY(1,1) NOT NULL,
        [Code] nvarchar(50) NOT NULL,
        [Name] nvarchar(200) NOT NULL,
        [Description] nvarchar(500) NULL,
        [CompanyId] int NOT NULL,
        [TemplateType] nvarchar(50) NOT NULL DEFAULT 'Standard',
        [ProductCategory] nvarchar(100) NULL,
        [MaterialType] nvarchar(100) NULL,
        [ComplexityLevel] nvarchar(20) NOT NULL DEFAULT 'Medium',
        [EstimatedTotalHours] decimal(10,2) NOT NULL DEFAULT 0,
        [DefaultEfficiencyPercentage] decimal(5,2) NOT NULL DEFAULT 100,
        [IncludesWelding] bit NOT NULL DEFAULT 0,
        [IncludesQualityControl] bit NOT NULL DEFAULT 1,
        [Version] nvarchar(20) NOT NULL DEFAULT '1.0',
        [IsActive] bit NOT NULL DEFAULT 1,
        [IsDefault] bit NOT NULL DEFAULT 0,
        [IsDeleted] bit NOT NULL DEFAULT 0,
        [UsageCount] int NOT NULL DEFAULT 0,
        [LastUsedDate] datetime2(7) NULL,
        [ApprovalStatus] nvarchar(50) NOT NULL DEFAULT 'Draft',
        [ApprovedByUserId] int NULL,
        [ApprovalDate] datetime2(7) NULL,
        [Notes] nvarchar(2000) NULL,
        [CreatedDate] datetime2(7) NOT NULL DEFAULT GETUTCDATE(),
        [CreatedByUserId] int NULL,
        [LastModified] datetime2(7) NOT NULL DEFAULT GETUTCDATE(),
        [LastModifiedByUserId] int NULL,
        CONSTRAINT [PK_RoutingTemplates] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_RoutingTemplates_Companies] FOREIGN KEY ([CompanyId]) REFERENCES [dbo].[Companies] ([Id]),
        CONSTRAINT [FK_RoutingTemplates_CreatedByUser] FOREIGN KEY ([CreatedByUserId]) REFERENCES [dbo].[Users] ([Id]),
        CONSTRAINT [FK_RoutingTemplates_LastModifiedByUser] FOREIGN KEY ([LastModifiedByUserId]) REFERENCES [dbo].[Users] ([Id]),
        CONSTRAINT [FK_RoutingTemplates_ApprovedByUser] FOREIGN KEY ([ApprovedByUserId]) REFERENCES [dbo].[Users] ([Id])
    );
    
    -- Create indexes for RoutingTemplates
    CREATE UNIQUE INDEX [IX_RoutingTemplates_CompanyId_Code] ON [dbo].[RoutingTemplates] ([CompanyId], [Code]);
    CREATE INDEX [IX_RoutingTemplates_IsActive] ON [dbo].[RoutingTemplates] ([IsActive]);
    CREATE INDEX [IX_RoutingTemplates_TemplateType] ON [dbo].[RoutingTemplates] ([TemplateType]);
    CREATE INDEX [IX_RoutingTemplates_ProductCategory] ON [dbo].[RoutingTemplates] ([ProductCategory]);
    CREATE INDEX [IX_RoutingTemplates_ApprovalStatus] ON [dbo].[RoutingTemplates] ([ApprovalStatus]);
    CREATE INDEX [IX_RoutingTemplates_UsageCount] ON [dbo].[RoutingTemplates] ([UsageCount]);
    
    PRINT 'RoutingTemplates table created successfully.';
END
ELSE
BEGIN
    PRINT 'RoutingTemplates table already exists. Skipping creation.';
END

-- Create RoutingOperations table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RoutingOperations')
BEGIN
    PRINT 'Creating RoutingOperations table...';
    
    CREATE TABLE [dbo].[RoutingOperations] (
        [Id] int IDENTITY(1,1) NOT NULL,
        [RoutingTemplateId] int NOT NULL,
        [WorkCenterId] int NOT NULL,
        [MachineCenterId] int NULL,
        [OperationCode] nvarchar(50) NOT NULL,
        [OperationName] nvarchar(200) NOT NULL,
        [Description] nvarchar(1000) NULL,
        [SequenceNumber] int NOT NULL,
        [OperationType] nvarchar(50) NOT NULL DEFAULT 'Processing',
        [SetupTimeMinutes] decimal(10,2) NOT NULL DEFAULT 0,
        [ProcessingTimePerUnit] decimal(10,2) NOT NULL DEFAULT 0,
        [ProcessingTimePerKg] decimal(10,2) NOT NULL DEFAULT 0,
        [MovementTimeMinutes] decimal(10,2) NOT NULL DEFAULT 0,
        [WaitingTimeMinutes] decimal(10,2) NOT NULL DEFAULT 0,
        [CalculationMethod] nvarchar(20) NOT NULL DEFAULT 'PerUnit',
        [RequiredOperators] int NOT NULL DEFAULT 1,
        [RequiredSkillLevel] nvarchar(100) NULL,
        [RequiresInspection] bit NOT NULL DEFAULT 0,
        [InspectionPercentage] decimal(5,2) NOT NULL DEFAULT 0,
        [PreviousOperationId] int NULL,
        [CanRunInParallel] bit NOT NULL DEFAULT 0,
        [OverrideHourlyRate] decimal(10,2) NULL,
        [MaterialCostPerUnit] decimal(10,2) NOT NULL DEFAULT 0,
        [ToolingCost] decimal(10,2) NOT NULL DEFAULT 0,
        [EfficiencyFactor] decimal(5,2) NOT NULL DEFAULT 100,
        [ScrapPercentage] decimal(5,2) NOT NULL DEFAULT 0,
        [WorkInstructions] nvarchar(2000) NULL,
        [SafetyNotes] nvarchar(1000) NULL,
        [QualityNotes] nvarchar(500) NULL,
        [IsActive] bit NOT NULL DEFAULT 1,
        [IsOptional] bit NOT NULL DEFAULT 0,
        [IsCriticalPath] bit NOT NULL DEFAULT 0,
        [CreatedDate] datetime2(7) NOT NULL DEFAULT GETUTCDATE(),
        [CreatedByUserId] int NULL,
        [LastModified] datetime2(7) NOT NULL DEFAULT GETUTCDATE(),
        [LastModifiedByUserId] int NULL,
        CONSTRAINT [PK_RoutingOperations] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_RoutingOperations_RoutingTemplates] FOREIGN KEY ([RoutingTemplateId]) REFERENCES [dbo].[RoutingTemplates] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_RoutingOperations_WorkCenters] FOREIGN KEY ([WorkCenterId]) REFERENCES [dbo].[WorkCenters] ([Id]),
        CONSTRAINT [FK_RoutingOperations_MachineCenters] FOREIGN KEY ([MachineCenterId]) REFERENCES [dbo].[MachineCenters] ([Id]),
        CONSTRAINT [FK_RoutingOperations_PreviousOperation] FOREIGN KEY ([PreviousOperationId]) REFERENCES [dbo].[RoutingOperations] ([Id]),
        CONSTRAINT [FK_RoutingOperations_CreatedByUser] FOREIGN KEY ([CreatedByUserId]) REFERENCES [dbo].[Users] ([Id]),
        CONSTRAINT [FK_RoutingOperations_LastModifiedByUser] FOREIGN KEY ([LastModifiedByUserId]) REFERENCES [dbo].[Users] ([Id])
    );
    
    -- Create indexes for RoutingOperations
    CREATE INDEX [IX_RoutingOperations_RoutingTemplateId] ON [dbo].[RoutingOperations] ([RoutingTemplateId]);
    CREATE INDEX [IX_RoutingOperations_WorkCenterId] ON [dbo].[RoutingOperations] ([WorkCenterId]);
    CREATE INDEX [IX_RoutingOperations_SequenceNumber] ON [dbo].[RoutingOperations] ([SequenceNumber]);
    CREATE INDEX [IX_RoutingOperations_OperationType] ON [dbo].[RoutingOperations] ([OperationType]);
    CREATE INDEX [IX_RoutingOperations_IsActive] ON [dbo].[RoutingOperations] ([IsActive]);
    
    PRINT 'RoutingOperations table created successfully.';
END
ELSE
BEGIN
    PRINT 'RoutingOperations table already exists. Skipping creation.';
END

-- Add RoutingTemplateId to Packages table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Packages]') AND name = 'RoutingTemplateId')
BEGIN
    PRINT 'Adding RoutingTemplateId column to Packages table...';
    
    ALTER TABLE [dbo].[Packages]
    ADD [RoutingTemplateId] int NULL;
    
    ALTER TABLE [dbo].[Packages]
    ADD CONSTRAINT [FK_Packages_RoutingTemplates] FOREIGN KEY ([RoutingTemplateId]) 
    REFERENCES [dbo].[RoutingTemplates] ([Id]);
    
    CREATE INDEX [IX_Packages_RoutingTemplateId] ON [dbo].[Packages] ([RoutingTemplateId]);
    
    PRINT 'RoutingTemplateId column added to Packages table successfully.';
END
ELSE
BEGIN
    PRINT 'RoutingTemplateId column already exists in Packages table. Skipping addition.';
END

-- Add RoutingOperationId to ProcessingItems table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'RoutingOperationId')
BEGIN
    PRINT 'Adding RoutingOperationId column to ProcessingItems table...';
    
    ALTER TABLE [dbo].[ProcessingItems]
    ADD [RoutingOperationId] int NULL;
    
    ALTER TABLE [dbo].[ProcessingItems]
    ADD CONSTRAINT [FK_ProcessingItems_RoutingOperations] FOREIGN KEY ([RoutingOperationId]) 
    REFERENCES [dbo].[RoutingOperations] ([Id]);
    
    CREATE INDEX [IX_ProcessingItems_RoutingOperationId] ON [dbo].[ProcessingItems] ([RoutingOperationId]);
    
    PRINT 'RoutingOperationId column added to ProcessingItems table successfully.';
END
ELSE
BEGIN
    PRINT 'RoutingOperationId column already exists in ProcessingItems table. Skipping addition.';
END

-- Insert sample routing templates for each company
PRINT 'Inserting sample routing templates...';

DECLARE @CompanyId int;
DECLARE @TemplateId int;
DECLARE @WC_Production int;
DECLARE @WC_Assembly int;
DECLARE @WC_Welding int;
DECLARE @WC_QC int;

-- Get the first company ID
SELECT TOP 1 @CompanyId = Id FROM [dbo].[Companies] WHERE IsActive = 1;

IF @CompanyId IS NOT NULL
BEGIN
    -- Get work center IDs (assuming they exist from previous migration)
    SELECT TOP 1 @WC_Production = Id FROM [dbo].[WorkCenters] WHERE CompanyId = @CompanyId AND WorkCenterType = 'Production';
    SELECT TOP 1 @WC_Assembly = Id FROM [dbo].[WorkCenters] WHERE CompanyId = @CompanyId AND WorkCenterType = 'Assembly';
    SELECT TOP 1 @WC_Welding = Id FROM [dbo].[WorkCenters] WHERE CompanyId = @CompanyId AND WorkCenterType = 'Welding';
    SELECT TOP 1 @WC_QC = Id FROM [dbo].[WorkCenters] WHERE CompanyId = @CompanyId AND WorkCenterType = 'QualityControl';
    
    -- If work centers don't exist, create basic ones
    IF @WC_Production IS NULL
    BEGIN
        INSERT INTO [dbo].[WorkCenters] (Code, Name, CompanyId, WorkCenterType, DailyCapacityHours, HourlyRate, OverheadRate, EfficiencyPercentage, IsActive)
        VALUES ('WC-PROD-001', 'Main Production', @CompanyId, 'Production', 8, 75, 25, 95, 1);
        SET @WC_Production = SCOPE_IDENTITY();
    END
    
    IF @WC_Assembly IS NULL
    BEGIN
        INSERT INTO [dbo].[WorkCenters] (Code, Name, CompanyId, WorkCenterType, DailyCapacityHours, HourlyRate, OverheadRate, EfficiencyPercentage, IsActive)
        VALUES ('WC-ASSY-001', 'Assembly Station', @CompanyId, 'Assembly', 8, 65, 20, 90, 1);
        SET @WC_Assembly = SCOPE_IDENTITY();
    END
    
    IF @WC_Welding IS NULL
    BEGIN
        INSERT INTO [dbo].[WorkCenters] (Code, Name, CompanyId, WorkCenterType, DailyCapacityHours, HourlyRate, OverheadRate, EfficiencyPercentage, IsActive)
        VALUES ('WC-WELD-001', 'Welding Bay', @CompanyId, 'Welding', 8, 85, 30, 88, 1);
        SET @WC_Welding = SCOPE_IDENTITY();
    END
    
    IF @WC_QC IS NULL
    BEGIN
        INSERT INTO [dbo].[WorkCenters] (Code, Name, CompanyId, WorkCenterType, DailyCapacityHours, HourlyRate, OverheadRate, EfficiencyPercentage, IsActive)
        VALUES ('WC-QC-001', 'Quality Control', @CompanyId, 'QualityControl', 8, 60, 15, 100, 1);
        SET @WC_QC = SCOPE_IDENTITY();
    END
    
    -- Template 1: Standard Steel Beam Processing
    IF NOT EXISTS (SELECT * FROM [dbo].[RoutingTemplates] WHERE Code = 'RT-STD-BEAM' AND CompanyId = @CompanyId)
    BEGIN
        INSERT INTO [dbo].[RoutingTemplates] 
        (Code, Name, Description, CompanyId, TemplateType, ProductCategory, MaterialType, ComplexityLevel, 
         EstimatedTotalHours, DefaultEfficiencyPercentage, IncludesWelding, IncludesQualityControl, 
         Version, IsActive, IsDefault, ApprovalStatus)
        VALUES 
        ('RT-STD-BEAM', 'Standard Steel Beam Processing', 'Standard routing for steel beam fabrication', 
         @CompanyId, 'Standard', 'Steel Beams', 'Carbon Steel', 'Medium', 
         4.5, 95, 1, 1, '1.0', 1, 1, 'Approved');
        
        SET @TemplateId = SCOPE_IDENTITY();
        
        -- Add operations for this template
        INSERT INTO [dbo].[RoutingOperations] 
        (RoutingTemplateId, WorkCenterId, OperationCode, OperationName, SequenceNumber, OperationType,
         SetupTimeMinutes, ProcessingTimePerUnit, CalculationMethod, RequiredOperators, IsActive)
        VALUES 
        (@TemplateId, @WC_Production, 'OP-010', 'Material Preparation', 1, 'Setup', 15, 5, 'PerUnit', 1, 1),
        (@TemplateId, @WC_Production, 'OP-020', 'Cutting', 2, 'Processing', 10, 15, 'PerUnit', 1, 1),
        (@TemplateId, @WC_Production, 'OP-030', 'Drilling', 3, 'Processing', 5, 10, 'PerUnit', 1, 1),
        (@TemplateId, @WC_Welding, 'OP-040', 'Welding', 4, 'Processing', 20, 30, 'PerUnit', 2, 1),
        (@TemplateId, @WC_QC, 'OP-050', 'Quality Inspection', 5, 'QualityControl', 5, 10, 'PerUnit', 1, 1);
    END
    
    -- Template 2: Express Plate Processing
    IF NOT EXISTS (SELECT * FROM [dbo].[RoutingTemplates] WHERE Code = 'RT-EXP-PLATE' AND CompanyId = @CompanyId)
    BEGIN
        INSERT INTO [dbo].[RoutingTemplates] 
        (Code, Name, Description, CompanyId, TemplateType, ProductCategory, MaterialType, ComplexityLevel, 
         EstimatedTotalHours, DefaultEfficiencyPercentage, IncludesWelding, IncludesQualityControl, 
         Version, IsActive, ApprovalStatus)
        VALUES 
        ('RT-EXP-PLATE', 'Express Plate Processing', 'Quick routing for simple plate cutting', 
         @CompanyId, 'Express', 'Plates', 'Carbon Steel', 'Simple', 
         2.0, 98, 0, 1, '1.0', 1, 'Approved');
        
        SET @TemplateId = SCOPE_IDENTITY();
        
        -- Add operations for this template
        INSERT INTO [dbo].[RoutingOperations] 
        (RoutingTemplateId, WorkCenterId, OperationCode, OperationName, SequenceNumber, OperationType,
         SetupTimeMinutes, ProcessingTimePerUnit, CalculationMethod, RequiredOperators, IsActive)
        VALUES 
        (@TemplateId, @WC_Production, 'OP-010', 'Setup', 1, 'Setup', 10, 0, 'Fixed', 1, 1),
        (@TemplateId, @WC_Production, 'OP-020', 'Plasma Cutting', 2, 'Processing', 5, 8, 'PerUnit', 1, 1),
        (@TemplateId, @WC_QC, 'OP-030', 'Dimension Check', 3, 'QualityControl', 0, 5, 'PerUnit', 1, 1);
    END
    
    -- Template 3: Complex Assembly
    IF NOT EXISTS (SELECT * FROM [dbo].[RoutingTemplates] WHERE Code = 'RT-CPX-ASSY' AND CompanyId = @CompanyId)
    BEGIN
        INSERT INTO [dbo].[RoutingTemplates] 
        (Code, Name, Description, CompanyId, TemplateType, ProductCategory, MaterialType, ComplexityLevel, 
         EstimatedTotalHours, DefaultEfficiencyPercentage, IncludesWelding, IncludesQualityControl, 
         Version, IsActive, ApprovalStatus)
        VALUES 
        ('RT-CPX-ASSY', 'Complex Assembly Process', 'Multi-stage assembly with welding and inspection', 
         @CompanyId, 'Complex', 'Assemblies', 'Mixed Materials', 'Complex', 
         8.5, 85, 1, 1, '1.0', 1, 'Approved');
        
        SET @TemplateId = SCOPE_IDENTITY();
        
        -- Add operations for this template
        INSERT INTO [dbo].[RoutingOperations] 
        (RoutingTemplateId, WorkCenterId, OperationCode, OperationName, SequenceNumber, OperationType,
         SetupTimeMinutes, ProcessingTimePerUnit, CalculationMethod, RequiredOperators, 
         RequiresInspection, InspectionPercentage, IsActive, IsCriticalPath)
        VALUES 
        (@TemplateId, @WC_Production, 'OP-010', 'Component Preparation', 1, 'Setup', 30, 10, 'PerUnit', 2, 0, 0, 1, 1),
        (@TemplateId, @WC_Assembly, 'OP-020', 'Pre-Assembly', 2, 'Processing', 15, 20, 'PerUnit', 2, 0, 0, 1, 1),
        (@TemplateId, @WC_Welding, 'OP-030', 'Tack Welding', 3, 'Processing', 10, 15, 'PerUnit', 1, 0, 0, 1, 1),
        (@TemplateId, @WC_Assembly, 'OP-040', 'Final Assembly', 4, 'Processing', 20, 30, 'PerUnit', 3, 0, 0, 1, 1),
        (@TemplateId, @WC_Welding, 'OP-050', 'Final Welding', 5, 'Processing', 30, 45, 'PerUnit', 2, 1, 100, 1, 1),
        (@TemplateId, @WC_QC, 'OP-060', 'NDT Testing', 6, 'QualityControl', 15, 20, 'PerUnit', 1, 1, 100, 1, 0),
        (@TemplateId, @WC_QC, 'OP-070', 'Final Inspection', 7, 'QualityControl', 10, 15, 'PerUnit', 1, 1, 100, 1, 0);
    END
    
    PRINT 'Sample routing templates inserted successfully.';
END
ELSE
BEGIN
    PRINT 'No active company found. Skipping sample data insertion.';
END

-- Update statistics
UPDATE STATISTICS [dbo].[RoutingTemplates];
UPDATE STATISTICS [dbo].[RoutingOperations];
UPDATE STATISTICS [dbo].[Packages];
UPDATE STATISTICS [dbo].[ProcessingItems];

PRINT 'Routing Templates migration completed successfully.';