const crypto = require('crypto');

// Test password verification matching FabOSAuthenticationService.VerifyPassword
function verifyPassword(password, hashBase64, saltBase64) {
    try {
        const saltBuffer = Buffer.from(saltBase64, 'base64');
        const hmac = crypto.createHmac('sha512', saltBuffer);
        hmac.update(password, 'utf8');
        const computedHash = hmac.digest();
        const computedHashBase64 = computedHash.toString('base64');
        
        console.log('Testing password verification:');
        console.log('==================================');
        console.log('Password:', password);
        console.log('Salt (Base64):', saltBase64);
        console.log('Stored Hash:', hashBase64);
        console.log('Computed Hash:', computedHashBase64);
        console.log('Match:', hashBase64 === computedHashBase64 ? '✅ YES' : '❌ NO');
        
        return hashBase64 === computedHashBase64;
    } catch (error) {
        console.error('Error:', error.message);
        return false;
    }
}

// Test with our admin user credentials
const adminSalt = 'nsYnK4MNzdfPHSCR3MbQnQ==';
const adminHash = 'QLl0gbsufEANZI3gpGe+qfEoQ+GER6+lom/s/IL5XajgxXJC0qNsLa1qZt6fqKT3TrcFARkDi4bh7j02bnSEsA==';
const adminPassword = 'Admin@123';

console.log('Verifying admin@steelestimation.com password...\n');
const isValid = verifyPassword(adminPassword, adminHash, adminSalt);

if (!isValid) {
    console.log('\n❌ Password verification failed!');
    console.log('The hash/salt combination does not match the password.');
    console.log('\nThis means either:');
    console.log('1. The password hash in the database is incorrect');
    console.log('2. The FabOSAuthenticationService verification logic has an issue');
} else {
    console.log('\n✅ Password verification successful!');
    console.log('The hash/salt combination correctly verifies the password.');
}