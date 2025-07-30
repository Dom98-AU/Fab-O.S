# GitHub Actions Deployment Workflows

This folder contains automated deployment workflows for the Steel Estimation Platform.

## Workflows

### 1. Deploy to Sandbox (`deploy-sandbox.yml`)
- **Trigger**: Automatically on push to `develop` branch
- **Target**: Sandbox/Staging environment
- **URL**: https://app-steel-estimation-prod-staging.azurewebsites.net
- **Manual Trigger**: Yes, available via Actions tab

### 2. Deploy to Production (`deploy-production.yml`)
- **Trigger**: Manual only (workflow_dispatch)
- **Target**: Production environment
- **URL**: https://app-steel-estimation-prod.azurewebsites.net
- **Requires**: 
  - Type "DEPLOY" to confirm
  - Environment approval (if configured)
  - Runs from `master` branch only

### 3. Promote to Production (`promote-to-production.yml`)
- **Trigger**: Manual only
- **Purpose**: Creates a PR from `develop` to `master`
- **Use**: When ready to promote sandbox changes to production

## Setup Required

### 1. Azure Publish Profiles

You need to add these secrets to your GitHub repository:

1. **Get Publish Profiles from Azure**:
   ```powershell
   # For Staging
   az webapp deployment list-publishing-profiles --name app-steel-estimation-prod --resource-group NWIApps --slot staging --xml > staging-publish-profile.xml
   
   # For Production
   az webapp deployment list-publishing-profiles --name app-steel-estimation-prod --resource-group NWIApps --xml > production-publish-profile.xml
   ```

2. **Add to GitHub Secrets**:
   - Go to Settings → Secrets and variables → Actions
   - Add `AZURE_WEBAPP_PUBLISH_PROFILE_STAGING` (content of staging-publish-profile.xml)
   - Add `AZURE_WEBAPP_PUBLISH_PROFILE_PRODUCTION` (content of production-publish-profile.xml)

### 2. Environment Protection (Optional but Recommended)

1. Go to Settings → Environments
2. Create "Production" environment
3. Add protection rules:
   - Required reviewers
   - Deployment branches: Only `master`

## Development Workflow

### Cloud-First Approach

1. **Make Changes**:
   ```bash
   git checkout develop
   # Make your changes
   git add .
   git commit -m "feat: your feature"
   git push origin develop
   ```

2. **Automatic Deployment**:
   - GitHub Actions automatically deploys to sandbox
   - Check Actions tab for progress
   - Visit sandbox URL in 2-3 minutes

3. **Promote to Production**:
   - Go to Actions tab
   - Run "Promote to Production" workflow
   - This creates a PR
   - Review and merge PR
   - Production deploys automatically

## Monitoring Deployments

- **GitHub Actions Tab**: See all deployment runs
- **Deployment Status**: Each workflow shows success/failure
- **Logs**: Click any workflow run to see detailed logs
- **Environments**: Check deployment history in Environments tab

## Rollback Procedures

### If Sandbox Deployment Fails
- Fix the issue in `develop` branch
- Push fixes - will auto-deploy again

### If Production Deployment Fails
1. **Immediate Rollback** (via Azure Portal):
   ```powershell
   az webapp deployment slot swap --resource-group NWIApps --name app-steel-estimation-prod --slot staging
   ```

2. **Code Rollback**:
   - Revert the merge commit in `master`
   - Run production deployment workflow

## Tips

- Always test in sandbox before promoting
- Use meaningful commit messages
- Check Actions tab for deployment status
- Monitor application logs after deployment