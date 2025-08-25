const { chromium } = require('playwright');

async function quickLoginTest() {
    console.log('Starting quick login test...');
    const browser = await chromium.launch({ 
        headless: false,
        args: ['--disable-dev-shm-usage']
    });
    
    const page = await browser.newPage();
    
    try {
        // Navigate to login
        console.log('1. Going to login page...');
        await page.goto('http://localhost:8080/Account/Login', { 
            waitUntil: 'domcontentloaded',
            timeout: 15000 
        });
        
        await page.screenshot({ path: 'quick-1-login.png' });
        
        // Login
        console.log('2. Logging in...');
        await page.fill('input[type="email"]', 'admin@steelestimation.com');
        await page.fill('input[type="password"]', 'Admin@123');
        await page.click('button[type="submit"]');
        
        // Wait a bit for redirect
        console.log('3. Waiting for redirect...');
        await page.waitForTimeout(5000);
        
        // Check current state
        const url = page.url();
        console.log(`Current URL: ${url}`);
        
        await page.screenshot({ path: 'quick-2-after-login.png' });
        
        // Check for sidebar
        console.log('4. Checking for sidebar...');
        const sidebar = await page.$('.sidebar, #sidebar, nav, aside');
        if (sidebar) {
            const box = await sidebar.boundingBox();
            console.log(`Sidebar found: ${box.width}x${box.height} at x=${box.x}`);
        } else {
            console.log('No sidebar found');
        }
        
        // Check for nav items
        const navItems = await page.$$eval('a', links => 
            links.map(a => a.textContent.trim()).filter(t => t.length > 0).slice(0, 10)
        );
        console.log('Navigation items:', navItems);
        
        // Final screenshot
        await page.screenshot({ path: 'quick-3-final.png' });
        
        console.log('\n=== RESULTS ===');
        console.log(`Login successful: ${!url.includes('Login')}`);
        console.log(`Sidebar present: ${sidebar !== null}`);
        console.log(`Nav items found: ${navItems.length}`);
        
    } catch (error) {
        console.error('Error:', error.message);
        await page.screenshot({ path: 'quick-error.png' });
    } finally {
        await browser.close();
    }
}

quickLoginTest().catch(console.error);