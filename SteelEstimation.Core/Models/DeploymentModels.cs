using System;

namespace SteelEstimation.Core.Models
{
    public class EnvironmentInfo
    {
        public string Name { get; set; } = string.Empty;
        public string Version { get; set; } = string.Empty;
        public string CommitHash { get; set; } = string.Empty;
        public DateTime DeployedAt { get; set; }
        public string DeployedBy { get; set; } = string.Empty;
        public string DatabaseName { get; set; } = string.Empty;
        public bool IsHealthy { get; set; }
        public string Url { get; set; } = string.Empty;
    }

    public class DeploymentRequest
    {
        public string SourceEnvironment { get; set; } = string.Empty;
        public string TargetEnvironment { get; set; } = string.Empty;
        public string CommitHash { get; set; } = string.Empty;
        public string RequestedBy { get; set; } = string.Empty;
        public DateTime RequestedAt { get; set; } = DateTime.UtcNow;
        public string Notes { get; set; } = string.Empty;
    }

    public class DeploymentHistory
    {
        public int Id { get; set; }
        public string Environment { get; set; } = string.Empty;
        public string Version { get; set; } = string.Empty;
        public string CommitHash { get; set; } = string.Empty;
        public string DeployedBy { get; set; } = string.Empty;
        public DateTime DeployedAt { get; set; }
        public string Status { get; set; } = string.Empty; // Success, Failed, Rolled Back
        public string Notes { get; set; } = string.Empty;
    }

    public class GitHubCommit
    {
        public string Sha { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public string Author { get; set; } = string.Empty;
        public DateTime Date { get; set; }
        public string Url { get; set; } = string.Empty;
    }

    public class EnvironmentComparison
    {
        public EnvironmentInfo Production { get; set; } = new();
        public EnvironmentInfo Staging { get; set; } = new();
        public List<GitHubCommit> PendingCommits { get; set; } = new();
        public bool CanPromote { get; set; }
        public string BlockReason { get; set; } = string.Empty;
    }
}