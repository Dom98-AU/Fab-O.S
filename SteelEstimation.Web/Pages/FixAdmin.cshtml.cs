using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using SteelEstimation.Core.Entities;
using SteelEstimation.Infrastructure.Data;
using System.Security.Cryptography;
using System.Text;

namespace SteelEstimation.Web.Pages
{
    public class FixAdminModel : PageModel
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<FixAdminModel> _logger;

        public string? Message { get; set; }
        public bool Success { get; set; }

        public FixAdminModel(ApplicationDbContext context, ILogger<FixAdminModel> logger)
        {
            _context = context;
            _logger = logger;
        }

        public void OnGet()
        {
            Message = "Click the button to fix the admin user account.";
        }

        public async Task<IActionResult> OnPostAsync()
        {
            try
            {
                // Check if admin user exists
                var adminUser = await _context.Users
                    .Include(u => u.Company)
                    .FirstOrDefaultAsync(u => u.Email == "admin@steelestimation.com");

                if (adminUser == null)
                {
                    // Create company if needed
                    var company = await _context.Companies.FirstOrDefaultAsync(c => c.Name == "NWI Group");
                    if (company == null)
                    {
                        company = new Company
                        {
                            Name = "NWI Group",
                            Code = "NWI",
                            IsActive = true,
                            CreatedDate = DateTime.UtcNow
                        };
                        _context.Companies.Add(company);
                        await _context.SaveChangesAsync();
                    }

                    // Create admin user
                    adminUser = new User
                    {
                        Username = "admin",
                        Email = "admin@steelestimation.com",
                        FirstName = "System",
                        LastName = "Administrator",
                        CompanyId = company.Id,
                        IsActive = true,
                        IsEmailConfirmed = true,
                        AuthProvider = "Local",
                        CreatedDate = DateTime.UtcNow
                    };
                    _context.Users.Add(adminUser);
                }

                // Generate password hash using HMACSHA512 (matching FabOSAuthenticationService)
                var password = "Admin@123";
                
                // Generate salt (16 bytes random)
                var buffer = new byte[16];
                using (var rng = System.Security.Cryptography.RandomNumberGenerator.Create())
                {
                    rng.GetBytes(buffer);
                }
                var salt = Convert.ToBase64String(buffer);
                
                // Hash password with salt as the HMAC key
                var saltBytes = Convert.FromBase64String(salt);
                using var hmac = new HMACSHA512(saltBytes);
                var hash = Convert.ToBase64String(hmac.ComputeHash(Encoding.UTF8.GetBytes(password)));

                // Update user
                adminUser.PasswordHash = hash;
                adminUser.PasswordSalt = salt;
                adminUser.IsActive = true;
                adminUser.IsEmailConfirmed = true;
                adminUser.AuthProvider = "Local";

                await _context.SaveChangesAsync();

                // Ensure admin role exists and is assigned
                var adminRole = await _context.Roles.FirstOrDefaultAsync(r => r.RoleName == "Administrator");
                if (adminRole != null)
                {
                    var userRole = await _context.UserRoles
                        .FirstOrDefaultAsync(ur => ur.UserId == adminUser.Id && ur.RoleId == adminRole.Id);
                    
                    if (userRole == null)
                    {
                        _context.UserRoles.Add(new UserRole
                        {
                            UserId = adminUser.Id,
                            RoleId = adminRole.Id
                        });
                        await _context.SaveChangesAsync();
                    }
                }

                Message = "Admin user has been successfully fixed!";
                Success = true;
                _logger.LogInformation("Admin user fixed with new password hash");
            }
            catch (Exception ex)
            {
                Message = $"Error: {ex.Message}";
                Success = false;
                _logger.LogError(ex, "Failed to fix admin user");
            }

            return Page();
        }
    }
}