const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🚀 Testing Full-Width Avatar Layout...\n');
  
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
    
    console.log('🔍 Checking Layout Changes...\n');
    
    // Check avatar preview section
    const previewSection = await page.locator('.avatar-preview-section').first();
    const previewBounds = await previewSection.boundingBox();
    if (previewBounds) {
      console.log(`📐 Avatar preview section width: ${previewBounds.width}px`);
    }
    
    // Check tabs container
    const tabsContainer = await page.locator('.avatar-tabs-container').first();
    const tabsBounds = await tabsContainer.boundingBox();
    if (tabsBounds) {
      console.log(`📐 Tabs container width: ${tabsBounds.width}px`);
    }
    
    // Check Type tab content width
    const typeTabContent = await page.locator('.tab-pane.show.active').first();
    const typeTabBounds = await typeTabContent.boundingBox();
    if (typeTabBounds) {
      console.log(`📐 Active tab content width: ${typeTabBounds.width}px`);
    }
    
    // Count avatar styles per row
    const styleGrid = await page.locator('.dicebear-styles-grid').first();
    const gridBounds = await styleGrid.boundingBox();
    const firstStyle = await page.locator('.dicebear-style-option').first();
    const styleBounds = await firstStyle.boundingBox();
    
    if (gridBounds && styleBounds) {
      const stylesPerRow = Math.floor(gridBounds.width / (styleBounds.width + 15)); // 15px gap
      console.log(`\n🎨 Avatar styles per row: ${stylesPerRow}`);
    }
    
    // Check customization section
    const customSection = await page.locator('.customization-section').first();
    const customBounds = await customSection.boundingBox();
    if (customBounds) {
      console.log(`📐 Customization section width: ${customBounds.width}px`);
    }
    
    // Test switching to Customize tab
    console.log('\n🔄 Testing tab switching...');
    const adventurer = page.locator('.dicebear-style-option:has(.style-name:text("Adventurer"))').first();
    await adventurer.click();
    await page.waitForTimeout(2000);
    
    // Check customize tab content
    const customizeTab = await page.locator('.tab-pane.show.active').first();
    const customizeBounds = await customizeTab.boundingBox();
    if (customizeBounds) {
      console.log(`📐 Customize tab content width: ${customizeBounds.width}px`);
    }
    
    // Count customization options per row
    const optionGrid = await page.locator('.visual-option-grid').first();
    if (await optionGrid.count() > 0) {
      const optionGridBounds = await optionGrid.boundingBox();
      const firstOption = await page.locator('.visual-option-btn').first();
      const optionBounds = await firstOption.boundingBox();
      
      if (optionGridBounds && optionBounds) {
        const optionsPerRow = Math.floor(optionGridBounds.width / (optionBounds.width + 15));
        console.log(`🎨 Customization options per row: ${optionsPerRow}`);
      }
    }
    
    // Take screenshots
    await page.screenshot({ path: 'avatar-layout-type-tab.png', fullPage: true });
    console.log('\n📸 Screenshot saved: avatar-layout-type-tab.png');
    
    // Switch back to Type tab for another screenshot
    await page.click('.nav-link:has-text("Type")');
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'avatar-layout-full-width.png', fullPage: true });
    console.log('📸 Screenshot saved: avatar-layout-full-width.png');
    
    console.log('\n✅ Layout test complete!');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    await page.screenshot({ path: 'avatar-layout-error.png' });
  }
  
  console.log('\nBrowser will remain open for 30 seconds for inspection...');
  await page.waitForTimeout(30000);
  await browser.close();
})();