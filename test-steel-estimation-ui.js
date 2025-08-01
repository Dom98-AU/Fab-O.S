const { chromium } = require('playwright');

(async () => {
  console.log('Starting Steel Estimation UI Test...');
  
  // Launch browser
  const browser = await chromium.launch({ 
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  
  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 }
  });
  
  const page = await context.newPage();
  
  try {
    // 1. Navigate to homepage
    console.log('1. Navigating to http://localhost:8080...');
    await page.goto('http://localhost:8080', { waitUntil: 'networkidle' });
    
    // Take screenshot of homepage/login page
    await page.screenshot({ path: 'screenshots/01-homepage.png', fullPage: true });
    console.log('   ✓ Homepage loaded and screenshot saved');
    
    // 2. Check if we're on the login page
    const pageTitle = await page.title();
    console.log(`   Page title: ${pageTitle}`);
    
    // 3. Fill login form
    console.log('2. Filling login form...');
    
    // Wait for email input to be visible
    await page.waitForSelector('input[name="Input.Email"], input#email, input[type="email"]', { timeout: 5000 });
    
    // Fill email
    await page.fill('input[name="Input.Email"], input#email, input[type="email"]', 'admin@steelestimation.com');
    console.log('   ✓ Email entered');
    
    // Fill password
    await page.fill('input[name="Input.Password"], input#password, input[type="password"]', 'Admin@123');
    console.log('   ✓ Password entered');
    
    // Take screenshot before login
    await page.screenshot({ path: 'screenshots/02-login-filled.png' });
    
    // 4. Click login button
    console.log('3. Clicking login button...');
    
    // Find and click the login button
    const loginButton = await page.locator('button[type="submit"], input[type="submit"], button:has-text("Log in"), button:has-text("Sign in")').first();
    await loginButton.click();
    
    // Wait for navigation or error
    await page.waitForLoadState('networkidle');
    
    // 5. Check if login was successful
    console.log('4. Checking login result...');
    
    // Check current URL
    const currentUrl = page.url();
    console.log(`   Current URL: ${currentUrl}`);
    
    // Take screenshot after login attempt
    await page.screenshot({ path: 'screenshots/03-after-login.png', fullPage: true });
    
    // Check if we're still on login page (indicates error)
    if (currentUrl.includes('/Account/Login') || currentUrl.includes('/login')) {
      console.log('   ⚠️  Still on login page - checking for errors...');
      
      // Look for error messages
      const errorText = await page.locator('.validation-summary-errors, .alert-danger, .text-danger').textContent().catch(() => null);
      if (errorText) {
        console.log(`   Error message: ${errorText}`);
      }
    } else {
      console.log('   ✓ Login successful!');
      
      // 6. Test navigation menu
      console.log('5. Testing navigation menu...');
      
      // Wait a bit for the page to fully load
      await page.waitForTimeout(2000);
      
      // Look for navigation links
      const navLinks = await page.locator('nav a, .navbar a, .sidebar a').all();
      console.log(`   Found ${navLinks.length} navigation links`);
      
      // Try to navigate to Projects if available
      const projectsLink = await page.locator('a:has-text("Projects"), a[href*="project"]').first();
      if (await projectsLink.isVisible()) {
        console.log('   Clicking Projects link...');
        await projectsLink.click();
        await page.waitForLoadState('networkidle');
        await page.screenshot({ path: 'screenshots/04-projects-page.png' });
        console.log('   ✓ Projects page loaded');
      }
      
      // Try to navigate to Customers
      const customersLink = await page.locator('a:has-text("Customers"), a[href*="customer"]').first();
      if (await customersLink.isVisible()) {
        console.log('   Clicking Customers link...');
        await customersLink.click();
        await page.waitForLoadState('networkidle');
        await page.screenshot({ path: 'screenshots/05-customers-page.png' });
        console.log('   ✓ Customers page loaded');
      }
    }
    
    // 7. Check for console errors
    console.log('6. Checking for console errors...');
    page.on('console', msg => {
      if (msg.type() === 'error') {
        console.log(`   Console error: ${msg.text()}`);
      }
    });
    
    console.log('\n✅ UI Test completed successfully!');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    await page.screenshot({ path: 'screenshots/error-screenshot.png' });
  } finally {
    await browser.close();
  }
})();