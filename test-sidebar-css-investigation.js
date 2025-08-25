const { chromium } = require('playwright');

(async () => {
    console.log('Starting CSS and sidebar investigation...');
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
        
        // Check CSS loading on landing page
        console.log('2. Checking CSS on landing page...');
        const cssFiles = await page.evaluate(() => {
            const stylesheets = Array.from(document.styleSheets);
            return stylesheets.map(sheet => ({
                href: sheet.href,
                rules: sheet.cssRules ? sheet.cssRules.length : 0
            }));
        });
        console.log('   Loaded stylesheets:');
        cssFiles.forEach(css => {
            console.log(`     ${css.href || 'inline'}: ${css.rules} rules`);
        });
        
        // Check sidebar on landing page
        const sidebarOnLanding = await page.locator('.sidebar').count() > 0;
        console.log(`   Sidebar exists on landing: ${sidebarOnLanding}`);
        
        if (sidebarOnLanding) {
            const sidebarStyles = await page.locator('.sidebar').evaluate(el => {
                const computed = window.getComputedStyle(el);
                return {
                    position: computed.position,
                    width: computed.width,
                    height: computed.height,
                    background: computed.backgroundColor,
                    border: computed.borderRight,
                    display: computed.display,
                    transform: computed.transform
                };
            });
            console.log('   Sidebar styles on landing:');
            Object.entries(sidebarStyles).forEach(([key, value]) => {
                console.log(`     ${key}: ${value}`);
            });
        }
        
        // Take screenshot
        await page.screenshot({ path: 'css-investigation-1-landing.png', fullPage: true });
        console.log('   ✓ Screenshot saved: css-investigation-1-landing.png');
        
        // Click Sign In button
        console.log('3. Clicking Sign In button...');
        await page.click('a:has-text("Sign In"), button:has-text("Sign In")');
        await page.waitForNavigation({ waitUntil: 'networkidle' });
        
        // Check if we're on login page
        const onLoginPage = await page.url().includes('login');
        console.log(`   On login page: ${onLoginPage}`);
        
        if (onLoginPage) {
            // Take screenshot of login page
            await page.screenshot({ path: 'css-investigation-2-login-page.png', fullPage: true });
            console.log('   ✓ Screenshot saved: css-investigation-2-login-page.png');
            
            // Try to find login form fields
            console.log('4. Looking for login form...');
            const emailInput = await page.locator('input[name="Input.Email"], input[type="email"], input#email, input#Input_Email').count();
            const passwordInput = await page.locator('input[name="Input.Password"], input[type="password"], input#password, input#Input_Password').count();
            console.log(`   Email input found: ${emailInput > 0}`);
            console.log(`   Password input found: ${passwordInput > 0}`);
            
            if (emailInput > 0 && passwordInput > 0) {
                // Fill login form
                console.log('5. Filling login form...');
                await page.fill('input[name="Input.Email"], input[type="email"], input#email, input#Input_Email', 'admin@steelestimation.com');
                await page.fill('input[name="Input.Password"], input[type="password"], input#password, input#Input_Password', 'Admin@123');
                await page.click('button[type="submit"]');
                
                // Wait for navigation after login
                await page.waitForNavigation({ waitUntil: 'networkidle' });
                console.log('   ✓ Login submitted');
                
                // Check if login was successful
                const afterLoginUrl = await page.url();
                console.log(`   After login URL: ${afterLoginUrl}`);
                
                // Take screenshot after login
                await page.screenshot({ path: 'css-investigation-3-after-login.png', fullPage: true });
                console.log('   ✓ Screenshot saved: css-investigation-3-after-login.png');
                
                // Check CSS after login
                console.log('6. Checking CSS after login...');
                const cssAfterLogin = await page.evaluate(() => {
                    const stylesheets = Array.from(document.styleSheets);
                    return stylesheets.map(sheet => ({
                        href: sheet.href,
                        rules: sheet.cssRules ? sheet.cssRules.length : 0
                    }));
                });
                console.log('   Loaded stylesheets after login:');
                cssAfterLogin.forEach(css => {
                    console.log(`     ${css.href || 'inline'}: ${css.rules} rules`);
                });
                
                // Check sidebar after login
                const sidebarAfterLogin = await page.locator('.sidebar').count() > 0;
                console.log(`   Sidebar exists after login: ${sidebarAfterLogin}`);
                
                if (sidebarAfterLogin) {
                    const sidebarStylesAfterLogin = await page.locator('.sidebar').evaluate(el => {
                        const computed = window.getComputedStyle(el);
                        return {
                            position: computed.position,
                            width: computed.width,
                            height: computed.height,
                            background: computed.backgroundColor,
                            border: computed.borderRight,
                            display: computed.display,
                            transform: computed.transform,
                            left: computed.left,
                            top: computed.top
                        };
                    });
                    console.log('   Sidebar styles after login:');
                    Object.entries(sidebarStylesAfterLogin).forEach(([key, value]) => {
                        console.log(`     ${key}: ${value}`);
                    });
                    
                    // Check if site.css rules are applied
                    const sidebarRulesApplied = await page.evaluate(() => {
                        const sidebar = document.querySelector('.sidebar');
                        if (!sidebar) return false;
                        const computed = window.getComputedStyle(sidebar);
                        // Check for expected styles from site.css
                        return {
                            hasFixedPosition: computed.position === 'fixed',
                            hasCorrectWidth: computed.width === '250px',
                            hasWhiteBackground: computed.backgroundColor === 'rgb(255, 255, 255)',
                            hasBorder: computed.borderRight !== 'none'
                        };
                    });
                    console.log('   Site.css rules applied:');
                    Object.entries(sidebarRulesApplied).forEach(([key, value]) => {
                        console.log(`     ${key}: ${value}`);
                    });
                }
                
                // Check main content positioning
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
        }
        
        // Save page HTML for debugging
        const pageHTML = await page.content();
        const fs = require('fs');
        fs.writeFileSync('css-investigation-page.html', pageHTML);
        console.log('   ✓ Page HTML saved to css-investigation-page.html');
        
        console.log('\n✓ CSS investigation complete!');
        
    } catch (error) {
        console.error('Error during investigation:', error);
        await page.screenshot({ path: 'css-investigation-error.png', fullPage: true });
    } finally {
        // Keep browser open for manual inspection
        console.log('\nBrowser will remain open for 30 seconds for manual inspection...');
        await page.waitForTimeout(30000);
        await browser.close();
    }
})();