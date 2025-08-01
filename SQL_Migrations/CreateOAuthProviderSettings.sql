-- =============================================
-- Create OAuthProviderSettings Table Only
-- Description: Creates the OAuth provider settings table
-- Date: 2025-08-01
-- =============================================

-- Create configuration table for OAuth providers
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'OAuthProviderSettings')
BEGIN
    CREATE TABLE OAuthProviderSettings (
        Id int IDENTITY(1,1) PRIMARY KEY,
        ProviderName nvarchar(50) NOT NULL UNIQUE,
        IsEnabled bit NOT NULL DEFAULT 0,
        DisplayName nvarchar(100) NOT NULL,
        IconClass nvarchar(100) NULL, -- Font Awesome class
        ButtonColor nvarchar(20) NULL, -- CSS color
        SortOrder int NOT NULL DEFAULT 0,
        CreatedDate datetime2 NOT NULL DEFAULT GETUTCDATE(),
        ModifiedDate datetime2 NOT NULL DEFAULT GETUTCDATE()
    );

    -- Insert default providers
    INSERT INTO OAuthProviderSettings (ProviderName, IsEnabled, DisplayName, IconClass, ButtonColor, SortOrder)
    VALUES 
        ('Microsoft', 1, 'Continue with Microsoft', 'fab fa-microsoft', '#0078d4', 1),
        ('Google', 0, 'Continue with Google', 'fab fa-google', '#4285f4', 2),
        ('LinkedIn', 0, 'Continue with LinkedIn', 'fab fa-linkedin', '#0077b5', 3);

    PRINT 'Created OAuthProviderSettings table with defaults';
    PRINT 'Microsoft authentication is ENABLED';
END
ELSE
BEGIN
    PRINT 'OAuthProviderSettings table already exists';
    
    -- Ensure Microsoft is enabled
    UPDATE OAuthProviderSettings 
    SET IsEnabled = 1 
    WHERE ProviderName = 'Microsoft';
    
    PRINT 'Microsoft authentication is ENABLED';
END