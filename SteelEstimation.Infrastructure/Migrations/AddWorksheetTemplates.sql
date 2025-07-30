-- Migration: Add Worksheet Templates System
-- Description: Adds support for customizable worksheet templates

-- 1. Create WorksheetTemplates table
CREATE TABLE WorksheetTemplates (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500) NULL,
    BaseType NVARCHAR(50) NOT NULL, -- 'Processing' or 'Welding'
    CreatedByUserId INT NOT NULL,
    IsPublished BIT NOT NULL DEFAULT 0, -- Personal use only
    IsGlobal BIT NOT NULL DEFAULT 0, -- Admin published for everyone
    IsDefault BIT NOT NULL DEFAULT 0, -- Replaces current fixed worksheets
    AllowColumnReorder BIT NOT NULL DEFAULT 1,
    DisplayOrder INT NOT NULL DEFAULT 0,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    LastModified DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    INDEX IX_WorksheetTemplates_BaseType (BaseType),
    INDEX IX_WorksheetTemplates_CreatedByUserId (CreatedByUserId),
    INDEX IX_WorksheetTemplates_IsGlobal (IsGlobal)
);

-- 2. Create WorksheetTemplateFields table
CREATE TABLE WorksheetTemplateFields (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    WorksheetTemplateId INT NOT NULL,
    FieldName NVARCHAR(100) NOT NULL, -- Matches property names
    DisplayName NVARCHAR(200) NULL, -- Custom label override
    IsVisible BIT NOT NULL DEFAULT 1,
    IsRequired BIT NOT NULL DEFAULT 0,
    DisplayOrder INT NOT NULL DEFAULT 0,
    ColumnWidth INT NULL, -- pixels
    IsFrozen BIT NOT NULL DEFAULT 0,
    
    CONSTRAINT FK_WorksheetTemplateFields_WorksheetTemplates 
        FOREIGN KEY (WorksheetTemplateId) REFERENCES WorksheetTemplates(Id) ON DELETE CASCADE,
    
    INDEX IX_WorksheetTemplateFields_WorksheetTemplateId (WorksheetTemplateId),
    CONSTRAINT UQ_WorksheetTemplateFields_Template_Field 
        UNIQUE (WorksheetTemplateId, FieldName)
);

-- 3. Create FieldDependencies table
CREATE TABLE FieldDependencies (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    BaseType NVARCHAR(50) NOT NULL, -- 'Processing' or 'Welding'
    FieldName NVARCHAR(100) NOT NULL,
    DependsOnField NVARCHAR(100) NOT NULL,
    DependencyType NVARCHAR(50) NOT NULL, -- 'Required' or 'Calculated'
    CalculationRule NVARCHAR(500) NULL,
    
    INDEX IX_FieldDependencies_BaseType_FieldName (BaseType, FieldName)
);

-- 4. Add WorksheetTemplateId to PackageWorksheets
ALTER TABLE PackageWorksheets
ADD WorksheetTemplateId INT NULL,
    CONSTRAINT FK_PackageWorksheets_WorksheetTemplates 
        FOREIGN KEY (WorksheetTemplateId) REFERENCES WorksheetTemplates(Id);

-- 5. Insert field dependencies for Processing worksheet
INSERT INTO FieldDependencies (BaseType, FieldName, DependsOnField, DependencyType, CalculationRule) VALUES
-- TotalWeight dependencies
('Processing', 'TotalWeight', 'Quantity', 'Required', 'Weight * Quantity'),
('Processing', 'TotalWeight', 'Weight', 'Required', 'Weight * Quantity'),
-- Total Hours dependencies (all time fields)
('Processing', 'TotalHours', 'UnloadTime', 'Required', NULL),
('Processing', 'TotalHours', 'MarkMeasureCut', 'Required', NULL),
('Processing', 'TotalHours', 'QualityCheck', 'Required', NULL),
('Processing', 'TotalHours', 'MoveToAssembly', 'Required', NULL),
('Processing', 'TotalHours', 'MoveAfterWeld', 'Required', NULL),
('Processing', 'TotalHours', 'LoadingTime', 'Required', NULL);

