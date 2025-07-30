-- Add Column Ordering and Saved Views Support
-- This migration adds support for customizable column ordering and saved views in worksheets

-- Create WorksheetColumnViews table
CREATE TABLE [dbo].[WorksheetColumnViews] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [UserId] INT NOT NULL,
    [CompanyId] INT NOT NULL,
    [ViewName] NVARCHAR(100) NOT NULL,
    [WorksheetType] NVARCHAR(50) NOT NULL, -- 'Processing' or 'Welding'
    [IsDefault] BIT NOT NULL DEFAULT 0,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedAt] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT [PK_WorksheetColumnViews] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_WorksheetColumnViews_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_WorksheetColumnViews_Companies_CompanyId] FOREIGN KEY ([CompanyId]) REFERENCES [dbo].[Companies] ([Id]) ON DELETE CASCADE
);

-- Create WorksheetColumnOrders table
CREATE TABLE [dbo].[WorksheetColumnOrders] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [WorksheetColumnViewId] INT NOT NULL,
    [ColumnName] NVARCHAR(100) NOT NULL,
    [DisplayOrder] INT NOT NULL,
    [IsVisible] BIT NOT NULL DEFAULT 1,
    [IsFrozen] BIT NOT NULL DEFAULT 0,
    [DependentColumnName] NVARCHAR(100) NULL, -- For columns that should move together
    CONSTRAINT [PK_WorksheetColumnOrders] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_WorksheetColumnOrders_WorksheetColumnViews_WorksheetColumnViewId] FOREIGN KEY ([WorksheetColumnViewId]) REFERENCES [dbo].[WorksheetColumnViews] ([Id]) ON DELETE CASCADE
);

-- Create indexes
CREATE NONCLUSTERED INDEX [IX_WorksheetColumnViews_UserId] ON [dbo].[WorksheetColumnViews] ([UserId]);
CREATE NONCLUSTERED INDEX [IX_WorksheetColumnViews_CompanyId] ON [dbo].[WorksheetColumnViews] ([CompanyId]);
CREATE NONCLUSTERED INDEX [IX_WorksheetColumnViews_UserId_CompanyId_WorksheetType] ON [dbo].[WorksheetColumnViews] ([UserId], [CompanyId], [WorksheetType]);
CREATE NONCLUSTERED INDEX [IX_WorksheetColumnViews_UserId_CompanyId_IsDefault] ON [dbo].[WorksheetColumnViews] ([UserId], [CompanyId], [IsDefault]);

CREATE NONCLUSTERED INDEX [IX_WorksheetColumnOrders_WorksheetColumnViewId] ON [dbo].[WorksheetColumnOrders] ([WorksheetColumnViewId]);
CREATE UNIQUE NONCLUSTERED INDEX [IX_WorksheetColumnOrders_WorksheetColumnViewId_ColumnName] ON [dbo].[WorksheetColumnOrders] ([WorksheetColumnViewId], [ColumnName]);
CREATE NONCLUSTERED INDEX [IX_WorksheetColumnOrders_WorksheetColumnViewId_DisplayOrder] ON [dbo].[WorksheetColumnOrders] ([WorksheetColumnViewId], [DisplayOrder]);

-- Insert default column orders for all existing users (Processing worksheet)
INSERT INTO [dbo].[WorksheetColumnViews] (UserId, CompanyId, ViewName, WorksheetType, IsDefault)
SELECT DISTINCT u.Id, u.CompanyId, 'Default Processing View', 'Processing', 1
FROM [dbo].[Users] u
WHERE NOT EXISTS (
    SELECT 1 FROM [dbo].[WorksheetColumnViews] wcv 
    WHERE wcv.UserId = u.Id AND wcv.CompanyId = u.CompanyId AND wcv.WorksheetType = 'Processing' AND wcv.IsDefault = 1
);

-- Insert default column orders for all existing users (Welding worksheet)
INSERT INTO [dbo].[WorksheetColumnViews] (UserId, CompanyId, ViewName, WorksheetType, IsDefault)
SELECT DISTINCT u.Id, u.CompanyId, 'Default Welding View', 'Welding', 1
FROM [dbo].[Users] u
WHERE NOT EXISTS (
    SELECT 1 FROM [dbo].[WorksheetColumnViews] wcv 
    WHERE wcv.UserId = u.Id AND wcv.CompanyId = u.CompanyId AND wcv.WorksheetType = 'Welding' AND wcv.IsDefault = 1
);

-- Insert default column orders for Processing views
INSERT INTO [dbo].[WorksheetColumnOrders] (WorksheetColumnViewId, ColumnName, DisplayOrder, IsVisible, IsFrozen, DependentColumnName)
SELECT wcv.Id, cols.ColumnName, cols.DisplayOrder, cols.IsVisible, cols.IsFrozen, cols.DependentColumnName
FROM [dbo].[WorksheetColumnViews] wcv
CROSS APPLY (
    VALUES 
        ('DrawingNumber', 1, 1, 0, NULL),
        ('Quantity', 2, 1, 0, NULL),
        ('Description', 3, 1, 0, NULL),
        ('Material', 4, 1, 0, 'MaterialType'),
        ('MaterialType', 5, 1, 0, NULL),
        ('Weight', 6, 1, 0, NULL),
        ('TotalWeight', 7, 1, 0, NULL),
        ('DeliveryBundle', 8, 1, 0, NULL),
        ('PackBundle', 9, 1, 0, NULL),
        ('HandlingTime', 10, 1, 0, NULL),
        ('UnloadTime', 11, 1, 0, NULL),
        ('MarkMeasureCut', 12, 1, 0, NULL),
        ('QualityCheck', 13, 1, 0, NULL),
        ('MoveToAssembly', 14, 1, 0, NULL),
        ('MoveAfterWeld', 15, 1, 0, NULL),
        ('LoadingTime', 16, 1, 0, NULL)
) AS cols(ColumnName, DisplayOrder, IsVisible, IsFrozen, DependentColumnName)
WHERE wcv.WorksheetType = 'Processing' AND wcv.IsDefault = 1;

-- Insert default column orders for Welding views
INSERT INTO [dbo].[WorksheetColumnOrders] (WorksheetColumnViewId, ColumnName, DisplayOrder, IsVisible, IsFrozen, DependentColumnName)
SELECT wcv.Id, cols.ColumnName, cols.DisplayOrder, cols.IsVisible, cols.IsFrozen, cols.DependentColumnName
FROM [dbo].[WorksheetColumnViews] wcv
CROSS APPLY (
    VALUES 
        ('DrawingNumber', 1, 1, 0, NULL),
        ('ItemDescription', 2, 1, 0, NULL),
        ('WeldType', 3, 1, 0, NULL),
        ('ConnectionQty', 4, 1, 0, NULL),
        ('WeldingConnections', 5, 1, 0, NULL),
        ('TotalMinutes', 6, 1, 0, NULL),
        ('Images', 7, 1, 0, NULL)
) AS cols(ColumnName, DisplayOrder, IsVisible, IsFrozen, DependentColumnName)
WHERE wcv.WorksheetType = 'Welding' AND wcv.IsDefault = 1;

PRINT 'Column ordering tables created successfully';
PRINT 'Default views created for all existing users';