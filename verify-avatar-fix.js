const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
  
  console.log('✅ Testing Avatar Save/Load Fix...\n');
  
  // Login
  await page.goto('http://localhost:8080/Account/Login');
  await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
  await page.fill('input[name="Input.Password"]', 'Admin@123');
  await page.click('button[type="submit"]');
  await page.waitForLoadState('networkidle');

  // Go to profile
  await page.goto('http://localhost:8080/profile');
  await page.waitForTimeout(3000);
  
  // Check database directly for saved data
  console.log('Avatar is displayed on profile page - check the browser window');
  console.log('The robot avatar with customizations should be visible');
  
  // Open modal to verify options
  await page.click('button:has-text("Edit Profile")');
  await page.waitForTimeout(5000); // Give time for modal to fully load
  
  console.log('\nModal is open - check if:');
  console.log('1. Robot Avatar style is selected');
  console.log('2. Click Customize tab to see if options are pre-selected');
  
  // Take screenshot
  await page.screenshot({ path: 'avatar-fix-verified.png', fullPage: false });
  console.log('\nScreenshot saved: avatar-fix-verified.png');
  
  console.log('\nManual verification needed - check browser window');
  await page.waitForTimeout(30000); // Keep open for 30 seconds
  await browser.close();
})();
