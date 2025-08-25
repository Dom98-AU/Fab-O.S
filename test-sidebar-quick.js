const playwright = require('playwright');
const fs = require('fs');

(async () => {
    const browser = await playwright.chromium.launch({ 
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const context = await browser.newContext({
        ignoreHTTPSErrors: true,
        viewport: { width: 1920, height: 1080 }
    });
    
    const page = await context.newPage();
    
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
        const domCheck = await page.evaluate(() => {
            const sidebar = document.querySelector('.sidebar');
            const navMenu = document.querySelector('.nav-menu');
            const mainLayout = document.querySelector('.main-layout');
            
            let sidebarInfo = null;
            if (sidebar) {
                const styles = window.getComputedStyle(sidebar);
                sidebarInfo = {
                    exists: true,
                    display: styles.display,
                    position: styles.position,
                    width: styles.width,
                    height: styles.height,
                    backgroundColor: styles.backgroundColor,
                    visible: sidebar.offsetWidth > 0 && sidebar.offsetHeight > 0,
                    innerHTML: sidebar.innerHTML.substring(0, 200)
                };
            }
            
            // Get all elements with nav or menu in their class
            const navElements = Array.from(document.querySelectorAll('[class*="nav"], [class*="menu"]'));
            const navClasses = navElements.map(el => el.className);
            
            return {
                sidebar: sidebarInfo,
                hasNavMenu: !!navMenu,
                hasMainLayout: !!mainLayout,
                bodyClasses: document.body.className,
                navElements: navClasses,
                allDivs: Array.from(document.querySelectorAll('div')).slice(0, 10).map(d => ({
                    class: d.className,
                    id: d.id
                }))
            };
        });
        
        console.log('DOM Check Results:');
        console.log('- Sidebar:', domCheck.sidebar);
        console.log('- Body classes:', domCheck.bodyClasses);
        console.log('- Nav elements found:', domCheck.navElements);
        console.log('- First 10 divs:', domCheck.allDivs);
        
        // Check CSS
        console.log('\n3. Checking CSS...');
        const cssCheck = await page.evaluate(() => {
            const stylesheets = Array.from(document.styleSheets);
            const cssFiles = [];
            
            stylesheets.forEach(sheet => {
                if (sheet.href) {
                    cssFiles.push(sheet.href);
                }
            });
            
            return {
                cssFiles,
                hasSiteCss: cssFiles.some(f => f.includes('site.css'))
            };
        });
        
        console.log('CSS Files:', cssCheck.cssFiles);
        console.log('Has site.css:', cssCheck.hasSiteCss);
        
        // Fetch site.css content
        const siteCssContent = await page.evaluate(async () => {
            try {
                const response = await fetch('/css/site.css');
                const text = await response.text();
                const sidebarStyles = text.match(/\.sidebar[^}]*\{[^}]*\}/g);
                
                return {
                    status: response.status,
                    hasSidebarStyles: text.includes('.sidebar'),
                    sidebarStylesCount: sidebarStyles ? sidebarStyles.length : 0,
                    firstSidebarStyle: sidebarStyles ? sidebarStyles[0] : null
                };
            } catch (e) {
                return { error: e.message };
            }
        });
        
        console.log('\nsite.css content check:', siteCssContent);
        
        // Save HTML
        const htmlContent = await page.content();
        fs.writeFileSync('sidebar-broken-initial.html', htmlContent);
        console.log('\nHTML saved to sidebar-broken-initial.html');
        
        // Try to login
        console.log('\n4. Attempting login...');
        
        // Navigate to login page
        await page.goto('http://localhost:8080/Login', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        
        await page.screenshot({ 
            path: 'sidebar-broken-login.png', 
            fullPage: true 
        });
        
        // Fill and submit login form
        await page.fill('input[type="email"], input[name="Email"], #Email', 'admin@steelestimation.com');
        await page.fill('input[type="password"], input[name="Password"], #Password', 'Admin@123');
        await page.click('button[type="submit"], input[type="submit"]');
        
        await page.waitForLoadState('networkidle');
        await page.waitForTimeout(2000);
        
        console.log('After login URL:', page.url());
        
        // Take screenshot after login
        await page.screenshot({ 
            path: 'sidebar-broken-after-login.png', 
            fullPage: true 
        });
        console.log('After login screenshot saved');
        
        // Check sidebar after login
        const afterLogin = await page.evaluate(() => {
            const sidebar = document.querySelector('.sidebar');
            let sidebarInfo = null;
            
            if (sidebar) {
                const styles = window.getComputedStyle(sidebar);
                sidebarInfo = {
                    exists: true,
                    display: styles.display,
                    position: styles.position,
                    width: styles.width,
                    visible: sidebar.offsetWidth > 0 && sidebar.offsetHeight > 0
                };
            }
            
            return {
                sidebar: sidebarInfo,
                bodyClasses: document.body.className,
                url: window.location.href
            };
        });
        
        console.log('\nAfter login state:', afterLogin);
        
        // Save final HTML
        const finalHtml = await page.content();
        fs.writeFileSync('sidebar-broken-final.html', finalHtml);
        
        console.log('\n=== Summary ===');
        console.log('Files created:');
        console.log('- sidebar-broken-initial.png');
        console.log('- sidebar-broken-login.png');
        console.log('- sidebar-broken-after-login.png');
        console.log('- sidebar-broken-initial.html');
        console.log('- sidebar-broken-final.html');
        
    } catch (error) {
        console.error('Error:', error);
    } finally {
        await browser.close();
    }
})();