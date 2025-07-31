-- Steel Estimation Platform Database Schema
-- Run this script in sqldb-steel-estimation-prod database

-- Create Users table
CREATE TABLE Users (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(100) NOT NULL UNIQUE,
    Email NVARCHAR(200) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(500) NOT NULL,
    SecurityStamp NVARCHAR(500) NOT NULL,
    FirstName NVARCHAR(100),
    LastName NVARCHAR(100),
    CompanyName NVARCHAR(200),
    JobTitle NVARCHAR(100),
    PhoneNumber NVARCHAR(20),
    IsActive BIT DEFAULT 1,
    IsEmailConfirmed BIT DEFAULT 0,
    EmailConfirmationToken NVARCHAR(500),
    PasswordResetToken NVARCHAR(500),
    PasswordResetExpiry DATETIME2,
    LastLoginDate DATETIME2,
    FailedLoginAttempts INT DEFAULT 0,
    LockedOutUntil DATETIME2,
    CreatedDate DATETIME2 DEFAULT GETUTCDATE(),
    LastModified DATETIME2 DEFAULT GETUTCDATE(),
    INDEX IX_Users_Email (Email),
    INDEX IX_Users_Username (Username),
    INDEX IX_Users_IsActive (IsActive)
);

-- Create Roles table
CREATE TABLE Roles (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    RoleName NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(500),
    CanCreateProjects BIT DEFAULT 1,
    CanEditProjects BIT DEFAULT 1,
    CanDeleteProjects BIT DEFAULT 0,
    CanViewAllProjects BIT DEFAULT 0,
    CanManageUsers BIT DEFAULT 0,
    CanExportData BIT DEFAULT 1,
    CanImportData BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETUTCDATE()
);

-- Create UserRoles table (many-to-many)
CREATE TABLE UserRoles (
    UserId INT NOT NULL FOREIGN KEY REFERENCES Users(Id),
    RoleId INT NOT NULL FOREIGN KEY REFERENCES Roles(Id),
    AssignedDate DATETIME2 DEFAULT GETUTCDATE(),
    AssignedBy INT FOREIGN KEY REFERENCES Users(Id),
    PRIMARY KEY (UserId, RoleId)
);

-- Create Projects table
CREATE TABLE Projects (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    ProjectName NVARCHAR(200) NOT NULL,
    JobNumber NVARCHAR(50) NOT NULL,
    EstimationStage NVARCHAR(20) NOT NULL DEFAULT 'Preliminary',
    LaborRate DECIMAL(10,2) NOT NULL DEFAULT 75.00,
    OwnerId INT FOREIGN KEY REFERENCES Users(Id),
    LastModifiedBy INT FOREIGN KEY REFERENCES Users(Id),
    CreatedDate DATETIME2 DEFAULT GETUTCDATE(),
    LastModified DATETIME2 DEFAULT GETUTCDATE(),
    IsDeleted BIT DEFAULT 0,
    INDEX IX_Projects_JobNumber (JobNumber),
    INDEX IX_Projects_CreatedDate (CreatedDate),
    INDEX IX_Projects_IsDeleted (IsDeleted)
);

-- Create ProjectUsers table for access control
CREATE TABLE ProjectUsers (
    ProjectId INT NOT NULL FOREIGN KEY REFERENCES Projects(Id),
    UserId INT NOT NULL FOREIGN KEY REFERENCES Users(Id),
    AccessLevel NVARCHAR(20) NOT NULL DEFAULT 'ReadWrite', -- ReadOnly, ReadWrite, Owner
    GrantedDate DATETIME2 DEFAULT GETUTCDATE(),
    GrantedBy INT FOREIGN KEY REFERENCES Users(Id),
    PRIMARY KEY (ProjectId, UserId),
    INDEX IX_ProjectUsers_UserId (UserId)
);

-- Create ProcessingItems table
CREATE TABLE ProcessingItems (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    ProjectId INT NOT NULL FOREIGN KEY REFERENCES Projects(Id),
    DrawingNumber NVARCHAR(100),
    Description NVARCHAR(500),
    MaterialId NVARCHAR(100),
    Quantity INT NOT NULL DEFAULT 0,
    Length DECIMAL(10,2) DEFAULT 0,
    Weight DECIMAL(10,3) DEFAULT 0,
    DeliveryBundleQty INT DEFAULT 1,
    PackBundleQty INT DEFAULT 1,
    BundleGroup NVARCHAR(50),
    PackGroup NVARCHAR(50),
    -- Time estimations in minutes
    UnloadTimePerBundle INT DEFAULT 15,
    MarkMeasureCut INT DEFAULT 30,
    QualityCheckClean INT DEFAULT 15,
    MoveToAssembly INT DEFAULT 20,
    MoveAfterWeld INT DEFAULT 20,
    LoadingTimePerBundle INT DEFAULT 15,
    -- Audit fields
    CreatedDate DATETIME2 DEFAULT GETUTCDATE(),
    LastModified DATETIME2 DEFAULT GETUTCDATE(),
    RowVersion ROWVERSION,
    INDEX IX_ProcessingItems_ProjectId (ProjectId),
    INDEX IX_ProcessingItems_BundleGroup (BundleGroup),
    INDEX IX_ProcessingItems_MaterialId (MaterialId)
);

