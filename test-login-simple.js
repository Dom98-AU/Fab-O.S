const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🚀 Testing Login Flow...\n');
  
  try {
    // Go directly to login page
    console.log('📍 Navigating to login page...');
    await page.goto('http://localhost:8080/Account/Login');
    await page.waitForLoadState('networkidle');
    
    console.log(`Current URL: ${page.url()}`);
    
    // Fill login form
    console.log('🔐 Filling login form...');
    
    // Wait for form to be visible
    await page.waitForSelector('input[name="Input.Email"]', { timeout: 5000 });
    
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    
    // Take screenshot before login
    await page.screenshot({ path: 'login-form.png' });
    console.log('📸 Screenshot saved: login-form.png');
    
    // Submit form
    console.log('Submitting login form...');
    await page.click('button[type="submit"]');
    
    // Wait for navigation
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(3000);
    
    console.log(`\n✅ Post-login URL: ${page.url()}`);
    
    // Check if we're authenticated
    const logoutLink = await page.locator('a:has-text("Logout"), button:has-text("Logout")').count();
    console.log(`Logout link found: ${logoutLink > 0 ? '✅ Authenticated' : '❌ Not authenticated'}`);
    
    // Now navigate to profile
    console.log('\n👤 Navigating to profile...');
    await page.goto('http://localhost:8080/profile');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);
    
    // Check profile page
    const profileHeader = await page.locator('.profile-header').count();
    console.log(`Profile header found: ${profileHeader > 0 ? '✅' : '❌'}`);
    
    const editButtons = await page.locator('button:has-text("Edit Profile")').count();
    console.log(`Edit Profile button found: ${editButtons > 0 ? '✅' : '❌'}`);
    
    // Take final screenshot
    await page.screenshot({ path: 'profile-after-login.png', fullPage: true });
    console.log('\n📸 Screenshot saved: profile-after-login.png');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    await page.screenshot({ path: 'login-error.png' });
  }
  
  console.log('\n✅ Test complete. Browser will remain open for 30 seconds...');
  await page.waitForTimeout(30000);
  await browser.close();
})();