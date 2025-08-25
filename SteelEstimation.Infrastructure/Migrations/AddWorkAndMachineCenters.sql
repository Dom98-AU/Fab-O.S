-- Add Work Centers and Machine Centers Tables
-- Migration: AddWorkAndMachineCenters
-- Date: 2025-01-07
-- Description: Adds comprehensive work center and machine center management system

-- Create WorkCenters table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'WorkCenters')
BEGIN
    CREATE TABLE WorkCenters (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Code NVARCHAR(50) NOT NULL,
        Name NVARCHAR(200) NOT NULL,
        Description NVARCHAR(500) NULL,
        CompanyId INT NOT NULL,
        WorkCenterType NVARCHAR(50) NOT NULL,
        DailyCapacityHours DECIMAL(10,2) NOT NULL DEFAULT 8,
        SimultaneousOperations INT NOT NULL DEFAULT 1,
        HourlyRate DECIMAL(10,2) NOT NULL DEFAULT 0,
        OverheadRate DECIMAL(10,2) NOT NULL DEFAULT 0,
        EfficiencyPercentage DECIMAL(5,2) NOT NULL DEFAULT 100,
        Department NVARCHAR(100) NULL,
        Building NVARCHAR(100) NULL,
        Floor NVARCHAR(50) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        IsDeleted BIT NOT NULL DEFAULT 0,
        MaintenanceIntervalDays INT NOT NULL DEFAULT 90,
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        CreatedByUserId INT NULL,
        LastModified DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        LastModifiedByUserId INT NULL,
        CONSTRAINT FK_WorkCenters_Company FOREIGN KEY (CompanyId) REFERENCES Companies(Id),
        CONSTRAINT FK_WorkCenters_CreatedByUser FOREIGN KEY (CreatedByUserId) REFERENCES Users(Id),
        CONSTRAINT FK_WorkCenters_LastModifiedByUser FOREIGN KEY (LastModifiedByUserId) REFERENCES Users(Id),
        CONSTRAINT UQ_WorkCenters_Code_Company UNIQUE (Code, CompanyId)
    );

    CREATE INDEX IX_WorkCenters_CompanyId ON WorkCenters(CompanyId);
    CREATE INDEX IX_WorkCenters_WorkCenterType ON WorkCenters(WorkCenterType);
    CREATE INDEX IX_WorkCenters_IsActive ON WorkCenters(IsActive);
    CREATE INDEX IX_WorkCenters_Department ON WorkCenters(Department);
END
GO

-- Create WorkCenterSkills table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'WorkCenterSkills')
BEGIN
    CREATE TABLE WorkCenterSkills (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        WorkCenterId INT NOT NULL,
        SkillName NVARCHAR(100) NOT NULL,
        SkillLevel NVARCHAR(50) NULL,
        Description NVARCHAR(500) NULL,
        IsRequired BIT NOT NULL DEFAULT 0,
        CONSTRAINT FK_WorkCenterSkills_WorkCenter FOREIGN KEY (WorkCenterId) REFERENCES WorkCenters(Id) ON DELETE CASCADE
    );

    CREATE INDEX IX_WorkCenterSkills_WorkCenterId ON WorkCenterSkills(WorkCenterId);
END
GO

-- Create WorkCenterShifts table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'WorkCenterShifts')
BEGIN
    CREATE TABLE WorkCenterShifts (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        WorkCenterId INT NOT NULL,
        ShiftName NVARCHAR(100) NOT NULL,
        StartTime TIME NOT NULL,
        EndTime TIME NOT NULL,
        BreakDurationMinutes INT NOT NULL DEFAULT 0,
        DaysOfWeek NVARCHAR(20) NOT NULL, -- Mon,Tue,Wed,Thu,Fri
        IsActive BIT NOT NULL DEFAULT 1,
        EfficiencyMultiplier DECIMAL(5,2) NOT NULL DEFAULT 1.0,
        CONSTRAINT FK_WorkCenterShifts_WorkCenter FOREIGN KEY (WorkCenterId) REFERENCES WorkCenters(Id) ON DELETE CASCADE
    );

    CREATE INDEX IX_WorkCenterShifts_WorkCenterId ON WorkCenterShifts(WorkCenterId);
