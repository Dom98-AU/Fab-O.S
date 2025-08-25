const { chromium } = require('playwright');

(async () => {
    console.log('Starting sidebar investigation...');
    const browser = await chromium.launch({ 
        headless: false,
        slowMo: 500
    });
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 }
    });
    const page = await context.newPage();

    try {
        // Navigate to the application
        console.log('1. Navigating to http://localhost:8080...');
        await page.goto('http://localhost:8080', { waitUntil: 'networkidle' });
        
        // Take screenshot of landing page
        await page.screenshot({ path: 'investigation-1-landing.png', fullPage: true });
        console.log('   ✓ Screenshot saved: investigation-1-landing.png');

        // Login
        console.log('2. Logging in...');
        await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
        await page.fill('input[name="Input.Password"]', 'Admin@123');
        await page.click('button[type="submit"]');
        
        // Wait for navigation after login
        await page.waitForNavigation({ waitUntil: 'networkidle' });
        console.log('   ✓ Login successful');
        
        // Take screenshot after login
        await page.screenshot({ path: 'investigation-2-after-login.png', fullPage: true });
        console.log('   ✓ Screenshot saved: investigation-2-after-login.png');

        // Check for sidebar element
        console.log('3. Checking for sidebar element...');
        const sidebarExists = await page.locator('.sidebar').count() > 0;
        console.log(`   Sidebar element exists: ${sidebarExists}`);
        
        if (sidebarExists) {
            // Get sidebar HTML
            const sidebarHTML = await page.locator('.sidebar').innerHTML();
            console.log('   Sidebar HTML structure found (truncated):');
            console.log('   ' + sidebarHTML.substring(0, 200) + '...');
            
            // Get computed styles
            const sidebarStyles = await page.locator('.sidebar').evaluate(el => {
                const computed = window.getComputedStyle(el);
                return {
                    display: computed.display,
                    position: computed.position,
                    width: computed.width,
                    height: computed.height,
                    left: computed.left,
                    transform: computed.transform,
                    visibility: computed.visibility,
                    opacity: computed.opacity,
                    zIndex: computed.zIndex,
                    backgroundColor: computed.backgroundColor
                };
            });
            console.log('   Sidebar computed styles:');
            Object.entries(sidebarStyles).forEach(([key, value]) => {
                console.log(`     ${key}: ${value}`);
            });
            
            // Check if sidebar has the collapsed class
            const hasCollapsedClass = await page.locator('.sidebar.sidebar-collapsed').count() > 0;
            console.log(`   Sidebar has 'sidebar-collapsed' class: ${hasCollapsedClass}`);
            
            // Check page element
            const pageStyles = await page.locator('.page').evaluate(el => {
                const computed = window.getComputedStyle(el);
                return {
                    display: computed.display,
                    position: computed.position,
                    classList: Array.from(el.classList)
                };
            });
            console.log('   Page element styles:');
            console.log(`     display: ${pageStyles.display}`);
            console.log(`     position: ${pageStyles.position}`);
            console.log(`     classes: ${pageStyles.classList.join(', ')}`);
        } else {
            console.log('   ⚠ Sidebar element not found!');
        }
        
        // Check main content positioning
        console.log('4. Checking main content positioning...');
        const mainExists = await page.locator('main').count() > 0;
        if (mainExists) {
            const mainStyles = await page.locator('main').evaluate(el => {
                const computed = window.getComputedStyle(el);
                return {
                    marginLeft: computed.marginLeft,
                    width: computed.width,
                    position: computed.position
                };
            });
            console.log('   Main element styles:');
            Object.entries(mainStyles).forEach(([key, value]) => {
                console.log(`     ${key}: ${value}`);
            });
        }
        
        // Check for CSS file loading
        console.log('5. Checking CSS file loading...');
        const cssLoaded = await page.evaluate(() => {
            const stylesheets = Array.from(document.styleSheets);
            return stylesheets.some(sheet => sheet.href && sheet.href.includes('site.css'));
        });
        console.log(`   site.css loaded: ${cssLoaded}`);
        
        // Check localStorage
        console.log('6. Checking localStorage...');
        const sidebarState = await page.evaluate(() => localStorage.getItem('sidebarOpen'));
        console.log(`   localStorage sidebarOpen: ${sidebarState}`);
        
        // Check for JavaScript errors
        console.log('7. Checking for console errors...');
        page.on('console', msg => {
            if (msg.type() === 'error') {
                console.log(`   Console error: ${msg.text()}`);
            }
        });
        
        // Try to toggle sidebar
        console.log('8. Attempting to toggle sidebar...');
        const toggleButtonExists = await page.locator('.menu-toggle-btn').count() > 0;
        console.log(`   Toggle button exists: ${toggleButtonExists}`);
        
        if (toggleButtonExists) {
            await page.click('.menu-toggle-btn');
            await page.waitForTimeout(1000);
            
            // Check sidebar state after toggle
            const sidebarAfterToggle = await page.locator('.sidebar').evaluate(el => {
                const computed = window.getComputedStyle(el);
                return {
                    transform: computed.transform,
                    classList: Array.from(el.classList)
                };
            });
            console.log('   Sidebar after toggle:');
            console.log(`     transform: ${sidebarAfterToggle.transform}`);
            console.log(`     classes: ${sidebarAfterToggle.classList.join(', ')}`);
            
            await page.screenshot({ path: 'investigation-3-after-toggle.png', fullPage: true });
            console.log('   ✓ Screenshot saved: investigation-3-after-toggle.png');
        }
        
        // Execute updateSidebarState function directly
        console.log('9. Testing updateSidebarState function...');
        const functionExists = await page.evaluate(() => typeof window.updateSidebarState === 'function');
        console.log(`   updateSidebarState function exists: ${functionExists}`);
        
        if (functionExists) {
            // Try to show sidebar
            await page.evaluate(() => window.updateSidebarState(true));
            await page.waitForTimeout(500);
            
            const sidebarAfterShow = await page.locator('.sidebar').evaluate(el => {
                const computed = window.getComputedStyle(el);
                return {
                    transform: computed.transform,
                    classList: Array.from(el.classList)
                };
            });
            console.log('   After updateSidebarState(true):');
            console.log(`     transform: ${sidebarAfterShow.transform}`);
            console.log(`     classes: ${sidebarAfterShow.classList.join(', ')}`);
            
            await page.screenshot({ path: 'investigation-4-after-show.png', fullPage: true });
            console.log('   ✓ Screenshot saved: investigation-4-after-show.png');
        }
        
        // Save the complete page HTML for inspection
        const pageHTML = await page.content();
        const fs = require('fs');
        fs.writeFileSync('investigation-page.html', pageHTML);
        console.log('   ✓ Page HTML saved to investigation-page.html');
        
        console.log('\n✓ Investigation complete!');
        console.log('Please review the screenshots and output above.');
        
    } catch (error) {
        console.error('Error during investigation:', error);
        await page.screenshot({ path: 'investigation-error.png', fullPage: true });
    } finally {
        await browser.close();
    }
})();