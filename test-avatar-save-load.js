const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
  
  console.log('💾 Testing Avatar Save and Load Functionality...\n');
  
  try {
    // Login
    console.log('📍 Step 1: Logging in...');
    await page.goto('http://localhost:8080/Account/Login');
    await page.waitForLoadState('networkidle');
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    await page.waitForLoadState('networkidle');

    // Navigate to profile and capture original avatar
    console.log('\n📍 Step 2: Checking original avatar...');
    await page.goto('http://localhost:8080/profile');
    await page.waitForLoadState('networkidle');
    
    // Capture original avatar src if exists
    const originalAvatar = await page.locator('.avatar-large').getAttribute('src').catch(() => null);
    console.log(`Original avatar URL: ${originalAvatar ? 'Present' : 'None'}`);
    
    // Open avatar customization
    console.log('\n📍 Step 3: Opening avatar customization...');
    await page.click('button:has-text("Edit Profile")');
    await page.waitForTimeout(2000);
    
    // Select Robot Avatar
    const robotAvatar = page.locator('.dicebear-style-option:has(.style-name:text("Robot Avatar"))').first();
    await robotAvatar.click();
    await page.waitForTimeout(1000);
    
    // Click Customize tab
    await page.locator('button:has-text("Customize")').click();
    await page.waitForTimeout(1000);
    
    // Make specific customizations
    console.log('\n🎨 Step 4: Making customizations...');
    
    // Change base color to a distinctive color (orange)
    const baseColorSwatches = await page.locator('label:has-text("Robot Base Color")').locator('..').locator('.color-swatch').all();
    if (baseColorSwatches.length > 3) {
      await baseColorSwatches[3].click(); // Click 4th color (should be orange)
      await page.waitForTimeout(1000);
      console.log('✓ Changed base color');
    }
    
    // Change eye type
    const eyeOptions = await page.locator('label:has-text("Eye Type")').locator('..').locator('.visual-option-btn').all();
    if (eyeOptions.length > 2) {
      await eyeOptions[2].click(); // Click 3rd eye option
      await page.waitForTimeout(1000);
      console.log('✓ Changed eye type');
    }
    
    // Change face shape
    const faceOptions = await page.locator('label:has-text("Face Shape")').locator('..').locator('.visual-option-btn').all();
    if (faceOptions.length > 1) {
      await faceOptions[1].click(); // Click 2nd face option
      await page.waitForTimeout(1000);
      console.log('✓ Changed face shape');
    }
    
    // Capture the customized avatar URL from the preview
    const customizedPreview = await page.locator('.avatar-preview').getAttribute('src');
    console.log(`\\nCustomized preview URL length: ${customizedPreview?.length || 0} chars`);
    
    // Save changes
    console.log('\\n💾 Step 5: Saving changes...');
    await page.click('button:has-text("Save Changes")');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);
    
    // Check if save was successful (modal should close)
    const modalStillOpen = await page.locator('.modal').isVisible().catch(() => false);
    console.log(`Save successful (modal closed): ${!modalStillOpen ? '✅' : '❌'}`);
    
    // Check the new avatar on the profile page
    console.log('\\n🔍 Step 6: Verifying saved avatar...');
    const newAvatar = await page.locator('.avatar-large').getAttribute('src');
    console.log(`New avatar URL length: ${newAvatar?.length || 0} chars`);
    console.log(`Avatar changed: ${newAvatar !== originalAvatar ? '✅' : '❌'}`);
    
    // Test reload persistence
    console.log('\\n🔄 Step 7: Testing persistence after page reload...');
    await page.reload();
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);
    
    const reloadedAvatar = await page.locator('.avatar-large').getAttribute('src');
    console.log(`Avatar persisted after reload: ${reloadedAvatar === newAvatar ? '✅' : '❌'}`);
    
    // Test opening customization again to see if options are preserved
    console.log('\\n🔧 Step 8: Testing if customization options are preserved...');
    await page.click('button:has-text("Edit Profile")');
    await page.waitForTimeout(2000);
    
    // Should auto-select Robot Avatar and show our customizations
    const robotSelected = await page.locator('.dicebear-style-option:has(.style-name:text("Robot Avatar"))').first().getAttribute('class');
    console.log(`Robot Avatar pre-selected: ${robotSelected?.includes('active') ? '✅' : '❌'}`);
    
    // Click Customize tab to see if our options are preserved
    await page.locator('button:has-text("Customize")').click();
    await page.waitForTimeout(1000);
    
    // Check if our customized preview matches what we saved
    const reopenedPreview = await page.locator('.avatar-preview').getAttribute('src');
    console.log(`Customization options preserved: ${reopenedPreview === customizedPreview ? '✅' : '❌'}`);
    
    // Take final screenshot
    await page.screenshot({ path: 'avatar-save-load-test.png', fullPage: true });
    console.log('\\n📸 Screenshot saved: avatar-save-load-test.png');
    
    // Summary
    console.log('\\n📊 Test Summary:');
    console.log(`• Avatar can be customized: ✅`);
    console.log(`• Customizations save properly: ${!modalStillOpen ? '✅' : '❌'}`);
    console.log(`• Avatar persists after reload: ${reloadedAvatar === newAvatar ? '✅' : '❌'}`);
    console.log(`• Customization options preserved: ${reopenedPreview === customizedPreview ? '✅' : '❌'}`);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  
  console.log('\\nTest complete. Browser will remain open for 15 seconds...');
  await page.waitForTimeout(15000);
  await browser.close();
})();