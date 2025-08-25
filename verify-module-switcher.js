const playwright = require('playwright');

(async () => {
    const browser = await playwright.chromium.launch({ headless: false });
    const page = await browser.newContext().then(ctx => ctx.newPage());
    
    console.log('Testing Module Switcher Integration...\n');
    
    // Navigate to login page
    await page.goto('http://localhost:8080/Account/Login');
    await page.waitForTimeout(2000);
    
    // Login
    await page.fill('input#email', 'admin@steelestimation.com');
    await page.fill('input#password', 'Admin@123');
    await page.click('button[type="submit"]');
    await page.waitForTimeout(3000);
    
    // Check for old separate module switcher
    const oldSwitcher = await page.$('.module-switcher');
    console.log('❌ Old separate .module-switcher:', oldSwitcher ? 'STILL PRESENT!' : 'Not found (good!)');
    
    // Check if logo is clickable
    const logo = await page.$('.sidebar-logo');
    console.log('✓ Logo element found:', !!logo);
    
    // Click logo to open dropdown
    if (logo) {
        await page.click('.sidebar-logo');
        await page.waitForTimeout(1000);
        
        // Check for module dropdown menu
        const dropdown = await page.$('.module-dropdown-menu');
        console.log('✓ Module dropdown appears on logo click:', !!dropdown);
        
        if (dropdown) {
            // Get available modules
            const modules = await page.$$eval('.module-item .item-name', 
                items => items.map(item => item.textContent)
            );
            console.log('✓ Available modules:', modules);
            
            // Check for Settings module
            console.log('✓ Settings module present:', modules.includes('Settings'));
        }
        
        // Click logo again to close
        await page.click('.sidebar-logo');
        await page.waitForTimeout(500);
        
        const dropdownClosed = await page.$('.module-dropdown-menu');
        console.log('✓ Dropdown closes on second click:', !dropdownClosed);
    }
    
    await page.screenshot({ path: 'module-switcher-verified.png' });
    console.log('\n✅ Test complete. Screenshot saved as module-switcher-verified.png');
    
    await browser.close();
})().catch(console.error);