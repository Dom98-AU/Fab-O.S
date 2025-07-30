-- Add TableViews table for saving column layouts across all tables
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='TableViews' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[TableViews] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [UserId] INT NOT NULL,
        [CompanyId] INT NOT NULL,
        [ViewName] NVARCHAR(100) NOT NULL,
        [TableType] NVARCHAR(50) NOT NULL,
        [IsDefault] BIT NOT NULL DEFAULT 0,
        [IsShared] BIT NOT NULL DEFAULT 0,
        [ColumnOrder] NVARCHAR(MAX) NULL,
        [ColumnWidths] NVARCHAR(MAX) NULL,
        [ColumnVisibility] NVARCHAR(MAX) NULL,
        [CreatedAt] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_TableViews] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_TableViews_Users_UserId] FOREIGN KEY([UserId]) REFERENCES [dbo].[Users] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_TableViews_Companies_CompanyId] FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id]) ON DELETE CASCADE
    );
    
    -- Create indexes
    CREATE NONCLUSTERED INDEX [IX_TableViews_UserId] ON [dbo].[TableViews] ([UserId]);
    CREATE NONCLUSTERED INDEX [IX_TableViews_CompanyId] ON [dbo].[TableViews] ([CompanyId]);
    CREATE NONCLUSTERED INDEX [IX_TableViews_UserId_CompanyId_TableType] ON [dbo].[TableViews] ([UserId], [CompanyId], [TableType]);
    CREATE NONCLUSTERED INDEX [IX_TableViews_CompanyId_TableType_IsShared] ON [dbo].[TableViews] ([CompanyId], [TableType], [IsShared]);
    CREATE NONCLUSTERED INDEX [IX_TableViews_UserId_CompanyId_IsDefault] ON [dbo].[TableViews] ([UserId], [CompanyId], [IsDefault]);
    
    PRINT 'TableViews table created successfully';
END
ELSE
BEGIN
    PRINT 'TableViews table already exists';
END
GO