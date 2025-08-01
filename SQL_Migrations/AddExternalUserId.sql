-- Add ExternalUserId column ONLY
ALTER TABLE Users ADD ExternalUserId nvarchar(256) NULL;
GO

-- Verify it was added
SELECT name FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'ExternalUserId';