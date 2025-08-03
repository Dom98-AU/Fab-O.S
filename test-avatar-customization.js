const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🚀 Testing Avatar Customization Images...\n');
  
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
    
    // Check if modal opened
    const modal = await page.locator('.modal.show').count();
    console.log(`Edit modal opened: ${modal > 0 ? '✅' : '❌'}`);
    
    // Look for avatar selector
    console.log('\n🎨 Checking Avatar Selector...');
    const avatarSelector = await page.locator('.avatar-selector').count();
    console.log(`Avatar selector found: ${avatarSelector > 0 ? '✅' : '❌'}`);
    
    // Check for DiceBear style options
    const styleOptions = await page.locator('.dicebear-style-option').count();
    console.log(`Style options found: ${styleOptions}`);
    
    // Click on first available style
    const styleButtons = await page.locator('.dicebear-style-option').all();
    if (styleButtons.length > 0) {
      const firstStyleName = await styleButtons[0].locator('.style-name').textContent();
      console.log(`\n🤖 Clicking on style: ${firstStyleName}...`);
      await styleButtons[0].click();
      await page.waitForTimeout(5000); // Wait for images to load
      
      // Check for preview images
      console.log('\n🖼️ Checking preview images...');
      
      // Count all preview wrappers
      const previewWrappers = await page.locator('.dicebear-preview-wrapper').count();
      console.log(`Preview wrappers: ${previewWrappers}`);
      
      // Count loaded images
      const loadedImages = await page.locator('.dicebear-preview-wrapper img').count();
      console.log(`Total images: ${loadedImages}`);
      
      // Check for images with data URLs
      const dataUrlImages = await page.locator('.dicebear-preview-wrapper img[src^="data:"]').count();
      console.log(`Images with data URLs: ${dataUrlImages}`);
      
      // Check for loading spinners
      const loadingSpinners = await page.locator('.dicebear-preview-wrapper .spinner-border').count();
      console.log(`Loading spinners: ${loadingSpinners}`);
      
      // Check for error states
      const errorStates = await page.locator('.preview-error').count();
      console.log(`Error states: ${errorStates}`);
      
      // Get details of first few images
      console.log('\n📋 First 3 images details:');
      const images = await page.locator('.dicebear-preview-wrapper img').all();
      for (let i = 0; i < Math.min(3, images.length); i++) {
        const src = await images[i].getAttribute('src');
        const naturalWidth = await images[i].evaluate(el => el.naturalWidth);
        const loaded = await images[i].evaluate(el => el.complete && el.naturalWidth > 0);
        console.log(`  Image ${i + 1}: ${loaded ? '✅ Loaded' : '❌ Not loaded'} (width: ${naturalWidth})`);
        if (src) {
          console.log(`    URL: ${src.substring(0, 60)}...`);
        }
      }
      
      // Take screenshot
      await page.screenshot({ path: 'avatar-customization-modal.png', fullPage: true });
      console.log('\n📸 Screenshot saved: avatar-customization-modal.png');
      
      // Check for specific customization sections
      const eyesSection = await page.locator('text=Eyes').count();
      const mouthSection = await page.locator('text=Mouth').count();
      const colorsSection = await page.locator('text=Colors').count();
      
      console.log('\n🎯 Customization sections:');
      console.log(`  Eyes: ${eyesSection > 0 ? '✅' : '❌'}`);
      console.log(`  Mouth: ${mouthSection > 0 ? '✅' : '❌'}`);
      console.log(`  Colors: ${colorsSection > 0 ? '✅' : '❌'}`);
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    await page.screenshot({ path: 'avatar-error.png' });
  }
  
  console.log('\n✅ Test complete. Browser will remain open for 30 seconds...');
  await page.waitForTimeout(30000);
  await browser.close();
})();