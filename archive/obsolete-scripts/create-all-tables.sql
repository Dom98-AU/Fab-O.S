-- Complete database setup script for Steel Estimation Platform
-- Run this script to create all necessary tables in the correct order

-- 1. Create Roles table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Roles' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[Roles] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [RoleName] NVARCHAR(100) NOT NULL,
        [Description] NVARCHAR(500) NULL,
        [CanCreateProjects] BIT NOT NULL DEFAULT 0,
        [CanEditProjects] BIT NOT NULL DEFAULT 0,
        [CanDeleteProjects] BIT NOT NULL DEFAULT 0,
        [CanViewAllProjects] BIT NOT NULL DEFAULT 0,
        [CanManageUsers] BIT NOT NULL DEFAULT 0,
        [CanExportData] BIT NOT NULL DEFAULT 0,
        [CanImportData] BIT NOT NULL DEFAULT 0,
        CONSTRAINT [PK_Roles] PRIMARY KEY CLUSTERED ([Id] ASC)
    )
    
    -- Insert default roles
    INSERT INTO [dbo].[Roles] ([RoleName], [Description], [CanCreateProjects], [CanEditProjects], [CanDeleteProjects], [CanViewAllProjects], [CanManageUsers], [CanExportData], [CanImportData])
    VALUES 
        ('Administrator', 'Full system access', 1, 1, 1, 1, 1, 1, 1),
        ('Project Manager', 'Can manage all projects and users', 1, 1, 1, 1, 0, 1, 1),
        ('Senior Estimator', 'Can create and edit projects', 1, 1, 0, 0, 0, 1, 1),
        ('Estimator', 'Can edit assigned projects', 0, 1, 0, 0, 0, 1, 1),
        ('Viewer', 'Read-only access to assigned projects', 0, 0, 0, 0, 0, 1, 0)
    
    PRINT 'Roles table created and populated successfully'
END
ELSE
BEGIN
    PRINT 'Roles table already exists'
END
GO

-- 2. Create Users table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Users' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[Users] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [Username] NVARCHAR(100) NOT NULL,
        [Email] NVARCHAR(200) NOT NULL,
        [PasswordHash] NVARCHAR(500) NOT NULL,
        [FirstName] NVARCHAR(100) NULL,
        [LastName] NVARCHAR(100) NULL,
        [CompanyName] NVARCHAR(200) NULL,
        [JobTitle] NVARCHAR(100) NULL,
        [PhoneNumber] NVARCHAR(20) NULL,
        [IsActive] BIT NOT NULL DEFAULT 1,
        [IsEmailConfirmed] BIT NOT NULL DEFAULT 0,
        [EmailConfirmationToken] NVARCHAR(200) NULL,
        [PasswordResetToken] NVARCHAR(200) NULL,
        [PasswordResetExpiry] DATETIME2 NULL,
        [SecurityStamp] NVARCHAR(200) NULL,
        [RefreshToken] NVARCHAR(200) NULL,
        [RefreshTokenExpiry] DATETIME2 NULL,
        [LastLoginDate] DATETIME2 NULL,
        [FailedLoginAttempts] INT NOT NULL DEFAULT 0,
        [LockedOutUntil] DATETIME2 NULL,
        [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        [LastModified] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED ([Id] ASC)
    )
    
    -- Create indexes
    CREATE UNIQUE INDEX [IX_Users_Username] ON [dbo].[Users] ([Username])
    CREATE UNIQUE INDEX [IX_Users_Email] ON [dbo].[Users] ([Email])
    CREATE INDEX [IX_Users_IsActive] ON [dbo].[Users] ([IsActive])
    
    PRINT 'Users table created successfully'
END
ELSE
BEGIN
    PRINT 'Users table already exists'
END
GO

