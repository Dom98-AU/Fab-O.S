using System;
using System.Security.Cryptography;
using System.Text;

public class PasswordHashGenerator
{
    public static void Main()
    {
        string password = "Admin@123";
        
        // Generate salt
        var saltBytes = new byte[16];
        using (var rng = RandomNumberGenerator.Create())
        {
            rng.GetBytes(saltBytes);
        }
        
        // Compute hash
        using (var hmac = new HMACSHA512(saltBytes))
        {
            var hashBytes = hmac.ComputeHash(Encoding.UTF8.GetBytes(password));
            
            // Convert to base64
            string salt = Convert.ToBase64String(saltBytes);
            string hash = Convert.ToBase64String(hashBytes);
            
            Console.WriteLine($"Password: {password}");
            Console.WriteLine($"Salt (Base64): {salt}");
            Console.WriteLine($"Hash (Base64): {hash}");
            Console.WriteLine();
            Console.WriteLine("SQL Update Statement:");
            Console.WriteLine($"UPDATE Users SET PasswordSalt = '{salt}', PasswordHash = '{hash}' WHERE Email = 'admin@steelestimation.com';");
        }
    }
}