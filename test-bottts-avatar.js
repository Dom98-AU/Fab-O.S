const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🚀 Testing Bottts Avatar Style...\n');
  
  try {
    // Navigate to login page
    console.log('📍 Logging in...');
    await page.goto('http://localhost:8080/Account/Login');
    await page.waitForLoadState('networkidle');
    
    // Login
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);
    
    // Navigate to profile
    console.log('👤 Navigating to profile...');
    await page.goto('http://localhost:8080/profile');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);
    
    // Click Edit Profile button
    console.log('✏️ Clicking Edit Profile...');
    await page.click('button:has-text("Edit Profile")');
    await page.waitForTimeout(2000);
    
    // Look for Bottts style specifically
    console.log('\n🤖 Looking for Bottts style...');
    
    // Find all style options and look for Bottts
    const styleOptions = await page.locator('.dicebear-style-option').all();
    let botttsFound = false;
    
    for (let i = 0; i < styleOptions.length; i++) {
      const styleName = await styleOptions[i].locator('.style-name').textContent();
      console.log(`  Style ${i + 1}: ${styleName}`);
      
      if (styleName && styleName.toLowerCase() === 'bottts') {
        console.log('\n✅ Found Bottts! Clicking it...');
        await styleOptions[i].click();
        botttsFound = true;
        break;
      }
    }
    
    if (botttsFound) {
      // Wait for customization to load
      await page.waitForTimeout(5000);
      
      // Check for customization sections
      console.log('\n🎨 Checking Bottts customization sections...');
      
      const eyesSection = await page.locator('text="Eyes"').count();
      const mouthSection = await page.locator('text="Mouth"').count();
      const sidesSection = await page.locator('text="Sides"').count();
      const faceSection = await page.locator('text="Face Shape"').count();
      const topSection = await page.locator('text="Top Accessories"').count();
      
      console.log(`  Eyes section: ${eyesSection > 0 ? '✅' : '❌'}`);
      console.log(`  Mouth section: ${mouthSection > 0 ? '✅' : '❌'}`);
      console.log(`  Sides section: ${sidesSection > 0 ? '✅' : '❌'}`);
      console.log(`  Face Shape section: ${faceSection > 0 ? '✅' : '❌'}`);
      console.log(`  Top Accessories section: ${topSection > 0 ? '✅' : '❌'}`);
      
      // Check for preview images
      console.log('\n🖼️ Checking preview images...');
      
      const previewWrappers = await page.locator('.dicebear-preview-wrapper').count();
      console.log(`Preview wrappers: ${previewWrappers}`);
      
      const loadedImages = await page.locator('.dicebear-preview-wrapper img').count();
      console.log(`Loaded images: ${loadedImages}`);
      
      const spinners = await page.locator('.dicebear-preview-wrapper .spinner-border').count();
      console.log(`Loading spinners: ${spinners}`);
      
      const errors = await page.locator('.preview-error').count();
      console.log(`Error states: ${errors}`);
      
      // Check specific preview types
      const eyePreviews = await page.locator('.visual-option-btn img[alt*="eva"], .visual-option-btn img[alt*="dizzy"]').count();
      console.log(`Eye type previews: ${eyePreviews}`);
      
      // Take screenshot
      await page.screenshot({ path: 'bottts-customization.png', fullPage: true });
      console.log('\n📸 Screenshot saved: bottts-customization.png');
    } else {
      console.log('\n❌ Bottts style not found!');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    await page.screenshot({ path: 'bottts-error.png' });
  }
  
  console.log('\n✅ Test complete. Browser will remain open for 30 seconds...');
  await page.waitForTimeout(30000);
  await browser.close();
})();