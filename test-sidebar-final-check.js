const { chromium } = require('playwright');

(async () => {
    console.log('Starting final sidebar check...');
    const browser = await chromium.launch({ 
        headless: false,
        slowMo: 300
    });
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 },
        // Clear any cached data
        storageState: undefined
    });
    const page = await context.newPage();

    try {
        // Navigate to the application with cache bypass
        console.log('1. Navigating to http://localhost:8080 (bypassing cache)...');
        await page.goto('http://localhost:8080', { 
            waitUntil: 'networkidle',
            // Force reload to bypass cache
            bypassCSP: true
        });
        
        // Force reload to ensure fresh CSS
        await page.reload({ waitUntil: 'networkidle' });
        
        // Wait for sidebar to be rendered
        await page.waitForSelector('.sidebar', { timeout: 5000 });
        
        // Check sidebar styles
        console.log('2. Checking sidebar styles...');
        const sidebarCheck = await page.evaluate(() => {
            const sidebar = document.querySelector('.sidebar');
            if (!sidebar) return { exists: false };
            
            const computed = window.getComputedStyle(sidebar);
            const page = document.querySelector('.page');
            const main = document.querySelector('main');
            
            return {
                exists: true,
                sidebar: {
                    position: computed.position,
                    width: computed.width,
                    height: computed.height,
                    backgroundColor: computed.backgroundColor,
                    left: computed.left,
                    top: computed.top,
                    transform: computed.transform,
                    display: computed.display,
                    zIndex: computed.zIndex,
                    borderRight: computed.borderRight
                },
                page: page ? {
                    classes: Array.from(page.classList)
                } : null,
                main: main ? {
                    marginLeft: window.getComputedStyle(main).marginLeft
                } : null,
                cssFileLoaded: Array.from(document.querySelectorAll('link[rel="stylesheet"]'))
                    .some(link => link.href.includes('site.css'))
            };
        });
        
        console.log('   CSS file loaded:', sidebarCheck.cssFileLoaded);
        console.log('   Sidebar exists:', sidebarCheck.exists);
        
        if (sidebarCheck.exists) {
            console.log('   Sidebar styles:');
            Object.entries(sidebarCheck.sidebar).forEach(([key, value]) => {
                const expected = {
                    position: 'fixed',
                    width: '250px',
                    height: '1080px',
                    backgroundColor: 'rgb(255, 255, 255)',
                    left: '0px',
                    top: '0px'
                };
                const isCorrect = expected[key] ? value === expected[key] : true;
                console.log(`     ${key}: ${value}${isCorrect ? ' ✓' : expected[key] ? ` (expected: ${expected[key]})` : ''}`);
            });
            
            if (sidebarCheck.main) {
                console.log('   Main content margin-left:', sidebarCheck.main.marginLeft);
            }
            
            if (sidebarCheck.page) {
                console.log('   Page classes:', sidebarCheck.page.classes.join(', '));
            }
        }
        
        // Take screenshot
        await page.screenshot({ path: 'sidebar-final-landing.png', fullPage: true });
        console.log('   ✓ Screenshot saved: sidebar-final-landing.png');
        
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
        await page.waitForSelector('.sidebar', { timeout: 5000 });
        
        const afterLoginCheck = await page.evaluate(() => {
            const sidebar = document.querySelector('.sidebar');
            const computed = window.getComputedStyle(sidebar);
            return {
                position: computed.position,
                width: computed.width,
                backgroundColor: computed.backgroundColor,
                transform: computed.transform,
                hasNavMenu: document.querySelector('.sidebar .nav-menu') !== null,
                navItemCount: document.querySelectorAll('.sidebar .nav-item').length
            };
        });
        
        console.log('   Sidebar after login:');
        Object.entries(afterLoginCheck).forEach(([key, value]) => {
            console.log(`     ${key}: ${value}`);
        });
        
        // Take screenshot after login
        await page.screenshot({ path: 'sidebar-final-after-login.png', fullPage: true });
        console.log('   ✓ Screenshot saved: sidebar-final-after-login.png');
        
        // Try toggle
        console.log('6. Testing sidebar toggle...');
        const toggleBtn = await page.locator('.menu-toggle-btn').count() > 0;
        if (toggleBtn) {
            await page.click('.menu-toggle-btn');
            await page.waitForTimeout(500);
            
            const afterToggle = await page.evaluate(() => {
                const sidebar = document.querySelector('.sidebar');
                return {
                    transform: window.getComputedStyle(sidebar).transform,
                    classes: Array.from(sidebar.classList)
                };
            });
            console.log('   After toggle:');
            console.log(`     transform: ${afterToggle.transform}`);
            console.log(`     classes: ${afterToggle.classes.join(', ')}`);
            
            await page.screenshot({ path: 'sidebar-final-after-toggle.png', fullPage: true });
            console.log('   ✓ Screenshot saved: sidebar-final-after-toggle.png');
        }
        
        console.log('\n✓ Final check complete!');
        
    } catch (error) {
        console.error('Error during final check:', error);
        await page.screenshot({ path: 'sidebar-final-error.png', fullPage: true });
    } finally {
        console.log('\nBrowser will remain open for 10 seconds for inspection...');
        await page.waitForTimeout(10000);
        await browser.close();
    }
})();