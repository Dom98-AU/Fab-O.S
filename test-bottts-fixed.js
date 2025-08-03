const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
  
  console.log('🤖 Testing Fixed Bottts Customization...\n');
  
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
    console.log('\n🤖 Selecting Robot Avatar...');
    const bottts = page.locator('.dicebear-style-option:has(.style-name:text("Robot Avatar"))').first();
    await bottts.click();
    await page.waitForTimeout(1000);
    
    // Click Customize tab
    await page.locator('button:has-text("Customize")').click();
    await page.waitForTimeout(1000);
    
    // Check what customization options are available
    console.log('\n🔍 Checking available customization options...');
    
    // Check for removed options
    const hasPrimaryColor = await page.locator('label:has-text("Primary Color")').count() > 0;
    const hasSides = await page.locator('label:has-text("Sides")').count() > 0;
    const hasTexture = await page.locator('label:has-text("Texture")').count() > 0;
    
    console.log(`Primary Color option: ${hasPrimaryColor ? '❌ Still present' : '✅ Removed'}`);
    console.log(`Sides option: ${hasSides ? '❌ Still present' : '✅ Removed'}`);
    console.log(`Texture option: ${hasTexture ? '❌ Still present' : '✅ Removed'}`);
    
    // Check for existing options
    const hasBackgroundColor = await page.locator('label:has-text("Background Color")').count() > 0;
    const hasEyeType = await page.locator('label:has-text("Eye Type")').count() > 0;
    const hasMouthType = await page.locator('label:has-text("Mouth Type")').count() > 0;
    
    console.log(`\nBackground Color option: ${hasBackgroundColor ? '✅ Present' : '❌ Missing'}`);
    console.log(`Eye Type option: ${hasEyeType ? '✅ Present' : '❌ Missing'}`);
    console.log(`Mouth Type option: ${hasMouthType ? '✅ Present' : '❌ Missing'}`);
    
    // Check for the note about fixed colors
    const noteAboutColors = await page.locator('small:has-text("Robot body colors are fixed")').count() > 0;
    console.log(`\nNote about fixed colors: ${noteAboutColors ? '✅ Present' : '❌ Missing'}`);
    
    // Test background color change
    console.log('\n🎨 Testing background color change...');
    const colorSwatches = await page.locator('.color-swatch').all();
    if (colorSwatches.length > 1) {
      // Click second color swatch (first is transparent)
      await colorSwatches[1].click();
      await page.waitForTimeout(1000);
      console.log('Background color changed');
    }
    
    // Take screenshot
    await page.screenshot({ path: 'bottts-fixed-customization.png', fullPage: true });
    console.log('\n📸 Screenshot saved: bottts-fixed-customization.png');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  
  console.log('\nTest complete. Browser will remain open for 10 seconds...');
  await page.waitForTimeout(10000);
  await browser.close();
})();