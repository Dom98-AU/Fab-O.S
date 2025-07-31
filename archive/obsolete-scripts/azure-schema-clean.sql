-- Clean Azure SQL Schema - No USE statements, Azure SQL compatible
-- Steel Estimation Database Schema for Azure SQL

-- Create Companies table (Multi-tenant support)
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Companies]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Companies](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [Name] [nvarchar](100) NOT NULL,
        [Code] [nvarchar](10) NOT NULL,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        CONSTRAINT [PK_Companies] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [UQ_Companies_Code] UNIQUE ([Code])
    );
END

-- Create AspNetRoles table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetRoles]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[AspNetRoles](
        [Id] [nvarchar](450) NOT NULL,
        [Name] [nvarchar](256) NULL,
        [NormalizedName] [nvarchar](256) NULL,
        [ConcurrencyStamp] [nvarchar](max) NULL,
        CONSTRAINT [PK_AspNetRoles] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE UNIQUE INDEX [RoleNameIndex] ON [dbo].[AspNetRoles]([NormalizedName]) WHERE [NormalizedName] IS NOT NULL;
END

-- Create AspNetUsers table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[AspNetUsers](
        [Id] [nvarchar](450) NOT NULL,
        [FullName] [nvarchar](100) NOT NULL,
        [CompanyId] [int] NOT NULL,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        [UserName] [nvarchar](256) NULL,
        [NormalizedUserName] [nvarchar](256) NULL,
        [Email] [nvarchar](256) NULL,
        [NormalizedEmail] [nvarchar](256) NULL,
        [EmailConfirmed] [bit] NOT NULL,
        [PasswordHash] [nvarchar](max) NULL,
        [SecurityStamp] [nvarchar](max) NULL,
        [ConcurrencyStamp] [nvarchar](max) NULL,
        [PhoneNumber] [nvarchar](max) NULL,
        [PhoneNumberConfirmed] [bit] NOT NULL,
        [TwoFactorEnabled] [bit] NOT NULL,
        [LockoutEnd] [datetimeoffset](7) NULL,
        [LockoutEnabled] [bit] NOT NULL,
        [AccessFailedCount] [int] NOT NULL,
        CONSTRAINT [PK_AspNetUsers] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_AspNetUsers_Companies] FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id])
    );
    CREATE INDEX [EmailIndex] ON [dbo].[AspNetUsers]([NormalizedEmail]);
    CREATE UNIQUE INDEX [UserNameIndex] ON [dbo].[AspNetUsers]([NormalizedUserName]) WHERE [NormalizedUserName] IS NOT NULL;
    CREATE INDEX [IX_AspNetUsers_CompanyId] ON [dbo].[AspNetUsers]([CompanyId]);
END

-- Create AspNetUserRoles table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUserRoles]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[AspNetUserRoles](
        [UserId] [nvarchar](450) NOT NULL,
        [RoleId] [nvarchar](450) NOT NULL,
        CONSTRAINT [PK_AspNetUserRoles] PRIMARY KEY CLUSTERED ([UserId] ASC, [RoleId] ASC),
        CONSTRAINT [FK_AspNetUserRoles_AspNetRoles_RoleId] FOREIGN KEY([RoleId]) REFERENCES [dbo].[AspNetRoles] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_AspNetUserRoles_AspNetUsers_UserId] FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX [IX_AspNetUserRoles_RoleId] ON [dbo].[AspNetUserRoles]([RoleId]);
END

-- Create AspNetUserClaims table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUserClaims]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[AspNetUserClaims](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [UserId] [nvarchar](450) NOT NULL,
        [ClaimType] [nvarchar](max) NULL,
        [ClaimValue] [nvarchar](max) NULL,
        CONSTRAINT [PK_AspNetUserClaims] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_AspNetUserClaims_AspNetUsers_UserId] FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX [IX_AspNetUserClaims_UserId] ON [dbo].[AspNetUserClaims]([UserId]);
END

