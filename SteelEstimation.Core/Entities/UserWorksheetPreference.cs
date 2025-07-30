namespace SteelEstimation.Core.Entities;

public class UserWorksheetPreference
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string BaseType { get; set; } = string.Empty; // "Processing" or "Welding"
    public int TemplateId { get; set; }
    
    // Navigation properties
    public User User { get; set; } = null!;
    public WorksheetTemplate Template { get; set; } = null!;
}