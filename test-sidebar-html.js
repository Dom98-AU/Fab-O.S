const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();
    
    console.log('Navigating to http://localhost:8080...');
    await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded' });
    
    // Wait for content to load
    await page.waitForTimeout(2000);
    
    // Get the main layout structure
    const layoutInfo = await page.evaluate(() => {
        const pageEl = document.querySelector('.page');
        const sidebarEl = document.querySelector('.sidebar');
        const mainEl = document.querySelector('main');
        
        const result = {
            hasPage: !!pageEl,
            hasSidebar: !!sidebarEl,
            hasMain: !!mainEl,
            pageHTML: pageEl ? pageEl.outerHTML.substring(0, 500) : null,
            sidebarComputedStyles: null,
            mainComputedStyles: null,
            bodyClasses: document.body.className,
            htmlClasses: document.documentElement.className
        };
        
        if (sidebarEl) {
            const sidebarStyles = window.getComputedStyle(sidebarEl);
            result.sidebarComputedStyles = {
                position: sidebarStyles.position,
                width: sidebarStyles.width,
                marginLeft: sidebarStyles.marginLeft,
                left: sidebarStyles.left,
                top: sidebarStyles.top,
                display: sidebarStyles.display,
                transform: sidebarStyles.transform
            };
        }
        
        if (mainEl) {
            const mainStyles = window.getComputedStyle(mainEl);
            result.mainComputedStyles = {
                marginLeft: mainStyles.marginLeft,
                position: mainStyles.position,
                display: mainStyles.display,
                width: mainStyles.width
            };
        }
        
        return result;
    });
    
    console.log('\n=== LAYOUT STRUCTURE ===');
    console.log(JSON.stringify(layoutInfo, null, 2));
    
    // Take screenshot
    await page.screenshot({ path: 'sidebar-current-state.png', fullPage: true });
    console.log('\nScreenshot saved as sidebar-current-state.png');
    
    await browser.close();
})();