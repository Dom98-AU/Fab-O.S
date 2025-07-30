-- Migration: Add Estimated Hours and Completion Date to Projects
-- Date: 2025-01-04
-- Description: Adds fields for tracking estimated vs actual time

-- Add EstimatedHours column to Projects table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'EstimatedHours')
BEGIN
    ALTER TABLE [dbo].[Projects]
    ADD [EstimatedHours] decimal(18,2) NULL;
END
GO

-- Add EstimatedCompletionDate column to Projects table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'EstimatedCompletionDate')
BEGIN
    ALTER TABLE [dbo].[Projects]
    ADD [EstimatedCompletionDate] datetime2(7) NULL;
END
GO

-- Migration complete
PRINT 'Migration AddEstimatedHoursToProjects completed successfully';
GO