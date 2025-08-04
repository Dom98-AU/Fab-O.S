const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('1. Logging in...');
  await page.goto('http://localhost:8080/Account/Login');
  await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
  await page.fill('input[name="Input.Password"]', 'Admin@123');
  await page.click('button[type="submit"]');
  await page.waitForLoadState('networkidle');

  console.log('2. Navigating to profile...');
  await page.goto('http://localhost:8080/profile');
  await page.waitForTimeout(3000);
  
  console.log('3. Opening avatar modal...');
  // Try multiple methods to open the modal
  const editButton = await page.locator('.avatar-change-btn').first();
  if (await editButton.count() > 0) {
    await editButton.click({ force: true });
  } else {
    // Fallback: click the main Edit Profile button
    await page.click('button:has-text("Edit Profile")');
  }
  
  await page.waitForTimeout(2000);
  
  // Check if modal opened
  const modal = await page.locator('.modal.show').first();
  const modalVisible = await modal.count() > 0;
  console.log('4. Modal opened:', modalVisible);
  
  if (modalVisible) {
    // Look for texture options
    console.log('5. Looking for texture options...');
    const textureButtons = await page.locator('.texture-option-btn').all();
    console.log('   Found texture buttons:', textureButtons.length);
    
    if (textureButtons.length > 0) {
      // Click on first 3 textures to test multi-select
      console.log('6. Testing multi-select by clicking textures...');
      for (let i = 0; i < Math.min(3, textureButtons.length); i++) {
        await textureButtons[i].click();
        await page.waitForTimeout(500);
        
        // Check if texture is marked as active
        const isActive = await textureButtons[i].evaluate(el => el.classList.contains('active'));
        console.log(`   Texture ${i + 1} active:`, isActive);
        
        // Check for checkmark
        const hasCheck = await textureButtons[i].locator('.texture-check').count() > 0;
        console.log(`   Texture ${i + 1} has checkmark:`, hasCheck);
      }
      
      // Test Clear All button
      console.log('7. Testing Clear All Textures button...');
      const clearButton = await page.locator('button:has-text("Clear All Textures")').first();
      if (await clearButton.count() > 0) {
        await clearButton.click();
        await page.waitForTimeout(500);
        
        // Check if all textures are deselected
        const activeCount = await page.locator('.texture-option-btn.active').count();
        console.log('   Active textures after clear:', activeCount);
      } else {
        console.log('   Clear All button not found');
      }
      
      // Get current avatar URL to check texture parameter
      const avatarImg = await page.locator('.avatar-preview img').first();
      if (await avatarImg.count() > 0) {
        const avatarSrc = await avatarImg.getAttribute('src');
        console.log('8. Avatar URL:', avatarSrc?.substring(0, 200));
        
        // Check if texture parameter is an array
        if (avatarSrc && avatarSrc.includes('texture')) {
          const hasArrayTexture = avatarSrc.includes('texture%5B%5D') || avatarSrc.includes('texture[]');
          console.log('   Has array texture parameter:', hasArrayTexture);
        }
      }
    } else {
      console.log('   ERROR: No texture buttons found!');
      
      // Debug: Check what's in the modal
      const modalContent = await modal.textContent();
      console.log('   Modal content preview:', modalContent.substring(0, 500));
    }
    
    await page.screenshot({ path: 'texture-test-modal.png' });
    console.log('9. Screenshot saved: texture-test-modal.png');
  } else {
    console.log('   ERROR: Modal did not open!');
    
    // Debug: Check page state
    const pageTitle = await page.title();
    console.log('   Page title:', pageTitle);
    
    const profileFound = await page.locator('h2:has-text("System Administrator")').count() > 0;
    console.log('   Profile page loaded:', profileFound);
    
    await page.screenshot({ path: 'texture-test-failed.png' });
  }
  
  await browser.close();
  console.log('Test complete.');
})();