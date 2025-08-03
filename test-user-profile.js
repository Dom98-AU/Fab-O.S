const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🚀 Testing User Profile Avatar System...\n');
  
  try {
    // Navigate and login
    console.log('📍 Navigating to application...');
    await page.goto('http://localhost:8080');
    await page.waitForLoadState('networkidle');
    
    const currentUrl = page.url();
    console.log(`Current URL: ${currentUrl}`);
    
    // Login if needed
    if (currentUrl.includes('login') || currentUrl.includes('Login')) {
      console.log('🔐 Logging in...');
      
      // Try username or email field
      const usernameField = await page.locator('input[name="Input.Username"], input[placeholder*="username" i]').first();
      const passwordField = await page.locator('input[type="password"]').first();
      
      if (await usernameField.isVisible()) {
        await usernameField.fill('admin@steelestimation.com');
      }
      
      if (await passwordField.isVisible()) {
        await passwordField.fill('Admin@123');
      }
      
      const submitButton = await page.locator('button[type="submit"]').first();
      if (await submitButton.isVisible()) {
        await submitButton.click();
        await page.waitForLoadState('networkidle');
      }
    }
    
    // Navigate to profile page
    console.log('\n👤 Navigating to profile page...');
    await page.goto('http://localhost:8080/profile');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(3000);
    
    console.log(`Current URL after navigation: ${page.url()}`);
    
    // Check for avatar components
    console.log('\n🔍 Checking for avatar components...');
    
    const avatarSelector = await page.locator('.avatar-selector').count();
    console.log(`Avatar selector: ${avatarSelector > 0 ? '✅' : '❌'} (${avatarSelector})`);
    
    const enhancedSelector = await page.locator('.avatar-selector, [class*="enhanced-avatar"]').count();
    console.log(`Enhanced avatar selector: ${enhancedSelector > 0 ? '✅' : '❌'} (${enhancedSelector})`);
    
    const dicebearStyles = await page.locator('.dicebear-style-option, .dicebear-styles-grid').count();
    console.log(`DiceBear style options: ${dicebearStyles > 0 ? '✅' : '❌'} (${dicebearStyles})`);
    
    const previewWrappers = await page.locator('.dicebear-preview-wrapper').count();
    console.log(`Preview wrappers: ${previewWrappers > 0 ? '✅' : '❌'} (${previewWrappers})`);
    
    // Check for specific elements
    console.log('\n📋 Detailed component check:');
    
    const avatarPreview = await page.locator('.avatar-preview, .avatar-preview-container').count();
    console.log(`  Avatar preview: ${avatarPreview}`);
    
    const customizationSections = await page.locator('.customization-section').count();
    console.log(`  Customization sections: ${customizationSections}`);
    
    const botttsOption = await page.locator('text=Bottts').count();
    console.log(`  Bottts style option: ${botttsOption}`);
    
    // Check for the new parameters
    const faceOptions = await page.locator('text=Face Shape').count();
    const topOptions = await page.locator('text=Top Accessories').count();
    const rotationControl = await page.locator('text=Rotation').count();
    const scaleControl = await page.locator('text=Scale').count();
    
    console.log(`  Face Shape options: ${faceOptions > 0 ? '✅' : '❌'}`);
    console.log(`  Top Accessories: ${topOptions > 0 ? '✅' : '❌'}`);
    console.log(`  Rotation control: ${rotationControl > 0 ? '✅' : '❌'}`);
    console.log(`  Scale control: ${scaleControl > 0 ? '✅' : '❌'}`);
    
    // Take screenshot
    await page.screenshot({ path: 'user-profile-page.png', fullPage: true });
    console.log('\n📸 Screenshot saved: user-profile-page.png');
    
    // If Bottts is available, click it
    if (botttsOption > 0) {
      console.log('\n🤖 Clicking on Bottts style...');
      await page.locator('text=Bottts').first().click();
      await page.waitForTimeout(5000); // Wait for previews to load
      
      // Check preview loading status
      console.log('\n🖼️ Checking preview loading status:');
      
      const loadedPreviews = await page.locator('.dicebear-preview-wrapper img[src^="data:"]').count();
      console.log(`  Loaded previews: ${loadedPreviews}`);
      
      const errorPreviews = await page.locator('.preview-error').count();
      console.log(`  Error previews: ${errorPreviews}`);
      
      const loadingSpinners = await page.locator('.dicebear-preview-wrapper .spinner-border').count();
      console.log(`  Loading spinners: ${loadingSpinners}`);
      
      // Check specific preview types
      const eyePreviews = await page.locator('[class*="eye"] img').count();
      const mouthPreviews = await page.locator('[class*="mouth"] img').count();
      const facePreviews = await page.locator('[class*="face"] img').count();
      
      console.log(`  Eye previews: ${eyePreviews}`);
      console.log(`  Mouth previews: ${mouthPreviews}`);
      console.log(`  Face previews: ${facePreviews}`);
      
      // Take screenshot after loading
      await page.screenshot({ path: 'avatar-customization-loaded.png', fullPage: true });
      console.log('\n📸 Screenshot saved: avatar-customization-loaded.png');
      
      // Check console for errors
      const errors = [];
      page.on('console', msg => {
        if (msg.type() === 'error') {
          errors.push(msg.text());
        }
      });
      
      if (errors.length > 0) {
        console.log('\n❌ Console errors found:');
        errors.forEach(err => console.log(`  - ${err}`));
      }
    }
    
    // Check for avatar debug panel
    const debugPanel = await page.locator('.debug-panel').count();
    console.log(`\n🐛 Debug panel present: ${debugPanel > 0 ? '✅' : '❌'}`);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    await page.screenshot({ path: 'profile-error.png' });
  }
  
  console.log('\n✅ Test complete. Browser will remain open for 30 seconds...');
  await page.waitForTimeout(30000);
  await browser.close();
})();