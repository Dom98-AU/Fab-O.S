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
  
  console.log('3. Opening avatar modal via Edit Profile button...');
  // Use the visible Edit Profile button
  await page.click('button:has-text("Edit Profile")');
  await page.waitForTimeout(2000);
  
  // Check if modal opened
  const modal = await page.locator('.modal.show, .modal.fade.show').first();
  const modalVisible = await modal.count() > 0;
  console.log('4. Modal opened:', modalVisible);
  
  if (modalVisible) {
    // First, make sure we're on the Bottts tab
    console.log('5. Checking for Bottts avatar style...');
    const botttsButton = await page.locator('button:has-text("Bottts"), .dicebear-style-option:has-text("Bottts")').first();
    if (await botttsButton.count() > 0) {
      const isBotttsActive = await botttsButton.evaluate(el => el.classList.contains('active'));
      if (!isBotttsActive) {
        console.log('   Selecting Bottts style...');
        await botttsButton.click();
        await page.waitForTimeout(1000);
      }
    }
    
    // Look for texture section
    console.log('6. Looking for texture section...');
    const textureLabel = await page.locator('label:has-text("Texture")').first();
    const textureSectionFound = await textureLabel.count() > 0;
    console.log('   Texture section found:', textureSectionFound);
    
    if (textureSectionFound) {
      // Find texture buttons
      const textureButtons = await page.locator('.texture-option-btn').all();
      console.log('   Found texture buttons:', textureButtons.length);
      
      if (textureButtons.length > 0) {
        // Get texture names
        for (let i = 0; i < textureButtons.length; i++) {
          const label = await textureButtons[i].locator('.option-label').textContent();
          console.log(`   Texture ${i + 1}: ${label}`);
        }
        
        // Test multi-select
        console.log('7. Testing multi-select...');
        
        // Click first texture
        await textureButtons[0].click();
        await page.waitForTimeout(500);
        let isActive = await textureButtons[0].evaluate(el => el.classList.contains('active'));
        console.log('   First texture active after click:', isActive);
        
        // Click second texture
        if (textureButtons.length > 1) {
          await textureButtons[1].click();
          await page.waitForTimeout(500);
          isActive = await textureButtons[1].evaluate(el => el.classList.contains('active'));
          console.log('   Second texture active after click:', isActive);
        }
        
        // Click third texture
        if (textureButtons.length > 2) {
          await textureButtons[2].click();
          await page.waitForTimeout(500);
          isActive = await textureButtons[2].evaluate(el => el.classList.contains('active'));
          console.log('   Third texture active after click:', isActive);
        }
        
        // Count active textures
        const activeTextures = await page.locator('.texture-option-btn.active').count();
        console.log('   Total active textures:', activeTextures);
        
        // Check for checkmarks
        const checkmarks = await page.locator('.texture-check').count();
        console.log('   Checkmarks visible:', checkmarks);
        
        // Test Clear All button
        console.log('8. Testing Clear All button...');
        const clearButton = await page.locator('button:has-text("Clear All Textures")').first();
        if (await clearButton.count() > 0) {
          await clearButton.click();
          await page.waitForTimeout(500);
          const activeAfterClear = await page.locator('.texture-option-btn.active').count();
          console.log('   Active textures after clear:', activeAfterClear);
        } else {
          console.log('   Clear All button not found');
        }
        
        // Check avatar preview URL
        const avatarImg = await page.locator('.avatar-preview img, .current-avatar img').first();
        if (await avatarImg.count() > 0) {
          const src = await avatarImg.getAttribute('src');
          if (src) {
            console.log('9. Avatar URL analysis:');
            console.log('   URL length:', src.length);
            const hasTexture = src.includes('texture');
            console.log('   Contains texture param:', hasTexture);
            if (hasTexture) {
              // Extract texture part
              const textureMatch = src.match(/texture[^&]*/);
              if (textureMatch) {
                console.log('   Texture param:', decodeURIComponent(textureMatch[0]));
              }
            }
          }
        }
      } else {
        console.log('   ERROR: No texture buttons found');
        
        // Debug: Check modal content
        const modalText = await modal.locator('.modal-body').textContent();
        console.log('   Modal body preview:', modalText.substring(0, 300));
      }
    } else {
      console.log('   ERROR: Texture section not found');
      
      // Check what tabs are visible
      const tabs = await page.locator('.nav-tabs .nav-link').allTextContents();
      console.log('   Available tabs:', tabs);
    }
    
    await page.screenshot({ path: 'texture-modal-test.png', fullPage: true });
    console.log('10. Screenshot saved: texture-modal-test.png');
  } else {
    console.log('   ERROR: Modal did not open');
    await page.screenshot({ path: 'texture-test-no-modal.png' });
  }
  
  await browser.close();
  console.log('Test complete.');
})();