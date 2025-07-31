# Create Azure SQL Tables One by One
Write-Host "=== Creating Azure SQL Tables Individually ===" -ForegroundColor Cyan

$azureUsername = "admin@nwi@nwiapps"
$azurePassword = "Natweigh88"
$azureServer = "nwiapps.database.windows.net"
$azureDatabase = "sqldb-steel-estimation-sandbox"

# Function to execute SQL with error handling
function Execute-SQL {
    param([string]$sql, [string]$description)
    
    Write-Host "Creating $description..." -ForegroundColor Yellow
    try {
        $result = $sql | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -t 60
        Write-Host "✅ $description created successfully" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Failed to create $description`: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Drop and recreate tables in correct order
Write-Host "`nDropping existing tables..." -ForegroundColor Cyan

# Drop tables in reverse dependency order
$dropTables = @(
    "DROP TABLE IF EXISTS [dbo].[AspNetUserRoles];",
    "DROP TABLE IF EXISTS [dbo].[AspNetUserClaims];", 
    "DROP TABLE IF EXISTS [dbo].[AspNetUserLogins];",
    "DROP TABLE IF EXISTS [dbo].[AspNetUserTokens];",
    "DROP TABLE IF EXISTS [dbo].[AspNetRoleClaims];",
    "DROP TABLE IF EXISTS [dbo].[EfficiencyRates];",
    "DROP TABLE IF EXISTS [dbo].[Customers];",
    "DROP TABLE IF EXISTS [dbo].[Projects];",
    "DROP TABLE IF EXISTS [dbo].[AspNetUsers];",
    "DROP TABLE IF EXISTS [dbo].[AspNetRoles];",
    "DROP TABLE IF EXISTS [dbo].[Companies];",
    "DROP TABLE IF EXISTS [dbo].[Postcodes];",
    "DROP TABLE IF EXISTS [dbo].[TestTable];"
)

foreach ($dropSQL in $dropTables) {
    $dropSQL | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -t 30 2>$null
}

Write-Host "Existing tables dropped" -ForegroundColor Green

# Create tables one by one
Write-Host "`nCreating tables..." -ForegroundColor Cyan

# 1. Companies
$companiesSQL = @"
CREATE TABLE [dbo].[Companies](
    [Id] [int] IDENTITY(1,1) NOT NULL,
    [Name] [nvarchar](100) NOT NULL,
    [Code] [nvarchar](10) NOT NULL,
    [IsActive] [bit] NOT NULL DEFAULT 1,
    [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedAt] [datetime2](7) NULL,
    CONSTRAINT [PK_Companies] PRIMARY KEY CLUSTERED ([Id] ASC)
);
"@
Execute-SQL $companiesSQL "Companies table"

# 2. AspNetRoles
$rolesSQL = @"
CREATE TABLE [dbo].[AspNetRoles](
    [Id] [nvarchar](450) NOT NULL,
    [Name] [nvarchar](256) NULL,
    [NormalizedName] [nvarchar](256) NULL,
    [ConcurrencyStamp] [nvarchar](max) NULL,
    CONSTRAINT [PK_AspNetRoles] PRIMARY KEY CLUSTERED ([Id] ASC)
);
"@
Execute-SQL $rolesSQL "AspNetRoles table"

# 3. AspNetUsers
$usersSQL = @"
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
"@
Execute-SQL $usersSQL "AspNetUsers table"

# 4. AspNetUserRoles
$userRolesSQL = @"
CREATE TABLE [dbo].[AspNetUserRoles](
    [UserId] [nvarchar](450) NOT NULL,
    [RoleId] [nvarchar](450) NOT NULL,
    CONSTRAINT [PK_AspNetUserRoles] PRIMARY KEY CLUSTERED ([UserId] ASC, [RoleId] ASC),
    CONSTRAINT [FK_AspNetUserRoles_AspNetRoles_RoleId] FOREIGN KEY([RoleId]) REFERENCES [dbo].[AspNetRoles] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_AspNetUserRoles_AspNetUsers_UserId] FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
);
"@
Execute-SQL $userRolesSQL "AspNetUserRoles table"

# 5. EfficiencyRates
$efficiencySQL = @"
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
"@
Execute-SQL $efficiencySQL "EfficiencyRates table"

# 6. Postcodes
$postcodesSQL = @"
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
"@
Execute-SQL $postcodesSQL "Postcodes table"

# 7. Projects
$projectsSQL = @"
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
"@
Execute-SQL $projectsSQL "Projects table"

# 8. Estimations
$estimationsSQL = @"
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
"@
Execute-SQL $estimationsSQL "Estimations table"

# 9. Packages
$packagesSQL = @"
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
"@
Execute-SQL $packagesSQL "Packages table"

# Verify tables created
Write-Host "`nVerifying tables..." -ForegroundColor Cyan
$tableCount = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0" -h -1 -t 30

Write-Host "Total tables created: $($tableCount.Trim())" -ForegroundColor Green

$tableList = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "SELECT name FROM sys.tables WHERE is_ms_shipped = 0 ORDER BY name" -t 30

Write-Host "Tables:" -ForegroundColor Green
Write-Host $tableList

Write-Host "`nTables created successfully! Now run the data insertion..." -ForegroundColor Green