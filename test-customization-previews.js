const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
  
  console.log('🚀 Testing Customization Preview Images...\n');
  
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
    
    // Select an avatar style to test customization
    console.log('🎨 Selecting Bottts style...');
    const botttsOption = page.locator('.dicebear-style-option:has(.style-name:text("Bottts"))').first();
    await botttsOption.click();
    await page.waitForTimeout(3000);
    
    console.log('\n🔍 Checking Customization Preview Images...');
    
    // Check if we're on the customize tab
    const customizeTabActive = await page.locator('.nav-link:has-text("Customize").active').count();
    console.log(`Customize tab active: ${customizeTabActive > 0 ? '✅' : '❌'}`);
    
    // Check for customization preview images
    const previewWrappers = await page.locator('.dicebear-preview-wrapper').all();
    console.log(`\n📷 Found ${previewWrappers.length} preview wrappers`);
    
    // Check the first few preview images
    for (let i = 0; i < Math.min(5, previewWrappers.length); i++) {
      const wrapper = previewWrappers[i];
      const img = await wrapper.locator('img').first();
      const hasImg = await img.count() > 0;
      
      if (hasImg) {
        const src = await img.getAttribute('src');
        const alt = await img.getAttribute('alt');
        console.log(`\nPreview ${i + 1}:`);
        console.log(`  Alt: ${alt}`);
        console.log(`  Has image: ✅`);
        console.log(`  Is DiceBear URL: ${src?.includes('dicebear') || src?.includes('data:image/svg') ? '✅' : '❌'}`);
        console.log(`  Source preview: ${src?.substring(0, 100)}...`);
      } else {
        // Check if it has a spinner
        const hasSpinner = await wrapper.locator('.spinner-border').count() > 0;
        console.log(`\nPreview ${i + 1}:`);
        console.log(`  Has image: ❌`);
        console.log(`  Has spinner: ${hasSpinner ? '✅ (Loading)' : '❌'}`);
      }
    }
    
    // Check if previewCache is being populated
    const cacheKeys = await page.evaluate(() => {
      const component = document.querySelector('.avatar-selector');
      // Try to access the component's state (this might not work directly)
      return 'Unable to directly access component cache';
    });
    console.log(`\n📦 Preview cache status: ${cacheKeys}`);
    
    // Check network requests for DiceBear API calls
    const dicebearRequests = [];
    page.on('response', response => {
      if (response.url().includes('dicebear') || response.url().includes('api.dicebear.com')) {
        dicebearRequests.push({
          url: response.url(),
          status: response.status()
        });
      }
    });
    
    // Wait a bit to capture any API calls
    await page.waitForTimeout(2000);
    
    console.log(`\n🌐 DiceBear API calls: ${dicebearRequests.length}`);
    dicebearRequests.slice(0, 5).forEach((req, i) => {
      console.log(`  ${i + 1}. Status: ${req.status}, URL: ${req.url.substring(0, 100)}...`);
    });
    
    // Take screenshot
    await page.screenshot({ path: 'customization-previews-debug.png', fullPage: true });
    console.log('\n📸 Screenshot saved: customization-previews-debug.png');
    
    // Try selecting a different style
    console.log('\n🎨 Switching to Adventurer style...');
    await page.click('.nav-link:has-text("Type")');
    await page.waitForTimeout(1000);
    const adventurerOption = page.locator('.dicebear-style-option:has(.style-name:text("Adventurer"))').first();
    await adventurerOption.click();
    await page.waitForTimeout(3000);
    
    // Check customization options for Adventurer
    const adventurerPreviews = await page.locator('.dicebear-preview-wrapper').count();
    console.log(`\n📷 Adventurer customization previews: ${adventurerPreviews}`);
    
    await page.screenshot({ path: 'adventurer-customization.png' });
    console.log('📸 Screenshot saved: adventurer-customization.png');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    await page.screenshot({ path: 'customization-error.png' });
  }
  
  console.log('\nBrowser will remain open for 30 seconds for inspection...');
  await page.waitForTimeout(30000);
  await browser.close();
})();