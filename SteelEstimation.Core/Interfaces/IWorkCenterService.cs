using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Interfaces;

public interface IWorkCenterService
{
    // Work Center operations
    Task<IEnumerable<WorkCenter>> GetAllWorkCentersAsync(int companyId);
    Task<WorkCenter?> GetWorkCenterByIdAsync(int id);
    Task<WorkCenter?> GetWorkCenterByCodeAsync(string code, int companyId);
    Task<WorkCenter> CreateWorkCenterAsync(WorkCenter workCenter);
    Task<WorkCenter> UpdateWorkCenterAsync(WorkCenter workCenter);
    Task<bool> DeleteWorkCenterAsync(int id);
    Task<bool> WorkCenterExistsAsync(string code, int companyId, int? excludeId = null);
    
    // Work Center Skills
    Task<IEnumerable<WorkCenterSkill>> GetWorkCenterSkillsAsync(int workCenterId);
    Task<WorkCenterSkill> AddWorkCenterSkillAsync(WorkCenterSkill skill);
    Task<bool> RemoveWorkCenterSkillAsync(int skillId);
    
    // Work Center Shifts
    Task<IEnumerable<WorkCenterShift>> GetWorkCenterShiftsAsync(int workCenterId);
    Task<WorkCenterShift> AddWorkCenterShiftAsync(WorkCenterShift shift);
    Task<WorkCenterShift> UpdateWorkCenterShiftAsync(WorkCenterShift shift);
    Task<bool> RemoveWorkCenterShiftAsync(int shiftId);
    
    // Analytics and reporting
    Task<decimal> CalculateTotalCapacityAsync(int companyId);
    Task<decimal> CalculateUtilizationRateAsync(int workCenterId, DateTime startDate, DateTime endDate);
    Task<IEnumerable<WorkCenter>> GetWorkCentersByTypeAsync(string type, int companyId);
}

public interface IMachineCenterService
{
    // Machine Center operations
    Task<IEnumerable<MachineCenter>> GetAllMachineCentersAsync(int companyId);
    Task<IEnumerable<MachineCenter>> GetMachineCentersByWorkCenterAsync(int workCenterId);
    Task<MachineCenter?> GetMachineCenterByIdAsync(int id);
    Task<MachineCenter?> GetMachineCenterByCodeAsync(string machineCode, int companyId);
    Task<MachineCenter> CreateMachineCenterAsync(MachineCenter machineCenter);
    Task<MachineCenter> UpdateMachineCenterAsync(MachineCenter machineCenter);
    Task<bool> DeleteMachineCenterAsync(int id);
    Task<bool> MachineCenterExistsAsync(string machineCode, int companyId, int? excludeId = null);
    
    // Machine status operations
    Task<bool> UpdateMachineStatusAsync(int machineCenterId, string status);
    Task<IEnumerable<MachineCenter>> GetAvailableMachinesAsync(int companyId);
    Task<IEnumerable<MachineCenter>> GetMachinesInMaintenanceAsync(int companyId);
    
    // Machine Capabilities
    Task<IEnumerable<MachineCapability>> GetMachineCapabilitiesAsync(int machineCenterId);
    Task<MachineCapability> AddMachineCapabilityAsync(MachineCapability capability);
    Task<MachineCapability> UpdateMachineCapabilityAsync(MachineCapability capability);
    Task<bool> RemoveMachineCapabilityAsync(int capabilityId);
    
    // Machine Operators
    Task<IEnumerable<MachineOperator>> GetMachineOperatorsAsync(int machineCenterId);
    Task<MachineOperator> AssignOperatorAsync(MachineOperator machineOperator);
    Task<bool> RemoveOperatorAsync(int operatorId);
    Task<IEnumerable<MachineCenter>> GetMachinesByOperatorAsync(int userId);
    
    // Maintenance tracking
    Task<bool> RecordMaintenanceAsync(int machineCenterId, DateTime maintenanceDate);
    Task<IEnumerable<MachineCenter>> GetMachinesDueForMaintenanceAsync(int companyId);
    Task<bool> UpdateOperatingHoursAsync(int machineCenterId, int hours);
    
    // Analytics
    Task<decimal> CalculateOEEAsync(int machineCenterId, DateTime startDate, DateTime endDate);
    Task<decimal> CalculateMachineUtilizationAsync(int machineCenterId, DateTime startDate, DateTime endDate);
}