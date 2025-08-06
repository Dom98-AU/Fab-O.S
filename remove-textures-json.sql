-- Simpler approach: Remove texture fields from JSON using SQL Server JSON functions
-- This script removes all texture-related fields from DiceBearOptions

-- First, check current state
PRINT 'Checking profiles with texture data...'
SELECT COUNT(*) as ProfilesWithTexture
FROM UserProfiles
WHERE DiceBearOptions LIKE '%texture%';

-- Show examples before update
PRINT 'Examples before cleanup:'
SELECT TOP 3 u.Email, up.DiceBearOptions
FROM UserProfiles up
JOIN Users u ON up.UserId = u.Id
WHERE up.DiceBearOptions LIKE '%texture%';
GO

-- For SQL Server 2016+ with JSON support
-- This approach parses JSON, removes fields, and rebuilds it
BEGIN TRANSACTION;

-- Create temporary table with parsed JSON
WITH ParsedOptions AS (
    SELECT 
        up.UserId,
        up.DiceBearOptions as OriginalJson,
        JSON_VALUE(up.DiceBearOptions, '$.baseColor') as baseColor,
        JSON_VALUE(up.DiceBearOptions, '$.backgroundColor') as backgroundColor,
        JSON_VALUE(up.DiceBearOptions, '$.eyes') as eyes,
        JSON_VALUE(up.DiceBearOptions, '$.face') as face,
        JSON_VALUE(up.DiceBearOptions, '$.mouth') as mouth,
        JSON_VALUE(up.DiceBearOptions, '$.sides') as sides,
        JSON_VALUE(up.DiceBearOptions, '$.top') as top,
        JSON_VALUE(up.DiceBearOptions, '$.flip') as flip
    FROM UserProfiles up
    WHERE up.DiceBearOptions IS NOT NULL
)
UPDATE UserProfiles
SET DiceBearOptions = (
    SELECT 
        CONCAT(
            '{',
            CASE WHEN p.baseColor IS NOT NULL THEN CONCAT('"baseColor":"', p.baseColor, '"') ELSE '' END,
            CASE WHEN p.backgroundColor IS NOT NULL THEN CONCAT(',"backgroundColor":"', p.backgroundColor, '"') ELSE '' END,
            CASE WHEN p.eyes IS NOT NULL THEN CONCAT(',"eyes":"', p.eyes, '"') ELSE '' END,
            CASE WHEN p.face IS NOT NULL THEN CONCAT(',"face":"', p.face, '"') ELSE '' END,
            CASE WHEN p.mouth IS NOT NULL THEN CONCAT(',"mouth":"', p.mouth, '"') ELSE '' END,
            CASE WHEN p.sides IS NOT NULL THEN CONCAT(',"sides":"', p.sides, '"') ELSE '' END,
            CASE WHEN p.top IS NOT NULL THEN CONCAT(',"top":"', p.top, '"') ELSE '' END,
            CASE WHEN p.flip IS NOT NULL THEN CONCAT(',"flip":', p.flip) ELSE '' END,
            '}'
        )
    FROM ParsedOptions p
    WHERE p.UserId = UserProfiles.UserId
)
WHERE EXISTS (
    SELECT 1 FROM ParsedOptions p 
    WHERE p.UserId = UserProfiles.UserId 
    AND p.OriginalJson LIKE '%texture%'
);

-- Clean up any formatting issues
UPDATE UserProfiles
SET DiceBearOptions = REPLACE(REPLACE(REPLACE(REPLACE(DiceBearOptions, '{,', '{'), ',,', ','), ',}', '}'), '""', '"')
WHERE DiceBearOptions LIKE '%{,%' OR DiceBearOptions LIKE '%,,%' OR DiceBearOptions LIKE '%,}%';

COMMIT TRANSACTION;

-- Verify the cleanup
PRINT ''
PRINT 'After cleanup:'
SELECT COUNT(*) as ProfilesWithTextureAfterCleanup
FROM UserProfiles
WHERE DiceBearOptions LIKE '%texture%';

-- Show examples after cleanup
SELECT TOP 3 u.Email, up.DiceBearOptions
FROM UserProfiles up
JOIN Users u ON up.UserId = u.Id
WHERE up.DiceBearOptions IS NOT NULL
ORDER BY up.UpdatedAt DESC;
GO