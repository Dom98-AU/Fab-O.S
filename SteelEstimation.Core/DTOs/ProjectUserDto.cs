namespace SteelEstimation.Core.DTOs;

public class ProjectUserDto
{
    public int UserId { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string AccessLevel { get; set; } = string.Empty;
    public DateTime GrantedDate { get; set; }
    public string? GrantedByName { get; set; }
}