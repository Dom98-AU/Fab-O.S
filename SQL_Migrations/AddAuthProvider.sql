-- Add AuthProvider column ONLY
ALTER TABLE Users ADD AuthProvider nvarchar(50) NULL;
GO

-- Verify it was added
SELECT name FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'AuthProvider';