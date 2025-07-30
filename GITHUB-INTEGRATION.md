# GitHub Integration Setup

## Overview

The Steel Estimation Platform includes GitHub integration for tracking deployments and managing code versions between environments.

## Setup GitHub Access Token

To enable full GitHub integration features:

1. **Generate a Personal Access Token**:
   - Go to GitHub → Settings → Developer settings → Personal access tokens
   - Click "Generate new token (classic)"
   - Give it a name: "Steel Estimation Deployment"
   - Select scopes:
     - `repo` (for private repositories)
     - `read:org` (if in an organization)
   - Generate and copy the token

2. **Add Token to Configuration**:
   
   **For Local Development**:
   Add to `appsettings.Development.json`:
   ```json
   {
     "GitHub": {
       "AccessToken": "your-github-token-here"
     }
   }
   ```

   **For Azure (Production/Staging)**:
   - Go to Azure Portal
   - Navigate to your App Service
   - Settings → Configuration → Application settings
   - Add new setting:
     - Name: `GitHub__AccessToken`
     - Value: `your-github-token`
   - Save and restart

## Branch Strategy

The application assumes the following branch structure:

- `main` or `master` → Production environment
- `develop` → Staging/Sandbox environment
- Feature branches → Individual features

## Workflow

1. **Development**:
   - Create feature branches from `develop`
   - Make changes and test locally
   - Push to GitHub

2. **Staging Deployment**:
   - Merge feature branches to `develop`
   - Deploy to staging using:
     ```powershell
     .\deploy.ps1 -Environment Staging
     ```

3. **Production Deployment**:
   - Test thoroughly in staging
   - Use the Deployment UI (`/admin/deployment`) to:
     - View pending changes
     - Compare environments
     - Promote to production
   - Or merge `develop` to `main` and deploy:
     ```powershell
     .\deploy.ps1 -Environment Production
     ```

## Features

### Environment Badge
Shows current environment in the top-right corner:
- 🔴 Red = Production
- 🟡 Yellow = Staging/Sandbox
- 🟢 Green = Development

### Environment Switcher
Dropdown in the header to quickly navigate between environments.

### Deployment Dashboard
Available at `/admin/deployment` (Admin only):
- View current version in each environment
- See pending commits
- One-click promotion to production
- Deployment history
- Rollback capabilities

## Security Notes

- Never commit the GitHub token to source control
- Use Azure Key Vault for production token storage
- Limit token permissions to minimum required
- Rotate tokens regularly

## Troubleshooting

### GitHub API Rate Limits
- Unauthenticated: 60 requests/hour
- Authenticated: 5,000 requests/hour
- If you hit limits, add a token

### Missing Commits
- Ensure branches are pushed to GitHub
- Check token has correct permissions
- Verify branch names in configuration

### Deployment UI Not Loading
- Check browser console for errors
- Verify GitHub token is configured
- Ensure user has Admin role