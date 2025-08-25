const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ 
    headless: false,
    slowMo: 300 
  });
  
  const context = await browser.newContext({
    ignoreHTTPSErrors: true,
    viewport: { width: 1920, height: 1080 }
  });
  
  const page = await context.newPage();
  
  try {
    // First navigate to home page
    console.log('Navigating to http://localhost:8080...');
    await page.goto('http://localhost:8080');
    await page.waitForTimeout(2000);
    
    // Check current URL to see if we're on login page
    const currentUrl = page.url();
    console.log('Current URL:', currentUrl);
    
    if (currentUrl.includes('Login') || currentUrl.includes('login')) {
      console.log('On login page, logging in...');
      
      // Wait for login form to be visible
      await page.waitForSelector('input[type="email"], #Input_Email', { timeout: 5000 });
      
      // Fill credentials
      await page.fill('input[type="email"], #Input_Email', 'admin@steelestimation.com');
      await page.fill('input[type="password"], #Input_Password', 'Admin@123');
      
      // Submit form
      await page.click('button[type="submit"]');
      
      // Wait for navigation
      await page.waitForLoadState('networkidle');
      console.log('Login successful, now at:', page.url());
    }
    
    // Now navigate directly to the ViewScape test page
    console.log('Navigating to ViewScape test page...');
    await page.goto('http://localhost:8080/viewscape-test');
    await page.waitForLoadState('networkidle');
    
    // Wait for ViewScape to initialize
    console.log('Waiting for ViewScape to initialize...');
    await page.waitForTimeout(3000);
    
    // Check for ViewScape elements
    const pageTitle = await page.title();
    const h1Text = await page.locator('h1').textContent().catch(() => 'No H1 found');
    
    console.log('Page Title:', pageTitle);
    console.log('H1 Content:', h1Text);
    console.log('Current URL:', page.url());
    
    // Look for ViewScape header and toolbar
    const viewscapeHeader = await page.locator('.viewscape-header').count();
    const viewscapeToolbar = await page.locator('.viewscape-toolbar').count();
    const viewModeButtons = await page.locator('.view-mode-buttons').count();
    const tableExists = await page.locator('.test-viewscape-table').count();
    
    console.log('\n=== ViewScape Component Check ===');
    console.log('ViewScape Header Found:', viewscapeHeader > 0);
    console.log('ViewScape Toolbar Found:', viewscapeToolbar > 0);
    console.log('View Mode Buttons Found:', viewModeButtons > 0);
    console.log('Test Table Found:', tableExists > 0);
    
    // Check if ViewScape JavaScript initialized
    const viewscapeInitialized = await page.evaluate(() => {
      return typeof window.viewscape !== 'undefined';
    });
    console.log('ViewScape JS Initialized:', viewscapeInitialized);
    
    // Take screenshot
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const screenshotPath = `/mnt/c/Fab.OS Platform/Fab O.S/viewscape-test-${timestamp}.png`;
    await page.screenshot({ 
      path: screenshotPath,
      fullPage: true 
    });
    console.log('\nScreenshot saved to:', screenshotPath);
    
    // Check console for any errors
    page.on('console', msg => {
      if (msg.type() === 'error') {
        console.log('Console Error:', msg.text());
      }
    });
    
    console.log('\nTest completed. Browser will remain open for 30 seconds...');
    await page.waitForTimeout(30000);
    
  } catch (error) {
    console.error('Error during test:', error);
    
    // Take error screenshot
    await page.screenshot({ 
      path: `/mnt/c/Fab.OS Platform/Fab O.S/viewscape-error.png`,
      fullPage: true 
    });
  } finally {
    await browser.close();
  }
})();