-- Create AspNetUserLogins table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUserLogins]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[AspNetUserLogins](
        [LoginProvider] [nvarchar](450) NOT NULL,
        [ProviderKey] [nvarchar](450) NOT NULL,
        [ProviderDisplayName] [nvarchar](max) NULL,
        [UserId] [nvarchar](450) NOT NULL,
        CONSTRAINT [PK_AspNetUserLogins] PRIMARY KEY CLUSTERED ([LoginProvider] ASC, [ProviderKey] ASC),
        CONSTRAINT [FK_AspNetUserLogins_AspNetUsers_UserId] FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX [IX_AspNetUserLogins_UserId] ON [dbo].[AspNetUserLogins]([UserId]);
END

-- Create AspNetUserTokens table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUserTokens]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[AspNetUserTokens](
        [UserId] [nvarchar](450) NOT NULL,
        [LoginProvider] [nvarchar](450) NOT NULL,
        [Name] [nvarchar](450) NOT NULL,
        [Value] [nvarchar](max) NULL,
        CONSTRAINT [PK_AspNetUserTokens] PRIMARY KEY CLUSTERED ([UserId] ASC, [LoginProvider] ASC, [Name] ASC),
        CONSTRAINT [FK_AspNetUserTokens_AspNetUsers_UserId] FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
    );
END

-- Create AspNetRoleClaims table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetRoleClaims]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[AspNetRoleClaims](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [RoleId] [nvarchar](450) NOT NULL,
        [ClaimType] [nvarchar](max) NULL,
        [ClaimValue] [nvarchar](max) NULL,
        CONSTRAINT [PK_AspNetRoleClaims] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_AspNetRoleClaims_AspNetRoles_RoleId] FOREIGN KEY([RoleId]) REFERENCES [dbo].[AspNetRoles] ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX [IX_AspNetRoleClaims_RoleId] ON [dbo].[AspNetRoleClaims]([RoleId]);
END

-- Create EfficiencyRates table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EfficiencyRates]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[EfficiencyRates](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [CompanyId] [int] NOT NULL,
        [Name] [nvarchar](100) NOT NULL,
        [Description] [nvarchar](500) NULL,
        [Rate] [decimal](5,2) NOT NULL,
        [IsDefault] [bit] NOT NULL DEFAULT 0,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        [CreatedById] [nvarchar](450) NOT NULL,
        CONSTRAINT [PK_EfficiencyRates] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_EfficiencyRates_Companies] FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id]),
        CONSTRAINT [FK_EfficiencyRates_AspNetUsers] FOREIGN KEY([CreatedById]) REFERENCES [dbo].[AspNetUsers] ([Id])
    );
    CREATE INDEX [IX_EfficiencyRates_CompanyId] ON [dbo].[EfficiencyRates]([CompanyId]);
END

-- Create Customers table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Customers]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Customers](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [CompanyId] [int] NOT NULL,
        [Name] [nvarchar](200) NOT NULL,
        [Code] [nvarchar](50) NULL,
        [ContactPerson] [nvarchar](100) NULL,
        [Email] [nvarchar](200) NULL,
        [Phone] [nvarchar](50) NULL,
        [Address] [nvarchar](500) NULL,
        [City] [nvarchar](100) NULL,
        [State] [nvarchar](50) NULL,
        [PostCode] [nvarchar](20) NULL,
        [Country] [nvarchar](100) NULL,
        [Notes] [nvarchar](max) NULL,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        [CreatedById] [nvarchar](450) NOT NULL,
        CONSTRAINT [PK_Customers] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_Customers_Companies] FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id]),
        CONSTRAINT [FK_Customers_AspNetUsers] FOREIGN KEY([CreatedById]) REFERENCES [dbo].[AspNetUsers] ([Id])
    );
    CREATE INDEX [IX_Customers_CompanyId] ON [dbo].[Customers]([CompanyId]);
    CREATE INDEX [IX_Customers_Code] ON [dbo].[Customers]([Code]);
END

-- Create Postcodes table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Postcodes]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Postcodes](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [Postcode] [nvarchar](10) NOT NULL,
        [Suburb] [nvarchar](100) NOT NULL,
        [State] [nvarchar](50) NOT NULL,
        [Country] [nvarchar](100) NOT NULL DEFAULT 'Australia',
        [Latitude] [decimal](10,6) NULL,
        [Longitude] [decimal](10,6) NULL,
        CONSTRAINT [PK_Postcodes] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_Postcodes_Postcode] ON [dbo].[Postcodes]([Postcode]);
    CREATE INDEX [IX_Postcodes_State] ON [dbo].[Postcodes]([State]);
END

