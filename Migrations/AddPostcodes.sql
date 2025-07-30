-- Add Postcodes table for postcode lookup functionality
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Postcodes')
BEGIN
    CREATE TABLE [dbo].[Postcodes] (
        [Id] int IDENTITY(1,1) NOT NULL,
        [Code] nvarchar(4) NOT NULL,
        [Suburb] nvarchar(100) NOT NULL,
        [State] nvarchar(3) NOT NULL,
        [Region] nvarchar(100) NULL,
        [Latitude] decimal(10,6) NULL,
        [Longitude] decimal(10,6) NULL,
        [IsActive] bit NOT NULL DEFAULT 1,
        CONSTRAINT [PK_Postcodes] PRIMARY KEY CLUSTERED ([Id] ASC)
    );

    -- Create indexes for performance
    CREATE INDEX [IX_Postcodes_Code] ON [dbo].[Postcodes] ([Code]);
    CREATE INDEX [IX_Postcodes_Suburb] ON [dbo].[Postcodes] ([Suburb]);
    CREATE INDEX [IX_Postcodes_Suburb_State] ON [dbo].[Postcodes] ([Suburb], [State]);
    CREATE INDEX [IX_Postcodes_IsActive] ON [dbo].[Postcodes] ([IsActive]);

    PRINT 'Postcodes table created successfully';
END
ELSE
BEGIN
    PRINT 'Postcodes table already exists';
END
GO

-- Insert some common Australian postcodes for testing
-- You can import a complete dataset later
INSERT INTO [dbo].[Postcodes] ([Code], [Suburb], [State], [Region], [Latitude], [Longitude], [IsActive])
VALUES 
    -- Sydney CBD and surrounds
    ('2000', 'SYDNEY', 'NSW', 'Sydney', -33.8688, 151.2093, 1),
    ('2000', 'HAYMARKET', 'NSW', 'Sydney', -33.8810, 151.2052, 1),
    ('2000', 'THE ROCKS', 'NSW', 'Sydney', -33.8599, 151.2090, 1),
    ('2001', 'SYDNEY', 'NSW', 'Sydney', -33.8688, 151.2093, 1),
    ('2010', 'DARLINGHURST', 'NSW', 'Sydney', -33.8785, 151.2211, 1),
    ('2010', 'SURRY HILLS', 'NSW', 'Sydney', -33.8818, 151.2125, 1),
    
    -- Melbourne CBD and surrounds
    ('3000', 'MELBOURNE', 'VIC', 'Melbourne', -37.8136, 144.9631, 1),
    ('3001', 'MELBOURNE', 'VIC', 'Melbourne', -37.8136, 144.9631, 1),
    ('3006', 'SOUTHBANK', 'VIC', 'Melbourne', -37.8260, 144.9588, 1),
    ('3008', 'DOCKLANDS', 'VIC', 'Melbourne', -37.8147, 144.9477, 1),
    
    -- Brisbane CBD and surrounds
    ('4000', 'BRISBANE', 'QLD', 'Brisbane', -27.4698, 153.0251, 1),
    ('4001', 'SPRING HILL', 'QLD', 'Brisbane', -27.4611, 153.0238, 1),
    ('4101', 'SOUTH BRISBANE', 'QLD', 'Brisbane', -27.4818, 153.0156, 1),
    
    -- Perth CBD and surrounds
    ('6000', 'PERTH', 'WA', 'Perth', -31.9505, 115.8605, 1),
    ('6001', 'PERTH', 'WA', 'Perth', -31.9505, 115.8605, 1),
    ('6003', 'NORTHBRIDGE', 'WA', 'Perth', -31.9465, 115.8539, 1),
    
    -- Adelaide CBD and surrounds
    ('5000', 'ADELAIDE', 'SA', 'Adelaide', -34.9285, 138.6007, 1),
    ('5001', 'ADELAIDE', 'SA', 'Adelaide', -34.9285, 138.6007, 1),
    ('5006', 'NORTH ADELAIDE', 'SA', 'Adelaide', -34.9064, 138.5932, 1),
    
    -- Hobart CBD and surrounds
    ('7000', 'HOBART', 'TAS', 'Hobart', -42.8821, 147.3272, 1),
    ('7001', 'HOBART', 'TAS', 'Hobart', -42.8821, 147.3272, 1),
    
    -- Canberra
    ('2600', 'CANBERRA', 'ACT', 'Canberra', -35.2820, 149.1287, 1),
    ('2601', 'CANBERRA', 'ACT', 'Canberra', -35.2820, 149.1287, 1),
    ('2602', 'AINSLIE', 'ACT', 'Canberra', -35.2628, 149.1434, 1),
    
    -- Darwin
    ('0800', 'DARWIN', 'NT', 'Darwin', -12.4634, 130.8456, 1),
    ('0801', 'DARWIN', 'NT', 'Darwin', -12.4634, 130.8456, 1);

PRINT 'Sample postcode data inserted successfully';
GO