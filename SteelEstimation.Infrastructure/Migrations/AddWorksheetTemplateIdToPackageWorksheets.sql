-- Add WorksheetTemplateId column to PackageWorksheets table
-- This migration adds support for linking package worksheets to specific worksheet templates

-- Add WorksheetTemplateId column
ALTER TABLE PackageWorksheets
ADD WorksheetTemplateId INT NULL;

-- Add foreign key constraint
ALTER TABLE PackageWorksheets
ADD CONSTRAINT FK_PackageWorksheets_WorksheetTemplates_WorksheetTemplateId
FOREIGN KEY (WorksheetTemplateId) REFERENCES WorksheetTemplates(Id);

-- Create index for performance
CREATE INDEX IX_PackageWorksheets_WorksheetTemplateId 
ON PackageWorksheets(WorksheetTemplateId);

-- Update existing PackageWorksheets to use default templates based on their type
-- This ensures existing data has valid template references
UPDATE pw
SET pw.WorksheetTemplateId = wt.Id
FROM PackageWorksheets pw
INNER JOIN WorksheetTemplates wt ON wt.IsDefault = 1
WHERE pw.WorksheetTemplateId IS NULL
AND wt.BaseType = 'Processing'; -- Default to Standard Processing template for existing worksheets

PRINT 'Successfully added WorksheetTemplateId column to PackageWorksheets table';