-- Add maintenance date columns to WorkCenters table
-- These columns track when maintenance was last performed and when it's next scheduled

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WorkCenters]') AND name = 'LastMaintenanceDate')
BEGIN
    ALTER TABLE [dbo].[WorkCenters] ADD [LastMaintenanceDate] datetime2(7) NULL;
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WorkCenters]') AND name = 'NextMaintenanceDate')
BEGIN
    ALTER TABLE [dbo].[WorkCenters] ADD [NextMaintenanceDate] datetime2(7) NULL;
END

PRINT 'Maintenance date columns added to WorkCenters table successfully';