const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🚀 Testing Dynamic Avatar Customization...\n');
  
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
    
    // Test multiple avatar styles
    const stylesToTest = ['bottts', 'adventurer', 'avataaars', 'big-smile', 'personas'];
    
    for (const style of stylesToTest) {
      console.log(`\n🤖 Testing ${style} style...`);
      
      // Click the style
      const styleLocator = page.locator(`.dicebear-style-option:has(.style-name:text("${style.charAt(0).toUpperCase() + style.slice(1)}"))`).first();
      if (await styleLocator.count() > 0) {
        await styleLocator.click();
        await page.waitForTimeout(3000); // Wait for style to load
        
        // Check if customization section appears
        const customizationSection = await page.locator('.customization-section:has(h6:text("Customize Your Avatar"))').count();
        console.log(`  Customization section visible: ${customizationSection > 0 ? '✅' : '❌'}`);
        
        // Check if dynamic options are loaded
        const visualOptions = await page.locator('.visual-option-grid .visual-option-btn').count();
        console.log(`  Dynamic customization options: ${visualOptions}`);
        
        // Check if images are loading
        const loadedImages = await page.locator('.dicebear-preview-wrapper img').count();
        const spinners = await page.locator('.dicebear-preview-wrapper .spinner-border').count();
        console.log(`  Images loaded: ${loadedImages}, Still loading: ${spinners}`);
        
        if (visualOptions > 0) {
          // Test clicking a customization option
          const firstOption = page.locator('.visual-option-btn').first();
          if (await firstOption.count() > 0) {
            await firstOption.click();
            await page.waitForTimeout(1000);
            console.log(`  ✅ Successfully clicked customization option`);
          }
        }
        
        // Check if main avatar preview updates
        const avatarPreview = await page.locator('.avatar-preview').count();
        console.log(`  Avatar preview visible: ${avatarPreview > 0 ? '✅' : '❌'}`);
        
      } else {
        console.log(`  ❌ Style "${style}" not found`);
      }
    }
    
    // Final check - go back to bottts and verify it still works
    console.log(`\n🔄 Final test - returning to bottts...`);
    const botttsLocator = page.locator('.dicebear-style-option:has(.style-name:text("Bottts"))').first();
    await botttsLocator.click();
    await page.waitForTimeout(3000);
    
    const finalCustomizations = await page.locator('.visual-option-grid .visual-option-btn').count();
    console.log(`  Bottts customizations available: ${finalCustomizations}`);
    
    // Test special bottts features (rotation, scale, texture)
    const rotationSlider = await page.locator('input[type="range"]').first().count();
    const textureOptions = await page.locator('.texture-option-btn').count();
    console.log(`  Special bottts features - Rotation: ${rotationSlider > 0 ? '✅' : '❌'}, Texture: ${textureOptions > 0 ? '✅' : '❌'}`);
    
    console.log(`\n✅ Dynamic avatar customization test complete!`);
    
    // Take final screenshot
    await page.screenshot({ path: 'dynamic-avatar-test.png', fullPage: true });
    console.log('📸 Screenshot saved: dynamic-avatar-test.png');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    await page.screenshot({ path: 'avatar-error.png' });
  }
  
  console.log('\nBrowser will remain open for 30 seconds for manual inspection...');
  await page.waitForTimeout(30000);
  await browser.close();
})();