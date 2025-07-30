USE [SteelEstimationDb];
GO

-- Update admin user to have complete profile
UPDATE Users 
SET FirstName = 'System',
    LastName = 'Administrator',
    CompanyName = 'Steel Estimation Platform',
    JobTitle = 'System Administrator',
    IsEmailConfirmed = 1,
    LastModified = GETUTCDATE()
WHERE Email = 'admin@steelestimation.com';

-- Verify the update
SELECT Id, Username, Email, FirstName, LastName, CompanyName, JobTitle, IsEmailConfirmed
FROM Users 
WHERE Email = 'admin@steelestimation.com';
GO