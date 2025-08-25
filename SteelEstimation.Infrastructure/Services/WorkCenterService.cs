using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services;

public class WorkCenterService : IWorkCenterService
{
    private readonly ApplicationDbContext _context;

    public WorkCenterService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<WorkCenter>> GetAllWorkCentersAsync(int companyId)
    {
        return await _context.WorkCenters
            .Include(w => w.RequiredSkills)
            .Include(w => w.Shifts)
            .Include(w => w.MachineCenters)
            .Where(w => w.CompanyId == companyId && !w.IsDeleted)
            .OrderBy(w => w.Code)
            .ToListAsync();
    }

    public async Task<WorkCenter?> GetWorkCenterByIdAsync(int id)
    {
        return await _context.WorkCenters
            .Include(w => w.RequiredSkills)
            .Include(w => w.Shifts)
            .Include(w => w.MachineCenters)
            .FirstOrDefaultAsync(w => w.Id == id && !w.IsDeleted);
    }

    public async Task<WorkCenter?> GetWorkCenterByCodeAsync(string code, int companyId)
    {
        return await _context.WorkCenters
            .Include(w => w.RequiredSkills)
            .Include(w => w.Shifts)
            .Include(w => w.MachineCenters)
            .FirstOrDefaultAsync(w => w.Code == code && w.CompanyId == companyId && !w.IsDeleted);
    }

    public async Task<WorkCenter> CreateWorkCenterAsync(WorkCenter workCenter)
    {
        workCenter.CreatedDate = DateTime.UtcNow;
        workCenter.LastModified = DateTime.UtcNow;
        
        _context.WorkCenters.Add(workCenter);
        await _context.SaveChangesAsync();
        return workCenter;
    }

    public async Task<WorkCenter> UpdateWorkCenterAsync(WorkCenter workCenter)
    {
        var existing = await _context.WorkCenters.FindAsync(workCenter.Id);
        if (existing == null)
            throw new InvalidOperationException($"Work center with ID {workCenter.Id} not found");

        existing.Code = workCenter.Code;
        existing.Name = workCenter.Name;
        existing.Description = workCenter.Description;
        existing.WorkCenterType = workCenter.WorkCenterType;
        existing.DailyCapacityHours = workCenter.DailyCapacityHours;
        existing.SimultaneousOperations = workCenter.SimultaneousOperations;
        existing.HourlyRate = workCenter.HourlyRate;
        existing.OverheadRate = workCenter.OverheadRate;
        existing.EfficiencyPercentage = workCenter.EfficiencyPercentage;
        existing.Department = workCenter.Department;
        existing.Building = workCenter.Building;
        existing.Floor = workCenter.Floor;
        existing.IsActive = workCenter.IsActive;
        existing.MaintenanceIntervalDays = workCenter.MaintenanceIntervalDays;
        existing.LastModified = DateTime.UtcNow;
        existing.LastModifiedByUserId = workCenter.LastModifiedByUserId;

        await _context.SaveChangesAsync();
        return existing;
    }

    public async Task<bool> DeleteWorkCenterAsync(int id)
    {
        var workCenter = await _context.WorkCenters.FindAsync(id);
        if (workCenter == null)
            return false;

        workCenter.IsDeleted = true;
        workCenter.LastModified = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> WorkCenterExistsAsync(string code, int companyId, int? excludeId = null)
    {
        var query = _context.WorkCenters
            .Where(w => w.Code == code && w.CompanyId == companyId && !w.IsDeleted);

        if (excludeId.HasValue)
            query = query.Where(w => w.Id != excludeId.Value);

        return await query.AnyAsync();
    }

    public async Task<IEnumerable<WorkCenterSkill>> GetWorkCenterSkillsAsync(int workCenterId)
    {
        return await _context.WorkCenterSkills
            .Where(s => s.WorkCenterId == workCenterId)
            .OrderBy(s => s.SkillName)
            .ToListAsync();
    }

    public async Task<WorkCenterSkill> AddWorkCenterSkillAsync(WorkCenterSkill skill)
    {
        _context.WorkCenterSkills.Add(skill);
        await _context.SaveChangesAsync();
        return skill;
    }

    public async Task<bool> RemoveWorkCenterSkillAsync(int skillId)
    {
        var skill = await _context.WorkCenterSkills.FindAsync(skillId);
        if (skill == null)
            return false;

        _context.WorkCenterSkills.Remove(skill);
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<IEnumerable<WorkCenterShift>> GetWorkCenterShiftsAsync(int workCenterId)
    {
        return await _context.WorkCenterShifts
            .Where(s => s.WorkCenterId == workCenterId)
            .OrderBy(s => s.StartTime)
            .ToListAsync();
    }

    public async Task<WorkCenterShift> AddWorkCenterShiftAsync(WorkCenterShift shift)
    {
        _context.WorkCenterShifts.Add(shift);
        await _context.SaveChangesAsync();
        return shift;
    }

    public async Task<WorkCenterShift> UpdateWorkCenterShiftAsync(WorkCenterShift shift)
    {
        var existing = await _context.WorkCenterShifts.FindAsync(shift.Id);
        if (existing == null)
            throw new InvalidOperationException($"Work center shift with ID {shift.Id} not found");

        existing.ShiftName = shift.ShiftName;
        existing.StartTime = shift.StartTime;
        existing.EndTime = shift.EndTime;
        existing.BreakDurationMinutes = shift.BreakDurationMinutes;
        existing.DaysOfWeek = shift.DaysOfWeek;
        existing.IsActive = shift.IsActive;
        existing.EfficiencyMultiplier = shift.EfficiencyMultiplier;

        await _context.SaveChangesAsync();
        return existing;
    }

    public async Task<bool> RemoveWorkCenterShiftAsync(int shiftId)
    {
        var shift = await _context.WorkCenterShifts.FindAsync(shiftId);
        if (shift == null)
            return false;

        _context.WorkCenterShifts.Remove(shift);
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<decimal> CalculateTotalCapacityAsync(int companyId)
    {
        var workCenters = await _context.WorkCenters
            .Where(w => w.CompanyId == companyId && w.IsActive && !w.IsDeleted)
            .ToListAsync();

        return workCenters.Sum(w => w.DailyCapacityHours * w.SimultaneousOperations);
    }

    public async Task<decimal> CalculateUtilizationRateAsync(int workCenterId, DateTime startDate, DateTime endDate)
    {
        var workCenter = await GetWorkCenterByIdAsync(workCenterId);
        if (workCenter == null)
            return 0;

        var totalAvailableHours = (decimal)(endDate - startDate).TotalDays * workCenter.DailyCapacityHours;
        
        // This would typically query actual production data
        // For now, returning a placeholder calculation
        var utilizationRate = workCenter.EfficiencyPercentage;
        
        return Math.Min(utilizationRate, 100);
    }

    public async Task<IEnumerable<WorkCenter>> GetWorkCentersByTypeAsync(string type, int companyId)
    {
        return await _context.WorkCenters
            .Include(w => w.MachineCenters)
            .Where(w => w.WorkCenterType == type && w.CompanyId == companyId && !w.IsDeleted)
            .OrderBy(w => w.Code)
            .ToListAsync();
    }
}