const crypto = require('crypto');

// Generate password hash in the format expected by AuthenticationService
// Format: {base64(salt)}.{base64(hash)}

function hashPassword(password) {
    // Generate a 128-bit salt (16 bytes)
    const salt = crypto.randomBytes(16);
    
    // Derive a 256-bit key using PBKDF2 with HMACSHA256
    const iterations = 100000;
    const keyLength = 32; // 256 bits / 8
    const hash = crypto.pbkdf2Sync(password, salt, iterations, keyLength, 'sha256');
    
    // Combine salt and hash with a dot
    const saltBase64 = salt.toString('base64');
    const hashBase64 = hash.toString('base64');
    const combined = `${saltBase64}.${hashBase64}`;
    
    console.log('Password:', password);
    console.log('Salt (Base64):', saltBase64);
    console.log('Hash (Base64):', hashBase64);
    console.log('Combined:', combined);
    console.log('\nSQL Update:');
    console.log(`UPDATE dbo.Users SET PasswordHash = '${combined}' WHERE Email = 'admin@steelestimation.com';`);
    
    return combined;
}

// Generate hash for Admin@123
hashPassword('Admin@123');