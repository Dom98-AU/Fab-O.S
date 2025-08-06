-- Simple script to remove texture from admin user only
-- This is a safer approach to test first

-- Check current admin user avatar options
PRINT 'Current admin user avatar options:'
SELECT u.Email, up.DiceBearOptions
FROM UserProfiles up
JOIN Users u ON up.UserId = u.Id
WHERE u.Email = 'admin@steelestimation.com';
GO

-- Update admin user to remove any texture
UPDATE UserProfiles
SET DiceBearOptions = '{"baseColor":"#1e88e5","eyes":"robocop","face":"square02","mouth":"square02","sides":"square","top":"bulb01"}'
WHERE UserId = (SELECT Id FROM Users WHERE Email = 'admin@steelestimation.com');
GO

-- Verify the update
PRINT ''
PRINT 'After update:'
SELECT u.Email, up.DiceBearOptions
FROM UserProfiles up
JOIN Users u ON up.UserId = u.Id
WHERE u.Email = 'admin@steelestimation.com';
GO

-- To remove texture from ALL users, run this:
/*
UPDATE UserProfiles
SET DiceBearOptions = 
    CASE 
        WHEN DiceBearOptions LIKE '%"texture"%' THEN
            -- Remove texture array pattern: "texture":["value"],
            REPLACE(
                REPLACE(
                    DiceBearOptions,
                    SUBSTRING(
                        DiceBearOptions,
                        CHARINDEX('"texture"', DiceBearOptions),
                        CHARINDEX(']', DiceBearOptions, CHARINDEX('"texture"', DiceBearOptions)) - CHARINDEX('"texture"', DiceBearOptions) + 2
                    ),
                    ''
                ),
                ',,', ','
            )
        ELSE DiceBearOptions
    END
WHERE DiceBearOptions LIKE '%texture%';

-- Also remove textureProbability
UPDATE UserProfiles
SET DiceBearOptions = 
    CASE 
        WHEN DiceBearOptions LIKE '%"textureProbability"%' THEN
            REPLACE(
                REPLACE(
                    DiceBearOptions,
                    SUBSTRING(
                        DiceBearOptions,
                        CHARINDEX('"textureProbability"', DiceBearOptions),
                        CHARINDEX(',', DiceBearOptions, CHARINDEX('"textureProbability"', DiceBearOptions)) - CHARINDEX('"textureProbability"', DiceBearOptions) + 1
                    ),
                    ''
                ),
                ',,', ','
            )
        ELSE DiceBearOptions
    END
WHERE DiceBearOptions LIKE '%textureProbability%';

-- Clean up JSON formatting
UPDATE UserProfiles
SET DiceBearOptions = REPLACE(REPLACE(REPLACE(DiceBearOptions, ',}', '}'), '{,', '{'), ',,', ',')
WHERE DiceBearOptions LIKE '%,}%' OR DiceBearOptions LIKE '%{,%' OR DiceBearOptions LIKE '%,,%';
*/