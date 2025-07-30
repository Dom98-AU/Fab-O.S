-- Manual Azure SQL Database Setup
-- Run this script in Azure Data Studio or SSMS connected to your Azure SQL Database

USE [sqldb-steel-estimation-sandbox];
GO

-- 1. Companies table (base table)
CREATE TABLE [dbo].[Companies] (
    [Id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [Name] NVARCHAR(200) NOT NULL,
    [ABN] NVARCHAR(20) NULL,
    [Address] NVARCHAR(500) NULL,
    [Phone] NVARCHAR(20) NULL,
    [Email] NVARCHAR(100) NULL,
    [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedDate] DATETIME2 NULL,
    [IsActive] BIT NOT NULL DEFAULT 1
);
GO

-- 2. Roles table
CREATE TABLE [dbo].[Roles] (
    [Id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [Name] NVARCHAR(100) NOT NULL,
    [Description] NVARCHAR(500) NULL,
    [IsActive] BIT NOT NULL DEFAULT 1
);
GO

-- 3. Users table
CREATE TABLE [dbo].[Users] (
    [Id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [CompanyId] INT NOT NULL,
    [Email] NVARCHAR(256) NOT NULL,
    [UserName] NVARCHAR(256) NOT NULL,
    [PasswordHash] NVARCHAR(MAX) NULL,
    [FirstName] NVARCHAR(100) NULL,
    [LastName] NVARCHAR(100) NULL,
    [PhoneNumber] NVARCHAR(20) NULL,
    [IsActive] BIT NOT NULL DEFAULT 1,
    [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedDate] DATETIME2 NULL,
    [LastLoginDate] DATETIME2 NULL,
    CONSTRAINT [FK_Users_Companies] FOREIGN KEY ([CompanyId]) REFERENCES [Companies]([Id])
);
GO

-- 4. UserRoles table
CREATE TABLE [dbo].[UserRoles] (
    [UserId] INT NOT NULL,
    [RoleId] INT NOT NULL,
    CONSTRAINT [PK_UserRoles] PRIMARY KEY ([UserId], [RoleId]),
    CONSTRAINT [FK_UserRoles_Users] FOREIGN KEY ([UserId]) REFERENCES [Users]([Id]),
    CONSTRAINT [FK_UserRoles_Roles] FOREIGN KEY ([RoleId]) REFERENCES [Roles]([Id])
);
GO

-- 5. Customers table
CREATE TABLE [dbo].[Customers] (
    [Id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [CompanyId] INT NOT NULL,
    [Name] NVARCHAR(200) NOT NULL,
    [ABN] NVARCHAR(20) NULL,
    [Address] NVARCHAR(500) NULL,
    [Phone] NVARCHAR(20) NULL,
    [Email] NVARCHAR(100) NULL,
    [ContactPerson] NVARCHAR(100) NULL,
    [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedDate] DATETIME2 NULL,
    [IsActive] BIT NOT NULL DEFAULT 1,
    CONSTRAINT [FK_Customers_Companies] FOREIGN KEY ([CompanyId]) REFERENCES [Companies]([Id])
);
GO

-- 6. Projects table
CREATE TABLE [dbo].[Projects] (
    [Id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [CompanyId] INT NOT NULL,
    [CustomerId] INT NULL,
    [Name] NVARCHAR(200) NOT NULL,
    [Description] NVARCHAR(MAX) NULL,
    [ProjectNumber] NVARCHAR(50) NULL,
    [Status] NVARCHAR(50) NULL,
    [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedDate] DATETIME2 NULL,
    [StartDate] DATETIME2 NULL,
    [EndDate] DATETIME2 NULL,
    [EstimatedHours] DECIMAL(10,2) NULL,
    [ActualHours] DECIMAL(10,2) NULL,
    [OwnerId] INT NULL,
    [IsDeleted] BIT NOT NULL DEFAULT 0,
    CONSTRAINT [FK_Projects_Companies] FOREIGN KEY ([CompanyId]) REFERENCES [Companies]([Id]),
    CONSTRAINT [FK_Projects_Customers] FOREIGN KEY ([CustomerId]) REFERENCES [Customers]([Id]),
    CONSTRAINT [FK_Projects_Users] FOREIGN KEY ([OwnerId]) REFERENCES [Users]([Id])
);
GO

-- Continue with remaining tables...
-- This is a starting point - add more tables as needed

-- Insert initial data
INSERT INTO [Companies] ([Name], [CreatedDate], [IsActive])
VALUES ('Default Company', GETUTCDATE(), 1);
GO

INSERT INTO [Roles] ([Name], [Description], [IsActive])
VALUES 
    ('Administrator', 'Full system access', 1),
    ('Project Manager', 'Manage projects and teams', 1),
    ('Senior Estimator', 'Create and approve estimations', 1),
    ('Estimator', 'Create estimations', 1),
    ('Viewer', 'View only access', 1);
GO

-- Insert admin user (password: Admin@123)
INSERT INTO [Users] ([CompanyId], [Email], [UserName], [PasswordHash], [FirstName], [LastName], [IsActive])
VALUES (1, 'admin@steelestimation.com', 'admin', 'AQAAAAEAACcQAAAAEJK+6WtjXnCbx5Vf8NxkY8jFtItvl8h7H6+7OXxhtskQzJdYG2jPaahVfgzTqO7tXg==', 'System', 'Administrator', 1);
GO

INSERT INTO [UserRoles] ([UserId], [RoleId])
VALUES (1, 1);
GO

PRINT 'Basic tables created successfully!';
PRINT 'Next: Run the data import script to migrate your data.';
GO