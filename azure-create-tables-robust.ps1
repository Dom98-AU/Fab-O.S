# Create Azure SQL Tables with Verification
Write-Host "=== Creating Azure SQL Tables with Verification ===" -ForegroundColor Cyan

$azureUsername = "admin@nwi@nwiapps"
$azurePassword = "Natweigh88"
$azureServer = "nwiapps.database.windows.net"
$azureDatabase = "sqldb-steel-estimation-sandbox"

# Function to check if table exists
function Test-TableExists {
    param([string]$tableName)
    
    $checkSQL = "SELECT COUNT(*) FROM sys.tables WHERE name = '$tableName'"
    try {
        $result = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q $checkSQL -h -1 -t 15
        return ([int]$result.Trim() -gt 0)
    } catch {
        return $false
    }
}

# Function to create table with verification
function Create-TableWithVerification {
    param([string]$sql, [string]$tableName, [string]$description)
    
    Write-Host "Creating $description..." -ForegroundColor Yellow
    
    # Check if table already exists
    if (Test-TableExists $tableName) {
        Write-Host "⚠️ $tableName already exists, dropping first..." -ForegroundColor Yellow
        $dropSQL = "DROP TABLE [dbo].[$tableName];"
        try {
            $dropSQL | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -t 15 2>$null
        } catch {
            # Ignore drop errors
        }
    }
    
    # Create the table
    try {
        $result = $sql | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -t 30
        
        # Verify table was created
        Start-Sleep -Seconds 2
        if (Test-TableExists $tableName) {
            Write-Host "✅ $description created and verified" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ $description creation failed - table not found" -ForegroundColor Red
            Write-Host "SQL Result: $result" -ForegroundColor Gray
            return $false
        }
    } catch {
        Write-Host "❌ Failed to create $description`: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Clear any existing tables first
Write-Host "`nCleaning up existing tables..." -ForegroundColor Cyan
$cleanupTables = @("AspNetUserRoles", "AspNetUserClaims", "AspNetUserLogins", "AspNetUserTokens", "AspNetRoleClaims", "EfficiencyRates", "Customers", "Projects", "Estimations", "Packages", "AspNetUsers", "AspNetRoles", "Companies", "Postcodes", "TestTable")

foreach ($table in $cleanupTables) {
    if (Test-TableExists $table) {
        Write-Host "Dropping $table..." -ForegroundColor Gray
        $dropSQL = "DROP TABLE [dbo].[$table];"
        try {
            $dropSQL | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -t 15 2>$null
        } catch {
            # Ignore errors
        }
    }
}

Write-Host "Cleanup complete" -ForegroundColor Green

# Create tables in dependency order
Write-Host "`nCreating tables in dependency order..." -ForegroundColor Cyan

# 1. Independent tables first
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
$success1 = Create-TableWithVerification $companiesSQL "Companies" "Companies table"

$rolesSQL = @"
CREATE TABLE [dbo].[AspNetRoles](
    [Id] [nvarchar](450) NOT NULL,
    [Name] [nvarchar](256) NULL,
    [NormalizedName] [nvarchar](256) NULL,
    [ConcurrencyStamp] [nvarchar](max) NULL,
    CONSTRAINT [PK_AspNetRoles] PRIMARY KEY CLUSTERED ([Id] ASC)
);
"@
$success2 = Create-TableWithVerification $rolesSQL "AspNetRoles" "AspNetRoles table"

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
$success3 = Create-TableWithVerification $postcodesSQL "Postcodes" "Postcodes table"

# 2. Dependent tables
if ($success1 -and $success2) {
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
    [EmailConfirmed] [bit] NOT NULL DEFAULT 0,
    [PasswordHash] [nvarchar](max) NULL,
    [SecurityStamp] [nvarchar](max) NULL,
    [ConcurrencyStamp] [nvarchar](max) NULL,
    [PhoneNumber] [nvarchar](max) NULL,
    [PhoneNumberConfirmed] [bit] NOT NULL DEFAULT 0,
    [TwoFactorEnabled] [bit] NOT NULL DEFAULT 0,
    [LockoutEnd] [datetimeoffset](7) NULL,
    [LockoutEnabled] [bit] NOT NULL DEFAULT 1,
    [AccessFailedCount] [int] NOT NULL DEFAULT 0,
    CONSTRAINT [PK_AspNetUsers] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_AspNetUsers_Companies] FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id])
);
"@
    $success4 = Create-TableWithVerification $usersSQL "AspNetUsers" "AspNetUsers table"
    
    if ($success4) {
        $userRolesSQL = @"
CREATE TABLE [dbo].[AspNetUserRoles](
    [UserId] [nvarchar](450) NOT NULL,
    [RoleId] [nvarchar](450) NOT NULL,
    CONSTRAINT [PK_AspNetUserRoles] PRIMARY KEY CLUSTERED ([UserId] ASC, [RoleId] ASC),
    CONSTRAINT [FK_AspNetUserRoles_AspNetRoles_RoleId] FOREIGN KEY([RoleId]) REFERENCES [dbo].[AspNetRoles] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_AspNetUserRoles_AspNetUsers_UserId] FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
);
"@
        $success5 = Create-TableWithVerification $userRolesSQL "AspNetUserRoles" "AspNetUserRoles table"
        
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
        $success6 = Create-TableWithVerification $efficiencySQL "EfficiencyRates" "EfficiencyRates table"
    }
}

# Final verification
Write-Host "`nFinal verification..." -ForegroundColor Cyan
$finalTables = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "SELECT name FROM sys.tables WHERE is_ms_shipped = 0 ORDER BY name" -t 30

Write-Host "Tables created:" -ForegroundColor Green
Write-Host $finalTables

$tableCountFinal = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0" -h -1 -t 30

Write-Host "Total tables: $($tableCountFinal.Trim())" -ForegroundColor Green

if ([int]$tableCountFinal.Trim() -ge 5) {
    Write-Host "`n✅ Table creation completed successfully!" -ForegroundColor Green
    Write-Host "Now run: .\azure-insert-data.ps1" -ForegroundColor Cyan
} else {
    Write-Host "`n❌ Table creation incomplete. Expected at least 5 tables." -ForegroundColor Red
}