const http = require('http');
const https = require('https');

console.log('Testing connection to Steel Estimation Platform...\n');

// Test HTTP on port 8080
function testHttp() {
  return new Promise((resolve) => {
    const options = {
      hostname: 'localhost',
      port: 8080,
      path: '/',
      method: 'GET',
      timeout: 5000
    };

    const req = http.request(options, (res) => {
      console.log(`HTTP (port 8080) - Status Code: ${res.statusCode}`);
      console.log(`HTTP - Headers:`, res.headers);
      
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log(`HTTP - Response body (first 500 chars):`);
        console.log(data.substring(0, 500));
        resolve();
      });
    });

    req.on('error', (error) => {
      console.log(`HTTP (port 8080) - Error: ${error.message}`);
      resolve();
    });

    req.on('timeout', () => {
      console.log('HTTP (port 8080) - Request timed out');
      req.destroy();
      resolve();
    });

    req.end();
  });
}

// Test HTTPS on port 5001
function testHttps() {
  return new Promise((resolve) => {
    const options = {
      hostname: 'localhost',
      port: 5001,
      path: '/',
      method: 'GET',
      timeout: 5000,
      rejectUnauthorized: false // Allow self-signed certificates
    };

    const req = https.request(options, (res) => {
      console.log(`\nHTTPS (port 5001) - Status Code: ${res.statusCode}`);
      console.log(`HTTPS - Headers:`, res.headers);
      
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log(`HTTPS - Response body (first 500 chars):`);
        console.log(data.substring(0, 500));
        resolve();
      });
    });

    req.on('error', (error) => {
      console.log(`\nHTTPS (port 5001) - Error: ${error.message}`);
      resolve();
    });

    req.on('timeout', () => {
      console.log('\nHTTPS (port 5001) - Request timed out');
      req.destroy();
      resolve();
    });

    req.end();
  });
}

// Test both endpoints
async function runTests() {
  await testHttp();
  await testHttps();
  
  console.log('\n=== Connection Test Summary ===');
  console.log('Please check if the application is running on either port 8080 (HTTP) or 5001 (HTTPS)');
  console.log('According to the documentation, the application should be accessible at https://localhost:5001');
}

runTests();