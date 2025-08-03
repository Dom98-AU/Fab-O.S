const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🚀 Testing DiceBear URL Generation...\n');
  
  // Track all HTTP requests
  const requests = [];
  page.on('request', request => {
    if (request.url().includes('dicebear')) {
      requests.push(request.url());
    }
  });
  
  // Track responses
  const responses = [];
  page.on('response', response => {
    if (response.url().includes('dicebear')) {
      responses.push({
        url: response.url(),
        status: response.status(),
        contentType: response.headers()['content-type'] || 'unknown'
      });
    }
  });
  
  try {
    // Login quickly
    await page.goto('http://localhost:8080/Account/Login');
    await page.waitForLoadState('networkidle');
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    await page.waitForLoadState('networkidle');
    
    // Go to profile and open avatar editor
    await page.goto('http://localhost:8080/profile');
    await page.waitForLoadState('networkidle');
    await page.click('button:has-text("Edit Profile")');
    await page.waitForTimeout(2000);
    
    // Click Bottts style
    console.log('🤖 Clicking Bottts style...');
    await page.locator('.dicebear-style-option:has(.style-name:text("Bottts"))').first().click();
    
    // Wait for requests to be made
    await page.waitForTimeout(10000);
    
    console.log('\n🌐 DiceBear API Requests:');
    console.log(`Total requests: ${requests.length}`);
    
    if (requests.length > 0) {
      console.log('\nFirst 5 request URLs:');
      requests.slice(0, 5).forEach((url, i) => {
        console.log(`  ${i + 1}. ${url}`);
      });
      
      console.log('\nURL Analysis:');
      console.log(`  Using 9.x API: ${requests[0].includes('/9.x/') ? '✅' : '❌'}`);
      console.log(`  Bottts style: ${requests[0].includes('/bottts/') ? '✅' : '❌'}`);
      console.log(`  SVG format: ${requests[0].includes('/svg') ? '✅' : '❌'}`);
      
      // Check for specific parameters
      const firstUrl = requests[0];
      console.log(`  Has eyes param: ${firstUrl.includes('eyes=') ? '✅' : '❌'}`);
      console.log(`  Has mouth param: ${firstUrl.includes('mouth=') ? '✅' : '❌'}`);
      console.log(`  Has baseColor param: ${firstUrl.includes('baseColor=') ? '✅' : '❌'}`);
    }
    
    console.log('\n📡 DiceBear API Responses:');
    console.log(`Total responses: ${responses.length}`);
    
    if (responses.length > 0) {
      console.log('\nResponse analysis:');
      const successful = responses.filter(r => r.status === 200).length;
      const failed = responses.filter(r => r.status !== 200).length;
      
      console.log(`  Successful (200): ${successful}`);
      console.log(`  Failed (non-200): ${failed}`);
      
      if (failed > 0) {
        console.log('\nFailed responses:');
        responses.filter(r => r.status !== 200).forEach((response, i) => {
          console.log(`  ${i + 1}. Status: ${response.status} - ${response.url.substring(0, 100)}...`);
        });
      }
      
      // Check content types
      const svgResponses = responses.filter(r => r.contentType.includes('svg')).length;
      console.log(`  SVG content responses: ${svgResponses}`);
    }
    
    // Test a specific DiceBear URL manually
    console.log('\n🧪 Testing a manual DiceBear URL...');
    const testUrl = 'https://api.dicebear.com/9.x/bottts/svg?seed=test&eyes=eva&mouth=smile01&baseColor=0E7490';
    console.log(`Test URL: ${testUrl}`);
    
    try {
      const testResponse = await page.goto(testUrl);
      console.log(`Manual test status: ${testResponse?.status()}`);
      
      // Check if it's SVG content
      const content = await page.content();
      console.log(`Is SVG: ${content.includes('<svg') ? '✅' : '❌'}`);
      
      if (content.includes('<svg')) {
        console.log('✅ Manual DiceBear URL works correctly!');
      }
    } catch (error) {
      console.log(`❌ Manual test failed: ${error.message}`);
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  
  console.log('\n✅ Test complete. Browser will remain open for 30 seconds...');
  await page.waitForTimeout(30000);
  await browser.close();
})();