END
GO

-- Create MachineCenters table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'MachineCenters')
BEGIN
    CREATE TABLE MachineCenters (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        MachineCode NVARCHAR(50) NOT NULL,
        MachineName NVARCHAR(200) NOT NULL,
        Description NVARCHAR(500) NULL,
        WorkCenterId INT NOT NULL,
        CompanyId INT NOT NULL,
        Manufacturer NVARCHAR(100) NULL,
        Model NVARCHAR(100) NULL,
        SerialNumber NVARCHAR(50) NULL,
        PurchaseDate DATETIME2 NULL,
        PurchasePrice DECIMAL(12,2) NULL,
        MachineType NVARCHAR(50) NOT NULL,
        MachineSubType NVARCHAR(100) NULL,
        MaxCapacity DECIMAL(10,2) NOT NULL DEFAULT 0,
        CapacityUnit NVARCHAR(20) NULL,
        SetupTimeMinutes DECIMAL(10,2) NOT NULL DEFAULT 0,
        WarmupTimeMinutes DECIMAL(10,2) NOT NULL DEFAULT 0,
        CooldownTimeMinutes DECIMAL(10,2) NOT NULL DEFAULT 0,
        HourlyRate DECIMAL(10,2) NOT NULL DEFAULT 0,
        PowerConsumptionKwh DECIMAL(10,2) NOT NULL DEFAULT 0,
        PowerCostPerKwh DECIMAL(10,2) NOT NULL DEFAULT 0,
        EfficiencyPercentage DECIMAL(5,2) NOT NULL DEFAULT 85,
        QualityRate DECIMAL(5,2) NOT NULL DEFAULT 95,
        AvailabilityRate DECIMAL(5,2) NOT NULL DEFAULT 90,
        IsActive BIT NOT NULL DEFAULT 1,
        IsDeleted BIT NOT NULL DEFAULT 0,
        CurrentStatus NVARCHAR(50) NOT NULL DEFAULT 'Available',
        LastMaintenanceDate DATETIME2 NULL,
        NextMaintenanceDate DATETIME2 NULL,
        MaintenanceIntervalHours INT NOT NULL DEFAULT 500,
        CurrentOperatingHours INT NOT NULL DEFAULT 0,
        RequiresTooling BIT NOT NULL DEFAULT 0,
        ToolingRequirements NVARCHAR(500) NULL,
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        CreatedByUserId INT NULL,
        LastModified DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        LastModifiedByUserId INT NULL,
        CONSTRAINT FK_MachineCenters_WorkCenter FOREIGN KEY (WorkCenterId) REFERENCES WorkCenters(Id),
        CONSTRAINT FK_MachineCenters_Company FOREIGN KEY (CompanyId) REFERENCES Companies(Id),
        CONSTRAINT FK_MachineCenters_CreatedByUser FOREIGN KEY (CreatedByUserId) REFERENCES Users(Id),
        CONSTRAINT FK_MachineCenters_LastModifiedByUser FOREIGN KEY (LastModifiedByUserId) REFERENCES Users(Id),
        CONSTRAINT UQ_MachineCenters_MachineCode_Company UNIQUE (MachineCode, CompanyId),
        CONSTRAINT CK_MachineCenters_Status CHECK (CurrentStatus IN ('Available', 'InUse', 'Maintenance', 'Breakdown'))
    );

    CREATE INDEX IX_MachineCenters_WorkCenterId ON MachineCenters(WorkCenterId);
    CREATE INDEX IX_MachineCenters_CompanyId ON MachineCenters(CompanyId);
    CREATE INDEX IX_MachineCenters_MachineType ON MachineCenters(MachineType);
    CREATE INDEX IX_MachineCenters_CurrentStatus ON MachineCenters(CurrentStatus);
    CREATE INDEX IX_MachineCenters_IsActive ON MachineCenters(IsActive);
