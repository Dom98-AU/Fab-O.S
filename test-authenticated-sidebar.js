const { chromium } = require('playwright');

(async () => {
    console.log('Starting authenticated sidebar and logo position test...');
    
    const browser = await chromium.launch({
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 }
    });
    
    const page = await context.newPage();
    
    try {
        // Navigate directly to login page
        console.log('1. Navigating to login page...');
        await page.goto('http://localhost:8080/Account/Login', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        
        await page.waitForTimeout(2000);
        
        // Take screenshot of login page
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        await page.screenshot({ 
            path: `auth-test-1-login-${timestamp}.png`, 
            fullPage: true 
        });
        console.log('Login page screenshot saved');
        
        // Try to find and fill login form
        console.log('2. Looking for login form...');
        
        // Check if email field exists
        const emailField = await page.$('#email, input[name="email"], input[type="email"]');
        const passwordField = await page.$('#password, input[name="password"], input[type="password"]');
        
        if (emailField && passwordField) {
            console.log('3. Filling login form...');
            await emailField.fill('admin@steelestimation.com');
            await passwordField.fill('Admin@123');
            
            // Find and click submit button
            const submitButton = await page.$('button[type="submit"], input[type="submit"], button:has-text("Sign In"), button:has-text("Login")');
            if (submitButton) {
                await submitButton.click();
                console.log('4. Login submitted, waiting for navigation...');
                
                // Wait for navigation
                await page.waitForLoadState('networkidle');
                await page.waitForTimeout(3000);
            }
        } else {
            console.log('Login form not found on this page');
        }
        
        // Take screenshot after attempted login
        await page.screenshot({ 
            path: `auth-test-2-after-login-${timestamp}.png`, 
            fullPage: true 
        });
        console.log('After login screenshot saved');
        
        // Now check for authenticated elements
        console.log('\n5. Checking for authenticated layout...');
        
        // Check for sidebar
        const sidebar = await page.$('.sidebar, #main-sidebar, [class*="sidebar"]');
        const logo = await page.$('.logo-container, .navbar-brand img, .brand-logo, img[alt="Fab O.S"]');
        const navMenu = await page.$('.nav-menu, nav, .nav-scrollable');
        
        console.log(`Sidebar found: ${sidebar !== null}`);
        console.log(`Logo found: ${logo !== null}`);
        console.log(`Navigation menu found: ${navMenu !== null}`);
        
        if (sidebar) {
            const sidebarInfo = await sidebar.evaluate(el => {
                const rect = el.getBoundingClientRect();
                const styles = window.getComputedStyle(el);
                return {
                    position: `left: ${rect.left}px, top: ${rect.top}px`,
                    size: `${rect.width}px x ${rect.height}px`,
                    display: styles.display,
                    cssPosition: styles.position,
                    backgroundColor: styles.backgroundColor
                };
            });
            console.log('\nSidebar details:', JSON.stringify(sidebarInfo, null, 2));
        }
        
        if (logo) {
            const logoInfo = await logo.evaluate(el => {
                const rect = el.getBoundingClientRect();
                const sidebar = document.querySelector('.sidebar, #main-sidebar');
                const isInsideSidebar = sidebar && sidebar.contains(el);
                
                return {
                    position: `left: ${rect.left}px, top: ${rect.top}px`,
                    size: `${rect.width}px x ${rect.height}px`,
                    isInsideSidebar: isInsideSidebar,
                    src: el.src || 'N/A'
                };
            });
            console.log('\nLogo details:', JSON.stringify(logoInfo, null, 2));
        }
        
        // Final comprehensive check
        console.log('\n=== FINAL LAYOUT ANALYSIS ===');
        const layoutAnalysis = await page.evaluate(() => {
            const sidebar = document.querySelector('.sidebar, #main-sidebar');
            const logo = document.querySelector('.navbar-brand img, .brand-logo, img[alt="Fab O.S"]');
            const mainContent = document.querySelector('main, #main-content, .content');
            
            const analysis = {
                pageTitle: document.title,
                currentUrl: window.location.href,
                isAuthenticated: false,
                sidebarFound: false,
                logoFound: false,
                logoPosition: null,
                layoutStructure: null
            };
            
            // Check if we're authenticated (look for dashboard elements)
            const dashboardElements = document.querySelectorAll('[class*="dashboard"], [class*="estimation"], .card');
            analysis.isAuthenticated = dashboardElements.length > 0;
            
            if (sidebar) {
                const sidebarRect = sidebar.getBoundingClientRect();
                analysis.sidebarFound = true;
                analysis.sidebarPosition = {
                    left: sidebarRect.left,
                    width: sidebarRect.width,
                    isLeftAligned: sidebarRect.left === 0,
                    isCorrectWidth: Math.abs(sidebarRect.width - 250) < 50
                };
            }
            
            if (logo) {
                const logoRect = logo.getBoundingClientRect();
                analysis.logoFound = true;
                analysis.logoPosition = {
                    left: logoRect.left,
                    top: logoRect.top,
                    isInTopLeft: logoRect.left < 100 && logoRect.top < 100,
                    isInsideSidebar: sidebar && sidebar.contains(logo)
                };
            }
            
            // Check overall layout structure
            if (mainContent) {
                const mainRect = mainContent.getBoundingClientRect();
                analysis.layoutStructure = {
                    mainContentLeft: mainRect.left,
                    hasSidebarLayout: mainRect.left > 200
                };
            }
            
            return analysis;
        });
        
        console.log(JSON.stringify(layoutAnalysis, null, 2));
        
        // Summary
        console.log('\n=== TEST RESULTS SUMMARY ===');
        if (layoutAnalysis.isAuthenticated) {
            console.log('✅ User is authenticated');
            
            if (layoutAnalysis.sidebarFound && layoutAnalysis.sidebarPosition?.isLeftAligned) {
                console.log('✅ Sidebar is positioned on the left');
            } else {
                console.log('❌ Sidebar NOT properly positioned');
            }
            
            if (layoutAnalysis.logoFound && layoutAnalysis.logoPosition?.isInTopLeft) {
                console.log('✅ Logo is in the top-left corner');
            } else {
                console.log('❌ Logo NOT in top-left corner');
            }
            
            if (layoutAnalysis.logoPosition?.isInsideSidebar) {
                console.log('✅ Logo is inside the sidebar');
            } else {
                console.log('❌ Logo NOT inside sidebar');
            }
        } else {
            console.log('❌ User is NOT authenticated - showing landing page');
            console.log('This is expected behavior. The logo should be centered on the landing page.');
            console.log('The sidebar with logo in top-left only appears after authentication.');
        }
        
    } catch (error) {
        console.error('Error during test:', error);
        await page.screenshot({ 
            path: `auth-test-error-${new Date().toISOString().replace(/[:.]/g, '-')}.png`, 
            fullPage: true 
        });
    } finally {
        await browser.close();
    }
})();