-- Migration: Add Weight column to WeldingItems table
-- This adds weight tracking to welding items for complete tonnage calculations

-- Add Weight column to WeldingItems table
ALTER TABLE WeldingItems 
ADD Weight decimal(18,2) NOT NULL DEFAULT 0;

-- Add comment to document the column
EXEC sp_addextendedproperty 
    @name = N'MS_Description',
    @value = N'Weight of the welding item in kilograms for tonnage calculations',
    @level0type = N'Schema',
    @level0name = N'dbo',
    @level1type = N'Table',
    @level1name = N'WeldingItems',
    @level2type = N'Column',
    @level2name = N'Weight';

-- Create index for performance on weight-based queries
CREATE INDEX IX_WeldingItems_Weight ON WeldingItems(Weight);

PRINT 'Successfully added Weight column to WeldingItems table';