-- 6. Insert field dependencies for Welding worksheet
INSERT INTO FieldDependencies (BaseType, FieldName, DependsOnField, DependencyType, CalculationRule) VALUES
-- ConnectionHours dependencies
('Welding', 'ConnectionHours', 'ConnectionType', 'Required', NULL),
('Welding', 'ConnectionHours', 'AssembleFitTack', 'Required', NULL),
('Welding', 'ConnectionHours', 'Weld', 'Required', NULL),
('Welding', 'ConnectionHours', 'WeldCheck', 'Required', NULL),
-- TotalHours dependencies
('Welding', 'TotalHours', 'AssembleFitTack', 'Required', NULL),
('Welding', 'TotalHours', 'Weld', 'Required', NULL),
('Welding', 'TotalHours', 'WeldCheck', 'Required', NULL),
('Welding', 'TotalHours', 'WeldTest', 'Required', NULL);

-- 7. Create default templates from existing worksheet types
DECLARE @AdminUserId INT;
SELECT TOP 1 @AdminUserId = Id FROM Users WHERE Email = 'admin@steelestimation.com';

-- Standard Processing Template
INSERT INTO WorksheetTemplates (Name, Description, BaseType, CreatedByUserId, IsPublished, IsGlobal, IsDefault, DisplayOrder)
VALUES ('Standard Processing', 'Complete processing worksheet with all fields', 'Processing', @AdminUserId, 1, 1, 1, 1);

DECLARE @ProcessingTemplateId INT = SCOPE_IDENTITY();

-- Insert all processing fields
INSERT INTO WorksheetTemplateFields (WorksheetTemplateId, FieldName, DisplayName, DisplayOrder, ColumnWidth, IsFrozen) VALUES
(@ProcessingTemplateId, 'ID', 'ID', 1, 50, 1),
(@ProcessingTemplateId, 'DrawingNumber', 'Drawing #', 2, 120, 1),
(@ProcessingTemplateId, 'Description', 'Description', 3, 200, 0),
(@ProcessingTemplateId, 'MaterialId', 'Material ID', 4, 100, 0),
(@ProcessingTemplateId, 'Quantity', 'Qty', 5, 80, 0),
(@ProcessingTemplateId, 'Length', 'Length', 6, 80, 0),
(@ProcessingTemplateId, 'Weight', 'Weight', 7, 80, 0),
(@ProcessingTemplateId, 'TotalWeight', 'Total Weight', 8, 100, 0),
(@ProcessingTemplateId, 'DeliveryBundle', 'Delivery Bundle', 9, 150, 0),
(@ProcessingTemplateId, 'PackBundle', 'Pack Bundle', 10, 150, 0),
(@ProcessingTemplateId, 'UnloadTime', 'Unload Time', 11, 100, 0),
(@ProcessingTemplateId, 'MarkMeasureCut', 'Mark/Measure/Cut', 12, 120, 0),
(@ProcessingTemplateId, 'QualityCheck', 'Quality Check', 13, 100, 0),
(@ProcessingTemplateId, 'MoveToAssembly', 'Move to Assembly', 14, 120, 0),
(@ProcessingTemplateId, 'MoveAfterWeld', 'Move After Weld', 15, 120, 0),
(@ProcessingTemplateId, 'LoadingTime', 'Loading Time', 16, 100, 0),
(@ProcessingTemplateId, 'TotalHours', 'Total Hours', 17, 100, 0);

-- Standard Welding Template
INSERT INTO WorksheetTemplates (Name, Description, BaseType, CreatedByUserId, IsPublished, IsGlobal, IsDefault, DisplayOrder)
VALUES ('Standard Welding', 'Complete welding worksheet with all fields', 'Welding', @AdminUserId, 1, 1, 1, 2);

