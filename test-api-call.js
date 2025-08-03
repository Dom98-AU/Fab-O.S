const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🔍 Testing Direct DiceBear API Call for Adventurer...\n');
  
  // Test 1: Direct API call
  console.log('1. Testing direct API call to DiceBear Adventurer...');
  const testUrl = 'https://api.dicebear.com/9.x/adventurer/svg?seed=test&eyes=variant01&hair=variant01&mouth=variant01';
  
  try {
    const response = await fetch(testUrl);
    console.log(`   API Response: ${response.status} ${response.statusText}`);
    
    if (response.ok) {
      const svgContent = await response.text();
      console.log(`   Response type: ${response.headers.get('content-type')}`);
      console.log(`   SVG Content length: ${svgContent.length}`);
      console.log(`   Is valid SVG: ${svgContent.includes('<svg') ? '✅' : '❌'}`);
      
      // Create data URL
      const encodedSvg = encodeURIComponent(svgContent);
      const dataUrl = `data:image/svg+xml,${encodedSvg}`;
      console.log(`   Data URL length: ${dataUrl.length}`);
      console.log(`   Data URL preview: ${dataUrl.substring(0, 100)}...`);
    }
  } catch (error) {
    console.log(`   ❌ API call failed: ${error.message}`);
  }
  
  // Test 2: App version
  console.log('\n2. Testing app avatar generation...');
  try {
    await page.goto('http://localhost:8080/Account/Login');
    await page.waitForLoadState('networkidle');
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    await page.waitForLoadState('networkidle');

    await page.goto('http://localhost:8080/profile');
    await page.waitForLoadState('networkidle');
    await page.click('button:has-text("Edit Profile")');
    await page.waitForTimeout(2000);
    
    // Click Adventurer
    const adventurerLocator = page.locator('.dicebear-style-option:has(.style-name:text("Adventurer"))').first();
    await adventurerLocator.click();
    await page.waitForTimeout(5000);
    
    // Check if main avatar loads
    const avatarImg = page.locator('.avatar-preview').first();
    const avatarSrc = await avatarImg.getAttribute('src');
    
    console.log(`   Avatar src type: ${avatarSrc ? (avatarSrc.startsWith('data:') ? 'Data URL' : 'HTTP URL') : 'No src'}`);
    if (avatarSrc && avatarSrc.startsWith('data:')) {
      console.log(`   Avatar data URL length: ${avatarSrc.length}`);
      console.log(`   Avatar preview: ${avatarSrc.substring(0, 100)}...`);
    } else if (avatarSrc) {
      console.log(`   Avatar URL: ${avatarSrc}`);
    }
    
    // Check what the container logs are saying
    console.log('\n3. Recent console activity (check Docker logs for more details)');
    
  } catch (error) {
    console.error('❌ App test error:', error.message);
  }
  
  console.log('\n✅ API test complete!');
  await page.waitForTimeout(10000);
  await browser.close();
})();