END
GO

-- Create MachineCapabilities table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'MachineCapabilities')
BEGIN
    CREATE TABLE MachineCapabilities (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        MachineCenterId INT NOT NULL,
        CapabilityName NVARCHAR(100) NOT NULL,
        Description NVARCHAR(500) NULL,
        MinValue DECIMAL(10,2) NULL,
        MaxValue DECIMAL(10,2) NULL,
        Unit NVARCHAR(20) NULL,
        CompatibleMaterials NVARCHAR(200) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CONSTRAINT FK_MachineCapabilities_MachineCenter FOREIGN KEY (MachineCenterId) REFERENCES MachineCenters(Id) ON DELETE CASCADE
    );

    CREATE INDEX IX_MachineCapabilities_MachineCenterId ON MachineCapabilities(MachineCenterId);
END
GO

-- Create MachineOperators table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'MachineOperators')
BEGIN
    CREATE TABLE MachineOperators (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        MachineCenterId INT NOT NULL,
        UserId INT NOT NULL,
        CertificationLevel NVARCHAR(50) NOT NULL DEFAULT 'Operator',
        CertificationDate DATETIME2 NULL,
        CertificationExpiry DATETIME2 NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        IsPrimary BIT NOT NULL DEFAULT 0,
        CONSTRAINT FK_MachineOperators_MachineCenter FOREIGN KEY (MachineCenterId) REFERENCES MachineCenters(Id) ON DELETE CASCADE,
        CONSTRAINT FK_MachineOperators_User FOREIGN KEY (UserId) REFERENCES Users(Id),
        CONSTRAINT UQ_MachineOperators_Machine_User UNIQUE (MachineCenterId, UserId)
    );

    CREATE INDEX IX_MachineOperators_MachineCenterId ON MachineOperators(MachineCenterId);
    CREATE INDEX IX_MachineOperators_UserId ON MachineOperators(UserId);
END
GO

-- Insert sample data for testing (only if tables are empty)
IF NOT EXISTS (SELECT 1 FROM WorkCenters)
BEGIN
    -- Insert sample work centers for each company
    INSERT INTO WorkCenters (Code, Name, Description, CompanyId, WorkCenterType, DailyCapacityHours, SimultaneousOperations, HourlyRate, OverheadRate, EfficiencyPercentage, Department, Building, Floor)
    SELECT 
        'WC-PROD-001', 
        'Main Production Line', 
        'Primary production work center for steel fabrication',
        Id,
        'Production',
        16, -- 2 shifts
        3,
        125.00,
        35.00,
        95,
        'Production',
        'Building A',
        'Ground Floor'
    FROM Companies WHERE IsDeleted = 0;

    INSERT INTO WorkCenters (Code, Name, Description, CompanyId, WorkCenterType, DailyCapacityHours, SimultaneousOperations, HourlyRate, OverheadRate, EfficiencyPercentage, Department, Building, Floor)
    SELECT 
        'WC-WELD-001', 
        'Welding Station Alpha', 
        'Advanced welding center with robotic assistance',
        Id,
        'Welding',
        8,
        2,
        150.00,
        40.00,
        90,
        'Welding',
        'Building B',
        'Ground Floor'
    FROM Companies WHERE IsDeleted = 0;

    INSERT INTO WorkCenters (Code, Name, Description, CompanyId, WorkCenterType, DailyCapacityHours, SimultaneousOperations, HourlyRate, OverheadRate, EfficiencyPercentage, Department, Building, Floor)
    SELECT 
        'WC-QC-001', 
        'Quality Control Center', 
        'Inspection and quality assurance station',
        Id,
        'QualityControl',
        8,
        1,
        100.00,
        25.00,
        100,
        'Quality',
        'Building A',
        'Second Floor'
    FROM Companies WHERE IsDeleted = 0;
