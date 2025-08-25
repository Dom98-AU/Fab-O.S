const playwright = require('playwright');

(async () => {
    const browser = await playwright.chromium.launch({ headless: false });
    const context = await browser.newContext();
    const page = await context.newPage();
    
    // Go to the app
    await page.goto('http://localhost:8080');
    
    // Login
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    
    // Wait for navigation
    await page.waitForTimeout(3000);
    
    // Check what's in the sidebar
    const sidebarHTML = await page.evaluate(() => {
        const sidebar = document.querySelector('.custom-sidebar');
        if (sidebar) {
            // Check for separate module switcher
            const separateSwitcher = sidebar.querySelector('.module-switcher');
            const logoArea = sidebar.querySelector('.sidebar-logo');
            
            return {
                hasSeparateSwitcher: !!separateSwitcher,
                logoHTML: logoArea ? logoArea.innerHTML.substring(0, 200) : 'No logo area found'
            };
        }
        return { error: 'No sidebar found' };
    });
    
    console.log('Sidebar Analysis:', JSON.stringify(sidebarHTML, null, 2));
    
    await browser.close();
})();
