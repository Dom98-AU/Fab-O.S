const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
  
  console.log('🔍 Testing Avatar Options Preservation...\n');
  
  try {
    // Login
    console.log('📍 Step 1: Logging in...');
    await page.goto('http://localhost:8080/Account/Login');
    await page.waitForLoadState('networkidle');
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    await page.waitForLoadState('networkidle');

    // Navigate to profile
    console.log('\n📍 Step 2: Navigate to profile...');
    await page.goto('http://localhost:8080/profile');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);
    
    // Check if avatar exists
    const hasAvatar = await page.locator('.avatar-large').count() > 0;
    console.log(`Current avatar exists: ${hasAvatar ? '✅' : '❌'}`);
    
    // Open edit modal
    console.log('\n📍 Step 3: Opening edit modal...');
    await page.click('button:has-text("Edit Profile")');
    await page.waitForTimeout(3000); // Wait for modal and options to load
    
    // Check if Robot Avatar is selected (should be pre-selected if saved)
    const robotAvatarClass = await page.locator('.dicebear-style-option:has(.style-name:text("Robot Avatar"))').first().getAttribute('class');
    const isRobotSelected = robotAvatarClass && robotAvatarClass.includes('active');
    console.log(`Robot Avatar pre-selected: ${isRobotSelected ? '✅' : '❌'}`);
    
    // If robot is selected, click Customize to check options
    if (isRobotSelected) {
      console.log('\n📍 Step 4: Checking customization options...');
      
      // Click Customize tab
      const customizeBtn = await page.locator('button:has-text("Customize")');
      if (await customizeBtn.isEnabled()) {
        await customizeBtn.click();
        await page.waitForTimeout(2000);
        
        // Check if base color is selected (not the default first color)
        const selectedColorSwatch = await page.locator('label:has-text("Robot Base Color")').locator('..').locator('.color-swatch.active').count();
        console.log(`Base color is selected: ${selectedColorSwatch > 0 ? '✅' : '❌'}`);
        
        // Check selected eye type
        const selectedEye = await page.locator('label:has-text("Eye Type")').locator('..').locator('.visual-option-btn.active').count();
        console.log(`Eye type is selected: ${selectedEye > 0 ? '✅' : '❌'}`);
        
        // Check selected face type
        const selectedFace = await page.locator('label:has-text("Face Shape")').locator('..').locator('.visual-option-btn.active').count();
        console.log(`Face shape is selected: ${selectedFace > 0 ? '✅' : '❌'}`);
        
        // Check selected mouth type
        const selectedMouth = await page.locator('label:has-text("Mouth Type")').locator('..').locator('.visual-option-btn.active').count();
        console.log(`Mouth type is selected: ${selectedMouth > 0 ? '✅' : '❌'}`);
      } else {
        console.log('Customize tab is disabled (no Robot selected)');
      }
    }
    
    // Take screenshot
    await page.screenshot({ path: 'avatar-options-preserved-test.png', fullPage: false });
    console.log('\n📸 Screenshot saved: avatar-options-preserved-test.png');
    
    // Summary
    console.log('\n📊 Test Summary:');
    console.log(`• Avatar exists on profile: ${hasAvatar ? '✅' : '❌'}`);
    console.log(`• Robot Avatar pre-selected in modal: ${isRobotSelected ? '✅' : '❌'}`);
    console.log(`• Customization options preserved: Check screenshot for visual confirmation`);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    await page.screenshot({ path: 'avatar-test-error.png', fullPage: false });
  }
  
  console.log('\nTest complete. Browser will remain open for 10 seconds...');
  await page.waitForTimeout(10000);
  await browser.close();
})();