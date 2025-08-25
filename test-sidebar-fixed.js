const { chromium } = require('playwright');

(async () => {
    console.log('Testing if sidebar issue is fixed...');
    const browser = await chromium.launch({ 
        headless: false,
        slowMo: 300
    });
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 }
    });
    const page = await context.newPage();

    try {
        // Navigate to the application
        console.log('1. Navigating to http://localhost:8080...');
        await page.goto('http://localhost:8080', { waitUntil: 'networkidle' });
        
        // Check if sidebar is NOT visible on landing page
        console.log('2. Checking landing page layout...');
        const sidebarOnLanding = await page.locator('.sidebar').count();
        console.log(`   Sidebar elements on landing page: ${sidebarOnLanding}`);
        
        // Take screenshot of landing page
        await page.screenshot({ path: 'fixed-1-landing.png', fullPage: true });
        console.log('   ✓ Screenshot saved: fixed-1-landing.png');
        
        // Click Sign In
        console.log('3. Clicking Sign In...');
        await page.click('a:has-text("Sign In"), button:has-text("Sign In")');
        await page.waitForNavigation({ waitUntil: 'networkidle' });
        
        // Login
        console.log('4. Logging in...');
        await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
        await page.fill('input[name="Input.Password"]', 'Admin@123');
        await page.click('button[type="submit"]');
        await page.waitForNavigation({ waitUntil: 'networkidle' });
        
        // Check sidebar after login
        console.log('5. Checking sidebar after login...');
        const sidebarAfterLogin = await page.locator('.sidebar').count();
        console.log(`   Sidebar elements after login: ${sidebarAfterLogin}`);
        
        if (sidebarAfterLogin > 0) {
            const sidebarStyles = await page.evaluate(() => {
                const sidebar = document.querySelector('.sidebar');
                const computed = window.getComputedStyle(sidebar);
                return {
                    position: computed.position,
                    width: computed.width,
                    backgroundColor: computed.backgroundColor,
                    left: computed.left,
                    display: computed.display
                };
            });
            console.log('   Sidebar styles:');
            Object.entries(sidebarStyles).forEach(([key, value]) => {
                console.log(`     ${key}: ${value}`);
            });
        }
        
        // Take screenshot after login
        await page.screenshot({ path: 'fixed-2-after-login.png', fullPage: true });
        console.log('   ✓ Screenshot saved: fixed-2-after-login.png');
        
        console.log('\n✓ Test complete!');
        
    } catch (error) {
        console.error('Error during test:', error);
        await page.screenshot({ path: 'fixed-error.png', fullPage: true });
    } finally {
        console.log('\nBrowser will remain open for 10 seconds...');
        await page.waitForTimeout(10000);
        await browser.close();
    }
})();