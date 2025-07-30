-- Update EstimatedHours column precision in Projects table
IF EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'Projects' 
    AND COLUMN_NAME = 'EstimatedHours'
)
BEGIN
    -- Drop any existing default constraint
    DECLARE @ConstraintName NVARCHAR(200)
    SELECT @ConstraintName = dc.name
    FROM sys.default_constraints dc
    INNER JOIN sys.columns c ON dc.parent_column_id = c.column_id
    WHERE dc.parent_object_id = OBJECT_ID('Projects') AND c.name = 'EstimatedHours'
    
    IF @ConstraintName IS NOT NULL
    BEGIN
        EXEC('ALTER TABLE Projects DROP CONSTRAINT ' + @ConstraintName)
    END
    
    -- Alter the column to specify precision
    ALTER TABLE Projects
    ALTER COLUMN EstimatedHours DECIMAL(10, 2) NULL
    
    PRINT 'Updated EstimatedHours column precision to DECIMAL(10, 2)'
END
ELSE
BEGIN
    PRINT 'EstimatedHours column not found in Projects table'
END