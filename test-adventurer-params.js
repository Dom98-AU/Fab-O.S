const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🔍 Testing Adventurer Parameters...\n');
  
  // Test different parameter values to find what works
  const testParams = [
    // Test 1: No parameters (should work)
    '',
    // Test 2: Common parameter names
    'eyes=default',
    'eyes=happy',
    'hair=short',
    'hair=long',
    'mouth=smile',
    'mouth=happy',
    // Test 3: Numbered variants
    'eyes=variant01',
    'eyes=variant1',
    'eyes=1',
    // Test 4: Multiple parameters
    'eyes=default&mouth=smile',
    'hair=short&eyes=happy',
  ];
  
  for (let i = 0; i < testParams.length; i++) {
    const params = testParams[i];
    const baseUrl = 'https://api.dicebear.com/9.x/adventurer/svg?seed=test';
    const fullUrl = params ? `${baseUrl}&${params}` : baseUrl;
    
    console.log(`\nTest ${i + 1}: ${params || '(no parameters)'}`);
    console.log(`URL: ${fullUrl}`);
    
    try {
      const response = await fetch(fullUrl);
      console.log(`Status: ${response.status} ${response.statusText}`);
      
      if (response.ok) {
        const content = await response.text();
        console.log(`✅ Success - Content length: ${content.length}`);
        
        // For successful requests, save a sample
        if (i === 0) {
          console.log(`Sample content: ${content.substring(0, 200)}...`);
        }
      } else {
        const errorText = await response.text();
        console.log(`❌ Failed - Error: ${errorText.substring(0, 100)}`);
      }
    } catch (error) {
      console.log(`❌ Network error: ${error.message}`);
    }
  }
  
  console.log('\n📋 Summary: Looking at the results above, we can determine which parameter values are valid for Adventurer style.');
  
  await browser.close();
})();