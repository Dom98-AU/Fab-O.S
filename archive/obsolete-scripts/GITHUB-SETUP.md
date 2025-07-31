# GitHub Actions Setup Guide

This guide will help you set up GitHub Actions for automatic deployments.

## Prerequisites

- GitHub repository access
- Azure CLI installed
- Azure portal access

## Step 1: Get Azure Publish Profiles

Run these PowerShell commands to get your publish profiles:

```powershell
# Login to Azure
az login

# Get Staging/Sandbox publish profile
az webapp deployment list-publishing-profiles `
  --name app-steel-estimation-prod `
  --resource-group NWIApps `
  --slot staging `
  --xml > staging-publish-profile.xml

# Get Production publish profile  
az webapp deployment list-publishing-profiles `
  --name app-steel-estimation-prod `
  --resource-group NWIApps `
  --xml > production-publish-profile.xml
```

## Step 2: Add Secrets to GitHub

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

Add these secrets:

### AZURE_WEBAPP_PUBLISH_PROFILE_STAGING
- **Name**: `AZURE_WEBAPP_PUBLISH_PROFILE_STAGING`
- **Value**: Copy entire content of `staging-publish-profile.xml`

### AZURE_WEBAPP_PUBLISH_PROFILE_PRODUCTION
- **Name**: `AZURE_WEBAPP_PUBLISH_PROFILE_PRODUCTION`
- **Value**: Copy entire content of `production-publish-profile.xml`

## Step 3: Configure Environments (Optional but Recommended)

1. In GitHub, go to **Settings** → **Environments**
2. Click **New environment**
3. Name: `Sandbox`
   - No special configuration needed
4. Click **New environment** again
5. Name: `Production`
   - Add protection rules:
     - ✓ Required reviewers (add yourself or team members)
     - ✓ Restrict deployment branches: `master`

## Step 4: Test Your Setup

### Test Sandbox Deployment
```bash
git checkout develop
echo "# Test" >> README.md
git add README.md
git commit -m "test: sandbox deployment"
git push origin develop
```

Go to the **Actions** tab - you should see the deployment running!

### Test Production Deployment
1. Go to **Actions** tab
2. Click **Deploy to Production**
3. Click **Run workflow**
4. Type `DEPLOY` to confirm
5. Add deployment notes
6. Click **Run workflow**

## Cleanup

After setup, delete the XML files (they contain sensitive information):

```powershell
Remove-Item staging-publish-profile.xml
Remove-Item production-publish-profile.xml
```

## Troubleshooting

### Deployment fails with authentication error
- Regenerate publish profiles
- Ensure secrets are named exactly as shown
- Check for extra spaces or line breaks in secrets

### Workflow doesn't trigger
- Ensure you're pushing to the correct branch
- Check if Actions are enabled in repository settings

### Can't see Actions tab
- Ensure you have appropriate repository permissions
- Actions might be disabled at organization level

## Next Steps

1. Make a test change and push to `develop`
2. Watch the automatic deployment in Actions tab
3. Visit your sandbox URL after deployment completes
4. When ready, use the production deployment workflow

## Security Notes

- Never commit publish profiles to Git
- Rotate publish profiles periodically
- Use environment protection rules for production
- Limit who can approve production deployments