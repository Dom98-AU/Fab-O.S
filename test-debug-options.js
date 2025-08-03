const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🔍 Debug: Testing which customization options are available...\n');
  
  try {
    // Login
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
    
    // Test adventurer specifically
    console.log('🧪 Testing Adventurer style specifically...');
    const adventurerLocator = page.locator('.dicebear-style-option:has(.style-name:text("Adventurer"))').first();
    if (await adventurerLocator.count() > 0) {
      await adventurerLocator.click();
      await page.waitForTimeout(5000); // Wait longer for loading
      
      // Check what sections are actually rendered
      const allSections = await page.locator('.customization-section').all();
      console.log(`Total customization sections: ${allSections.length}`);
      
      for (let i = 0; i < allSections.length; i++) {
        const sectionText = await allSections[i].textContent();
        const header = sectionText.split('\n')[0];
        console.log(`  Section ${i + 1}: ${header}`);
      }
      
      // Look for specific dynamic option grids
      const optionGrids = await page.locator('.visual-option-grid').all();
      console.log(`Visual option grids found: ${optionGrids.length}`);
      
      for (let i = 0; i < optionGrids.length; i++) {
        const parentSection = await optionGrids[i].locator('..').textContent();
        const optionButtons = await optionGrids[i].locator('.visual-option-btn').count();
        console.log(`  Grid ${i + 1}: ${optionButtons} options (in section: ${parentSection.split('\n')[0]})`);
      }
      
      // Check if any console logs show what's happening
      const logs = await page.evaluate(() => {
        return window.console._logs || [];
      });
      
      if (logs.length > 0) {
        console.log('\nConsole logs:');
        logs.forEach(log => console.log(`  ${log}`));
      }
      
    } else {
      console.log('❌ Adventurer style not found');
    }
    
    // Take screenshot for debugging
    await page.screenshot({ path: 'debug-adventurer.png', fullPage: true });
    console.log('\n📸 Debug screenshot saved: debug-adventurer.png');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    await page.screenshot({ path: 'debug-error.png' });
  }
  
  console.log('\nBrowser will remain open for manual inspection...');
  await page.waitForTimeout(60000); // Keep open longer for debugging
  await browser.close();
})();