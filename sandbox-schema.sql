-- Create schema for Steel Estimation Sandbox Database

-- Users table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Users' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[Users](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [Username] [nvarchar](100) NOT NULL,
        [Email] [nvarchar](255) NOT NULL,
        [PasswordHash] [nvarchar](500) NOT NULL,
        [FirstName] [nvarchar](100) NULL,
        [LastName] [nvarchar](100) NULL,
        [Role] [nvarchar](50) NULL,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [LastLoginDate] [datetime2](7) NULL,
        CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED ([Id] ASC)
    )
END
GO

-- Projects table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Projects' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[Projects](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [ProjectName] [nvarchar](200) NOT NULL,
        [JobNumber] [nvarchar](50) NOT NULL,
        [CustomerName] [nvarchar](200) NULL,
        [ProjectLocation] [nvarchar](200) NULL,
        [EstimationStage] [nvarchar](50) NULL,
        [StartDate] [datetime2](7) NULL,
        [EndDate] [datetime2](7) NULL,
        [TotalCost] [decimal](18, 2) NULL,
        [Status] [nvarchar](50) NULL,
        [Notes] [nvarchar](max) NULL,
        [OwnerId] [int] NULL,
        [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [LastModified] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [IsDeleted] [bit] NOT NULL DEFAULT 0,
        [LaborRate] [decimal](18, 2) NULL,
        [ContingencyPercentage] [decimal](5, 2) NULL,
        CONSTRAINT [PK_Projects] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_Projects_Users] FOREIGN KEY([OwnerId]) REFERENCES [dbo].[Users] ([Id])
    )
END
GO

-- ProcessingItems table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='ProcessingItems' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[ProcessingItems](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [ProjectId] [int] NOT NULL,
        [DrawingNumber] [nvarchar](100) NULL,
        [Description] [nvarchar](500) NULL,
        [MaterialId] [nvarchar](100) NULL,
        [Quantity] [int] NOT NULL DEFAULT 0,
        [Weight] [decimal](18, 3) NOT NULL DEFAULT 0,
        [Length] [decimal](18, 3) NOT NULL DEFAULT 0,
        [UnloadTimePerBundle] [int] NOT NULL DEFAULT 15,
        [MarkMeasureCut] [int] NOT NULL DEFAULT 30,
        [QualityCheckClean] [int] NOT NULL DEFAULT 15,
        [MoveToAssembly] [int] NOT NULL DEFAULT 20,
        [MoveAfterWeld] [int] NOT NULL DEFAULT 20,
        [LoadingTimePerBundle] [int] NOT NULL DEFAULT 15,
        [DeliveryBundleQty] [int] NOT NULL DEFAULT 1,
        [PackBundleQty] [int] NOT NULL DEFAULT 1,
        [BundleGroup] [nvarchar](50) NULL,
        [PackGroup] [nvarchar](50) NULL,
        [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [LastModified] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [RowVersion] [timestamp] NOT NULL,
        CONSTRAINT [PK_ProcessingItems] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_ProcessingItems_Projects] FOREIGN KEY([ProjectId]) REFERENCES [dbo].[Projects] ([Id])
    )
END
GO

-- WeldingItems table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='WeldingItems' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[WeldingItems](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [ProjectId] [int] NOT NULL,
        [DrawingNumber] [nvarchar](100) NULL,
        [ItemDescription] [nvarchar](500) NULL,
        [WeldType] [nvarchar](50) NULL,
        [WeldLength] [decimal](18, 2) NOT NULL DEFAULT 0,
        [LocationComments] [nvarchar](500) NULL,
        [PhotoReference] [nvarchar](200) NULL,
        [ConnectionQty] [int] NOT NULL DEFAULT 1,
        [AssembleFitTack] [int] NOT NULL DEFAULT 5,
        [Weld] [int] NOT NULL DEFAULT 3,
        [WeldCheck] [int] NOT NULL DEFAULT 2,
        [WeldTest] [int] NOT NULL DEFAULT 0,
        [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [LastModified] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [RowVersion] [timestamp] NOT NULL,
        CONSTRAINT [PK_WeldingItems] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_WeldingItems_Projects] FOREIGN KEY([ProjectId]) REFERENCES [dbo].[Projects] ([Id])
    )
END
GO

-- Create indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Projects_JobNumber')
    CREATE INDEX IX_Projects_JobNumber ON Projects(JobNumber);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ProcessingItems_ProjectId')
    CREATE INDEX IX_ProcessingItems_ProjectId ON ProcessingItems(ProjectId);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_WeldingItems_ProjectId')
    CREATE INDEX IX_WeldingItems_ProjectId ON WeldingItems(ProjectId);
GO

-- Create default admin user
IF NOT EXISTS (SELECT * FROM Users WHERE Username = 'admin')
BEGIN
    INSERT INTO Users (Username, Email, PasswordHash, FirstName, LastName, Role, IsActive)
    VALUES ('admin', 'admin@steelestimation.com', 
            'AQAAAAEAACcQAAAAEPg+Pz0Kz6AnHQfSfKRNq5pN3Q3kOJBHwZ9Vg6bKaYQp8M2XFI7TaVB5oZ4OtGI+3Q==', -- Password: Admin123!
            'Admin', 'User', 'Admin', 1)
    PRINT 'Admin user created (Username: admin, Password: Admin123!)'
END
GO

PRINT 'Schema creation completed successfully!'