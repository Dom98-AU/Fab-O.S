-- Migration: Update Project table to remove CustomerName column
-- Created: 2025-07-05
-- Description: Removes the CustomerName column from Projects table after Customer relationship is established

-- First, ensure all existing customer names are migrated to Customer table
-- This should be run AFTER the AddCustomerManagementTables.sql migration
-- and AFTER data has been migrated using the commented script in that file

-- Drop the CustomerName column from Projects table
-- WARNING: Only run this after ensuring all customer data has been migrated!
-- ALTER TABLE [dbo].[Projects] DROP COLUMN [CustomerName];

-- To revert this migration:
-- ALTER TABLE [dbo].[Projects] ADD [CustomerName] nvarchar(200) NULL;