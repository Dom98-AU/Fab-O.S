const playwright = require('playwright');

(async () => {
    const browser = await playwright.chromium.launch({ 
        headless: false,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const context = await browser.newContext({
        ignoreHTTPSErrors: true,
        viewport: { width: 1920, height: 1080 }
    });
    
    const page = await context.newPage();
    
    // Enable console logging
    page.on('console', msg => console.log('Browser console:', msg.text()));
    page.on('pageerror', error => console.log('Page error:', error.message));
    
    try {
        console.log('1. Navigating to http://localhost:8080...');
        await page.goto('http://localhost:8080', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        
        // Take initial screenshot
        await page.screenshot({ 
            path: 'sidebar-broken-initial.png', 
            fullPage: true 
        });
        console.log('Initial screenshot saved as sidebar-broken-initial.png');
        
        // Check for sidebar element
        console.log('\n2. Checking DOM structure...');
        const sidebarExists = await page.evaluate(() => {
            const sidebar = document.querySelector('.sidebar');
            const navMenu = document.querySelector('.nav-menu');
            const mainLayout = document.querySelector('.main-layout');
            
            return {
                hasSidebar: !!sidebar,
                hasNavMenu: !!navMenu,
                hasMainLayout: !!mainLayout,
                sidebarHTML: sidebar ? sidebar.outerHTML.substring(0, 500) : 'Not found',
                bodyClasses: document.body.className,
                documentStructure: document.documentElement.outerHTML.substring(0, 1000)
            };
        });
        
        console.log('DOM Check Results:');
        console.log('- Has .sidebar element:', sidebarExists.hasSidebar);
        console.log('- Has .nav-menu element:', sidebarExists.hasNavMenu);
        console.log('- Has .main-layout element:', sidebarExists.hasMainLayout);
        console.log('- Body classes:', sidebarExists.bodyClasses);
        console.log('- Sidebar HTML preview:', sidebarExists.sidebarHTML);
        
        // Check CSS loading
        console.log('\n3. Checking CSS files...');
        const cssCheck = await page.evaluate(() => {
            const stylesheets = Array.from(document.styleSheets);
            const cssFiles = [];
            
            stylesheets.forEach(sheet => {
                try {
                    if (sheet.href) {
                        cssFiles.push({
                            href: sheet.href,
                            loaded: true,
                            rules: sheet.cssRules ? sheet.cssRules.length : 0
                        });
                    }
                } catch (e) {
                    cssFiles.push({
                        href: sheet.href || 'inline',
                        loaded: false,
                        error: e.message
                    });
                }
            });
            
            // Check specific sidebar styles
            const sidebarElement = document.querySelector('.sidebar');
            let computedStyles = null;
            if (sidebarElement) {
                const styles = window.getComputedStyle(sidebarElement);
                computedStyles = {
                    display: styles.display,
                    position: styles.position,
                    width: styles.width,
                    height: styles.height,
                    left: styles.left,
                    top: styles.top,
                    backgroundColor: styles.backgroundColor,
                    zIndex: styles.zIndex
                };
            }
            
            return {
                cssFiles,
                sidebarComputedStyles: computedStyles,
                hasSiteCss: cssFiles.some(f => f.href && f.href.includes('site.css'))
            };
        });
        
        console.log('CSS Files loaded:');
        cssCheck.cssFiles.forEach(file => {
            console.log(`- ${file.href}: ${file.loaded ? 'Loaded' : 'Failed'} (${file.rules || 0} rules)`);
        });
        console.log('Has site.css:', cssCheck.hasSiteCss);
        
        if (cssCheck.sidebarComputedStyles) {
            console.log('\nSidebar computed styles:');
            Object.entries(cssCheck.sidebarComputedStyles).forEach(([key, value]) => {
                console.log(`  ${key}: ${value}`);
            });
        }
        
        // Check site.css content
        console.log('\n4. Fetching site.css content...');
        const siteCssResponse = await page.evaluate(async () => {
            try {
                const response = await fetch('/css/site.css');
                const text = await response.text();
                const hasSidebarStyles = text.includes('.sidebar');
                const sidebarStylesPreview = text.match(/\.sidebar[^}]*\{[^}]*\}/g);
                
                return {
                    status: response.status,
                    length: text.length,
                    hasSidebarStyles,
                    sidebarStylesPreview: sidebarStylesPreview ? sidebarStylesPreview.slice(0, 3) : null
                };
            } catch (e) {
                return { error: e.message };
            }
        });
        
        console.log('site.css check:');
        console.log('- Status:', siteCssResponse.status);
        console.log('- Length:', siteCssResponse.length);
        console.log('- Has sidebar styles:', siteCssResponse.hasSidebarStyles);
        if (siteCssResponse.sidebarStylesPreview) {
            console.log('- Sidebar styles preview:', siteCssResponse.sidebarStylesPreview);
        }
        
        // Check for JavaScript errors
        console.log('\n5. Checking for JavaScript errors...');
        const jsErrors = await page.evaluate(() => {
            const errors = [];
            // Check if site.js loaded
            const scripts = Array.from(document.scripts);
            const hasSiteJs = scripts.some(s => s.src && s.src.includes('site.js'));
            
            return {
                hasSiteJs,
                scriptCount: scripts.length,
                hasJQuery: typeof $ !== 'undefined',
                hasBootstrap: typeof bootstrap !== 'undefined'
            };
        });
        
        console.log('JavaScript check:');
        console.log('- Has site.js:', jsErrors.hasSiteJs);
        console.log('- Script count:', jsErrors.scriptCount);
        console.log('- Has jQuery:', jsErrors.hasJQuery);
        console.log('- Has Bootstrap:', jsErrors.hasBootstrap);
        
        // Save current HTML structure
        const htmlContent = await page.content();
        const fs = require('fs');
        fs.writeFileSync('sidebar-broken-html.html', htmlContent);
        console.log('\nHTML structure saved to sidebar-broken-html.html');
        
        // Now try to login
        console.log('\n6. Attempting to login...');
        
        // Check if we're already on login page or need to navigate
        const isLoginPage = await page.evaluate(() => {
            return window.location.pathname.includes('login') || 
                   document.querySelector('input[type="email"]') !== null;
        });
        
        if (!isLoginPage) {
            // Try to find and click login link
            const loginLink = await page.$('a[href*="login"], a[href*="Login"]');
            if (loginLink) {
                await loginLink.click();
                await page.waitForLoadState('networkidle');
            } else {
                // Navigate directly to login
                await page.goto('http://localhost:8080/Login', { 
                    waitUntil: 'networkidle',
                    timeout: 30000 
                });
            }
        }
        
        // Fill login form
        await page.fill('input[type="email"], input[name="Email"], #Email', 'admin@steelestimation.com');
        await page.fill('input[type="password"], input[name="Password"], #Password', 'Admin@123');
        
        // Take screenshot of login page
        await page.screenshot({ 
            path: 'sidebar-broken-login-page.png', 
            fullPage: true 
        });
        console.log('Login page screenshot saved');
        
        // Submit login
        await page.click('button[type="submit"], input[type="submit"]');
        await page.waitForLoadState('networkidle');
        
        // Wait a bit for any redirects
        await page.waitForTimeout(3000);
        
        console.log('Current URL after login:', page.url());
        
        // Take screenshot after login
        await page.screenshot({ 
            path: 'sidebar-broken-after-login.png', 
            fullPage: true 
        });
        console.log('After login screenshot saved');
        
        // Check sidebar after login
        console.log('\n7. Checking sidebar after login...');
        const afterLoginCheck = await page.evaluate(() => {
            const sidebar = document.querySelector('.sidebar');
            const navMenu = document.querySelector('.nav-menu');
            
            let sidebarInfo = null;
            if (sidebar) {
                const styles = window.getComputedStyle(sidebar);
                sidebarInfo = {
                    exists: true,
                    display: styles.display,
                    position: styles.position,
                    width: styles.width,
                    visible: sidebar.offsetWidth > 0 && sidebar.offsetHeight > 0,
                    innerHTML: sidebar.innerHTML.substring(0, 500)
                };
            }
            
            return {
                sidebar: sidebarInfo,
                hasNavMenu: !!navMenu,
                authenticated: document.body.className.includes('authenticated') || 
                              document.querySelector('.user-info') !== null,
                currentPath: window.location.pathname
            };
        });
        
        console.log('After login check:');
        console.log('- Sidebar exists:', afterLoginCheck.sidebar?.exists);
        console.log('- Sidebar visible:', afterLoginCheck.sidebar?.visible);
        console.log('- Sidebar width:', afterLoginCheck.sidebar?.width);
        console.log('- Authenticated:', afterLoginCheck.authenticated);
        console.log('- Current path:', afterLoginCheck.currentPath);
        
        // Save final HTML
        const finalHtml = await page.content();
        fs.writeFileSync('sidebar-broken-final-html.html', finalHtml);
        console.log('\nFinal HTML saved to sidebar-broken-final-html.html');
        
        console.log('\n=== Diagnosis Complete ===');
        console.log('Screenshots saved:');
        console.log('- sidebar-broken-initial.png');
        console.log('- sidebar-broken-login-page.png');
        console.log('- sidebar-broken-after-login.png');
        console.log('HTML files saved:');
        console.log('- sidebar-broken-html.html');
        console.log('- sidebar-broken-final-html.html');
        
    } catch (error) {
        console.error('Error during diagnosis:', error);
        await page.screenshot({ path: 'sidebar-error-state.png', fullPage: true });
    }
    
    // Keep browser open for manual inspection
    console.log('\nBrowser will remain open for manual inspection. Press Ctrl+C to close.');
    await new Promise(() => {}); // Keep running
})();