const crypto = require('crypto');

// Test password hashing to match FabOSAuthenticationService.VerifyPassword method
function verifyPassword(password, hashBase64, saltBase64) {
    try {
        // Convert base64 to buffers
        const saltBuffer = Buffer.from(saltBase64, 'base64');
        const storedHashBuffer = Buffer.from(hashBase64, 'base64');
        
        // Create HMACSHA512 with salt as key
        const hmac = crypto.createHmac('sha512', saltBuffer);
        hmac.update(password, 'utf8');
        const computedHash = hmac.digest();
        
        // Compare hashes
        const match = computedHash.equals(storedHashBuffer);
        
        console.log('Password:', password);
        console.log('Salt (Base64):', saltBase64);
        console.log('Stored Hash (Base64):', hashBase64);
        console.log('Computed Hash (Base64):', computedHash.toString('base64'));
        console.log('Match:', match ? '✅ YES' : '❌ NO');
        
        return match;
    } catch (error) {
        console.error('Error:', error.message);
        return false;
    }
}

// Test with the values from our SQL script
console.log('Testing Admin@123 password hash...\n');

const testSalt = 'Yw7DnUwhRJW8L8PGnCKz6g==';
const testHash = 'J3e0NrXLVdgr8BxRD2PH5tOKF9zVGp8cRNXBvZ+A9RTDj7gVGXN9FnYjRUkHQmvGCjc4GpBPXNgqwXg4ZyHEVg==';

verifyPassword('Admin@123', testHash, testSalt);

console.log('\n--- Generating fresh hash for verification ---\n');

// Generate a fresh hash to show the process
const password = 'Admin@123';
const salt = crypto.randomBytes(16);
const hmac = crypto.createHmac('sha512', salt);
hmac.update(password, 'utf8');
const hash = hmac.digest();

console.log('Fresh Salt (Base64):', salt.toString('base64'));
console.log('Fresh Hash (Base64):', hash.toString('base64'));
console.log('\nSQL Update:');
console.log(`UPDATE Users SET PasswordSalt = '${salt.toString('base64')}', PasswordHash = '${hash.toString('base64')}' WHERE Email = 'admin@steelestimation.com';`);