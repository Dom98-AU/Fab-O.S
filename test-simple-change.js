const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🔍 Testing if simple change is applied...\n');
  
  try {
    // Quick login and check
    await page.goto('http://localhost:8080/Account/Login');
    await page.waitForLoadState('networkidle');
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    await page.waitForLoadState('networkidle');
    await page.goto('http://localhost:8080/profile');
    await page.waitForLoadState('networkidle');
    await page.click('button:has-text("Edit Profile")');
    await page.waitForTimeout(2000);
    
    // Check if the title contains our emoji and "Tabbed" text
    const titleText = await page.locator('h5.card-title').first().textContent();
    console.log(`Avatar Preview title: "${titleText}"`);
    
    if (titleText && (titleText.includes('🎭') || titleText.includes('Tabbed'))) {
      console.log('✅ Simple change was applied - Docker is picking up code changes');
    } else {
      console.log('❌ Simple change NOT applied - Docker caching issue');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  
  await page.waitForTimeout(10000);
  await browser.close();
})();