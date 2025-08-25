const { chromium } = require('playwright');

(async () => {
  // Launch browser
  const browser = await chromium.launch({ 
    headless: false,
    slowMo: 500 
  });
  
  const context = await browser.newContext({
    ignoreHTTPSErrors: true,
    viewport: { width: 1920, height: 1080 }
  });
  
  const page = await context.newPage();
  
  try {
    // Navigate to the application
    console.log('Navigating to http://localhost:8080...');
    await page.goto('http://localhost:8080', { 
      waitUntil: 'networkidle',
      timeout: 30000 
    });
    
    // Check if we need to login
    const loginButton = await page.locator('button:has-text("Login")').count();
    if (loginButton > 0 || await page.url().includes('login')) {
      console.log('Login required. Logging in...');
      
      // Fill in login credentials
      await page.fill('input[type="email"], input[name="Input.Email"], #Input_Email', 'admin@steelestimation.com');
      await page.fill('input[type="password"], input[name="Input.Password"], #Input_Password', 'Admin@123');
      
      // Click login button
      await page.click('button[type="submit"]:has-text("Log in"), button:has-text("Login")');
      
      // Wait for navigation after login
      await page.waitForURL('**/dashboard', { timeout: 10000 }).catch(() => {
        console.log('Dashboard not reached, continuing...');
      });
    }
    
    // Navigate to ViewScape test page
    console.log('Navigating to ViewScape test page...');
    await page.goto('http://localhost:8080/viewscape-test', { 
      waitUntil: 'networkidle',
      timeout: 30000 
    });
    
    // Wait for ViewScape header to load
    await page.waitForTimeout(2000);
    
    // Take screenshot
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const screenshotPath = `/mnt/c/Fab.OS Platform/Fab O.S/viewscape-screenshot-${timestamp}.png`;
    await page.screenshot({ 
      path: screenshotPath,
      fullPage: true 
    });
    
    console.log(`Screenshot saved to: ${screenshotPath}`);
    
    // Check for ViewScape header elements
    const headerExists = await page.locator('.viewscape-header, [class*="viewscape"], [id*="viewscape"]').count() > 0;
    const toolbarExists = await page.locator('.toolbar, .branded-toolbar, [class*="toolbar"]').count() > 0;
    
    console.log(`ViewScape Header Found: ${headerExists}`);
    console.log(`Branded Toolbar Found: ${toolbarExists}`);
    
    // Get page title and URL for verification
    const pageTitle = await page.title();
    const pageUrl = page.url();
    console.log(`Page Title: ${pageTitle}`);
    console.log(`Current URL: ${pageUrl}`);
    
    // Keep browser open for manual inspection
    console.log('\nBrowser will remain open for inspection. Press Ctrl+C to close.');
    await page.waitForTimeout(60000);
    
  } catch (error) {
    console.error('Error during test:', error);
    
    // Take error screenshot
    const errorScreenshotPath = `/mnt/c/Fab.OS Platform/Fab O.S/viewscape-error-screenshot.png`;
    await page.screenshot({ 
      path: errorScreenshotPath,
      fullPage: true 
    });
    console.log(`Error screenshot saved to: ${errorScreenshotPath}`);
  } finally {
    await browser.close();
  }
})();