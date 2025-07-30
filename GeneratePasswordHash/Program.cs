using System;
using System.Security.Cryptography;
using Microsoft.AspNetCore.Cryptography.KeyDerivation;

class Program
{
    static void Main()
    {
        string password = "Admin@123";
        
        // Generate a 128-bit salt (16 bytes)
        byte[] salt = new byte[128 / 8];
        using (var rng = RandomNumberGenerator.Create())
        {
            rng.GetBytes(salt);
        }
        
        // Derive a 256-bit subkey (use HMACSHA256 with 100,000 iterations)
        string hashed = Convert.ToBase64String(KeyDerivation.Pbkdf2(
            password: password,
            salt: salt,
            prf: KeyDerivationPrf.HMACSHA256,
            iterationCount: 100000,
            numBytesRequested: 256 / 8));
        
        // Combine salt and hash
        string finalHash = $"{Convert.ToBase64String(salt)}.{hashed}";
        
        Console.WriteLine($"Password: {password}");
        Console.WriteLine($"Hash: {finalHash}");
        Console.WriteLine();
        Console.WriteLine("SQL to update admin user:");
        Console.WriteLine($@"UPDATE Users 
SET PasswordHash = '{finalHash}'
WHERE Email = 'admin@steelestimation.com';");
    }
}