-- 3. Create UserRoles table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='UserRoles' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[UserRoles] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [UserId] INT NOT NULL,
        [RoleId] INT NOT NULL,
        [AssignedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        [AssignedBy] INT NULL,
        CONSTRAINT [PK_UserRoles] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_UserRoles_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users]([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_UserRoles_Roles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [dbo].[Roles]([Id]) ON DELETE CASCADE
    )
    
    -- Create indexes
    CREATE INDEX [IX_UserRoles_UserId] ON [dbo].[UserRoles] ([UserId])
    CREATE INDEX [IX_UserRoles_RoleId] ON [dbo].[UserRoles] ([RoleId])
    CREATE UNIQUE INDEX [IX_UserRoles_UserId_RoleId] ON [dbo].[UserRoles] ([UserId], [RoleId])
    
    PRINT 'UserRoles table created successfully'
END
ELSE
BEGIN
    PRINT 'UserRoles table already exists'
END
GO

-- 4. Create Projects table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Projects' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[Projects] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ProjectName] NVARCHAR(200) NOT NULL,
        [ProjectCode] NVARCHAR(50) NULL,
        [ClientName] NVARCHAR(200) NOT NULL,
        [ClientContact] NVARCHAR(200) NULL,
        [ProjectManager] NVARCHAR(200) NULL,
        [Estimator] NVARCHAR(200) NULL,
        [Description] NVARCHAR(MAX) NULL,
        [Status] NVARCHAR(50) NOT NULL DEFAULT 'Draft',
        [StartDate] DATETIME2 NULL,
        [EndDate] DATETIME2 NULL,
        [EstimatedHours] DECIMAL(10,2) NULL,
        [EstimatedCost] DECIMAL(18,2) NULL,
        [ActualHours] DECIMAL(10,2) NULL,
        [ActualCost] DECIMAL(18,2) NULL,
        [CreatedBy] INT NOT NULL,
        [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        [LastModified] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        [ModifiedBy] INT NULL,
        [IsDeleted] BIT NOT NULL DEFAULT 0,
        [DeletedDate] DATETIME2 NULL,
        [DeletedBy] INT NULL,
        CONSTRAINT [PK_Projects] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_Projects_Users_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([Id])
    )
    
    -- Create indexes
    CREATE INDEX [IX_Projects_ProjectCode] ON [dbo].[Projects] ([ProjectCode])
    CREATE INDEX [IX_Projects_Status] ON [dbo].[Projects] ([Status])
    CREATE INDEX [IX_Projects_CreatedBy] ON [dbo].[Projects] ([CreatedBy])
    CREATE INDEX [IX_Projects_IsDeleted] ON [dbo].[Projects] ([IsDeleted])
    
    PRINT 'Projects table created successfully'
END
ELSE
BEGIN
    PRINT 'Projects table already exists'
END
GO

-- 5. Create ProjectUsers table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='ProjectUsers' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[ProjectUsers] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ProjectId] INT NOT NULL,
        [UserId] INT NOT NULL,
        [Role] NVARCHAR(50) NOT NULL,
        [AssignedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        [AssignedBy] INT NULL,
        CONSTRAINT [PK_ProjectUsers] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_ProjectUsers_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Projects]([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_ProjectUsers_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users]([Id]) ON DELETE CASCADE
    )
    
    -- Create indexes
    CREATE INDEX [IX_ProjectUsers_ProjectId] ON [dbo].[ProjectUsers] ([ProjectId])
    CREATE INDEX [IX_ProjectUsers_UserId] ON [dbo].[ProjectUsers] ([UserId])
    CREATE UNIQUE INDEX [IX_ProjectUsers_ProjectId_UserId] ON [dbo].[ProjectUsers] ([ProjectId], [UserId])
    
    PRINT 'ProjectUsers table created successfully'
END
ELSE
BEGIN
    PRINT 'ProjectUsers table already exists'
END
GO

-- 6. Create ProcessingItems table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='ProcessingItems' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[ProcessingItems] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ProjectId] INT NOT NULL,
        [RowIndex] INT NOT NULL,
        [BundleGroup] NVARCHAR(50) NULL,
        [MaterialId] NVARCHAR(50) NULL,
        [Description] NVARCHAR(500) NULL,
        [Size] NVARCHAR(50) NULL,
        [Weight] DECIMAL(10,3) NULL,
        [PieceCount] INT NULL,
        [PieceType] NVARCHAR(50) NULL,
        [Length] DECIMAL(10,2) NULL,
        [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        [LastModified] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_ProcessingItems] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_ProcessingItems_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Projects]([Id]) ON DELETE CASCADE
    )
    
    -- Create indexes
    CREATE INDEX [IX_ProcessingItems_ProjectId] ON [dbo].[ProcessingItems] ([ProjectId])
    CREATE INDEX [IX_ProcessingItems_BundleGroup] ON [dbo].[ProcessingItems] ([BundleGroup])
    CREATE INDEX [IX_ProcessingItems_MaterialId] ON [dbo].[ProcessingItems] ([MaterialId])
    
    PRINT 'ProcessingItems table created successfully'
