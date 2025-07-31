-- Simple Azure SQL Setup Script

-- Companies (if not exists)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Companies')
CREATE TABLE [dbo].[Companies]([Id] [int] IDENTITY(1,1) NOT NULL,[Name] [nvarchar](100) NOT NULL,[Code] [nvarchar](10) NOT NULL,[IsActive] [bit] NOT NULL DEFAULT 1,[CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),[UpdatedAt] [datetime2](7) NULL,CONSTRAINT [PK_Companies] PRIMARY KEY CLUSTERED ([Id] ASC));

-- AspNetRoles (if not exists)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AspNetRoles')
CREATE TABLE [dbo].[AspNetRoles]([Id] [nvarchar](450) NOT NULL,[Name] [nvarchar](256) NULL,[NormalizedName] [nvarchar](256) NULL,[ConcurrencyStamp] [nvarchar](max) NULL,CONSTRAINT [PK_AspNetRoles] PRIMARY KEY CLUSTERED ([Id] ASC));

-- AspNetUsers (if not exists)  
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AspNetUsers')
CREATE TABLE [dbo].[AspNetUsers]([Id] [nvarchar](450) NOT NULL,[FullName] [nvarchar](100) NOT NULL,[CompanyId] [int] NOT NULL,[IsActive] [bit] NOT NULL DEFAULT 1,[CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),[UpdatedAt] [datetime2](7) NULL,[UserName] [nvarchar](256) NULL,[NormalizedUserName] [nvarchar](256) NULL,[Email] [nvarchar](256) NULL,[NormalizedEmail] [nvarchar](256) NULL,[EmailConfirmed] [bit] NOT NULL DEFAULT 0,[PasswordHash] [nvarchar](max) NULL,[SecurityStamp] [nvarchar](max) NULL,[ConcurrencyStamp] [nvarchar](max) NULL,[PhoneNumber] [nvarchar](max) NULL,[PhoneNumberConfirmed] [bit] NOT NULL DEFAULT 0,[TwoFactorEnabled] [bit] NOT NULL DEFAULT 0,[LockoutEnd] [datetimeoffset](7) NULL,[LockoutEnabled] [bit] NOT NULL DEFAULT 1,[AccessFailedCount] [int] NOT NULL DEFAULT 0,CONSTRAINT [PK_AspNetUsers] PRIMARY KEY CLUSTERED ([Id] ASC),CONSTRAINT [FK_AspNetUsers_Companies] FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id]));

-- AspNetUserRoles (if not exists)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AspNetUserRoles')
CREATE TABLE [dbo].[AspNetUserRoles]([UserId] [nvarchar](450) NOT NULL,[RoleId] [nvarchar](450) NOT NULL,CONSTRAINT [PK_AspNetUserRoles] PRIMARY KEY CLUSTERED ([UserId] ASC, [RoleId] ASC),CONSTRAINT [FK_AspNetUserRoles_AspNetRoles_RoleId] FOREIGN KEY([RoleId]) REFERENCES [dbo].[AspNetRoles] ([Id]) ON DELETE CASCADE,CONSTRAINT [FK_AspNetUserRoles_AspNetUsers_UserId] FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE);

-- EfficiencyRates (if not exists)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'EfficiencyRates')
CREATE TABLE [dbo].[EfficiencyRates]([Id] [int] IDENTITY(1,1) NOT NULL,[CompanyId] [int] NOT NULL,[Name] [nvarchar](100) NOT NULL,[Description] [nvarchar](500) NULL,[Rate] [decimal](5,2) NOT NULL,[IsDefault] [bit] NOT NULL DEFAULT 0,[IsActive] [bit] NOT NULL DEFAULT 1,[CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),[UpdatedAt] [datetime2](7) NULL,[CreatedById] [nvarchar](450) NOT NULL,CONSTRAINT [PK_EfficiencyRates] PRIMARY KEY CLUSTERED ([Id] ASC),CONSTRAINT [FK_EfficiencyRates_Companies] FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id]),CONSTRAINT [FK_EfficiencyRates_AspNetUsers] FOREIGN KEY([CreatedById]) REFERENCES [dbo].[AspNetUsers] ([Id]));

-- Postcodes (if not exists)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Postcodes')
CREATE TABLE [dbo].[Postcodes]([Id] [int] IDENTITY(1,1) NOT NULL,[Postcode] [nvarchar](10) NOT NULL,[Suburb] [nvarchar](100) NOT NULL,[State] [nvarchar](50) NOT NULL,[Country] [nvarchar](100) NOT NULL DEFAULT 'Australia',[Latitude] [decimal](10,6) NULL,[Longitude] [decimal](10,6) NULL,CONSTRAINT [PK_Postcodes] PRIMARY KEY CLUSTERED ([Id] ASC));

-- Projects (if not exists)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Projects')
CREATE TABLE [dbo].[Projects]([Id] [int] IDENTITY(1,1) NOT NULL,[CompanyId] [int] NOT NULL,[ProjectNumber] [nvarchar](50) NOT NULL,[Name] [nvarchar](200) NOT NULL,[ClientName] [nvarchar](200) NULL,[Location] [nvarchar](200) NULL,[StartDate] [datetime2](7) NULL,[EndDate] [datetime2](7) NULL,[EstimatedHours] [decimal](10,2) NULL,[Status] [nvarchar](50) NOT NULL DEFAULT 'Active',[CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),[UpdatedAt] [datetime2](7) NULL,[CreatedById] [nvarchar](450) NOT NULL,CONSTRAINT [PK_Projects] PRIMARY KEY CLUSTERED ([Id] ASC),CONSTRAINT [FK_Projects_Companies] FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id]),CONSTRAINT [FK_Projects_AspNetUsers] FOREIGN KEY([CreatedById]) REFERENCES [dbo].[AspNetUsers] ([Id]));

