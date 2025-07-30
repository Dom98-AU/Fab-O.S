using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SteelEstimation.Core.Models;

namespace SteelEstimation.Web.Services
{
    public class DeploymentService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<DeploymentService> _logger;
        private readonly GitHubService _gitHubService;
        private readonly List<DeploymentHistory> _deploymentHistory = new(); // In-memory for demo

        public DeploymentService(
            IConfiguration configuration, 
            ILogger<DeploymentService> logger,
            GitHubService gitHubService)
        {
            _configuration = configuration;
            _logger = logger;
            _gitHubService = gitHubService;
        }

        public async Task<EnvironmentInfo> GetEnvironmentInfoAsync(string environmentName)
        {
            var info = new EnvironmentInfo
            {
                Name = environmentName,
                DeployedAt = DateTime.UtcNow.AddHours(-2), // Mock data
                DeployedBy = "admin@company.com",
                IsHealthy = true
            };

            // Set environment-specific details
            try
            {
                if (environmentName == "Production")
                {
                    info.DatabaseName = "sqldb-steel-estimation-prod";
                    info.Url = "https://app-steel-estimation-prod.azurewebsites.net";
                    info.Version = "1.2.3";
                    info.CommitHash = await _gitHubService.GetLatestCommitHashAsync("master");
                    if (string.IsNullOrEmpty(info.CommitHash))
                        info.CommitHash = "No GitHub token configured";
                }
                else
                {
                    info.DatabaseName = "sqldb-steel-estimation-sandbox";
                    info.Url = "https://app-steel-estimation-prod-staging.azurewebsites.net";
                    info.Version = "1.2.4-dev";
                    info.CommitHash = await _gitHubService.GetLatestCommitHashAsync("develop");
                    if (string.IsNullOrEmpty(info.CommitHash))
                        info.CommitHash = "No GitHub token configured";
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting environment info for {environmentName}");
                info.CommitHash = "Error loading GitHub data";
            }

            return info;
        }

        public async Task<EnvironmentComparison> CompareEnvironmentsAsync()
        {
            var comparison = new EnvironmentComparison
            {
                Production = await GetEnvironmentInfoAsync("Production"),
                Staging = await GetEnvironmentInfoAsync("Staging")
            };

            // Get pending commits (safely)
            try
            {
                comparison.PendingCommits = await _gitHubService.GetCommitsBetweenAsync("master", "develop");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting pending commits from GitHub");
                comparison.PendingCommits = new List<GitHubCommit>();
            }
            
            // Check if promotion is allowed
            var hasGitHubToken = !string.IsNullOrEmpty(_configuration["GitHub:AccessToken"]);
            comparison.CanPromote = comparison.Staging.IsHealthy && (comparison.PendingCommits.Any() || !hasGitHubToken);
            
            if (!comparison.CanPromote)
            {
                if (!comparison.Staging.IsHealthy)
                    comparison.BlockReason = "Staging environment is unhealthy";
                else if (!hasGitHubToken)
                    comparison.BlockReason = "GitHub token not configured - manual promotion available";
                else
                    comparison.BlockReason = "No new commits to promote";
            }

            return comparison;
        }

        public async Task<bool> PromoteToProductionAsync(DeploymentRequest request)
        {
            try
            {
                _logger.LogInformation($"Starting promotion to production by {request.RequestedBy}");

                // In a real implementation, this would:
                // 1. Call Azure Management API to swap slots
                // 2. Run health checks
                // 3. Update deployment history
                
                // For now, we'll simulate the process
                await Task.Delay(5000); // Simulate deployment time

                // Record deployment
                _deploymentHistory.Add(new DeploymentHistory
                {
                    Id = _deploymentHistory.Count + 1,
                    Environment = "Production",
                    Version = "1.2.4",
                    CommitHash = request.CommitHash,
                    DeployedBy = request.RequestedBy,
                    DeployedAt = DateTime.UtcNow,
                    Status = "Success",
                    Notes = request.Notes
                });

                _logger.LogInformation("Promotion to production completed successfully");
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to promote to production");
                
                _deploymentHistory.Add(new DeploymentHistory
                {
                    Id = _deploymentHistory.Count + 1,
                    Environment = "Production",
                    Version = "1.2.4",
                    CommitHash = request.CommitHash,
                    DeployedBy = request.RequestedBy,
                    DeployedAt = DateTime.UtcNow,
                    Status = "Failed",
                    Notes = $"Error: {ex.Message}"
                });
                
                return false;
            }
        }

        public async Task<bool> SwapSlotsAsync()
        {
            try
            {
                var resourceGroup = _configuration["Azure:ResourceGroup"] ?? "NWIApps";
                var appServiceName = _configuration["Azure:AppServiceName"] ?? "app-steel-estimation-prod";

                // In a real implementation, this would call Azure Management API or use PowerShell
                // For now, we'll simulate the swap
                _logger.LogInformation($"Swapping slots for {appServiceName}");
                
                // Simulate swap - in production, this would execute:
                // az webapp deployment slot swap --resource-group {resourceGroup} --name {appServiceName} --slot staging
                await Task.Delay(3000);
                
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to swap slots");
                return false;
            }
        }

        public async Task<List<DeploymentHistory>> GetDeploymentHistoryAsync(int count = 10)
        {
            // In a real implementation, this would query a database
            return await Task.FromResult(_deploymentHistory
                .OrderByDescending(d => d.DeployedAt)
                .Take(count)
                .ToList());
        }

        public async Task<bool> RollbackAsync(string environmentName)
        {
            try
            {
                _logger.LogInformation($"Starting rollback for {environmentName}");
                
                // In a real implementation, this would swap slots again
                await Task.Delay(3000);
                
                _deploymentHistory.Add(new DeploymentHistory
                {
                    Id = _deploymentHistory.Count + 1,
                    Environment = environmentName,
                    Version = "Rollback",
                    CommitHash = "previous",
                    DeployedBy = "System",
                    DeployedAt = DateTime.UtcNow,
                    Status = "Rolled Back",
                    Notes = "Emergency rollback performed"
                });
                
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to rollback {environmentName}");
                return false;
            }
        }

        public bool IsBusinessHours()
        {
            var now = DateTime.Now;
            var isWeekday = now.DayOfWeek >= DayOfWeek.Monday && now.DayOfWeek <= DayOfWeek.Friday;
            var isBusinessHours = now.Hour >= 9 && now.Hour < 17;
            return isWeekday && isBusinessHours;
        }
    }
}