# Social Authentication Setup Guide

This guide explains how to configure social authentication providers (Microsoft, Google, LinkedIn) for the Steel Estimation Platform.

## Overview

The platform supports multiple authentication methods:
- **Email/Password** - Traditional authentication (always available)
- **Microsoft Account** - Sign in with Microsoft/Outlook accounts
- **Google Account** - Sign in with Google accounts
- **LinkedIn Account** - Sign in with LinkedIn accounts

Users can:
- Sign up/login using any enabled provider
- Link multiple authentication methods to one account
- Manage their authentication methods in account settings

## Configuration Steps

### 1. Microsoft Account

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to "App registrations" → "New registration"
3. Configure:
   - Name: "Steel Estimation Platform"
   - Supported account types: "Personal Microsoft accounts only" or "Any Azure AD directory and personal accounts"
   - Redirect URI: `https://yourdomain.com/signin-microsoft`
4. After creation:
   - Copy the **Application (client) ID**
   - Go to "Certificates & secrets" → "New client secret"
   - Copy the **Client secret value**
5. Update `appsettings.json`:
   ```json
   "Microsoft": {
     "Enabled": true,
     "ClientId": "your-client-id",
     "ClientSecret": "your-client-secret"
   }
   ```

### 2. Google Account

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing
3. Enable Google+ API:
   - Go to "APIs & Services" → "Enable APIs and services"
   - Search for "Google+ API" and enable it
4. Create OAuth credentials:
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "OAuth client ID"
   - Application type: "Web application"
   - Add authorized redirect URI: `https://yourdomain.com/signin-google`
5. Copy the **Client ID** and **Client secret**
6. Update `appsettings.json`:
   ```json
   "Google": {
     "Enabled": true,
     "ClientId": "your-client-id",
     "ClientSecret": "your-client-secret"
   }
   ```

### 3. LinkedIn Account

1. Go to [LinkedIn Developers](https://www.linkedin.com/developers/)
2. Create a new app:
   - App name: "Steel Estimation Platform"
   - LinkedIn Page: Your company page
   - App logo: Upload your logo
3. In app settings:
   - Add redirect URL: `https://yourdomain.com/signin-linkedin`
   - Request access to: "Sign In with LinkedIn"
4. Go to "Auth" tab:
   - Copy the **Client ID**
   - Copy the **Client Secret**
5. Update `appsettings.json`:
   ```json
   "LinkedIn": {
     "Enabled": true,
     "ClientId": "your-client-id",
     "ClientSecret": "your-client-secret"
   }
   ```

## Environment-Specific Configuration

You can configure different settings per environment:

- `appsettings.Development.json` - Local development
- `appsettings.Staging.json` - Staging environment
- `appsettings.Production.json` - Production environment

Example for production:
```json
{
  "Authentication": {
    "Microsoft": {
      "Enabled": true,
      "ClientId": "prod-client-id",
      "ClientSecret": "prod-client-secret"
    },
    "Google": {
      "Enabled": true,
      "ClientId": "prod-client-id",
      "ClientSecret": "prod-client-secret"
    },
    "LinkedIn": {
      "Enabled": false
    }
  }
}
```

## Azure Key Vault (Production)

For production deployments on Azure:

1. Store secrets in Key Vault:
   ```bash
   az keyvault secret set --vault-name "your-vault" --name "Authentication--Microsoft--ClientSecret" --value "your-secret"
   az keyvault secret set --vault-name "your-vault" --name "Authentication--Google--ClientSecret" --value "your-secret"
   ```

2. Grant app access to Key Vault using Managed Identity

3. Secrets will be automatically loaded from Key Vault

## Testing

1. Enable providers in `appsettings.json`
2. Run the application
3. Visit `/Account/Login` - you should see social login buttons
4. Test each provider:
   - Click provider button
   - Authenticate with provider
   - Verify account creation/login
5. Test account linking at `/Account/Manage/LinkedAccounts`

## Troubleshooting

### Common Issues

1. **"Invalid redirect URI"**
   - Ensure redirect URIs match exactly (including https://)
   - Update URIs for each environment

2. **"Invalid client credentials"**
   - Double-check ClientId and ClientSecret
   - Ensure secrets aren't expired

3. **Missing user email**
   - Some providers may not return email
   - User will need to provide email during registration

### Debug Mode

Enable detailed logging in `appsettings.Development.json`:
```json
{
  "Logging": {
    "LogLevel": {
      "Microsoft.AspNetCore.Authentication": "Debug"
    }
  }
}
```

## Security Considerations

1. **Always use HTTPS** in production
2. **Store secrets securely** (Key Vault, environment variables)
3. **Validate redirect URIs** to prevent open redirect attacks
4. **Review OAuth scopes** - only request necessary permissions
5. **Monitor authentication logs** for suspicious activity

## User Experience

When enabled, users will see:
- Social login buttons on login/register pages
- Option to link/unlink accounts in profile settings
- Ability to set password for social-only accounts
- Clear indication of which auth methods are linked

The system automatically:
- Creates user accounts on first social login
- Links accounts with matching emails
- Tracks authentication method usage
- Maintains audit logs for security