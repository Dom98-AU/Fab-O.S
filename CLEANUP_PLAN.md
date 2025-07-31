# Cleanup Plan - Files to Remove

## Summary
- Total files to clean: ~250+ files
- Files to keep: ~20 essential files
- Space to recover: Significant (includes zip/tar files, publish folders)

## FILES TO REMOVE (By Category)

### 1. Azure Migration Scripts (50+ files)
All azure-* files except test-azure-app.ps1:
- azure-cleanup.sql
- azure-complete-*.sql/ps1
- azure-configure.ps1
- azure-create-*.ps1
- azure-fix-*.ps1
- azure-insert-data.ps1
- azure-migration-*.ps1/sql
- azure-schema-*.sql
- azure-setup*.ps1
- azure-simple-*.ps1/sql
- azure-sql-*.ps1/sh/sql
- azure-transform-*.sql
- azure-update-*.ps1
- migrate-azure-*.ps1
- execute-azure-*.ps1
- direct-azure-migration.ps1
- simple-azure-migration.ps1
- complete-azure-migration.ps1

### 2. Docker Migration & Import/Export (10+ files)
- migrate-docker-to-azure-fresh.ps1
- backup-restore-to-docker.ps1
- import-to-docker.ps1
- export-*.ps1
- docker-run.ps1/sh (use docker-compose instead)
- fix-import-export-wizard.ps1
- fix-missing-dll.ps1
- download-missing-dll.ps1

### 3. Staging/Production Deployment Scripts (40+ files)
All deploy-* and staging-* files:
- deploy-*.ps1/sh
- staging-*.ps1/sh/sql
- production-*.ps1/sh/sql/zip/tar.gz
- redeploy-staging.ps1
- promote-to-production.ps1
- swap-slots.ps1
- configure-*.ps1
- grant-*.sql
- use-sql-auth-staging.ps1
- verify-*.ps1/sql

### 4. Check/Debug Scripts (50+ files)
All check-* files:
- check-azure-*.ps1/sql
- check-docker-*.ps1
- check-column-*.ps1
- check-staging-*.ps1
- check-production-*.sql
- check-admin-*.ps1/sql
- check-build.ps1
- check-errors.ps1
- check-*.ps1/sql (all of them)
- diagnose-*.ps1/sh

### 5. Fix Scripts (30+ files)
- fix-admin-*.ps1/sql
- fix-worksheet-*.ps1
- fix-auth-*.sql
- fix-packbundle-*.ps1
- fix-firewall.ps1
- fix-production-*.ps1/sql
- update-admin-*.sql
- update-users-table*.sql
- update-*.ps1/sql

### 6. Test/Build Scripts (20+ files)
- test-compile*.ps1/bat
- test-minimal*.ps1/sh
- test-server.ps1
- test-ipv6.ps1
- test-connection*.ps1
- test-sql-*.ps1/sql
- test-direct-*.sql
- test-managed-*.sql
- quick-*.ps1/sh
- build-*.ps1/bat (except maybe build-solution.ps1)
- clean-*.ps1/bat (except clean-azure-db.ps1)

### 7. Migration Runner Scripts (30+ files)
All run-*-migration scripts except base run-migration.ps1/bat:
- run-all-migrations-*.ps1
- run-column-*.ps1/bat
- run-efficiency-*.ps1/bat
- run-feature-*.ps1
- run-multitenant-*.ps1/bat
- run-packbundle-*.ps1/bat
- run-settings-*.ps1/bat
- run-tableviews-*.ps1/bat
- run-template-*.ps1/bat
- run-worksheet-*.ps1/bat

### 8. Seed/Create Scripts (10+ files)
- seed-*.sql
- create-admin-*.sql
- create-test-*.sql
- create-database-*.sql
- create-all-*.sql
- create-invites-*.sql
- create-simple-*.sql
- emergency-admin-*.sql

### 9. Utility Scripts (15+ files)
- kill-dotnet.ps1
- get-*.ps1
- push-changes.ps1
- find-sql-server.ps1
- enable-*.ps1
- set-*.ps1
- add-*.ps1 (most of them)
- generate-password-hash.ps1

### 10. Old/Obsolete Files (10+ files)
- migration-script.sql
- manual-*.sql/txt
- direct-data-export.sql
- extract-local-schema.ps1
- copy-database-schema.ps1
- list-azure-tables.sql
- sandbox-schema.sql

### 11. Unnecessary Markdown Files
- SSMS-Migration-Guide.md (used SqlPackage instead)
- DOCKER-DATA-MIGRATION.md (migration complete)
- MIGRATE-TO-DOCKER.md (already on Docker)
- STAGING-*.md (all staging docs - not deployed yet)
- GITHUB-*.md (setup complete)
- DEPLOYMENT.md (old deployment guide)
- CLOUD-FIRST-WORKFLOW.md (old workflow)
- FINAL-STAGING-STEPS.md
- IMPORTANT-ADMIN-ACCESS.md (admin access documented in CLAUDE.md)
- MULTITENANT_SETUP.md (not using multi-tenant)
- FEATURE_ACCESS_IMPLEMENTATION.md (feature implemented)
- cleanup-analysis.md (this cleanup doc)

### 12. Compiled/Archive Files
- *.zip
- *.tar.gz
- logs.zip
- production-logs.zip
- staging-logs.zip
- build-output.txt
- publish-fixed/ (entire folder)
- publish-selfcontained/ (entire folder)

### 13. Config/Temp Files
- appsettings.Azure.json (duplicate in Web folder)
- docker-compose.azure.yml (old version)
- docker-compose-clean.yml
- azure-mcp-*.json/js
- playwright-mcp*.json
- manual-github-setup.txt
- azure-users-backup.txt
- simple-test.html
- quick-ssms-steps.txt

### 14. Python Scripts (if not using)
- create-*.py

### 15. Old Batch Files
Most .bat files (keeping only essential ones like run-migration.bat)

## FILES TO KEEP

### Essential Scripts
- setup-local-db.ps1
- run-local.ps1
- run-migration.ps1/bat
- migrate-to-azure.ps1 (documented)
- test-azure-app.ps1
- clean-azure-db.ps1

### Docker Files
- docker-compose.yml
- docker-compose-dev.yml
- docker-compose-azure.yml (the updated one)
- Dockerfile
- docker/ folder

### Documentation
- README.md
- CLAUDE.md
- AZURE-SQL-MIGRATION-GUIDE.md
- CONFIGURATION-BEST-PRACTICES.md
- README-GoogleAddressAutocomplete.md

### Core Project Structure
- All .csproj files
- All source code folders
- Migrations/ folder
- SQL_Migrations/ folder
- sqlpackage/ folder
- backups/ folder
- logs/ folder
- uploads/ folder

## Total Files to Remove: ~250+
## Space to Recover: Several MB (includes compiled folders)