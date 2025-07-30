-- Migration: Add Time Tracking, Multiple Connections, and Processing Efficiency
-- Date: 2025-01-04
-- Description: Adds support for time tracking, multiple welding connections, and processing efficiency

-- Add ProcessingEfficiency column to Packages table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Packages]') AND name = 'ProcessingEfficiency')
BEGIN
    ALTER TABLE [dbo].[Packages]
    ADD [ProcessingEfficiency] decimal(18,2) NULL;
END
GO

-- Create EstimationTimeLogs table for time tracking
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EstimationTimeLogs]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[EstimationTimeLogs] (
        [Id] int IDENTITY(1,1) NOT NULL,
        [EstimationId] int NOT NULL,
        [UserId] int NOT NULL,
        [SessionId] uniqueidentifier NOT NULL,
        [StartTime] datetime2(7) NOT NULL,
        [EndTime] datetime2(7) NULL,
        [Duration] int NOT NULL DEFAULT 0,
        [PageName] nvarchar(200) NULL,
        [IsActive] bit NOT NULL DEFAULT 0,
        CONSTRAINT [PK_EstimationTimeLogs] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_EstimationTimeLogs_Projects_EstimationId] FOREIGN KEY([EstimationId]) REFERENCES [dbo].[Projects] ([Id]),
        CONSTRAINT [FK_EstimationTimeLogs_Users_UserId] FOREIGN KEY([UserId]) REFERENCES [dbo].[Users] ([Id])
    );
    
    -- Create indexes for performance
    CREATE NONCLUSTERED INDEX [IX_EstimationTimeLogs_EstimationId] ON [dbo].[EstimationTimeLogs] ([EstimationId]);
    CREATE NONCLUSTERED INDEX [IX_EstimationTimeLogs_UserId] ON [dbo].[EstimationTimeLogs] ([UserId]);
    CREATE NONCLUSTERED INDEX [IX_EstimationTimeLogs_SessionId] ON [dbo].[EstimationTimeLogs] ([SessionId]);
    CREATE NONCLUSTERED INDEX [IX_EstimationTimeLogs_IsActive] ON [dbo].[EstimationTimeLogs] ([IsActive]);
END
GO

-- Create WeldingItemConnections table for many-to-many relationship
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItemConnections]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[WeldingItemConnections] (
        [Id] int IDENTITY(1,1) NOT NULL,
        [WeldingItemId] int NOT NULL,
        [WeldingConnectionId] int NOT NULL,
        [Quantity] int NOT NULL DEFAULT 1,
        [AssembleFitTack] decimal(18,2) NULL,
        [Weld] decimal(18,2) NULL,
        [WeldCheck] decimal(18,2) NULL,
        [WeldTest] decimal(18,2) NULL,
        CONSTRAINT [PK_WeldingItemConnections] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_WeldingItemConnections_WeldingItems_WeldingItemId] FOREIGN KEY([WeldingItemId]) REFERENCES [dbo].[WeldingItems] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_WeldingItemConnections_WeldingConnections_WeldingConnectionId] FOREIGN KEY([WeldingConnectionId]) REFERENCES [dbo].[WeldingConnections] ([Id])
    );
    
    -- Create indexes for performance
    CREATE NONCLUSTERED INDEX [IX_WeldingItemConnections_WeldingItemId] ON [dbo].[WeldingItemConnections] ([WeldingItemId]);
    CREATE NONCLUSTERED INDEX [IX_WeldingItemConnections_WeldingConnectionId] ON [dbo].[WeldingItemConnections] ([WeldingConnectionId]);
    
    -- Create unique constraint to prevent duplicate connections
    CREATE UNIQUE NONCLUSTERED INDEX [IX_WeldingItemConnections_Unique] 
    ON [dbo].[WeldingItemConnections] ([WeldingItemId], [WeldingConnectionId]);
END
GO

-- Add default efficiency value for existing packages
UPDATE [dbo].[Packages]
SET [ProcessingEfficiency] = 100
WHERE [ProcessingEfficiency] IS NULL;
GO

-- Migration complete
PRINT 'Migration AddTimeTrackingAndEfficiency completed successfully';
GO