#!/usr/bin/env dotnet-script
using System;
using System.Security.Cryptography;
using System.Text;

// Generate password hash for Admin@123
string password = "Admin@123";

// Generate salt
byte[] salt = new byte[16];
using (var rng = RandomNumberGenerator.Create())
{
    rng.GetBytes(salt);
}

// Generate hash using PBKDF2 with HMACSHA256 (matching the application)
using (var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 10000, HashAlgorithmName.SHA256))
{
    byte[] hash = pbkdf2.GetBytes(32); // 256 bits
    
    string saltBase64 = Convert.ToBase64String(salt);
    string hashBase64 = Convert.ToBase64String(hash);
    
    Console.WriteLine("Password Hash Generation for Admin@123");
    Console.WriteLine("=====================================");
    Console.WriteLine($"Salt (Base64): {saltBase64}");
    Console.WriteLine($"Hash (Base64): {hashBase64}");
    Console.WriteLine();
    Console.WriteLine("SQL Update Statement:");
    Console.WriteLine("---------------------");
    Console.WriteLine($@"UPDATE Users 
SET PasswordHash = '{hashBase64}',
    PasswordSalt = '{saltBase64}',
    IsActive = 1,
    IsEmailConfirmed = 1
WHERE Email = 'admin@steelestimation.com';");
}