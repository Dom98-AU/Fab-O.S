const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
  
  console.log('🤖 Testing Bottts Customization Issues...\n');
  
  // Monitor console errors
  page.on('console', msg => {
    if (msg.type() === 'error') {
      console.log('❌ Console Error:', msg.text());
    }
  });
  
  // Monitor page reloads
  let reloadCount = 0;
  page.on('load', () => {
    reloadCount++;
    if (reloadCount > 1) {
      console.log('⚠️  Page reloaded! Count:', reloadCount);
    }
  });
  
  try {
    // Login
    console.log('📍 Logging in...');
    await page.goto('http://localhost:8080/Account/Login');
    await page.waitForLoadState('networkidle');
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    await page.waitForLoadState('networkidle');

    // Navigate to profile
    await page.goto('http://localhost:8080/profile');
    await page.waitForLoadState('networkidle');
    await page.click('button:has-text("Edit Profile")');
    await page.waitForTimeout(2000);
    
    // Select Bottts
    console.log('\n🤖 Selecting Bottts style...');
    const bottts = page.locator('.dicebear-style-option:has(.style-name:text("Bottts"))').first();
    await bottts.click();
    await page.waitForTimeout(3000);
    
    // Check preview images
    console.log('\n🔍 Checking Eye Type Preview Images...');
    const eyePreviews = await page.locator('.visual-option-btn').filter({ hasText: /eva|robocop|round/ }).all();
    
    for (let i = 0; i < Math.min(3, eyePreviews.length); i++) {
      const preview = eyePreviews[i];
      const img = await preview.locator('img').first();
      
      if (await img.count() > 0) {
        const src = await img.getAttribute('src');
        const alt = await img.getAttribute('alt');
        const naturalWidth = await img.evaluate(el => el.naturalWidth);
        
        console.log(`\nEye Preview ${i + 1} (${alt}):`);
        console.log(`  Image source type: ${src?.startsWith('data:image/svg') ? 'SVG Data URL' : src?.startsWith('http') ? 'HTTP URL' : 'Other'}`);
        console.log(`  Natural width: ${naturalWidth}px`);
        console.log(`  Source length: ${src?.length || 0} chars`);
        
        // Check if it's actually showing robot parts
        if (src?.includes('data:image/svg')) {
          const hasRobotParts = src.includes('robot') || src.includes('eye') || src.includes('circle') || src.includes('rect');
          console.log(`  Contains robot SVG elements: ${hasRobotParts ? '✅' : '❌'}`);
        }
      }
    }
    
    // Test color selection
    console.log('\n🎨 Testing Color Selection...');
    const colorSwatches = await page.locator('.color-swatch').all();
    console.log(`Found ${colorSwatches.length} color swatches`);
    
    if (colorSwatches.length > 0) {
      const firstColor = colorSwatches[0];
      const colorStyle = await firstColor.getAttribute('style');
      console.log(`First color style: ${colorStyle}`);
      
      console.log('\nClicking first color...');
      await firstColor.click();
      await page.waitForTimeout(2000);
      
      // Check if color was applied
      const activeColor = await page.locator('.color-swatch.active').count();
      console.log(`Active color swatch found: ${activeColor > 0 ? '✅' : '❌'}`);
    }
    
    // Test clicking customization option
    console.log('\n👆 Testing Customization Click...');
    const currentUrl = page.url();
    console.log(`Current URL before click: ${currentUrl}`);
    
    const firstEyeOption = page.locator('.visual-option-btn').first();
    console.log('Clicking first eye option...');
    await firstEyeOption.click();
    await page.waitForTimeout(2000);
    
    const newUrl = page.url();
    console.log(`URL after click: ${newUrl}`);
    console.log(`Page changed: ${currentUrl !== newUrl ? '❌ YES (BAD!)' : '✅ NO (GOOD!)'}`);
    
    // Check the form structure
    console.log('\n📋 Checking Form Structure...');
    const form = await page.locator('form').first();
    const formAction = await form.getAttribute('action');
    const formMethod = await form.getAttribute('method');
    console.log(`Form action: ${formAction || 'none'}`);
    console.log(`Form method: ${formMethod || 'none'}`);
    
    // Check if buttons are inside form
    const buttonInForm = await page.locator('form .visual-option-btn').count();
    console.log(`Customization buttons inside form: ${buttonInForm > 0 ? '⚠️  YES' : '✅ NO'}`);
    
    // Take screenshot
    await page.screenshot({ path: 'bottts-customization-debug.png', fullPage: true });
    console.log('\n📸 Screenshot saved: bottts-customization-debug.png');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  
  console.log('\nBrowser will remain open for 30 seconds...');
  await page.waitForTimeout(30000);
  await browser.close();
})();