-- Add UserWorksheetPreferences table for storing user's preferred worksheet templates
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'UserWorksheetPreferences')
BEGIN
    CREATE TABLE UserWorksheetPreferences (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        UserId INT NOT NULL,
        BaseType NVARCHAR(50) NOT NULL,
        TemplateId INT NOT NULL,
        CONSTRAINT FK_UserWorksheetPreferences_User FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
        CONSTRAINT FK_UserWorksheetPreferences_Template FOREIGN KEY (TemplateId) REFERENCES WorksheetTemplates(Id) ON DELETE NO ACTION,
        CONSTRAINT UQ_UserWorksheetPreferences_UserBaseType UNIQUE (UserId, BaseType)
    );
    
    CREATE INDEX IX_UserWorksheetPreferences_UserId ON UserWorksheetPreferences(UserId);
    CREATE INDEX IX_UserWorksheetPreferences_TemplateId ON UserWorksheetPreferences(TemplateId);
END

-- Update PackageWorksheets to use default templates if WorksheetTemplateId is NULL
UPDATE pw
SET pw.WorksheetTemplateId = wt.Id
FROM PackageWorksheets pw
JOIN WorksheetTemplates wt ON wt.BaseType = pw.WorksheetType AND wt.IsDefault = 1
WHERE pw.WorksheetTemplateId IS NULL;

PRINT 'User worksheet preferences migration completed successfully!';