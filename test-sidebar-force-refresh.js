const { chromium } = require('playwright');

(async () => {
    console.log('Starting sidebar test with forced refresh...');
    const browser = await chromium.launch({ 
        headless: false,
        args: ['--start-maximized', '--disable-blink-features=AutomationControlled']
    });
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 },
        ignoreHTTPSErrors: true,
        // Disable cache
        bypassCSP: true,
        offline: false
    });
    
    const page = await context.newPage();
    
    try {
        // Clear all cookies and cache
        await context.clearCookies();
        
        // Navigate with cache disabled
        console.log('Navigating to http://localhost:8080 with cache disabled...');
        await page.goto('http://localhost:8080', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        
        // Hard refresh with Ctrl+Shift+R
        console.log('Performing hard refresh (Ctrl+Shift+R)...');
        await page.keyboard.down('Control');
        await page.keyboard.down('Shift');
        await page.keyboard.press('R');
        await page.keyboard.up('Shift');
        await page.keyboard.up('Control');
        await page.waitForTimeout(3000);
        
        // Check what CSS is actually loaded
        console.log('\nChecking loaded CSS version...');
        const cssInfo = await page.evaluate(() => {
            const links = Array.from(document.querySelectorAll('link[rel="stylesheet"]'));
            const siteCSS = links.find(link => link.href.includes('site.css'));
            return {
                siteCSSUrl: siteCSS ? siteCSS.href : 'Not found',
                version: siteCSS ? siteCSS.href.match(/v=(\d+)/)?.[1] : 'Unknown'
            };
        });
        
        console.log(`Site CSS URL: ${cssInfo.siteCSSUrl}`);
        console.log(`CSS Version: v${cssInfo.version} (Expected: v18)`);
        
        // Login
        const loginForm = await page.locator('form').first();
        if (await loginForm.isVisible()) {
            console.log('\nLogging in...');
            await page.fill('input[type="email"], input[name="email"], input#email', 'admin@steelestimation.com');
            await page.fill('input[type="password"], input[name="password"], input#password', 'Admin@123');
            await page.click('button[type="submit"]');
            await page.waitForTimeout(3000);
        }
        
        // Check the actual CSS rules being applied
        console.log('\n=== CSS RULES CHECK ===');
        const cssRules = await page.evaluate(() => {
            // Find the site.css stylesheet
            let siteStylesheet = null;
            for (let sheet of document.styleSheets) {
                if (sheet.href && sheet.href.includes('site.css')) {
                    siteStylesheet = sheet;
                    break;
                }
            }
            
            if (!siteStylesheet) return { error: 'site.css not found in stylesheets' };
            
            const rules = [];
            try {
                // Look for sidebar rules
                for (let rule of siteStylesheet.cssRules) {
                    if (rule.selectorText && rule.selectorText.includes('sidebar')) {
                        rules.push({
                            selector: rule.selectorText,
                            width: rule.style.width,
                            position: rule.style.position,
                            maxWidth: rule.style.maxWidth
                        });
                    }
                }
            } catch (e) {
                return { error: 'Cannot access CSS rules: ' + e.message };
            }
            
            return { rules: rules.slice(0, 10) }; // First 10 sidebar rules
        });
        
        console.log('CSS Rules found:', JSON.stringify(cssRules, null, 2));
        
        // Check actual computed styles
        console.log('\n=== COMPUTED STYLES ===');
        const computed = await page.evaluate(() => {
            const sidebar = document.querySelector('.sidebar, #main-sidebar');
            const main = document.querySelector('main, #main-content');
            
            if (!sidebar) return { error: 'Sidebar not found' };
            
            const sidebarStyles = window.getComputedStyle(sidebar);
            const mainStyles = main ? window.getComputedStyle(main) : null;
            
            return {
                sidebar: {
                    width: sidebarStyles.width,
                    maxWidth: sidebarStyles.maxWidth,
                    position: sidebarStyles.position,
                    left: sidebarStyles.left,
                    transform: sidebarStyles.transform
                },
                main: main ? {
                    marginLeft: mainStyles.marginLeft,
                    width: mainStyles.width
                } : null
            };
        });
        
        console.log('Computed styles:', JSON.stringify(computed, null, 2));
        
        // If styles are still wrong, inject correct CSS and test
        if (computed.sidebar && computed.sidebar.position !== 'fixed') {
            console.log('\n=== INJECTING CORRECT CSS ===');
            await page.addStyleTag({
                content: `
                    /* Override all sidebar styles */
                    .sidebar, #main-sidebar {
                        width: 250px !important;
                        max-width: 250px !important;
                        position: fixed !important;
                        left: 0 !important;
                        top: 0 !important;
                        height: 100vh !important;
                        z-index: 1000 !important;
                        transform: translateX(0) !important;
                        transition: transform 0.3s ease !important;
                    }
                    
                    .page.sidebar-collapsed .sidebar,
                    .page.sidebar-collapsed #main-sidebar {
                        transform: translateX(-250px) !important;
                    }
                    
                    main, #main-content {
                        margin-left: 250px !important;
                        width: calc(100% - 250px) !important;
                        transition: margin-left 0.3s ease, width 0.3s ease !important;
                    }
                    
                    .page.sidebar-collapsed main,
                    .page.sidebar-collapsed #main-content {
                        margin-left: 0 !important;
                        width: 100% !important;
                    }
                `
            });
            
            await page.waitForTimeout(500);
            
            const afterInjection = await page.evaluate(() => {
                const sidebar = document.querySelector('.sidebar, #main-sidebar');
                const main = document.querySelector('main, #main-content');
                
                const sidebarStyles = sidebar ? window.getComputedStyle(sidebar) : null;
                const mainStyles = main ? window.getComputedStyle(main) : null;
                
                return {
                    sidebar: sidebarStyles ? {
                        width: sidebarStyles.width,
                        position: sidebarStyles.position
                    } : null,
                    main: mainStyles ? {
                        marginLeft: mainStyles.marginLeft
                    } : null
                };
            });
            
            console.log('After injection:', JSON.stringify(afterInjection, null, 2));
            
            // Test toggle with injected CSS
            const toggleButton = await page.locator('button[title="Toggle navigation"]').first();
            if (await toggleButton.isVisible()) {
                console.log('\nTesting toggle with injected CSS...');
                await toggleButton.click();
                await page.waitForTimeout(500);
                
                const collapsed = await page.evaluate(() => {
                    const page = document.querySelector('.page, #main-page');
                    return page ? page.classList.contains('sidebar-collapsed') : false;
                });
                
                console.log(`Sidebar collapsed: ${collapsed ? 'YES' : 'NO'}`);
                
                // Toggle back
                await toggleButton.click();
                await page.waitForTimeout(500);
                console.log('Sidebar re-expanded');
            }
        }
        
        // Take final screenshots
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        await page.screenshot({ 
            path: `sidebar-force-refresh-${timestamp}.png`,
            fullPage: false 
        });
        console.log(`\nScreenshot saved: sidebar-force-refresh-${timestamp}.png`);
        
    } catch (error) {
        console.error('Test error:', error);
    }
    
    console.log('\nTest complete. Browser will close in 5 seconds...');
    await page.waitForTimeout(5000);
    
    await browser.close();
})();