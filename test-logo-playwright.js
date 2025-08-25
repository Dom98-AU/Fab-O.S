const { chromium } = require('playwright');
const fs = require('fs');

(async () => {
    console.log('Starting logo position test with Playwright...');
    
    const browser = await chromium.launch({
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 }
    });
    
    const page = await context.newPage();
    
    try {
        // Navigate to the application
        console.log('Navigating to http://localhost:8080...');
        await page.goto('http://localhost:8080', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        
        // Wait for page to fully load
        await page.waitForTimeout(3000);
        
        // Take initial screenshot
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const screenshotPath1 = `logo-position-initial-${timestamp}.png`;
        await page.screenshot({ path: screenshotPath1, fullPage: true });
        console.log(`Initial screenshot saved: ${screenshotPath1}`);
        
        // Check if we're on login page
        const loginForm = await page.$('#loginForm');
        
        if (loginForm) {
            console.log('On login page, attempting to login...');
            
            // Login
            await page.fill('#email', 'admin@steelestimation.com');
            await page.fill('#password', 'Admin@123');
            
            // Click login button
            await page.click('button[type="submit"]');
            
            // Wait for navigation
            await page.waitForLoadState('networkidle');
            await page.waitForTimeout(3000);
            
            // Take screenshot after login
            const screenshotPath2 = `logo-position-logged-in-${timestamp}.png`;
            await page.screenshot({ path: screenshotPath2, fullPage: true });
            console.log(`Logged in screenshot saved: ${screenshotPath2}`);
        }
        
        // Check for sidebar and logo
        const sidebar = await page.$('.sidebar');
        const logo = await page.$('.logo-container');
        
        console.log(`Sidebar exists: ${sidebar !== null}`);
        console.log(`Logo container exists: ${logo !== null}`);
        
        // Get sidebar dimensions and position
        if (sidebar) {
            const sidebarInfo = await sidebar.evaluate(el => {
                const rect = el.getBoundingClientRect();
                const styles = window.getComputedStyle(el);
                return {
                    width: rect.width,
                    height: rect.height,
                    left: rect.left,
                    top: rect.top,
                    position: styles.position,
                    display: styles.display
                };
            });
            console.log('Sidebar info:', sidebarInfo);
        }
        
        // Get logo position
        if (logo) {
            const logoInfo = await logo.evaluate(el => {
                const rect = el.getBoundingClientRect();
                const styles = window.getComputedStyle(el);
                
                // Check if logo is inside sidebar
                const sidebar = document.querySelector('.sidebar');
                const isInsideSidebar = sidebar && sidebar.contains(el);
                
                return {
                    width: rect.width,
                    height: rect.height,
                    left: rect.left,
                    top: rect.top,
                    position: styles.position,
                    display: styles.display,
                    isInsideSidebar: isInsideSidebar
                };
            });
            console.log('Logo info:', logoInfo);
            
            // Try clicking the logo to show dropdown
            console.log('Clicking logo to show module dropdown...');
            await logo.click();
            await page.waitForTimeout(1000);
            
            // Check if dropdown appeared
            const dropdown = await page.$('.module-dropdown');
            console.log(`Module dropdown exists: ${dropdown !== null}`);
            
            if (dropdown) {
                // Take screenshot with dropdown
                const screenshotPath3 = `logo-position-dropdown-${timestamp}.png`;
                await page.screenshot({ path: screenshotPath3, fullPage: true });
                console.log(`Dropdown screenshot saved: ${screenshotPath3}`);
                
                // Get dropdown position
                const dropdownInfo = await dropdown.evaluate(el => {
                    const rect = el.getBoundingClientRect();
                    const styles = window.getComputedStyle(el);
                    return {
                        width: rect.width,
                        height: rect.height,
                        left: rect.left,
                        top: rect.top,
                        position: styles.position,
                        display: styles.display
                    };
                });
                console.log('Dropdown info:', dropdownInfo);
            }
        }
        
        // Final analysis
        console.log('\n=== LOGO POSITION ANALYSIS ===');
        
        const analysis = await page.evaluate(() => {
            const sidebar = document.querySelector('.sidebar');
            const logo = document.querySelector('.logo-container');
            
            if (!sidebar || !logo) {
                return { error: 'Sidebar or logo not found' };
            }
            
            const sidebarRect = sidebar.getBoundingClientRect();
            const logoRect = logo.getBoundingClientRect();
            const isInsideSidebar = sidebar.contains(logo);
            
            return {
                sidebarPosition: {
                    left: sidebarRect.left,
                    width: sidebarRect.width,
                    isFixed: window.getComputedStyle(sidebar).position === 'fixed'
                },
                logoPosition: {
                    left: logoRect.left,
                    top: logoRect.top,
                    isAtTopOfSidebar: logoRect.top < 100,
                    isOnLeftSide: logoRect.left < 300,
                    isInsideSidebar: isInsideSidebar
                },
                verdict: {
                    sidebarCorrect: sidebarRect.left === 0 && sidebarRect.width === 250,
                    logoCorrect: isInsideSidebar && logoRect.top < 100 && logoRect.left < 300
                }
            };
        });
        
        console.log(JSON.stringify(analysis, null, 2));
        
        // Summary
        console.log('\n=== SUMMARY ===');
        if (analysis.verdict) {
            console.log(`✓ Sidebar positioned correctly: ${analysis.verdict.sidebarCorrect ? 'YES' : 'NO'}`);
            console.log(`✓ Logo in top-left of sidebar: ${analysis.verdict.logoCorrect ? 'YES' : 'NO'}`);
        }
        
    } catch (error) {
        console.error('Error during test:', error);
        // Take error screenshot
        const errorScreenshot = `logo-position-error-${new Date().toISOString().replace(/[:.]/g, '-')}.png`;
        await page.screenshot({ path: errorScreenshot, fullPage: true });
        console.log(`Error screenshot saved: ${errorScreenshot}`);
    } finally {
        await browser.close();
    }
})();