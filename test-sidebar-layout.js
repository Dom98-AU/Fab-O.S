const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.launch({ 
        headless: false,
        args: ['--disable-dev-shm-usage']
    });
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 },
        ignoreHTTPSErrors: true
    });
    
    const page = await context.newPage();
    
    console.log('Navigating to http://localhost:8080...');
    await page.goto('http://localhost:8080', { waitUntil: 'networkidle' });
    
    // Wait for the page to fully load
    await page.waitForTimeout(3000);
    
    // Take screenshot of initial page load
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    await page.screenshot({ 
        path: `sidebar-initial-${timestamp}.png`, 
        fullPage: true 
    });
    console.log('Screenshot 1: Initial page load captured');
    
    // Check sidebar positioning
    const sidebar = await page.locator('.sidebar').first();
    const sidebarBox = await sidebar.boundingBox();
    console.log('\n=== SIDEBAR POSITIONING ===');
    console.log(`Sidebar position: Left=${sidebarBox?.x}px, Top=${sidebarBox?.y}px`);
    console.log(`Sidebar dimensions: Width=${sidebarBox?.width}px, Height=${sidebarBox?.height}px`);
    
    // Check if sidebar is on the left
    if (sidebarBox?.x === 0) {
        console.log('✓ Sidebar is correctly positioned on the LEFT side');
    } else {
        console.log(`✗ Sidebar is NOT on the left (x=${sidebarBox?.x})`);
    }
    
    // Check sidebar width
    if (sidebarBox?.width === 250) {
        console.log('✓ Sidebar width is correct (250px)');
    } else {
        console.log(`✗ Sidebar width is incorrect (${sidebarBox?.width}px, expected 250px)`);
    }
    
    // Check logo position
    const logo = await page.locator('.sidebar-logo, .sidebar img').first();
    const logoBox = await logo.boundingBox();
    console.log('\n=== LOGO POSITIONING ===');
    console.log(`Logo position: Left=${logoBox?.x}px, Top=${logoBox?.y}px`);
    
    if (logoBox && logoBox.y < 100) {
        console.log('✓ Logo is at the TOP of the sidebar');
    } else {
        console.log(`✗ Logo is NOT at the top (y=${logoBox?.y})`);
    }
    
    // Check main content offset
    const mainContent = await page.locator('.main-content, main, [role="main"]').first();
    const mainBox = await mainContent.boundingBox();
    console.log('\n=== MAIN CONTENT OFFSET ===');
    console.log(`Main content position: Left=${mainBox?.x}px`);
    
    if (mainBox && mainBox.x >= 250) {
        console.log('✓ Main content is properly offset (not hidden behind sidebar)');
    } else {
        console.log(`✗ Main content may be hidden behind sidebar (x=${mainBox?.x})`);
    }
    
    // Try to find and click hamburger menu
    console.log('\n=== TESTING HAMBURGER MENU ===');
    const hamburger = await page.locator('.navbar-toggler, .hamburger-menu, [aria-label*="Toggle"], button:has(i.fa-bars)').first();
    
    if (await hamburger.isVisible()) {
        console.log('Found hamburger menu, clicking to collapse sidebar...');
        await hamburger.click();
        await page.waitForTimeout(1000);
        
        await page.screenshot({ 
            path: `sidebar-collapsed-${timestamp}.png`, 
            fullPage: true 
        });
        console.log('Screenshot 2: Sidebar collapsed state captured');
        
        // Check sidebar state after collapse
        const sidebarAfter = await page.locator('.sidebar').first();
        const sidebarCollapsed = await sidebarAfter.boundingBox();
        console.log(`Sidebar after toggle: Width=${sidebarCollapsed?.width}px`);
        
        // Click again to expand
        await hamburger.click();
        await page.waitForTimeout(1000);
        
        await page.screenshot({ 
            path: `sidebar-expanded-${timestamp}.png`, 
            fullPage: true 
        });
        console.log('Screenshot 3: Sidebar expanded state captured');
    } else {
        console.log('Hamburger menu not found or not visible');
    }
    
    // Now login to test authenticated layout
    console.log('\n=== TESTING LOGIN ===');
    
    // Look for login form
    const emailInput = await page.locator('input[type="email"], input[name*="email"], input[id*="email"]').first();
    const passwordInput = await page.locator('input[type="password"]').first();
    const loginButton = await page.locator('button[type="submit"], button:has-text("Login"), button:has-text("Sign in")').first();
    
    if (await emailInput.isVisible() && await passwordInput.isVisible()) {
        console.log('Login form found, logging in...');
        await emailInput.fill('admin@steelestimation.com');
        await passwordInput.fill('Admin@123');
        await loginButton.click();
        
        // Wait for navigation
        await page.waitForTimeout(3000);
        
        await page.screenshot({ 
            path: `sidebar-authenticated-${timestamp}.png`, 
            fullPage: true 
        });
        console.log('Screenshot 4: Authenticated layout captured');
        
        // Check sidebar after login
        const sidebarAuth = await page.locator('.sidebar').first();
        const sidebarAuthBox = await sidebarAuth.boundingBox();
        console.log('\n=== POST-LOGIN LAYOUT CHECK ===');
        console.log(`Sidebar still on left: ${sidebarAuthBox?.x === 0 ? '✓' : '✗'}`);
        console.log(`Sidebar width maintained: ${sidebarAuthBox?.width === 250 ? '✓' : '✗'}`);
    } else {
        console.log('Login form not found - may already be authenticated or on different page');
    }
    
    // Get computed styles for verification
    console.log('\n=== COMPUTED STYLES ===');
    const sidebarStyles = await page.evaluate(() => {
        const sidebar = document.querySelector('.sidebar');
        if (sidebar) {
            const styles = window.getComputedStyle(sidebar);
            return {
                position: styles.position,
                left: styles.left,
                width: styles.width,
                height: styles.height,
                zIndex: styles.zIndex,
                backgroundColor: styles.backgroundColor
            };
        }
        return null;
    });
    
    if (sidebarStyles) {
        console.log('Sidebar computed styles:', sidebarStyles);
    }
    
    const mainStyles = await page.evaluate(() => {
        const main = document.querySelector('.main-content, main');
        if (main) {
            const styles = window.getComputedStyle(main);
            return {
                marginLeft: styles.marginLeft,
                paddingLeft: styles.paddingLeft,
                position: styles.position
            };
        }
        return null;
    });
    
    if (mainStyles) {
        console.log('Main content computed styles:', mainStyles);
    }
    
    console.log('\n=== TEST COMPLETE ===');
    console.log('Screenshots saved in the current directory');
    
    await browser.close();
})().catch(console.error);