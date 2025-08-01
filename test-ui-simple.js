const http = require('http');
const fs = require('fs');

async function makeRequest(url, options = {}) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    
    const req = http.request(url, options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ 
        statusCode: res.statusCode, 
        headers: res.headers, 
        body: data 
      }));
    });
    
    req.on('error', reject);
    if (options.body) req.write(options.body);
    req.end();
  });
}

async function testSteelEstimationUI() {
  console.log('Testing Steel Estimation Platform UI...\n');
  
  const baseUrl = 'http://localhost:8080';
  
  try {
    // 1. Test homepage
    console.log('1. Testing homepage...');
    const homepage = await makeRequest(baseUrl);
    console.log(`   Status: ${homepage.statusCode}`);
    
    if (homepage.statusCode === 200) {
      console.log('   ✅ Homepage loads successfully');
      
      // Check if it's a login page
      if (homepage.body.includes('Login') || homepage.body.includes('Sign in')) {
        console.log('   📋 Login page detected');
      }
      
      // Save homepage HTML for inspection
      fs.writeFileSync('login-page.html', homepage.body);
      console.log('   💾 Saved login page HTML');
    }
    
    // 2. Test various endpoints
    console.log('\n2. Testing endpoints...');
    const endpoints = ['/health', '/Account/Login'];
    
    for (const endpoint of endpoints) {
      const response = await makeRequest(baseUrl + endpoint);
      console.log(`   ${endpoint}: ${response.statusCode}`);
    }
    
    console.log('\n✅ UI test completed\!');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testSteelEstimationUI();
EOF < /dev/null
