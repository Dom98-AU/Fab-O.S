-- Add EfficiencyRates table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'EfficiencyRates')
BEGIN
    CREATE TABLE [dbo].[EfficiencyRates] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [Name] NVARCHAR(100) NOT NULL,
        [EfficiencyPercentage] DECIMAL(5,2) NOT NULL,
        [Description] NVARCHAR(500) NULL,
        [IsDefault] BIT NOT NULL DEFAULT 0,
        [IsActive] BIT NOT NULL DEFAULT 1,
        [CompanyId] INT NOT NULL,
        [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        [ModifiedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_EfficiencyRates] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_EfficiencyRates_Companies_CompanyId] FOREIGN KEY ([CompanyId]) 
            REFERENCES [dbo].[Companies] ([Id]) ON DELETE CASCADE
    );

    -- Create indexes
    CREATE UNIQUE INDEX [IX_EfficiencyRates_CompanyId_Name] ON [dbo].[EfficiencyRates] ([CompanyId], [Name]);
    CREATE INDEX [IX_EfficiencyRates_CompanyId] ON [dbo].[EfficiencyRates] ([CompanyId]);
    CREATE INDEX [IX_EfficiencyRates_IsActive] ON [dbo].[EfficiencyRates] ([IsActive]);
    CREATE INDEX [IX_EfficiencyRates_IsDefault] ON [dbo].[EfficiencyRates] ([IsDefault]);
END
GO

-- Add EfficiencyRateId column to Packages table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Packages]') AND name = 'EfficiencyRateId')
BEGIN
    ALTER TABLE [dbo].[Packages]
    ADD [EfficiencyRateId] INT NULL;

    -- Add foreign key constraint
    ALTER TABLE [dbo].[Packages]
    ADD CONSTRAINT [FK_Packages_EfficiencyRates_EfficiencyRateId] 
        FOREIGN KEY ([EfficiencyRateId]) REFERENCES [dbo].[EfficiencyRates] ([Id]) 
        ON DELETE SET NULL;

    -- Create index
    CREATE INDEX [IX_Packages_EfficiencyRateId] ON [dbo].[Packages] ([EfficiencyRateId]);
END
GO

-- Insert default efficiency rates for existing companies
INSERT INTO [dbo].[EfficiencyRates] ([Name], [EfficiencyPercentage], [Description], [IsDefault], [IsActive], [CompanyId], [CreatedDate], [ModifiedDate])
SELECT 
    'Standard' as [Name],
    100.00 as [EfficiencyPercentage],
    'Standard efficiency rate (100%)' as [Description],
    1 as [IsDefault],
    1 as [IsActive],
    c.[Id] as [CompanyId],
    GETUTCDATE() as [CreatedDate],
    GETUTCDATE() as [ModifiedDate]
FROM [dbo].[Companies] c
WHERE NOT EXISTS (
    SELECT 1 FROM [dbo].[EfficiencyRates] er 
    WHERE er.[CompanyId] = c.[Id] AND er.[Name] = 'Standard'
);

-- Insert additional common efficiency rates
INSERT INTO [dbo].[EfficiencyRates] ([Name], [EfficiencyPercentage], [Description], [IsDefault], [IsActive], [CompanyId], [CreatedDate], [ModifiedDate])
SELECT 
    rates.[Name],
    rates.[EfficiencyPercentage],
    rates.[Description],
    0 as [IsDefault],
    1 as [IsActive],
    c.[Id] as [CompanyId],
    GETUTCDATE() as [CreatedDate],
    GETUTCDATE() as [ModifiedDate]
FROM [dbo].[Companies] c
CROSS JOIN (
    VALUES 
        ('High Efficiency', 90.00, 'High efficiency rate (90% - faster processing)'),
        ('Rush Job', 80.00, 'Rush job efficiency (80% - expedited processing)'),
        ('Complex Work', 110.00, 'Complex work efficiency (110% - slower, detailed processing)'),
        ('Training/New Staff', 120.00, 'Training or new staff efficiency (120% - learning curve)')
) as rates([Name], [EfficiencyPercentage], [Description])
WHERE NOT EXISTS (
    SELECT 1 FROM [dbo].[EfficiencyRates] er 
    WHERE er.[CompanyId] = c.[Id] AND er.[Name] = rates.[Name]
);

PRINT 'EfficiencyRates table and data created successfully';
GO