using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Services;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services
{
    public class WorksheetChangeService : IWorksheetChangeService
    {
        private readonly IDbContextFactory<ApplicationDbContext> _contextFactory;

        public WorksheetChangeService(IDbContextFactory<ApplicationDbContext> contextFactory)
        {
            _contextFactory = contextFactory;
        }

        public async Task RecordChangeAsync(WorksheetChange change)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            context.WorksheetChanges.Add(change);
            await context.SaveChangesAsync();
        }

        public async Task<WorksheetChange?> GetLastChangeAsync(int worksheetId, int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            return await context.WorksheetChanges
                .Where(c => c.PackageWorksheetId == worksheetId && 
                           c.UserId == userId && 
                           !c.IsUndone)
                .OrderByDescending(c => c.Timestamp)
                .FirstOrDefaultAsync();
        }

        public async Task<bool> UndoAsync(int worksheetId, int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var lastChange = await GetLastChangeAsync(worksheetId, userId);
            if (lastChange == null) return false;

            // Mark the change as undone
            lastChange.IsUndone = true;

            // Apply the undo based on change type
            switch (lastChange.ChangeType)
            {
                case "Add":
                    await UndoAddAsync(lastChange, context);
                    break;
                case "Update":
                    await UndoUpdateAsync(lastChange, context);
                    break;
                case "Delete":
                    await UndoDeleteAsync(lastChange, context);
                    break;
            }

            await context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> RedoAsync(int worksheetId, int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var lastUndoneChange = await context.WorksheetChanges
                .Where(c => c.PackageWorksheetId == worksheetId && 
                           c.UserId == userId && 
                           c.IsUndone)
                .OrderByDescending(c => c.Timestamp)
                .FirstOrDefaultAsync();

            if (lastUndoneChange == null) return false;

            // Mark the change as not undone
            lastUndoneChange.IsUndone = false;

            // Apply the redo based on change type
            switch (lastUndoneChange.ChangeType)
            {
                case "Add":
                    await RedoAddAsync(lastUndoneChange, context);
                    break;
                case "Update":
                    await RedoUpdateAsync(lastUndoneChange, context);
                    break;
                case "Delete":
                    await RedoDeleteAsync(lastUndoneChange, context);
                    break;
            }

            await context.SaveChangesAsync();
            return true;
        }

        public async Task<List<WorksheetChange>> GetRecentChangesAsync(int worksheetId, int count = 10)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            return await context.WorksheetChanges
                .Where(c => c.PackageWorksheetId == worksheetId)
                .OrderByDescending(c => c.Timestamp)
                .Take(count)
                .ToListAsync();
        }

        private async Task UndoAddAsync(WorksheetChange change, ApplicationDbContext context)
        {
            if (change.EntityType == "ProcessingItem")
            {
                var item = await context.ProcessingItems.FindAsync(change.EntityId);
                if (item != null)
                {
                    item.IsDeleted = true;
                }
            }
            else if (change.EntityType == "WeldingItem")
            {
                var item = await context.WeldingItems.FindAsync(change.EntityId);
                if (item != null)
                {
                    item.IsDeleted = true;
                }
            }
        }

        private async Task UndoUpdateAsync(WorksheetChange change, ApplicationDbContext context)
        {
            if (string.IsNullOrEmpty(change.OldValues)) return;

            if (change.EntityType == "ProcessingItem")
            {
                var item = await context.ProcessingItems.FindAsync(change.EntityId);
                if (item != null)
                {
                    var oldValues = JsonConvert.DeserializeObject<Dictionary<string, object>>(change.OldValues);
                    ApplyValues(item, oldValues);
                }
            }
            else if (change.EntityType == "WeldingItem")
            {
                var item = await context.WeldingItems.FindAsync(change.EntityId);
                if (item != null)
                {
                    var oldValues = JsonConvert.DeserializeObject<Dictionary<string, object>>(change.OldValues);
                    ApplyValues(item, oldValues);
                }
            }
        }

        private async Task UndoDeleteAsync(WorksheetChange change, ApplicationDbContext context)
        {
            if (string.IsNullOrEmpty(change.OldValues)) return;

            if (change.EntityType == "ProcessingItem")
            {
                var item = await context.ProcessingItems.FindAsync(change.EntityId);
                if (item != null)
                {
                    item.IsDeleted = false;
                }
            }
            else if (change.EntityType == "WeldingItem")
            {
                var item = await context.WeldingItems.FindAsync(change.EntityId);
                if (item != null)
                {
                    item.IsDeleted = false;
                }
            }
        }

        private async Task RedoAddAsync(WorksheetChange change, ApplicationDbContext context)
        {
            if (change.EntityType == "ProcessingItem")
            {
                var item = await context.ProcessingItems.FindAsync(change.EntityId);
                if (item != null)
                {
                    item.IsDeleted = false;
                }
            }
            else if (change.EntityType == "WeldingItem")
            {
                var item = await context.WeldingItems.FindAsync(change.EntityId);
                if (item != null)
                {
                    item.IsDeleted = false;
                }
            }
        }

        private async Task RedoUpdateAsync(WorksheetChange change, ApplicationDbContext context)
        {
            if (string.IsNullOrEmpty(change.NewValues)) return;

            if (change.EntityType == "ProcessingItem")
            {
                var item = await context.ProcessingItems.FindAsync(change.EntityId);
                if (item != null)
                {
                    var newValues = JsonConvert.DeserializeObject<Dictionary<string, object>>(change.NewValues);
                    ApplyValues(item, newValues);
                }
            }
            else if (change.EntityType == "WeldingItem")
            {
                var item = await context.WeldingItems.FindAsync(change.EntityId);
                if (item != null)
                {
                    var newValues = JsonConvert.DeserializeObject<Dictionary<string, object>>(change.NewValues);
                    ApplyValues(item, newValues);
                }
            }
        }

        private async Task RedoDeleteAsync(WorksheetChange change, ApplicationDbContext context)
        {
            if (change.EntityType == "ProcessingItem")
            {
                var item = await context.ProcessingItems.FindAsync(change.EntityId);
                if (item != null)
                {
                    item.IsDeleted = true;
                }
            }
            else if (change.EntityType == "WeldingItem")
            {
                var item = await context.WeldingItems.FindAsync(change.EntityId);
                if (item != null)
                {
                    item.IsDeleted = true;
                }
            }
        }

        private void ApplyValues(object entity, Dictionary<string, object>? values)
        {
            if (values == null) return;

            var type = entity.GetType();
            foreach (var kvp in values)
            {
                var property = type.GetProperty(kvp.Key);
                if (property != null && property.CanWrite)
                {
                    var value = kvp.Value;
                    if (value != null)
                    {
                        // Handle type conversions
                        if (property.PropertyType == typeof(decimal) && value is long)
                        {
                            value = Convert.ToDecimal(value);
                        }
                        else if (property.PropertyType == typeof(int) && value is long)
                        {
                            value = Convert.ToInt32(value);
                        }
                        // Add more conversions as needed
                    }
                    property.SetValue(entity, value);
                }
            }
        }
    }
}