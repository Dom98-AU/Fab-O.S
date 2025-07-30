-- Steel Estimation Database Initialization Script for Docker
-- This script creates the database schema and initial data

USE master;
GO

-- Create database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'SteelEstimationDB')
BEGIN
    CREATE DATABASE [SteelEstimationDB];
END
GO

USE [SteelEstimationDB];
GO

-- Create Companies table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Companies]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Companies](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [Name] [nvarchar](100) NOT NULL,
        [Code] [nvarchar](10) NOT NULL,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        CONSTRAINT [PK_Companies] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END
GO

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
END
GO

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
END
GO

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
END
GO

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
        [Status] [nvarchar](50) NOT NULL DEFAULT 'Active',
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        [CreatedById] [nvarchar](450) NOT NULL,
        CONSTRAINT [PK_Projects] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_Projects_Companies] FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id]),
        CONSTRAINT [FK_Projects_AspNetUsers] FOREIGN KEY([CreatedById]) REFERENCES [dbo].[AspNetUsers] ([Id])
    );
END
GO

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
END
GO

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
END
GO

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
END
GO

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
END
GO

-- Create other necessary tables (ProcessingItems, WeldingItems, etc.)
-- Note: Add all other tables from your schema here

-- Insert initial data
-- Insert default company
SET IDENTITY_INSERT [dbo].[Companies] ON;
INSERT INTO [dbo].[Companies] ([Id], [Name], [Code], [IsActive]) 
SELECT 1, 'Default Company', 'DEFAULT', 1
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Companies] WHERE [Id] = 1);
SET IDENTITY_INSERT [dbo].[Companies] OFF;
GO

-- Insert roles
INSERT INTO [dbo].[AspNetRoles] ([Id], [Name], [NormalizedName]) 
SELECT '1', 'Administrator', 'ADMINISTRATOR'
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[AspNetRoles] WHERE [Id] = '1');

INSERT INTO [dbo].[AspNetRoles] ([Id], [Name], [NormalizedName]) 
SELECT '2', 'Project Manager', 'PROJECT MANAGER'
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[AspNetRoles] WHERE [Id] = '2');

INSERT INTO [dbo].[AspNetRoles] ([Id], [Name], [NormalizedName]) 
SELECT '3', 'Senior Estimator', 'SENIOR ESTIMATOR'
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[AspNetRoles] WHERE [Id] = '3');

INSERT INTO [dbo].[AspNetRoles] ([Id], [Name], [NormalizedName]) 
SELECT '4', 'Estimator', 'ESTIMATOR'
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[AspNetRoles] WHERE [Id] = '4');

INSERT INTO [dbo].[AspNetRoles] ([Id], [Name], [NormalizedName]) 
SELECT '5', 'Viewer', 'VIEWER'
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[AspNetRoles] WHERE [Id] = '5');
GO

-- Insert admin user (password: Admin@123)
INSERT INTO [dbo].[AspNetUsers] ([Id], [FullName], [CompanyId], [UserName], [NormalizedUserName], [Email], [NormalizedEmail], [EmailConfirmed], [PasswordHash], [SecurityStamp], [ConcurrencyStamp], [PhoneNumberConfirmed], [TwoFactorEnabled], [LockoutEnabled], [AccessFailedCount])
SELECT 
    '00000000-0000-0000-0000-000000000001',
    'System Administrator',
    1,
    'admin@steelestimation.com',
    'ADMIN@STEELESTIMATION.COM',
    'admin@steelestimation.com',
    'ADMIN@STEELESTIMATION.COM',
    1,
    'AQAAAAEAACcQAAAAEMvMR2X5W6V7LqYqHZWuHVOKRrYmYJ+eWz9J7NfV0cJHQF5bHQ5TvB+vW7C1X8vL5g==', -- Admin@123
    'QWERTYUIOPASDFGHJKLZXCVBNM123456',
    'abcdef01-2345-6789-abcd-ef0123456789',
    0,
    0,
    1,
    0
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[AspNetUsers] WHERE [Id] = '00000000-0000-0000-0000-000000000001');
GO

-- Assign admin role
INSERT INTO [dbo].[AspNetUserRoles] ([UserId], [RoleId])
SELECT '00000000-0000-0000-0000-000000000001', '1'
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[AspNetUserRoles] WHERE [UserId] = '00000000-0000-0000-0000-000000000001' AND [RoleId] = '1');
GO

-- Insert default efficiency rates
SET IDENTITY_INSERT [dbo].[EfficiencyRates] ON;
INSERT INTO [dbo].[EfficiencyRates] ([Id], [CompanyId], [Name], [Description], [Rate], [IsDefault], [IsActive], [CreatedById])
SELECT 1, 1, 'Standard (75%)', 'Standard efficiency rate for normal operations', 75.00, 1, 1, '00000000-0000-0000-0000-000000000001'
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[EfficiencyRates] WHERE [Id] = 1);

INSERT INTO [dbo].[EfficiencyRates] ([Id], [CompanyId], [Name], [Description], [Rate], [IsDefault], [IsActive], [CreatedById])
SELECT 2, 1, 'High Efficiency (85%)', 'For optimized operations with experienced teams', 85.00, 0, 1, '00000000-0000-0000-0000-000000000001'
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[EfficiencyRates] WHERE [Id] = 2);

INSERT INTO [dbo].[EfficiencyRates] ([Id], [CompanyId], [Name], [Description], [Rate], [IsDefault], [IsActive], [CreatedById])
SELECT 3, 1, 'Complex Work (65%)', 'For complex operations requiring extra care', 65.00, 0, 1, '00000000-0000-0000-0000-000000000001'
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[EfficiencyRates] WHERE [Id] = 3);
SET IDENTITY_INSERT [dbo].[EfficiencyRates] OFF;
GO

PRINT 'Database initialization completed successfully!';