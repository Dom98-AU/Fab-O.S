-- Create Invites table for the invite system
-- Run this in both sandbox and production databases

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