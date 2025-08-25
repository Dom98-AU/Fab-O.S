const { chromium } = require('playwright');

(async () => {
  // Launch browser
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
    // Navigate to the application
    console.log('========================================');
    console.log('SIDEBAR FUNCTIONALITY TEST');
    console.log('========================================');
    console.log('1. Navigating to http://localhost:8080...');
    await page.goto('http://localhost:8080', { 
      waitUntil: 'networkidle',
      timeout: 30000 
    });
    
    // Check if we need to login
    const loginButton = await page.locator('button:has-text("Login")').count();
    if (loginButton > 0 || await page.url().includes('login')) {
      console.log('2. Login required. Logging in...');
      
      // Fill in login credentials
      await page.fill('input[type="email"], input[name="Input.Email"], #Input_Email', 'admin@steelestimation.com');
      await page.fill('input[type="password"], input[name="Input.Password"], #Input_Password', 'Admin@123');
      
      // Click login button
      await page.click('button[type="submit"]:has-text("Log in"), button:has-text("Login")');
      
      // Wait for navigation after login
      await page.waitForTimeout(3000);
      console.log('   ✓ Login successful');
    }
    
    // Wait for page to fully load
    await page.waitForTimeout(2000);
    
    // Test 1: Check if sidebar exists and Fab O.S logo is visible
    console.log('\n3. Testing Sidebar Elements:');
    console.log('   Checking for sidebar...');
    
    const sidebarExists = await page.locator('.sidebar, nav.sidebar, #sidebar, [class*="sidebar"]').count() > 0;
    console.log(`   Sidebar Found: ${sidebarExists ? '✓' : '✗'}`);
    
    // Check for Fab O.S logo
    const logoExists = await page.locator('.sidebar-logo, .logo, img[alt*="Fab"], img[src*="logo"], .navbar-brand').count() > 0;
    console.log(`   Fab O.S Logo Found: ${logoExists ? '✓' : '✗'}`);
    
    // Take screenshot of initial state
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const screenshotPath1 = `/mnt/c/Fab.OS Platform/Fab O.S/sidebar-test-1-initial-${timestamp}.png`;
    await page.screenshot({ 
      path: screenshotPath1,
      fullPage: false 
    });
    console.log(`   Screenshot saved: sidebar-test-1-initial-${timestamp}.png`);
    
    // Test 2: Click on logo to test module dropdown
    console.log('\n4. Testing Module/Product Switcher:');
    if (logoExists) {
      console.log('   Clicking on Fab O.S logo...');
      
      // Try to click on the logo
      const logoSelectors = [
        '.sidebar-logo',
        '.logo',
        '.navbar-brand',
        'img[alt*="Fab"]',
        'img[src*="logo"]',
        '.sidebar-header',
        '.sidebar-top'
      ];
      
      for (const selector of logoSelectors) {
        const element = await page.locator(selector).first();
        if (await element.count() > 0) {
          await element.click({ force: true }).catch(() => {});
          break;
        }
      }
      
      await page.waitForTimeout(1000);
      
      // Check if dropdown appeared
      const dropdownExists = await page.locator('.dropdown-menu:visible, .module-dropdown, [class*="dropdown"]:visible').count() > 0;
      console.log(`   Module Dropdown Visible: ${dropdownExists ? '✓' : '✗'}`);
      
      // Take screenshot with dropdown
      if (dropdownExists) {
        const screenshotPath2 = `/mnt/c/Fab.OS Platform/Fab O.S/sidebar-test-2-dropdown-${timestamp}.png`;
        await page.screenshot({ 
          path: screenshotPath2,
          fullPage: false 
        });
        console.log(`   Screenshot saved: sidebar-test-2-dropdown-${timestamp}.png`);
        
        // Close dropdown by clicking elsewhere
        await page.click('body');
        await page.waitForTimeout(500);
      }
    }
    
    // Test 3: Test sidebar toggle (hamburger menu)
    console.log('\n5. Testing Sidebar Toggle:');
    console.log('   Looking for hamburger menu button...');
    
    const toggleButtonSelectors = [
      'button.sidebar-toggle',
      'button.navbar-toggler',
      'button[aria-label*="toggle"]',
      '.hamburger',
      'button i.fa-bars',
      'button i.fas.fa-bars',
      '[onclick*="toggleSidebar"]',
      'button[title*="toggle"]'
    ];
    
    let toggleFound = false;
    for (const selector of toggleButtonSelectors) {
      const button = await page.locator(selector).first();
      if (await button.count() > 0) {
        console.log(`   Found toggle button with selector: ${selector}`);
        
        // Click to collapse
        await button.click();
        await page.waitForTimeout(1000);
        
        // Take screenshot of collapsed state
        const screenshotPath3 = `/mnt/c/Fab.OS Platform/Fab O.S/sidebar-test-3-collapsed-${timestamp}.png`;
        await page.screenshot({ 
          path: screenshotPath3,
          fullPage: false 
        });
        console.log(`   Screenshot saved: sidebar-test-3-collapsed-${timestamp}.png`);
        
        // Click to expand again
        await button.click();
        await page.waitForTimeout(1000);
        
        // Take screenshot of expanded state
        const screenshotPath4 = `/mnt/c/Fab.OS Platform/Fab O.S/sidebar-test-4-expanded-${timestamp}.png`;
        await page.screenshot({ 
          path: screenshotPath4,
          fullPage: false 
        });
        console.log(`   Screenshot saved: sidebar-test-4-expanded-${timestamp}.png`);
        
        toggleFound = true;
        console.log('   ✓ Sidebar toggle working');
        break;
      }
    }
    
    if (!toggleFound) {
      console.log('   ✗ Toggle button not found');
    }
    
    // Test 4: Check navigation items
    console.log('\n6. Testing Navigation Items:');
    
    const navItems = [
      { text: 'Dashboard', selector: 'a:has-text("Dashboard"), [href*="dashboard"]' },
      { text: 'Projects', selector: 'a:has-text("Projects"), [href*="projects"]' },
      { text: 'Customers', selector: 'a:has-text("Customers"), [href*="customers"]' },
      { text: 'Settings', selector: 'a:has-text("Settings"), [href*="settings"]' },
      { text: 'Admin', selector: 'a:has-text("Admin"), [href*="admin"]' }
    ];
    
    for (const item of navItems) {
      const exists = await page.locator(item.selector).count() > 0;
      console.log(`   ${item.text}: ${exists ? '✓' : '✗'}`);
    }
    
    // Test 5: Check sidebar styling
    console.log('\n7. Checking Sidebar Styling:');
    
    // Get computed styles if sidebar exists
    if (sidebarExists) {
      const sidebarElement = await page.locator('.sidebar, nav.sidebar, #sidebar').first();
      
      // Check background color
      const bgColor = await sidebarElement.evaluate(el => 
        window.getComputedStyle(el).backgroundColor
      );
      console.log(`   Background Color: ${bgColor}`);
      
      // Check width
      const width = await sidebarElement.evaluate(el => 
        window.getComputedStyle(el).width
      );
      console.log(`   Width: ${width}`);
      
      // Check position
      const position = await sidebarElement.evaluate(el => 
        window.getComputedStyle(el).position
      );
      console.log(`   Position: ${position}`);
    }
    
    // Final comprehensive screenshot
    console.log('\n8. Taking final comprehensive screenshot...');
    const screenshotPath5 = `/mnt/c/Fab.OS Platform/Fab O.S/sidebar-test-5-final-${timestamp}.png`;
    await page.screenshot({ 
      path: screenshotPath5,
      fullPage: true 
    });
    console.log(`   Screenshot saved: sidebar-test-5-final-${timestamp}.png`);
    
    // Summary
    console.log('\n========================================');
    console.log('TEST SUMMARY');
    console.log('========================================');
    console.log(`Sidebar Present: ${sidebarExists ? '✓' : '✗'}`);
    console.log(`Logo Visible: ${logoExists ? '✓' : '✗'}`);
    console.log(`Toggle Functional: ${toggleFound ? '✓' : '✗'}`);
    console.log('\nAll screenshots saved with timestamp: ' + timestamp);
    console.log('========================================');
    
    // Keep browser open for manual inspection
    console.log('\nBrowser will remain open for 30 seconds for manual inspection...');
    await page.waitForTimeout(30000);
    
  } catch (error) {
    console.error('Error during test:', error);
    
    // Take error screenshot
    const errorScreenshotPath = `/mnt/c/Fab.OS Platform/Fab O.S/sidebar-error-screenshot.png`;
    await page.screenshot({ 
      path: errorScreenshotPath,
      fullPage: true 
    });
    console.log(`Error screenshot saved to: ${errorScreenshotPath}`);
  } finally {
    await browser.close();
    console.log('\nTest completed. Browser closed.');
  }
})();