const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
  
  console.log('🧪 Testing Avatar Edit Button Fix...\n');
  
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
    console.log(`Avatar displayed: ${hasAvatar ? '✅' : '❌'}`);
    
    // Try clicking the small edit button on avatar
    console.log('\n📍 Step 3: Testing small edit button on avatar...');
    const avatarEditButton = page.locator('.avatar-change-btn');
    const avatarEditBtnVisible = await avatarEditButton.isVisible();
    console.log(`Small edit button visible: ${avatarEditBtnVisible ? '✅' : '❌'}`);
    
    if (avatarEditBtnVisible) {
      await avatarEditButton.click();
      await page.waitForTimeout(2000);
      
      // Check if modal opened
      const modalVisible = await page.locator('.modal.show').isVisible();
      console.log(`Modal opened from avatar button: ${modalVisible ? '✅' : '❌'}`);
      
      if (modalVisible) {
        // Close modal
        await page.click('.btn-close');
        await page.waitForTimeout(1000);
      }
    }
    
    // Try the main Edit Profile button
    console.log('\n📍 Step 4: Testing main Edit Profile button...');
    const mainEditButton = page.locator('button:has-text("Edit Profile")');
    const mainEditBtnVisible = await mainEditButton.isVisible();
    console.log(`Main edit button visible: ${mainEditBtnVisible ? '✅' : '❌'}`);
    
    if (mainEditBtnVisible) {
      await mainEditButton.click();
      await page.waitForTimeout(2000);
      
      // Check if modal opened
      const modalVisible = await page.locator('.modal.show').isVisible();
      console.log(`Modal opened from main button: ${modalVisible ? '✅' : '❌'}`);
    }
    
    // Take screenshot
    await page.screenshot({ path: 'avatar-button-test.png', fullPage: false });
    console.log('\n📸 Screenshot saved: avatar-button-test.png');
    
    // Summary
    console.log('\n📊 Test Summary:');
    console.log(`• Avatar displayed: ${hasAvatar ? '✅' : '❌'}`);
    console.log(`• Small edit button visible: ${avatarEditBtnVisible ? '✅' : '❌'}`);
    console.log(`• Main edit button visible: ${mainEditBtnVisible ? '✅' : '❌'}`);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    await page.screenshot({ path: 'avatar-button-error.png', fullPage: false });
  }
  
  console.log('\nTest complete. Browser will remain open for 10 seconds...');
  await page.waitForTimeout(10000);
  await browser.close();
})();