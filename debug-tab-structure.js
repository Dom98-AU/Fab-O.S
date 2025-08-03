const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🔍 Debugging Tab Structure...\n');
  
  try {
    // Login and navigate
    await page.goto('http://localhost:8080/Account/Login');
    await page.waitForLoadState('networkidle');
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    await page.waitForLoadState('networkidle');
    await page.goto('http://localhost:8080/profile');
    await page.waitForLoadState('networkidle');
    await page.click('button:has-text("Edit Profile")');
    await page.waitForTimeout(3000);
    
    // Check for tab-related elements
    console.log('🔍 Looking for tab elements...');
    
    const navTabs = await page.locator('.nav-tabs').count();
    const navItems = await page.locator('.nav-item').count();
    const navLinks = await page.locator('.nav-link').count();
    const tabContent = await page.locator('.tab-content').count();
    const tabPanes = await page.locator('.tab-pane').count();
    
    console.log(`  .nav-tabs found: ${navTabs}`);
    console.log(`  .nav-item found: ${navItems}`);
    console.log(`  .nav-link found: ${navLinks}`);
    console.log(`  .tab-content found: ${tabContent}`);
    console.log(`  .tab-pane found: ${tabPanes}`);
    
    // Get all text content to see what's actually rendered
    const modalContent = await page.locator('.modal-content, .card-body').first().textContent();
    console.log('\n📄 Modal content preview:');
    console.log(modalContent.substring(0, 500) + '...');
    
    // Look for any buttons or links that might be our tabs
    const allButtons = await page.locator('button').all();
    console.log('\n🔘 All buttons found:');
    for (let i = 0; i < Math.min(allButtons.length, 10); i++) {
      const text = await allButtons[i].textContent();
      const classes = await allButtons[i].getAttribute('class');
      console.log(`  Button ${i + 1}: "${text?.trim()}" (classes: ${classes})`);
    }
    
    // Check if we have any compilation errors by looking at the HTML
    const htmlContent = await page.content();
    if (htmlContent.includes('nav-tabs') || htmlContent.includes('tab-content')) {
      console.log('\n✅ Tab HTML is present in the page source');
    } else {
      console.log('\n❌ Tab HTML not found in page source - possible compilation issue');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  
  await page.waitForTimeout(60000); // Keep open longer for debugging
  await browser.close();
})();