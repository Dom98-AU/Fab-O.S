# Database Migration Instructions

## Overview
This migration adds support for:
1. Welding Connections with pre-defined connection types
2. Image Upload functionality for welding items
3. Worksheet Change Tracking for undo/redo functionality
4. Package-level welding connection overrides
5. Editable project descriptions

## Files Included
- `AddWeldingConnectionsAndImageSupport.sql` - Main migration script
- `Rollback_AddWeldingConnectionsAndImageSupport.sql` - Rollback script if needed
- `CheckDatabaseState.sql` - Script to check current database state
- `Manual_AddWeldingConnectionsAndImageSupport.cs` - Entity Framework migration file

## Prerequisites
- SQL Server 2016 or later
- Appropriate database permissions (db_ddladmin or higher)
- Backup your database before applying migrations

## Method 1: Using SQL Scripts Directly

### Step 1: Check Current Database State
```sql
-- Run CheckDatabaseState.sql to see what already exists
sqlcmd -S your_server -d your_database -i CheckDatabaseState.sql
```

### Step 2: Apply Migration
```sql
-- Run the main migration script
sqlcmd -S your_server -d your_database -i AddWeldingConnectionsAndImageSupport.sql
```

### Step 3: Verify Migration
Run the CheckDatabaseState.sql script again to confirm all objects were created.

## Method 2: Using Entity Framework Core

### Step 1: Add Migration
```bash
cd /path/to/SteelEstimation.Infrastructure
dotnet ef migrations add AddWeldingConnectionsAndImageSupport -c ApplicationDbContext
```

### Step 2: Update Database
```bash
dotnet ef database update -c ApplicationDbContext
```

## Method 3: Using SQL Server Management Studio (SSMS)

1. Open SSMS and connect to your database
2. Open `AddWeldingConnectionsAndImageSupport.sql`
3. Review the script
4. Execute the script (F5)

## What This Migration Does

### 1. Creates New Tables
- **WeldingConnections**: Stores pre-defined welding connection types
- **ImageUploads**: Stores image metadata for uploaded images
- **WorksheetChanges**: Tracks changes for undo/redo functionality
- **PackageWeldingConnections**: Allows package-level time overrides

### 2. Modifies Existing Tables
- **WeldingItems**: 
  - Adds `WeldingConnectionId` column
  - Changes time fields from `int` to `decimal(18,2)`
- **Projects**: 
  - Adds `Description` column for editable project descriptions

### 3. Seeds Default Data
Inserts 22 pre-defined welding connection types in categories:
- Baseplate (3 types)
- Stiffener (3 types)
- Gusset (2 types)
- Cleat (2 types)
- Splice (2 types)
- Moment (2 types)
- Brace (2 types)
- Special (3 types)
- Complex (3 types)

## Rollback Instructions

If you need to rollback this migration:

```sql
-- Run the rollback script
sqlcmd -S your_server -d your_database -i Rollback_AddWeldingConnectionsAndImageSupport.sql
```

**WARNING**: Rolling back will:
- Delete all uploaded images metadata (actual files remain on disk)
- Remove all worksheet change history
- Lose any package-level connection overrides
- Convert decimal time values back to integers (may lose precision)

## Post-Migration Steps

1. **Create Upload Directory**: Ensure the image upload directory exists
   ```
   /wwwroot/uploads/images/
   /wwwroot/uploads/thumbnails/
   ```

2. **Set Permissions**: Ensure the web application has write permissions to upload directories

3. **Update Configuration**: Add image upload settings to appsettings.json if needed:
   ```json
   {
     "ImageUpload": {
       "MaxFileSize": 10485760,
       "AllowedExtensions": [".jpg", ".jpeg", ".png", ".gif", ".bmp"],
       "UploadPath": "wwwroot/uploads/images",
       "ThumbnailPath": "wwwroot/uploads/thumbnails"
     }
   }
   ```

4. **Test Features**:
   - Create a welding item and select a connection type
   - Upload images to a welding item
   - Test undo/redo functionality
   - Edit estimation details

## Troubleshooting

### Error: "Column already exists"
The migration may have been partially applied. Run `CheckDatabaseState.sql` to see what exists, then manually apply only the missing parts.

### Error: "Foreign key constraint conflict"
Ensure all referenced tables exist and have the expected structure. The WeldingItems table must exist before this migration.

### Error: "Cannot alter column because it has dependent objects"
Drop any indexes or constraints on the affected columns first, then reapply them after the migration.

## Support
If you encounter issues:
1. Check the SQL Server error logs
2. Run `CheckDatabaseState.sql` to verify current state
3. Ensure you have appropriate permissions
4. Consider running the migration in smaller parts if needed