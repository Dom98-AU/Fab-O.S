-- Script to permanently remove all texture data from user profiles
-- This will clean up the DiceBearOptions JSON to remove texture-related fields

-- First, let's see how many profiles have texture data
SELECT COUNT(*) as ProfilesWithTexture
FROM UserProfiles
WHERE DiceBearOptions LIKE '%texture%';

-- Show some examples of current data
SELECT TOP 5 u.Email, up.DiceBearOptions
FROM UserProfiles up
JOIN Users u ON up.UserId = u.Id
WHERE up.DiceBearOptions LIKE '%texture%';

-- Create a backup of current data (just in case)
SELECT u.Email, up.DiceBearOptions as OriginalOptions, GETDATE() as BackupDate
INTO UserProfiles_Texture_Backup_20250108
FROM UserProfiles up
JOIN Users u ON up.UserId = u.Id
WHERE up.DiceBearOptions LIKE '%texture%';

-- Update all profiles to remove texture fields
-- This handles various JSON formats
UPDATE UserProfiles
SET DiceBearOptions = 
    CASE 
        -- Handle texture as array with textureProbability
        WHEN DiceBearOptions LIKE '%"texture":[%]%"textureProbability":%'
        THEN REPLACE(
                REPLACE(
                    REPLACE(
                        DiceBearOptions,
                        SUBSTRING(
                            DiceBearOptions,
                            CHARINDEX('"texture":', DiceBearOptions),
                            CHARINDEX(']', DiceBearOptions, CHARINDEX('"texture":', DiceBearOptions)) - CHARINDEX('"texture":', DiceBearOptions) + 2
                        ),
                        ''
                    ),
                    SUBSTRING(
                        DiceBearOptions,
                        CHARINDEX('"textureProbability":', DiceBearOptions),
                        CASE 
                            WHEN CHARINDEX(',', DiceBearOptions, CHARINDEX('"textureProbability":', DiceBearOptions)) > 0
                            THEN CHARINDEX(',', DiceBearOptions, CHARINDEX('"textureProbability":', DiceBearOptions)) - CHARINDEX('"textureProbability":', DiceBearOptions) + 1
                            ELSE CHARINDEX('}', DiceBearOptions, CHARINDEX('"textureProbability":', DiceBearOptions)) - CHARINDEX('"textureProbability":', DiceBearOptions)
                        END
                    ),
                    ''
                ),
                ',,', ','
            )
        
        -- Handle texture as string
        WHEN DiceBearOptions LIKE '%"texture":"%'
        THEN REPLACE(
                DiceBearOptions,
                SUBSTRING(
                    DiceBearOptions,
                    CHARINDEX('"texture":', DiceBearOptions),
                    CASE 
                        WHEN CHARINDEX(',', DiceBearOptions, CHARINDEX('"texture":', DiceBearOptions)) > 0
                        THEN CHARINDEX(',', DiceBearOptions, CHARINDEX('"texture":', DiceBearOptions)) - CHARINDEX('"texture":', DiceBearOptions) + 1
                        ELSE CHARINDEX('}', DiceBearOptions, CHARINDEX('"texture":', DiceBearOptions)) - CHARINDEX('"texture":', DiceBearOptions)
                    END
                ),
                ''
            )
        
        -- Handle just textureProbability without texture
        WHEN DiceBearOptions LIKE '%"textureProbability":%'
        THEN REPLACE(
                DiceBearOptions,
                SUBSTRING(
                    DiceBearOptions,
                    CHARINDEX('"textureProbability":', DiceBearOptions),
                    CASE 
                        WHEN CHARINDEX(',', DiceBearOptions, CHARINDEX('"textureProbability":', DiceBearOptions)) > 0
                        THEN CHARINDEX(',', DiceBearOptions, CHARINDEX('"textureProbability":', DiceBearOptions)) - CHARINDEX('"textureProbability":', DiceBearOptions) + 1
                        ELSE CHARINDEX('}', DiceBearOptions, CHARINDEX('"textureProbability":', DiceBearOptions)) - CHARINDEX('"textureProbability":', DiceBearOptions)
                    END
                ),
                ''
            )
        
        ELSE DiceBearOptions
    END
WHERE DiceBearOptions LIKE '%texture%' OR DiceBearOptions LIKE '%textureProbability%';

-- Clean up any double commas or trailing commas
UPDATE UserProfiles
SET DiceBearOptions = REPLACE(REPLACE(REPLACE(DiceBearOptions, ',,', ','), ',}', '}'), '{,', '{')
WHERE DiceBearOptions LIKE '%,,%' OR DiceBearOptions LIKE '%,}%' OR DiceBearOptions LIKE '%{,%';

-- Verify the cleanup
SELECT COUNT(*) as ProfilesWithTextureAfterCleanup
FROM UserProfiles
WHERE DiceBearOptions LIKE '%texture%';

-- Show some examples after cleanup
SELECT TOP 5 u.Email, up.DiceBearOptions
FROM UserProfiles up
JOIN Users u ON up.UserId = u.Id
WHERE up.UserId IN (
    SELECT UserId FROM UserProfiles WHERE DiceBearOptions IS NOT NULL
)
ORDER BY up.UpdatedAt DESC;

-- Optional: Drop the backup table after verification
-- DROP TABLE UserProfiles_Texture_Backup_20250108;