END
GO

-- Insert sample machine centers (only if work centers exist and machine centers table is empty)
IF EXISTS (SELECT 1 FROM WorkCenters) AND NOT EXISTS (SELECT 1 FROM MachineCenters)
BEGIN
    -- CNC Machines for Production Work Centers
    INSERT INTO MachineCenters (MachineCode, MachineName, Description, WorkCenterId, CompanyId, Manufacturer, Model, MachineType, MaxCapacity, CapacityUnit, SetupTimeMinutes, HourlyRate, EfficiencyPercentage)
    SELECT 
        'CNC-001',
        'CNC Mill #1',
        '5-axis CNC milling machine for precision steel cutting',
        wc.Id,
        wc.CompanyId,
        'Haas',
        'VF-5/50',
        'CNC',
        1000,
        'kg',
        30,
        175.00,
        92
    FROM WorkCenters wc WHERE wc.WorkCenterType = 'Production' AND wc.IsDeleted = 0;

    -- Welding Robots for Welding Work Centers
    INSERT INTO MachineCenters (MachineCode, MachineName, Description, WorkCenterId, CompanyId, Manufacturer, Model, MachineType, MaxCapacity, CapacityUnit, SetupTimeMinutes, HourlyRate, EfficiencyPercentage)
    SELECT 
        'WELD-ROB-001',
        'Welding Robot Alpha',
        'Automated MIG welding robot with 6-axis movement',
        wc.Id,
        wc.CompanyId,
        'Fanuc',
        'ARC Mate 120iD',
        'Welding',
        500,
        'kg',
        45,
        200.00,
        88
    FROM WorkCenters wc WHERE wc.WorkCenterType = 'Welding' AND wc.IsDeleted = 0;

    -- Inspection Equipment for QC Work Centers
    INSERT INTO MachineCenters (MachineCode, MachineName, Description, WorkCenterId, CompanyId, Manufacturer, Model, MachineType, MaxCapacity, CapacityUnit, SetupTimeMinutes, HourlyRate, EfficiencyPercentage)
    SELECT 
        'CMM-001',
        'Coordinate Measuring Machine',
        'High-precision 3D measurement system',
        wc.Id,
        wc.CompanyId,
        'Zeiss',
        'CONTURA G2',
        'Inspection',
        100,
        'pieces/day',
        15,
        150.00,
        98
    FROM WorkCenters wc WHERE wc.WorkCenterType = 'QualityControl' AND wc.IsDeleted = 0;
END
GO

-- Add default shifts for all work centers
IF NOT EXISTS (SELECT 1 FROM WorkCenterShifts)
BEGIN
    -- Day Shift
    INSERT INTO WorkCenterShifts (WorkCenterId, ShiftName, StartTime, EndTime, BreakDurationMinutes, DaysOfWeek, IsActive, EfficiencyMultiplier)
    SELECT 
        Id,
        'Day Shift',
        '07:00:00',
        '15:30:00',
        30,
        'Mon,Tue,Wed,Thu,Fri',
        1,
        1.0
    FROM WorkCenters WHERE IsDeleted = 0;

    -- Evening Shift (only for Production work centers)
    INSERT INTO WorkCenterShifts (WorkCenterId, ShiftName, StartTime, EndTime, BreakDurationMinutes, DaysOfWeek, IsActive, EfficiencyMultiplier)
    SELECT 
        Id,
        'Evening Shift',
        '15:30:00',
        '00:00:00',
        30,
        'Mon,Tue,Wed,Thu,Fri',
        1,
        0.95
    FROM WorkCenters WHERE WorkCenterType = 'Production' AND IsDeleted = 0;
END
GO

PRINT 'Work Centers and Machine Centers tables created successfully';
PRINT 'Sample data inserted for testing';
PRINT 'Migration completed successfully';