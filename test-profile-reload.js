const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🔍 Testing Profile Page Reload Issue...\n');
  
  try {
    // Login
    console.log('📍 Step 1: Logging in...');
    await page.goto('http://localhost:8080/Account/Login');
    await page.waitForLoadState('networkidle');
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    await page.waitForLoadState('networkidle');
    console.log('✅ Logged in successfully\n');

    // Navigate to profile
    console.log('📍 Step 2: Navigating to profile page...');
    await page.goto('http://localhost:8080/profile');
    await page.waitForLoadState('networkidle');
    
    // Check if profile loads
    await page.waitForTimeout(2000);
    const pageContent = await page.content();
    
    if (pageContent.includes('Profile Not Found')) {
      console.log('❌ Profile Not Found error appeared');
      
      // Check debug info
      const debugInfo = await page.locator('.small.text-muted').textContent().catch(() => 'No debug info');
      console.log('Debug info:', debugInfo);
      
      // Try retry button if available
      const retryButton = page.locator('button:has-text("Retry")');
      if (await retryButton.count() > 0) {
        console.log('\n📍 Clicking Retry button...');
        await retryButton.click();
        await page.waitForTimeout(2000);
        
        const newContent = await page.content();
        if (!newContent.includes('Profile Not Found')) {
          console.log('✅ Profile loaded after retry!');
        } else {
          console.log('❌ Still showing Profile Not Found after retry');
        }
      }
    } else if (pageContent.includes('admin@steelestimation.com')) {
      console.log('✅ Profile loaded successfully on first try!');
    }
    
    // Test reload
    console.log('\n📍 Step 3: Reloading the page...');
    await page.reload();
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);
    
    const reloadedContent = await page.content();
    if (reloadedContent.includes('Profile Not Found')) {
      console.log('❌ Profile Not Found after reload');
      const debugInfo = await page.locator('.small.text-muted').textContent().catch(() => 'No debug info');
      console.log('Debug info:', debugInfo);
    } else if (reloadedContent.includes('admin@steelestimation.com')) {
      console.log('✅ Profile still loads correctly after reload!');
    }
    
    // Take screenshot
    await page.screenshot({ path: 'profile-reload-test.png', fullPage: true });
    console.log('\n📸 Screenshot saved: profile-reload-test.png');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  
  console.log('\nTest complete. Browser will remain open for 10 seconds...');
  await page.waitForTimeout(10000);
  await browser.close();
})();