-- Create Projects table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Projects](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [CompanyId] [int] NOT NULL,
        [ProjectNumber] [nvarchar](50) NOT NULL,
        [Name] [nvarchar](200) NOT NULL,
        [ClientName] [nvarchar](200) NULL,
        [Location] [nvarchar](200) NULL,
        [StartDate] [datetime2](7) NULL,
        [EndDate] [datetime2](7) NULL,
        [EstimatedHours] [decimal](10,2) NULL,
        [Status] [nvarchar](50) NOT NULL DEFAULT 'Active',
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        [CreatedById] [nvarchar](450) NOT NULL,
        CONSTRAINT [PK_Projects] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_Projects_Companies] FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id]),
        CONSTRAINT [FK_Projects_AspNetUsers] FOREIGN KEY([CreatedById]) REFERENCES [dbo].[AspNetUsers] ([Id])
    );
    CREATE INDEX [IX_Projects_CompanyId] ON [dbo].[Projects]([CompanyId]);
    CREATE INDEX [IX_Projects_ProjectNumber] ON [dbo].[Projects]([ProjectNumber]);
END

-- Create Estimations table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Estimations]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Estimations](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [ProjectId] [int] NOT NULL,
        [EstimationNumber] [nvarchar](50) NOT NULL,
        [Name] [nvarchar](200) NOT NULL,
        [Description] [nvarchar](max) NULL,
        [PreparedBy] [nvarchar](100) NULL,
        [PreparedDate] [datetime2](7) NULL,
        [ReviewedBy] [nvarchar](100) NULL,
        [ReviewedDate] [datetime2](7) NULL,
        [Status] [nvarchar](50) NOT NULL DEFAULT 'Draft',
        [Version] [int] NOT NULL DEFAULT 1,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        [CreatedById] [nvarchar](450) NOT NULL,
        CONSTRAINT [PK_Estimations] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_Estimations_Projects] FOREIGN KEY([ProjectId]) REFERENCES [dbo].[Projects] ([Id]),
        CONSTRAINT [FK_Estimations_AspNetUsers] FOREIGN KEY([CreatedById]) REFERENCES [dbo].[AspNetUsers] ([Id])
    );
    CREATE INDEX [IX_Estimations_ProjectId] ON [dbo].[Estimations]([ProjectId]);
    CREATE INDEX [IX_Estimations_EstimationNumber] ON [dbo].[Estimations]([EstimationNumber]);
END

-- Create EstimationTimeLogs table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EstimationTimeLogs]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[EstimationTimeLogs](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [EstimationId] [int] NOT NULL,
        [UserId] [nvarchar](450) NOT NULL,
        [StartTime] [datetime2](7) NOT NULL,
        [EndTime] [datetime2](7) NULL,
        [DurationMinutes] [int] NULL,
        [IsPaused] [bit] NOT NULL DEFAULT 0,
        [LastActivityTime] [datetime2](7) NOT NULL,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_EstimationTimeLogs] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_EstimationTimeLogs_Estimations] FOREIGN KEY([EstimationId]) REFERENCES [dbo].[Estimations] ([Id]),
        CONSTRAINT [FK_EstimationTimeLogs_AspNetUsers] FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id])
    );
    CREATE INDEX [IX_EstimationTimeLogs_EstimationId] ON [dbo].[EstimationTimeLogs]([EstimationId]);
    CREATE INDEX [IX_EstimationTimeLogs_UserId] ON [dbo].[EstimationTimeLogs]([UserId]);
END

-- Create Packages table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Packages]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Packages](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [EstimationId] [int] NOT NULL,
        [Name] [nvarchar](200) NOT NULL,
        [Description] [nvarchar](max) NULL,
        [ProcessingEfficiency] [decimal](5,2) NOT NULL DEFAULT 75.00,
        [EfficiencyRateId] [int] NULL,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        CONSTRAINT [PK_Packages] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_Packages_Estimations] FOREIGN KEY([EstimationId]) REFERENCES [dbo].[Estimations] ([Id]),
        CONSTRAINT [FK_Packages_EfficiencyRates] FOREIGN KEY([EfficiencyRateId]) REFERENCES [dbo].[EfficiencyRates] ([Id])
    );
    CREATE INDEX [IX_Packages_EstimationId] ON [dbo].[Packages]([EstimationId]);
END

-- Create remaining tables (ProcessingItems, DeliveryBundles, PackBundles, WeldingItems, WeldingItemConnections)
-- These will be created as needed by the application

PRINT 'Core database schema created successfully!';
PRINT 'Essential tables: Companies, AspNetUsers, AspNetRoles, Projects, Estimations, Packages, etc.';