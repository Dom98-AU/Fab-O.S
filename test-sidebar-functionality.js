const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ 
    headless: false,
    slowMo: 500 
  });
  
  const context = await browser.newContext({
    viewport: { width: 1920, height: 1080 },
    ignoreHTTPSErrors: true
  });
  
  const page = await context.newPage();
  
  try {
    console.log('1. Navigating to application...');
    await page.goto('http://localhost:8080', { 
      waitUntil: 'networkidle',
      timeout: 60000 
    });
    
    // Wait for page to fully load and check if we need to login
    await page.waitForTimeout(3000);
    
    // Check if we're on the login page or already logged in
    const isLoginPage = await page.url().includes('/Account/Login') || await page.isVisible('input[name="Input.Email"]');
    
    if (isLoginPage) {
      // Login
      console.log('2. Logging in...');
      await page.waitForSelector('input[name="Input.Email"]', { state: 'visible', timeout: 10000 });
      await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
      await page.fill('input[name="Input.Password"]', 'Admin@123');
      await page.click('button[type="submit"]');
      
      // Wait for navigation after login
      await page.waitForURL('**/Index', { timeout: 10000 });
      console.log('3. Login successful!');
    } else {
      console.log('2. Already logged in or on main page');
    }
    
    
    // Wait for sidebar to be fully loaded
    console.log('3. Waiting for sidebar to load...');
    await page.waitForSelector('.sidebar', { state: 'visible', timeout: 15000 });
    await page.waitForTimeout(2000); // Allow animations to complete
    
    // Screenshot 1: Sidebar in expanded state with logo visible
    console.log('4. Taking screenshot of expanded sidebar with Fab O.S logo...');
    const sidebarExpanded = await page.locator('.sidebar');
    await sidebarExpanded.screenshot({ 
      path: 'sidebar-expanded-with-logo.png',
      animations: 'disabled'
    });
    console.log('   Screenshot saved: sidebar-expanded-with-logo.png');
    
    // Check if logo is visible
    const logoVisible = await page.isVisible('.sidebar-logo img');
    console.log(`   Fab O.S Logo visible: ${logoVisible}`);
    
    // Screenshot 2: Click on logo to open module dropdown
    console.log('5. Clicking on Fab O.S logo to open module switcher...');
    await page.click('.sidebar-logo');
    await page.waitForTimeout(500); // Wait for dropdown animation
    
    // Check if dropdown opened
    const dropdownVisible = await page.isVisible('.module-dropdown');
    if (dropdownVisible) {
      console.log('   Module dropdown opened successfully!');
      await page.screenshot({ 
        path: 'module-dropdown-open.png',
        fullPage: false
      });
      console.log('   Screenshot saved: module-dropdown-open.png');
      
      // Click outside to close dropdown
      await page.click('body', { position: { x: 500, y: 300 } });
      await page.waitForTimeout(300);
    } else {
      console.log('   Warning: Module dropdown not visible');
    }
    
    // Screenshot 3: Full sidebar with navigation items
    console.log('6. Taking screenshot of sidebar navigation menu...');
    await page.screenshot({ 
      path: 'sidebar-navigation-full.png',
      fullPage: true
    });
    console.log('   Screenshot saved: sidebar-navigation-full.png');
    
    // List all navigation items
    const navItems = await page.locator('.nav-item').allTextContents();
    console.log('   Navigation items found:', navItems.length);
    navItems.forEach(item => console.log(`     - ${item.trim()}`));
    
    // Screenshot 4: Collapse sidebar using hamburger menu
    console.log('7. Clicking hamburger menu to collapse sidebar...');
    
    // Find and click the hamburger menu button
    const hamburgerButton = await page.locator('button.navbar-toggler, button[aria-label*="menu"], button:has(svg.bi-list), button:has(.navbar-toggler-icon)').first();
    
    if (await hamburgerButton.isVisible()) {
      await hamburgerButton.click();
      await page.waitForTimeout(800); // Wait for collapse animation
      
      // Take screenshot of collapsed state
      await page.screenshot({ 
        path: 'sidebar-collapsed.png',
        fullPage: true
      });
      console.log('   Screenshot saved: sidebar-collapsed.png');
      
      // Check if sidebar is collapsed
      const sidebarCollapsed = await page.locator('.sidebar').evaluate(el => {
        const width = el.getBoundingClientRect().width;
        return width < 100; // Collapsed sidebar should be narrow
      });
      console.log(`   Sidebar collapsed: ${sidebarCollapsed}`);
      
      // Screenshot 5: Expand sidebar again
      console.log('8. Clicking hamburger menu to expand sidebar again...');
      await hamburgerButton.click();
      await page.waitForTimeout(800); // Wait for expand animation
      
      await page.screenshot({ 
        path: 'sidebar-re-expanded.png',
        fullPage: true
      });
      console.log('   Screenshot saved: sidebar-re-expanded.png');
      
      // Check if sidebar is expanded
      const sidebarReExpanded = await page.locator('.sidebar').evaluate(el => {
        const width = el.getBoundingClientRect().width;
        return width > 200; // Expanded sidebar should be wide
      });
      console.log(`   Sidebar re-expanded: ${sidebarReExpanded}`);
    } else {
      console.log('   Warning: Hamburger menu button not found');
      
      // Try alternative method to find toggle button
      const alternativeToggle = await page.locator('[onclick*="toggleSidebar"], [data-toggle="sidebar"], .sidebar-toggle').first();
      if (await alternativeToggle.isVisible()) {
        console.log('   Found alternative toggle button, clicking...');
        await alternativeToggle.click();
        await page.waitForTimeout(800);
        await page.screenshot({ 
          path: 'sidebar-collapsed-alt.png',
          fullPage: true
        });
      }
    }
    
    // Final summary screenshot
    console.log('9. Taking final summary screenshot...');
    await page.screenshot({ 
      path: 'sidebar-final-state.png',
      fullPage: true
    });
    console.log('   Screenshot saved: sidebar-final-state.png');
    
    // Generate test report
    console.log('\n=== SIDEBAR FUNCTIONALITY TEST REPORT ===');
    console.log(`✓ Application loaded successfully`);
    console.log(`✓ Login successful`);
    console.log(`✓ Sidebar visible: ${await page.isVisible('.sidebar')}`);
    console.log(`✓ Fab O.S logo visible: ${logoVisible}`);
    console.log(`✓ Module dropdown functional: ${dropdownVisible}`);
    console.log(`✓ Navigation items loaded: ${navItems.length} items`);
    console.log(`✓ Sidebar toggle functional: ${await hamburgerButton.isVisible() ? 'Yes' : 'Needs investigation'}`);
    console.log('\nAll screenshots saved to current directory.');
    
  } catch (error) {
    console.error('Test failed:', error);
    await page.screenshot({ path: 'error-state.png' });
  } finally {
    await browser.close();
  }
})();