-- Insert data only if tables are empty
IF NOT EXISTS (SELECT 1 FROM Companies WHERE Id = 1)
BEGIN
    SET IDENTITY_INSERT [Companies] ON;
    INSERT INTO [Companies] ([Id], [Name], [Code], [IsActive]) VALUES (1, 'Default Company', 'DEFAULT', 1);
    SET IDENTITY_INSERT [Companies] OFF;
END

IF NOT EXISTS (SELECT 1 FROM AspNetRoles WHERE Id = '1')
BEGIN
    INSERT INTO [AspNetRoles] ([Id], [Name], [NormalizedName]) VALUES ('1', 'Administrator', 'ADMINISTRATOR');
    INSERT INTO [AspNetRoles] ([Id], [Name], [NormalizedName]) VALUES ('2', 'Project Manager', 'PROJECT MANAGER');
    INSERT INTO [AspNetRoles] ([Id], [Name], [NormalizedName]) VALUES ('3', 'Senior Estimator', 'SENIOR ESTIMATOR');
    INSERT INTO [AspNetRoles] ([Id], [Name], [NormalizedName]) VALUES ('4', 'Estimator', 'ESTIMATOR');
    INSERT INTO [AspNetRoles] ([Id], [Name], [NormalizedName]) VALUES ('5', 'Viewer', 'VIEWER');
END

IF NOT EXISTS (SELECT 1 FROM AspNetUsers WHERE Id = '00000000-0000-0000-0000-000000000001')
BEGIN
    INSERT INTO [AspNetUsers] ([Id], [FullName], [CompanyId], [UserName], [NormalizedUserName], [Email], [NormalizedEmail], [EmailConfirmed], [PasswordHash], [SecurityStamp], [ConcurrencyStamp], [PhoneNumberConfirmed], [TwoFactorEnabled], [LockoutEnabled], [AccessFailedCount]) VALUES ('00000000-0000-0000-0000-000000000001', 'System Administrator', 1, 'admin@steelestimation.com', 'ADMIN@STEELESTIMATION.COM', 'admin@steelestimation.com', 'ADMIN@STEELESTIMATION.COM', 1, 'AQAAAAEAACcQAAAAEMvMR2X5W6V7LqYqHZWuHVOKRrYmYJ+eWz9J7NfV0cJHQF5bHQ5TvB+vW7C1X8vL5g==', 'QWERTYUIOPASDFGHJKLZXCVBNM123456', 'abcdef01-2345-6789-abcd-ef0123456789', 0, 0, 1, 0);
END

IF NOT EXISTS (SELECT 1 FROM AspNetUserRoles WHERE UserId = '00000000-0000-0000-0000-000000000001')
BEGIN
    INSERT INTO [AspNetUserRoles] ([UserId], [RoleId]) VALUES ('00000000-0000-0000-0000-000000000001', '1');
END

IF NOT EXISTS (SELECT 1 FROM EfficiencyRates WHERE Id = 1)
BEGIN
    SET IDENTITY_INSERT [EfficiencyRates] ON;
    INSERT INTO [EfficiencyRates] ([Id], [CompanyId], [Name], [Description], [Rate], [IsDefault], [IsActive], [CreatedById]) VALUES (1, 1, 'Standard (75%)', 'Standard efficiency rate for normal operations', 75.00, 1, 1, '00000000-0000-0000-0000-000000000001');
    INSERT INTO [EfficiencyRates] ([Id], [CompanyId], [Name], [Description], [Rate], [IsDefault], [IsActive], [CreatedById]) VALUES (2, 1, 'High Efficiency (85%)', 'For optimized operations with experienced teams', 85.00, 0, 1, '00000000-0000-0000-0000-000000000001');
    INSERT INTO [EfficiencyRates] ([Id], [CompanyId], [Name], [Description], [Rate], [IsDefault], [IsActive], [CreatedById]) VALUES (3, 1, 'Complex Work (65%)', 'For complex operations requiring extra care', 65.00, 0, 1, '00000000-0000-0000-0000-000000000001');
    INSERT INTO [EfficiencyRates] ([Id], [CompanyId], [Name], [Description], [Rate], [IsDefault], [IsActive], [CreatedById]) VALUES (4, 1, 'Rush Job (55%)', 'For urgent projects with tight deadlines', 55.00, 0, 1, '00000000-0000-0000-0000-000000000001');
    SET IDENTITY_INSERT [EfficiencyRates] OFF;
END

IF NOT EXISTS (SELECT 1 FROM Postcodes WHERE Postcode = '2000')
BEGIN
    INSERT INTO [Postcodes] ([Postcode], [Suburb], [State]) VALUES ('2000', 'Sydney', 'NSW');
    INSERT INTO [Postcodes] ([Postcode], [Suburb], [State]) VALUES ('3000', 'Melbourne', 'VIC');
    INSERT INTO [Postcodes] ([Postcode], [Suburb], [State]) VALUES ('4000', 'Brisbane', 'QLD');
    INSERT INTO [Postcodes] ([Postcode], [Suburb], [State]) VALUES ('5000', 'Adelaide', 'SA');
    INSERT INTO [Postcodes] ([Postcode], [Suburb], [State]) VALUES ('6000', 'Perth', 'WA');
END

PRINT 'Setup completed successfully!';
