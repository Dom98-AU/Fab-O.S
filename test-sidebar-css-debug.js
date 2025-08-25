const { chromium } = require('playwright');

(async () => {
    console.log('Starting CSS debugging test...');
    const browser = await chromium.launch({ 
        headless: false,
        args: ['--start-maximized']
    });
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 },
        ignoreHTTPSErrors: true
    });
    
    const page = await context.newPage();
    
    try {
        // Navigate to the application
        console.log('Navigating to http://localhost:8080...');
        await page.goto('http://localhost:8080', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        
        // Wait for page to load
        await page.waitForTimeout(2000);
        
        // Check for login form and login if necessary
        const loginForm = await page.locator('form').first();
        if (await loginForm.isVisible()) {
            console.log('Logging in...');
            await page.fill('input[type="email"], input[name="email"], input#email', 'admin@steelestimation.com');
            await page.fill('input[type="password"], input[name="password"], input#password', 'Admin@123');
            await page.click('button[type="submit"]');
            await page.waitForTimeout(3000);
        }
        
        console.log('\n=== CSS Debug Information ===\n');
        
        // Check if site.css is loaded
        const stylesheets = await page.evaluate(() => {
            const sheets = [];
            for (let sheet of document.styleSheets) {
                try {
                    sheets.push({
                        href: sheet.href,
                        rules: sheet.cssRules ? sheet.cssRules.length : 0
                    });
                } catch (e) {
                    sheets.push({
                        href: sheet.href,
                        rules: 'Cannot access (CORS)'
                    });
                }
            }
            return sheets;
        });
        
        console.log('Loaded stylesheets:');
        stylesheets.forEach(sheet => {
            console.log(`  - ${sheet.href || 'inline'}: ${sheet.rules} rules`);
        });
        
        // Check computed styles for sidebar
        const sidebarInfo = await page.evaluate(() => {
            const sidebar = document.querySelector('.sidebar, #main-sidebar');
            const page = document.querySelector('.page, #main-page');
            const main = document.querySelector('main, #main-content');
            
            if (!sidebar) return { error: 'Sidebar not found' };
            
            const sidebarStyles = window.getComputedStyle(sidebar);
            const pageStyles = page ? window.getComputedStyle(page) : null;
            const mainStyles = main ? window.getComputedStyle(main) : null;
            
            // Check for specific CSS rules
            const checkRule = (selector) => {
                for (let sheet of document.styleSheets) {
                    try {
                        for (let rule of sheet.cssRules) {
                            if (rule.selectorText && rule.selectorText.includes(selector)) {
                                return {
                                    found: true,
                                    text: rule.cssText.substring(0, 200)
                                };
                            }
                        }
                    } catch (e) {}
                }
                return { found: false };
            };
            
            return {
                sidebar: {
                    element: sidebar.tagName + (sidebar.id ? '#' + sidebar.id : '') + '.' + Array.from(sidebar.classList).join('.'),
                    width: sidebarStyles.width,
                    maxWidth: sidebarStyles.maxWidth,
                    position: sidebarStyles.position,
                    display: sidebarStyles.display,
                    transform: sidebarStyles.transform,
                    left: sidebarStyles.left,
                    backgroundColor: sidebarStyles.backgroundColor,
                    boxShadow: sidebarStyles.boxShadow
                },
                page: page ? {
                    classes: Array.from(page.classList),
                    display: pageStyles.display
                } : null,
                main: main ? {
                    marginLeft: mainStyles.marginLeft,
                    width: mainStyles.width
                } : null,
                cssRules: {
                    sidebarRule: checkRule('.sidebar'),
                    sidebarWidthRule: checkRule('@media.*min-width.*768px.*sidebar'),
                    pageRule: checkRule('.page')
                }
            };
        });
        
        console.log('\n=== Sidebar Element Info ===');
        console.log(JSON.stringify(sidebarInfo, null, 2));
        
        // Try to inject the correct CSS directly
        console.log('\n=== Injecting correct CSS ===');
        await page.addStyleTag({
            content: `
                /* Force correct sidebar width */
                .sidebar, #main-sidebar {
                    width: 250px !important;
                    max-width: 250px !important;
                    position: fixed !important;
                    left: 0 !important;
                    top: 0 !important;
                    height: 100vh !important;
                    z-index: 1000 !important;
                    background: white !important;
                    box-shadow: 4px 0 20px rgba(0, 0, 0, 0.08) !important;
                }
                
                main, #main-content {
                    margin-left: 250px !important;
                    width: calc(100% - 250px) !important;
                }
                
                .page.sidebar-collapsed .sidebar,
                .page.sidebar-collapsed #main-sidebar {
                    transform: translateX(-250px) !important;
                }
                
                .page.sidebar-collapsed main,
                .page.sidebar-collapsed #main-content {
                    margin-left: 0 !important;
                    width: 100% !important;
                }
            `
        });
        
        await page.waitForTimeout(1000);
        
        // Check styles after injection
        const afterInjection = await page.evaluate(() => {
            const sidebar = document.querySelector('.sidebar, #main-sidebar');
            const main = document.querySelector('main, #main-content');
            
            if (!sidebar) return { error: 'Sidebar not found' };
            
            const sidebarStyles = window.getComputedStyle(sidebar);
            const mainStyles = main ? window.getComputedStyle(main) : null;
            
            return {
                sidebar: {
                    width: sidebarStyles.width,
                    position: sidebarStyles.position,
                    left: sidebarStyles.left
                },
                main: main ? {
                    marginLeft: mainStyles.marginLeft,
                    width: mainStyles.width
                } : null
            };
        });
        
        console.log('\n=== After CSS Injection ===');
        console.log(JSON.stringify(afterInjection, null, 2));
        
        // Take screenshot
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const screenshot = `sidebar-css-debug-${timestamp}.png`;
        await page.screenshot({ path: screenshot, fullPage: false });
        console.log(`\nScreenshot saved: ${screenshot}`);
        
        // Test toggle functionality
        console.log('\n=== Testing Toggle with Injected CSS ===');
        
        // Find and click toggle button
        const toggleButton = await page.locator('button[title="Toggle navigation"]').first();
        if (await toggleButton.isVisible()) {
            console.log('Clicking toggle button...');
            await toggleButton.click();
            await page.waitForTimeout(1000);
            
            // Check collapsed state
            const collapsedState = await page.evaluate(() => {
                const page = document.querySelector('.page, #main-page');
                const sidebar = document.querySelector('.sidebar, #main-sidebar');
                const main = document.querySelector('main, #main-content');
                
                const sidebarStyles = sidebar ? window.getComputedStyle(sidebar) : null;
                const mainStyles = main ? window.getComputedStyle(main) : null;
                
                return {
                    pageHasCollapsedClass: page ? page.classList.contains('sidebar-collapsed') : false,
                    sidebarTransform: sidebarStyles ? sidebarStyles.transform : null,
                    mainMarginLeft: mainStyles ? mainStyles.marginLeft : null
                };
            });
            
            console.log('Collapsed state:', JSON.stringify(collapsedState, null, 2));
            
            const collapsedScreenshot = `sidebar-collapsed-debug-${timestamp}.png`;
            await page.screenshot({ path: collapsedScreenshot, fullPage: false });
            console.log(`Screenshot saved: ${collapsedScreenshot}`);
            
            // Toggle back
            await toggleButton.click();
            await page.waitForTimeout(1000);
            
            const expandedScreenshot = `sidebar-expanded-debug-${timestamp}.png`;
            await page.screenshot({ path: expandedScreenshot, fullPage: false });
            console.log(`Screenshot saved: ${expandedScreenshot}`);
        }
        
    } catch (error) {
        console.error('Test failed:', error);
    }
    
    console.log('\nTest complete. Browser will remain open for 10 seconds...');
    await page.waitForTimeout(10000);
    
    await browser.close();
    console.log('Browser closed.');
})();