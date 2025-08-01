-- Simple test to verify column access
SELECT TOP 1
    Email,
    AuthProvider,
    PasswordSalt
FROM dbo.Users;