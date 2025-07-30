namespace SteelEstimation.Core.Configuration;

public class TimeTrackerSettings
{
    public bool Enabled { get; set; } = true;
    public bool ShowTimer { get; set; } = true;
    public bool ShowExpectedTime { get; set; } = true;
    public bool ShowOvertime { get; set; } = true;
    public double OvertimeWarningThreshold { get; set; } = 0.9; // 90% of estimated time
    public int InactivityTimeoutMinutes { get; set; } = 5;
}