-- Create WeldingItems table
CREATE TABLE WeldingItems (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    ProjectId INT NOT NULL FOREIGN KEY REFERENCES Projects(Id),
    DrawingNumber NVARCHAR(100),
    LocationComments NVARCHAR(500),
    PhotoReference NVARCHAR(200),
    ConnectionQty INT NOT NULL DEFAULT 1,
    -- Time estimations in minutes
    AssembleFitTack INT DEFAULT 5,
    Weld INT DEFAULT 3,
    WeldCheck INT DEFAULT 2,
    WeldTest INT DEFAULT 0,
    -- Audit fields
    CreatedDate DATETIME2 DEFAULT GETUTCDATE(),
    LastModified DATETIME2 DEFAULT GETUTCDATE(),
    RowVersion ROWVERSION,
    INDEX IX_WeldingItems_ProjectId (ProjectId)
);

-- Create AuditLog table
CREATE TABLE AuditLog (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT FOREIGN KEY REFERENCES Users(Id),
    SessionId NVARCHAR(100),
    Action NVARCHAR(50) NOT NULL,
    EntityName NVARCHAR(100) NOT NULL,
    EntityId INT NOT NULL,
    OldValues NVARCHAR(MAX),
    NewValues NVARCHAR(MAX),
    ChangedColumns NVARCHAR(MAX),
    Timestamp DATETIME2 DEFAULT GETUTCDATE(),
    INDEX IX_AuditLog_UserId (UserId),
    INDEX IX_AuditLog_Timestamp (Timestamp),
    INDEX IX_AuditLog_EntityName_EntityId (EntityName, EntityId)
);

-- Insert default roles
INSERT INTO Roles (RoleName, Description, CanCreateProjects, CanEditProjects, CanDeleteProjects, CanViewAllProjects, CanManageUsers, CanExportData, CanImportData) VALUES
('Administrator', 'Full system access', 1, 1, 1, 1, 1, 1, 1),
('Project Manager', 'Can manage all projects and users', 1, 1, 1, 1, 0, 1, 1),
('Senior Estimator', 'Can create and edit projects', 1, 1, 0, 0, 0, 1, 1),
('Estimator', 'Can edit assigned projects', 0, 1, 0, 0, 0, 1, 1),
('Viewer', 'Read-only access to assigned projects', 0, 0, 0, 0, 0, 1, 0);

-- Create a view for project summary calculations
CREATE VIEW vw_ProjectSummary AS
SELECT 
    p.Id AS ProjectId,
    p.ProjectName,
    p.JobNumber,
    p.LaborRate,
    COUNT(DISTINCT pi.Id) AS ProcessingItemCount,
    COUNT(DISTINCT wi.Id) AS WeldingItemCount,
    SUM(pi.Quantity * pi.Weight) AS TotalWeight,
    SUM(
        (pi.UnloadTimePerBundle * CEILING(CAST(pi.Quantity AS FLOAT) / NULLIF(pi.DeliveryBundleQty, 0))) +
        (pi.MarkMeasureCut * pi.Quantity) +
        (pi.QualityCheckClean * pi.Quantity) +
        (pi.MoveToAssembly * CEILING(CAST(pi.Quantity AS FLOAT) / NULLIF(pi.PackBundleQty, 0))) +
        (pi.MoveAfterWeld * CEILING(CAST(pi.Quantity AS FLOAT) / NULLIF(pi.PackBundleQty, 0))) +
        (pi.LoadingTimePerBundle * CEILING(CAST(pi.Quantity AS FLOAT) / NULLIF(pi.DeliveryBundleQty, 0)))
    ) / 60.0 AS TotalProcessingHours,
    SUM((wi.AssembleFitTack + wi.Weld + wi.WeldCheck + wi.WeldTest) * wi.ConnectionQty) / 60.0 AS TotalWeldingHours
FROM Projects p
LEFT JOIN ProcessingItems pi ON p.Id = pi.ProjectId
LEFT JOIN WeldingItems wi ON p.Id = wi.ProjectId
WHERE p.IsDeleted = 0
GROUP BY p.Id, p.ProjectName, p.JobNumber, p.LaborRate;