END
ELSE
BEGIN
    PRINT 'ProcessingItems table already exists'
END
GO

-- 7. Create WeldingItems table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='WeldingItems' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[WeldingItems] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ProjectId] INT NOT NULL,
        [RowIndex] INT NOT NULL,
        [WeldType] NVARCHAR(50) NULL,
        [WeldSize] NVARCHAR(50) NULL,
        [WeldLength] DECIMAL(10,2) NULL,
        [WeldCount] INT NULL,
        [Position] NVARCHAR(50) NULL,
        [Process] NVARCHAR(50) NULL,
        [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        [LastModified] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_WeldingItems] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_WeldingItems_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Projects]([Id]) ON DELETE CASCADE
    )
    
    -- Create indexes
    CREATE INDEX [IX_WeldingItems_ProjectId] ON [dbo].[WeldingItems] ([ProjectId])
    
    PRINT 'WeldingItems table created successfully'
END
ELSE
BEGIN
    PRINT 'WeldingItems table already exists'
END
GO

-- 8. Create Invites table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Invites' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[Invites] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [Email] NVARCHAR(200) NOT NULL,
        [FirstName] NVARCHAR(100) NOT NULL,
        [LastName] NVARCHAR(100) NOT NULL,
        [CompanyName] NVARCHAR(200) NULL,
        [JobTitle] NVARCHAR(100) NULL,
        [Token] NVARCHAR(200) NOT NULL,
        [CreatedDate] DATETIME2 NOT NULL,
        [ExpiryDate] DATETIME2 NOT NULL,
        [IsUsed] BIT NOT NULL DEFAULT 0,
        [UsedDate] DATETIME2 NULL,
        [InvitedByUserId] INT NOT NULL,
        [RoleId] INT NOT NULL,
        [UserId] INT NULL,
        [Message] NVARCHAR(500) NULL,
        [SendWelcomeEmail] BIT NOT NULL DEFAULT 1,
        CONSTRAINT [PK_Invites] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_Invites_Users_InvitedByUserId] FOREIGN KEY ([InvitedByUserId]) REFERENCES [dbo].[Users]([Id]),
        CONSTRAINT [FK_Invites_Roles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [dbo].[Roles]([Id]),
        CONSTRAINT [FK_Invites_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users]([Id]) ON DELETE SET NULL
    )
    
    -- Create indexes for performance
    CREATE INDEX [IX_Invites_Email] ON [dbo].[Invites] ([Email])
    CREATE UNIQUE INDEX [IX_Invites_Token] ON [dbo].[Invites] ([Token])
    CREATE INDEX [IX_Invites_IsUsed] ON [dbo].[Invites] ([IsUsed])
    CREATE INDEX [IX_Invites_ExpiryDate] ON [dbo].[Invites] ([ExpiryDate])
    
    PRINT 'Invites table created successfully'
END
ELSE
BEGIN
    PRINT 'Invites table already exists'
END
GO

-- 9. Create default admin user if no users exist
IF NOT EXISTS (SELECT 1 FROM [dbo].[Users])
BEGIN
    -- Insert admin user
    INSERT INTO [dbo].[Users] (
        [Username],
        [Email],
        [PasswordHash],
        [FirstName],
        [LastName],
        [IsActive],
        [IsEmailConfirmed],
        [CreatedDate],
        [LastModified],
        [SecurityStamp]
    )
    VALUES (
        'admin',
        'admin@steelestimation.com',
        'F+TJMqUPKmI7yqm7MpfP2FTjpCJfEaOCdBvPL8h8GQk=.J3KDgS/Yy8eaBCVa05q0X3KQQRNiUAa8m4DmDCVyBuQ=', -- Admin@123
        'System',
        'Administrator',
        1,
        1,
        GETUTCDATE(),
        GETUTCDATE(),
        NEWID()
    )
    
    -- Get the admin user ID
    DECLARE @AdminUserId INT = SCOPE_IDENTITY()
    
    -- Assign Administrator role (RoleId 1 is Administrator)
    INSERT INTO [dbo].[UserRoles] ([UserId], [RoleId], [AssignedDate])
    VALUES (@AdminUserId, 1, GETUTCDATE())
    
    PRINT 'Admin user created successfully. Username: admin, Password: Admin@123'
END
ELSE
BEGIN
    PRINT 'Users already exist in the database. No admin user created.'
END
GO

PRINT 'Database setup complete!'