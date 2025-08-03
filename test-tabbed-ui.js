const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🚀 Testing New Tabbed Avatar UI...\n');
  
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
    
    console.log('🔍 Testing Tab Structure...');
    
    // Check if tabs are present
    const typeTab = await page.locator('.nav-link:has-text("Type")').count();
    const customizeTab = await page.locator('.nav-link:has-text("Customize")').count();
    
    console.log(`  Type tab found: ${typeTab > 0 ? '✅' : '❌'}`);
    console.log(`  Customize tab found: ${customizeTab > 0 ? '✅' : '❌'}`);
    
    // Check initial state - should be on Type tab
    const typeTabActive = await page.locator('.nav-link:has-text("Type").active').count();
    const customizeTabDisabled = await page.locator('.nav-link:has-text("Customize").disabled').count();
    
    console.log(`  Type tab initially active: ${typeTabActive > 0 ? '✅' : '❌'}`);
    console.log(`  Customize tab initially disabled: ${customizeTabDisabled > 0 ? '✅' : '❌'}`);
    
    // Check if avatar styles are visible in Type tab
    const avatarStyles = await page.locator('.dicebear-style-option').count();
    console.log(`  Avatar styles visible in Type tab: ${avatarStyles} ${avatarStyles > 0 ? '✅' : '❌'}`);
    
    // Test selecting an avatar style
    console.log('\n🤖 Testing Style Selection and Tab Switching...');
    const adventurerOption = page.locator('.dicebear-style-option:has(.style-name:text("Adventurer"))').first();
    if (await adventurerOption.count() > 0) {
      await adventurerOption.click();
      await page.waitForTimeout(3000);
      
      // Check if it switched to Customize tab
      const customizeTabActive = await page.locator('.nav-link:has-text("Customize").active').count();
      console.log(`  Auto-switched to Customize tab: ${customizeTabActive > 0 ? '✅' : '❌'}`);
      
      // Check if customization options are visible
      const customizationOptions = await page.locator('.visual-option-grid .visual-option-btn').count();
      console.log(`  Customization options visible: ${customizationOptions} ${customizationOptions > 0 ? '✅' : '❌'}`);
      
      // Test manual tab switching
      console.log('\n🔄 Testing Manual Tab Switching...');
      await page.click('.nav-link:has-text("Type")');
      await page.waitForTimeout(1000);
      
      const backToTypeTab = await page.locator('.nav-link:has-text("Type").active').count();
      const avatarStylesVisible = await page.locator('.dicebear-style-option').count();
      
      console.log(`  Switched back to Type tab: ${backToTypeTab > 0 ? '✅' : '❌'}`);
      console.log(`  Avatar styles visible after switch: ${avatarStylesVisible > 0 ? '✅' : '❌'}`);
      
      // Switch back to Customize
      await page.click('.nav-link:has-text("Customize")');
      await page.waitForTimeout(1000);
      
      const backToCustomizeTab = await page.locator('.nav-link:has-text("Customize").active').count();
      const customOptionsVisible = await page.locator('.visual-option-grid').count();
      
      console.log(`  Switched back to Customize tab: ${backToCustomizeTab > 0 ? '✅' : '❌'}`);
      console.log(`  Customization options visible after switch: ${customOptionsVisible > 0 ? '✅' : '❌'}`);
      
    } else {
      console.log('  ❌ Adventurer style option not found');
    }
    
    // Take screenshot
    await page.screenshot({ path: 'tabbed-ui-test.png', fullPage: true });
    console.log('\n📸 Screenshot saved: tabbed-ui-test.png');
    
    console.log('\n✅ Tabbed UI test complete!');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    await page.screenshot({ path: 'tabbed-ui-error.png' });
  }
  
  console.log('\nBrowser will remain open for 30 seconds for inspection...');
  await page.waitForTimeout(30000);
  await browser.close();
})();