// Test FabOS Authentication
const http = require('http');

async function testLogin() {
    console.log('Testing FabOS Authentication...\n');
    
    // First get the login page to extract the verification token
    const getOptions = {
        hostname: 'localhost',
        port: 8080,
        path: '/Account/Login',
        method: 'GET'
    };
    
    const tokenPromise = new Promise((resolve, reject) => {
        const req = http.request(getOptions, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                const match = data.match(/name="__RequestVerificationToken".*?value="([^"]+)"/);
                if (match) {
                    resolve(match[1]);
                } else {
                    reject('Token not found');
                }
            });
        });
        req.on('error', reject);
        req.end();
    });
    
    try {
        const token = await tokenPromise;
        console.log('✓ Got verification token');
        
        // Now submit the login form
        const postData = new URLSearchParams({
            'Input.Email': 'admin@steelestimation.com',
            'Input.Password': 'Admin@123',
            '__RequestVerificationToken': token
        }).toString();
        
        const postOptions = {
            hostname: 'localhost',
            port: 8080,
            path: '/Account/Login',
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Content-Length': Buffer.byteLength(postData)
            }
        };
        
        const loginPromise = new Promise((resolve, reject) => {
            const req = http.request(postOptions, (res) => {
                console.log('\nResponse Status:', res.statusCode);
                console.log('Response Headers:', res.headers);
                
                let data = '';
                res.on('data', (chunk) => data += chunk);
                res.on('end', () => {
                    if (res.statusCode === 302 || res.statusCode === 200) {
                        if (res.headers.location) {
                            console.log('✓ Login successful - Redirect to:', res.headers.location);
                        } else if (data.includes('Invalid')) {
                            console.log('✗ Login failed - Invalid credentials');
                            console.log('\nChecking for error messages...');
                            const errorMatch = data.match(/class="text-danger[^>]*>([^<]+)</g);
                            if (errorMatch) {
                                errorMatch.forEach(err => console.log('  Error:', err));
                            }
                        } else {
                            console.log('✓ Login response received');
                        }
                    }
                    resolve(data);
                });
            });
            req.on('error', reject);
            req.write(postData);
            req.end();
        });
        
        await loginPromise;
        
    } catch (error) {
        console.error('Error:', error);
    }
}

testLogin();