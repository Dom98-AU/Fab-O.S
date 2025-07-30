namespace SteelEstimation.Core.Interfaces;

public interface IEmailService
{
    Task SendEmailAsync(string to, string subject, string body, bool isHtml = true);
    Task SendEmailAsync(string[] to, string subject, string body, bool isHtml = true);
    Task SendWelcomeEmailAsync(string to, string firstName, string temporaryPassword);
    Task SendPasswordResetEmailAsync(string to, string resetToken);
    Task SendEmailConfirmationAsync(string to, string confirmationToken);
}