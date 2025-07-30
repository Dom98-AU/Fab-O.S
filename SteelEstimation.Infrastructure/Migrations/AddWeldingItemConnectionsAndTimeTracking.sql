-- Migration: Add WeldingItemConnections and EstimationTimeLogs tables
-- Date: 2025-01-07

-- Create WeldingItemConnections table for many-to-many relationship
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'WeldingItemConnections')
BEGIN
    CREATE TABLE WeldingItemConnections (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        WeldingItemId INT NOT NULL,
        WeldingConnectionId INT NOT NULL,
        Quantity INT NOT NULL DEFAULT 1,
        AssembleFitTack DECIMAL(10,2) NULL,
        Weld DECIMAL(10,2) NULL,
        WeldCheck DECIMAL(10,2) NULL,
        WeldTest DECIMAL(10,2) NULL,
        CONSTRAINT FK_WeldingItemConnections_WeldingItem FOREIGN KEY (WeldingItemId) 
            REFERENCES WeldingItems(Id) ON DELETE CASCADE,
        CONSTRAINT FK_WeldingItemConnections_WeldingConnection FOREIGN KEY (WeldingConnectionId) 
            REFERENCES WeldingConnections(Id) ON DELETE NO ACTION,
        CONSTRAINT UQ_WeldingItemConnections_Item_Connection UNIQUE (WeldingItemId, WeldingConnectionId)
    );
    
    CREATE INDEX IX_WeldingItemConnections_WeldingItemId ON WeldingItemConnections(WeldingItemId);
    CREATE INDEX IX_WeldingItemConnections_WeldingConnectionId ON WeldingItemConnections(WeldingConnectionId);
    
    PRINT 'Created WeldingItemConnections table';
END
GO

-- Create EstimationTimeLogs table for time tracking
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'EstimationTimeLogs')
BEGIN
    CREATE TABLE EstimationTimeLogs (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        EstimationId INT NOT NULL,
        UserId INT NOT NULL,
        StartTime DATETIME2 NOT NULL,
        EndTime DATETIME2 NULL,
        Duration INT NOT NULL DEFAULT 0,
        IsActive BIT NOT NULL DEFAULT 0,
        SessionId UNIQUEIDENTIFIER NOT NULL,
        PageName NVARCHAR(100) NULL,
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT FK_EstimationTimeLogs_Project FOREIGN KEY (EstimationId) 
            REFERENCES Projects(Id) ON DELETE CASCADE,
        CONSTRAINT FK_EstimationTimeLogs_User FOREIGN KEY (UserId) 
            REFERENCES Users(Id) ON DELETE NO ACTION
    );
    
    CREATE INDEX IX_EstimationTimeLogs_EstimationId ON EstimationTimeLogs(EstimationId);
    CREATE INDEX IX_EstimationTimeLogs_UserId ON EstimationTimeLogs(UserId);
    CREATE INDEX IX_EstimationTimeLogs_SessionId ON EstimationTimeLogs(SessionId);
    CREATE INDEX IX_EstimationTimeLogs_StartTime ON EstimationTimeLogs(StartTime);
    CREATE INDEX IX_EstimationTimeLogs_IsActive ON EstimationTimeLogs(IsActive);
    
    PRINT 'Created EstimationTimeLogs table';
END
GO

-- Migrate existing WeldingItem single connections to the new many-to-many table
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'WeldingItemConnections')
BEGIN
    INSERT INTO WeldingItemConnections (WeldingItemId, WeldingConnectionId, Quantity)
    SELECT 
        wi.Id,
        wi.WeldingConnectionId,
        wi.ConnectionQty
    FROM WeldingItems wi
    WHERE wi.WeldingConnectionId IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 FROM WeldingItemConnections wic 
        WHERE wic.WeldingItemId = wi.Id 
        AND wic.WeldingConnectionId = wi.WeldingConnectionId
    );
    
    PRINT 'Migrated existing welding connections to WeldingItemConnections table';
END
GO

PRINT 'Migration completed successfully';