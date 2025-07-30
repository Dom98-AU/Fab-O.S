IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE TABLE [Roles] (
        [Id] int NOT NULL IDENTITY,
        [RoleName] nvarchar(50) NOT NULL,
        [Description] nvarchar(500) NULL,
        [CanCreateProjects] bit NOT NULL,
        [CanEditProjects] bit NOT NULL,
        [CanDeleteProjects] bit NOT NULL,
        [CanViewAllProjects] bit NOT NULL,
        [CanManageUsers] bit NOT NULL,
        [CanExportData] bit NOT NULL,
        [CanImportData] bit NOT NULL,
        [CreatedDate] datetime2 NOT NULL,
        CONSTRAINT [PK_Roles] PRIMARY KEY ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE TABLE [Users] (
        [Id] int NOT NULL IDENTITY,
        [Username] nvarchar(100) NOT NULL,
        [Email] nvarchar(200) NOT NULL,
        [PasswordHash] nvarchar(500) NOT NULL,
        [SecurityStamp] nvarchar(500) NOT NULL,
        [FirstName] nvarchar(100) NULL,
        [LastName] nvarchar(100) NULL,
        [CompanyName] nvarchar(200) NULL,
        [JobTitle] nvarchar(100) NULL,
        [PhoneNumber] nvarchar(20) NULL,
        [IsActive] bit NOT NULL,
        [IsEmailConfirmed] bit NOT NULL,
        [EmailConfirmationToken] nvarchar(max) NULL,
        [PasswordResetToken] nvarchar(max) NULL,
        [PasswordResetExpiry] datetime2 NULL,
        [LastLoginDate] datetime2 NULL,
        [FailedLoginAttempts] int NOT NULL,
        [LockedOutUntil] datetime2 NULL,
        [CreatedDate] datetime2 NOT NULL,
        [LastModified] datetime2 NOT NULL,
        CONSTRAINT [PK_Users] PRIMARY KEY ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE TABLE [Invites] (
        [Id] int NOT NULL IDENTITY,
        [Email] nvarchar(450) NOT NULL,
        [FirstName] nvarchar(max) NOT NULL,
        [LastName] nvarchar(max) NOT NULL,
        [CompanyName] nvarchar(max) NULL,
        [JobTitle] nvarchar(max) NULL,
        [Token] nvarchar(450) NOT NULL,
        [CreatedDate] datetime2 NOT NULL,
        [ExpiryDate] datetime2 NOT NULL,
        [IsUsed] bit NOT NULL,
        [UsedDate] datetime2 NULL,
        [InvitedByUserId] int NOT NULL,
        [RoleId] int NOT NULL,
        [UserId] int NULL,
        [Message] nvarchar(max) NULL,
        [SendWelcomeEmail] bit NOT NULL,
        CONSTRAINT [PK_Invites] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Invites_Roles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [Roles] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_Invites_Users_InvitedByUserId] FOREIGN KEY ([InvitedByUserId]) REFERENCES [Users] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_Invites_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE SET NULL
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE TABLE [Projects] (
        [Id] int NOT NULL IDENTITY,
        [ProjectName] nvarchar(200) NOT NULL,
        [JobNumber] nvarchar(50) NOT NULL,
        [CustomerName] nvarchar(200) NULL,
        [ProjectLocation] nvarchar(200) NULL,
        [EstimationStage] nvarchar(20) NOT NULL,
        [LaborRate] decimal(18,2) NOT NULL,
        [ContingencyPercentage] decimal(18,2) NOT NULL,
        [Notes] nvarchar(max) NULL,
        [OwnerId] int NULL,
        [LastModifiedBy] int NULL,
        [CreatedDate] datetime2 NOT NULL,
        [LastModified] datetime2 NOT NULL,
        [IsDeleted] bit NOT NULL,
        CONSTRAINT [PK_Projects] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Projects_Users_LastModifiedBy] FOREIGN KEY ([LastModifiedBy]) REFERENCES [Users] ([Id]),
        CONSTRAINT [FK_Projects_Users_OwnerId] FOREIGN KEY ([OwnerId]) REFERENCES [Users] ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE TABLE [UserRoles] (
        [UserId] int NOT NULL,
        [RoleId] int NOT NULL,
        [AssignedDate] datetime2 NOT NULL,
        [AssignedBy] int NULL,
        CONSTRAINT [PK_UserRoles] PRIMARY KEY ([UserId], [RoleId]),
        CONSTRAINT [FK_UserRoles_Roles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [Roles] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_UserRoles_Users_AssignedBy] FOREIGN KEY ([AssignedBy]) REFERENCES [Users] ([Id]),
        CONSTRAINT [FK_UserRoles_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE TABLE [ProcessingItems] (
        [Id] int NOT NULL IDENTITY,
        [ProjectId] int NOT NULL,
        [DrawingNumber] nvarchar(100) NULL,
        [Description] nvarchar(500) NULL,
        [MaterialId] nvarchar(100) NULL,
        [Quantity] int NOT NULL,
        [Length] decimal(10,2) NOT NULL,
        [Weight] decimal(10,3) NOT NULL,
        [DeliveryBundleQty] int NOT NULL,
        [PackBundleQty] int NOT NULL,
        [BundleGroup] nvarchar(50) NULL,
        [PackGroup] nvarchar(50) NULL,
        [UnloadTimePerBundle] int NOT NULL,
        [MarkMeasureCut] int NOT NULL,
        [QualityCheckClean] int NOT NULL,
        [MoveToAssembly] int NOT NULL,
        [MoveAfterWeld] int NOT NULL,
        [LoadingTimePerBundle] int NOT NULL,
        [CreatedDate] datetime2 NOT NULL,
        [LastModified] datetime2 NOT NULL,
        [RowVersion] rowversion NULL,
        CONSTRAINT [PK_ProcessingItems] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_ProcessingItems_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [Projects] ([Id]) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE TABLE [ProjectUsers] (
        [ProjectId] int NOT NULL,
        [UserId] int NOT NULL,
        [AccessLevel] nvarchar(20) NOT NULL,
        [GrantedDate] datetime2 NOT NULL,
        [GrantedBy] int NULL,
        CONSTRAINT [PK_ProjectUsers] PRIMARY KEY ([ProjectId], [UserId]),
        CONSTRAINT [FK_ProjectUsers_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [Projects] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_ProjectUsers_Users_GrantedBy] FOREIGN KEY ([GrantedBy]) REFERENCES [Users] ([Id]),
        CONSTRAINT [FK_ProjectUsers_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE TABLE [WeldingItems] (
        [Id] int NOT NULL IDENTITY,
        [ProjectId] int NOT NULL,
        [DrawingNumber] nvarchar(100) NULL,
        [ItemDescription] nvarchar(500) NULL,
        [WeldType] nvarchar(50) NULL,
        [WeldLength] decimal(18,2) NOT NULL,
        [LocationComments] nvarchar(500) NULL,
        [PhotoReference] nvarchar(200) NULL,
        [ConnectionQty] int NOT NULL,
        [AssembleFitTack] int NOT NULL,
        [Weld] int NOT NULL,
        [WeldCheck] int NOT NULL,
        [WeldTest] int NOT NULL,
        [CreatedDate] datetime2 NOT NULL,
        [LastModified] datetime2 NOT NULL,
        [RowVersion] rowversion NULL,
        CONSTRAINT [PK_WeldingItems] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_WeldingItems_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [Projects] ([Id]) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    IF EXISTS (SELECT * FROM [sys].[identity_columns] WHERE [name] IN (N'Id', N'CanCreateProjects', N'CanDeleteProjects', N'CanEditProjects', N'CanExportData', N'CanImportData', N'CanManageUsers', N'CanViewAllProjects', N'CreatedDate', N'Description', N'RoleName') AND [object_id] = OBJECT_ID(N'[Roles]'))
        SET IDENTITY_INSERT [Roles] ON;
    EXEC(N'INSERT INTO [Roles] ([Id], [CanCreateProjects], [CanDeleteProjects], [CanEditProjects], [CanExportData], [CanImportData], [CanManageUsers], [CanViewAllProjects], [CreatedDate], [Description], [RoleName])
    VALUES (1, CAST(1 AS bit), CAST(1 AS bit), CAST(1 AS bit), CAST(1 AS bit), CAST(1 AS bit), CAST(1 AS bit), CAST(1 AS bit), ''2025-06-30T05:42:45.1374608Z'', N''Full system access'', N''Administrator''),
    (2, CAST(1 AS bit), CAST(1 AS bit), CAST(1 AS bit), CAST(1 AS bit), CAST(1 AS bit), CAST(0 AS bit), CAST(1 AS bit), ''2025-06-30T05:42:45.1374614Z'', N''Can manage all projects and users'', N''Project Manager''),
    (3, CAST(1 AS bit), CAST(0 AS bit), CAST(1 AS bit), CAST(1 AS bit), CAST(1 AS bit), CAST(0 AS bit), CAST(0 AS bit), ''2025-06-30T05:42:45.1374616Z'', N''Can create and edit projects'', N''Senior Estimator''),
    (4, CAST(0 AS bit), CAST(0 AS bit), CAST(1 AS bit), CAST(1 AS bit), CAST(1 AS bit), CAST(0 AS bit), CAST(0 AS bit), ''2025-06-30T05:42:45.1374617Z'', N''Can edit assigned projects'', N''Estimator''),
    (5, CAST(0 AS bit), CAST(0 AS bit), CAST(0 AS bit), CAST(1 AS bit), CAST(0 AS bit), CAST(0 AS bit), CAST(0 AS bit), ''2025-06-30T05:42:45.1374619Z'', N''Read-only access to assigned projects'', N''Viewer'')');
    IF EXISTS (SELECT * FROM [sys].[identity_columns] WHERE [name] IN (N'Id', N'CanCreateProjects', N'CanDeleteProjects', N'CanEditProjects', N'CanExportData', N'CanImportData', N'CanManageUsers', N'CanViewAllProjects', N'CreatedDate', N'Description', N'RoleName') AND [object_id] = OBJECT_ID(N'[Roles]'))
        SET IDENTITY_INSERT [Roles] OFF;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Invites_Email] ON [Invites] ([Email]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Invites_ExpiryDate] ON [Invites] ([ExpiryDate]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Invites_InvitedByUserId] ON [Invites] ([InvitedByUserId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Invites_IsUsed] ON [Invites] ([IsUsed]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Invites_RoleId] ON [Invites] ([RoleId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Invites_Token] ON [Invites] ([Token]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Invites_UserId] ON [Invites] ([UserId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_ProcessingItems_BundleGroup] ON [ProcessingItems] ([BundleGroup]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_ProcessingItems_MaterialId] ON [ProcessingItems] ([MaterialId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_ProcessingItems_ProjectId] ON [ProcessingItems] ([ProjectId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Projects_CreatedDate] ON [Projects] ([CreatedDate]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Projects_IsDeleted] ON [Projects] ([IsDeleted]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Projects_JobNumber] ON [Projects] ([JobNumber]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Projects_LastModifiedBy] ON [Projects] ([LastModifiedBy]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Projects_OwnerId] ON [Projects] ([OwnerId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_ProjectUsers_GrantedBy] ON [ProjectUsers] ([GrantedBy]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_ProjectUsers_UserId] ON [ProjectUsers] ([UserId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Roles_RoleName] ON [Roles] ([RoleName]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_UserRoles_AssignedBy] ON [UserRoles] ([AssignedBy]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_UserRoles_RoleId] ON [UserRoles] ([RoleId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Users_Email] ON [Users] ([Email]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Users_IsActive] ON [Users] ([IsActive]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Users_Username] ON [Users] ([Username]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_WeldingItems_ProjectId] ON [WeldingItems] ([ProjectId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20250630054245_InitialCreate'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20250630054245_InitialCreate', N'8.0.0');
END;
GO

COMMIT;
GO

