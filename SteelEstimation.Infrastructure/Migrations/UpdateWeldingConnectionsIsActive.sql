-- Ensure all existing WeldingConnections have IsActive set to true
-- This is needed for the LoadWeldingConnections method to work properly

-- Check if IsActive column exists
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingConnections]') AND name = 'IsActive')
BEGIN
    -- Update any NULL values to true (1)
    UPDATE [dbo].[WeldingConnections]
    SET [IsActive] = 1
    WHERE [IsActive] IS NULL;
    
    PRINT 'Updated IsActive values for WeldingConnections'
END
ELSE
BEGIN
    -- Add IsActive column if it doesn't exist
    ALTER TABLE [dbo].[WeldingConnections]
    ADD [IsActive] bit NOT NULL DEFAULT 1;
    
    PRINT 'Added IsActive column to WeldingConnections'
END

-- Verify the update
SELECT COUNT(*) AS TotalConnections, 
       SUM(CASE WHEN IsActive = 1 THEN 1 ELSE 0 END) AS ActiveConnections
FROM [dbo].[WeldingConnections];