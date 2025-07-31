# Cleanup Analysis - Files to Remove

## 1. Azure Migration Scripts (No longer needed - migration complete)
- All azure-migration-*.ps1/sql files
- azure-complete-*.sql/ps1
- migrate-*.ps1 (except migrate-to-azure.ps1 which is documented)
- azure-schema-*.sql
- azure-transform-*.sql
- direct-azure-migration.ps1
- execute-azure-migration*.ps1
- simple-azure-migration.ps1

## 2. Docker-to-Azure Transition Scripts (Using Azure SQL now)
- migrate-docker-to-azure-fresh.ps1
- backup-restore-to-docker.ps1
- import-to-docker.ps1
- export-for-docker.ps1

## 3. Import/Export Wizard Fix Scripts (We used SqlPackage instead)
- fix-import-export-wizard.ps1
- fix-missing-dll.ps1
- download-missing-dll.ps1

## 4. Old Azure Setup Scripts (Setup is complete)
- azure-create-*.ps1
- azure-setup*.ps1
- azure-configure.ps1
- azure-insert-data.ps1
- setup-azure-*.ps1

## 5. Staging/Production Deployment Scripts (Not in use yet)
- deploy-*.ps1/sh
- redeploy-staging.ps1
- promote-to-production.ps1
- swap-slots.ps1
- All staging-*.ps1/sh/sql files
- All production-*.ps1/sh/sql files

## 6. Check/Debug Scripts (One-time use)
- check-azure-*.ps1/sql
- check-docker-*.ps1
- check-column-tables*.ps1
- check-staging-*.ps1
- check-production-*.sql
- diagnose-*.ps1/sh

## 7. Fix Scripts (Issues already resolved)
- fix-admin-*.ps1/sql
- fix-worksheet-*.ps1
- fix-auth-*.sql
- fix-packbundle-*.ps1
- fix-firewall.ps1
- update-admin-*.sql
- update-users-table*.sql

## 8. Old Migration Scripts (Migrations already applied)
- run-*-migration.ps1/bat (keep run-migration.ps1/bat for future use)
- All individual migration runner scripts

## 9. Test/Build Scripts (Use docker-compose instead)
- test-compile*.ps1/bat
- test-minimal*.ps1/sh
- test-server.ps1
- test-ipv6.ps1
- quick-test.ps1
- quick-build-*.ps1

## 10. Old Connection Test Scripts
- test-connection.ps1
- test-sql-connection.ps1
- test-direct-sql-connection.sql
- test-managed-identity-connection.sql

## 11. Utility Scripts (No longer needed)
- kill-dotnet.ps1
- get-first-error.ps1
- get-stdout-logs.ps1
- push-changes.ps1
- find-sql-server.ps1

## 12. Old Seed Scripts
- seed-*.sql
- quick-seed.ps1
- create-test-user-*.sql
- create-admin-user.sql

## Files to KEEP:
- migrate-to-azure.ps1 (documented migration script)
- test-azure-app.ps1 (current test script)
- clean-azure-db.ps1 (might need for cleanup)
- setup-local-db.ps1 (for local development)
- run-local.ps1 (for local development)
- run-migration.ps1/bat (for future migrations)
- docker-compose*.yml files
- CLAUDE.md and other documentation files