DECLARE @WeldingTemplateId INT = SCOPE_IDENTITY();

-- Insert all welding fields
INSERT INTO WorksheetTemplateFields (WorksheetTemplateId, FieldName, DisplayName, DisplayOrder, ColumnWidth, IsFrozen) VALUES
(@WeldingTemplateId, 'ID', 'ID', 1, 50, 1),
(@WeldingTemplateId, 'DrawingNumber', 'Drawing #', 2, 120, 1),
(@WeldingTemplateId, 'Images', 'Images', 3, 150, 0),
(@WeldingTemplateId, 'ConnectionType', 'Connection Type', 4, 250, 0),
(@WeldingTemplateId, 'ConnectionQty', 'Conn Qty', 5, 100, 0),
(@WeldingTemplateId, 'AssembleFitTack', 'Assemble', 6, 100, 0),
(@WeldingTemplateId, 'Weld', 'Weld', 7, 80, 0),
(@WeldingTemplateId, 'WeldCheck', 'Check', 8, 80, 0),
(@WeldingTemplateId, 'ConnectionHours', 'Connection Hours', 9, 250, 0),
(@WeldingTemplateId, 'TotalHours', 'Total Hours', 10, 100, 0);

-- Quick Processing Entry Template
INSERT INTO WorksheetTemplates (Name, Description, BaseType, CreatedByUserId, IsPublished, IsGlobal, IsDefault, DisplayOrder)
VALUES ('Quick Processing Entry', 'Simplified processing worksheet for quick data entry', 'Processing', @AdminUserId, 1, 1, 0, 3);

DECLARE @QuickProcessingTemplateId INT = SCOPE_IDENTITY();

INSERT INTO WorksheetTemplateFields (WorksheetTemplateId, FieldName, DisplayName, DisplayOrder, ColumnWidth) VALUES
(@QuickProcessingTemplateId, 'ID', 'ID', 1, 50),
(@QuickProcessingTemplateId, 'DrawingNumber', 'Drawing #', 2, 120),
(@QuickProcessingTemplateId, 'Description', 'Description', 3, 250),
(@QuickProcessingTemplateId, 'Quantity', 'Qty', 4, 80),
(@QuickProcessingTemplateId, 'Weight', 'Weight', 5, 80),
(@QuickProcessingTemplateId, 'TotalWeight', 'Total Weight', 6, 100),
(@QuickProcessingTemplateId, 'MarkMeasureCut', 'Process Time', 7, 120);

-- Packing & Shipping Template
INSERT INTO WorksheetTemplates (Name, Description, BaseType, CreatedByUserId, IsPublished, IsGlobal, IsDefault, DisplayOrder)
VALUES ('Packing & Shipping', 'Template for packing and shipping operations', 'Processing', @AdminUserId, 1, 1, 0, 4);

DECLARE @PackingTemplateId INT = SCOPE_IDENTITY();

INSERT INTO WorksheetTemplateFields (WorksheetTemplateId, FieldName, DisplayName, DisplayOrder, ColumnWidth) VALUES
(@PackingTemplateId, 'ID', 'ID', 1, 50),
(@PackingTemplateId, 'DrawingNumber', 'Drawing #', 2, 120),
(@PackingTemplateId, 'Description', 'Description', 3, 250),
(@PackingTemplateId, 'Quantity', 'Qty', 4, 80),
(@PackingTemplateId, 'TotalWeight', 'Total Weight', 5, 100),
(@PackingTemplateId, 'DeliveryBundle', 'Delivery Bundle', 6, 150),
(@PackingTemplateId, 'PackBundle', 'Pack Bundle', 7, 150),
(@PackingTemplateId, 'LoadingTime', 'Loading Time', 8, 100);

PRINT 'Worksheet Templates tables created successfully';
PRINT 'Default templates created successfully';