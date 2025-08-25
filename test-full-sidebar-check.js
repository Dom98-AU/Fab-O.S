const { chromium } = require('playwright');

(async () => {
    console.log('Starting comprehensive sidebar and logo position test...');
    
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
        console.log('1. Navigating to http://localhost:8080...');
        await page.goto('http://localhost:8080', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        
        await page.waitForTimeout(2000);
        
        // Take screenshot of landing page
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        await page.screenshot({ 
            path: `test-1-landing-${timestamp}.png`, 
            fullPage: true 
        });
        console.log('Landing page screenshot saved');
        
        // Click Sign In button on landing page
        const signInBtn = await page.$('button:has-text("Sign In")');
        if (signInBtn) {
            console.log('2. Clicking Sign In button...');
            await signInBtn.click();
            await page.waitForLoadState('networkidle');
            await page.waitForTimeout(2000);
        }
        
        // Take screenshot of login page
        await page.screenshot({ 
            path: `test-2-login-${timestamp}.png`, 
            fullPage: true 
        });
        console.log('Login page screenshot saved');
        
        // Login
        console.log('3. Logging in with admin credentials...');
        await page.fill('#email', 'admin@steelestimation.com');
        await page.fill('#password', 'Admin@123');
        await page.click('button[type="submit"]');
        
        // Wait for dashboard to load
        await page.waitForLoadState('networkidle');
        await page.waitForTimeout(3000);
        
        // Take screenshot after login
        await page.screenshot({ 
            path: `test-3-dashboard-${timestamp}.png`, 
            fullPage: true 
        });
        console.log('Dashboard screenshot saved');
        
        // Check for sidebar
        console.log('\n4. Checking sidebar and logo elements...');
        const sidebar = await page.$('.sidebar');
        const logo = await page.$('.logo-container');
        
        if (sidebar) {
            console.log('✓ Sidebar found');
            
            // Get sidebar info
            const sidebarInfo = await sidebar.evaluate(el => {
                const rect = el.getBoundingClientRect();
                const styles = window.getComputedStyle(el);
                return {
                    width: rect.width,
                    height: rect.height,
                    left: rect.left,
                    top: rect.top,
                    position: styles.position,
                    backgroundColor: styles.backgroundColor
                };
            });
            console.log('Sidebar dimensions:', sidebarInfo);
        } else {
            console.log('✗ Sidebar NOT found');
        }
        
        if (logo) {
            console.log('✓ Logo container found');
            
            // Get logo info
            const logoInfo = await logo.evaluate(el => {
                const rect = el.getBoundingClientRect();
                const sidebar = document.querySelector('.sidebar');
                const isInsideSidebar = sidebar && sidebar.contains(el);
                
                return {
                    width: rect.width,
                    height: rect.height,
                    left: rect.left,
                    top: rect.top,
                    isInsideSidebar: isInsideSidebar
                };
            });
            console.log('Logo position:', logoInfo);
            
            // Click logo to show dropdown
            console.log('\n5. Testing module dropdown...');
            await logo.click();
            await page.waitForTimeout(1000);
            
            const dropdown = await page.$('.module-dropdown');
            if (dropdown) {
                console.log('✓ Module dropdown appeared');
                await page.screenshot({ 
                    path: `test-4-dropdown-${timestamp}.png`, 
                    fullPage: true 
                });
                console.log('Dropdown screenshot saved');
            } else {
                console.log('✗ Module dropdown NOT found');
            }
        } else {
            console.log('✗ Logo container NOT found');
        }
        
        // Check sidebar toggle
        console.log('\n6. Testing sidebar toggle...');
        const toggleBtn = await page.$('.sidebar-toggle');
        if (toggleBtn) {
            await toggleBtn.click();
            await page.waitForTimeout(1000);
            await page.screenshot({ 
                path: `test-5-collapsed-${timestamp}.png`, 
                fullPage: true 
            });
            console.log('Collapsed sidebar screenshot saved');
            
            await toggleBtn.click();
            await page.waitForTimeout(1000);
            await page.screenshot({ 
                path: `test-6-expanded-${timestamp}.png`, 
                fullPage: true 
            });
            console.log('Expanded sidebar screenshot saved');
        }
        
        // Final analysis
        console.log('\n=== FINAL ANALYSIS ===');
        const analysis = await page.evaluate(() => {
            const sidebar = document.querySelector('.sidebar');
            const logo = document.querySelector('.logo-container');
            
            if (!sidebar) {
                return { error: 'Sidebar not found on page' };
            }
            
            if (!logo) {
                return { error: 'Logo not found on page' };
            }
            
            const sidebarRect = sidebar.getBoundingClientRect();
            const logoRect = logo.getBoundingClientRect();
            const isLogoInSidebar = sidebar.contains(logo);
            
            return {
                sidebar: {
                    position: `left: ${sidebarRect.left}px, width: ${sidebarRect.width}px`,
                    isFixed: window.getComputedStyle(sidebar).position === 'fixed',
                    isOnLeft: sidebarRect.left === 0,
                    isCorrectWidth: Math.abs(sidebarRect.width - 250) < 10
                },
                logo: {
                    position: `left: ${logoRect.left}px, top: ${logoRect.top}px`,
                    isInsideSidebar: isLogoInSidebar,
                    isAtTop: logoRect.top < 100,
                    isOnLeft: logoRect.left < 100
                },
                verdict: {
                    sidebarPositionCorrect: sidebarRect.left === 0 && Math.abs(sidebarRect.width - 250) < 10,
                    logoPositionCorrect: isLogoInSidebar && logoRect.top < 100 && logoRect.left < 100,
                    overallCorrect: false
                }
            };
        });
        
        analysis.verdict.overallCorrect = analysis.verdict.sidebarPositionCorrect && analysis.verdict.logoPositionCorrect;
        
        console.log(JSON.stringify(analysis, null, 2));
        
        console.log('\n=== TEST RESULTS ===');
        if (analysis.error) {
            console.log(`❌ ERROR: ${analysis.error}`);
        } else {
            console.log(`Sidebar on left side (0px): ${analysis.sidebar.isOnLeft ? '✅ YES' : '❌ NO'}`);
            console.log(`Sidebar width ~250px: ${analysis.sidebar.isCorrectWidth ? '✅ YES' : '❌ NO'}`);
            console.log(`Logo inside sidebar: ${analysis.logo.isInsideSidebar ? '✅ YES' : '❌ NO'}`);
            console.log(`Logo at top (<100px): ${analysis.logo.isAtTop ? '✅ YES' : '❌ NO'}`);
            console.log(`Logo on left (<100px): ${analysis.logo.isOnLeft ? '✅ YES' : '❌ NO'}`);
            console.log(`\nOVERALL: ${analysis.verdict.overallCorrect ? '✅ PASS - Logo correctly positioned in top-left sidebar' : '❌ FAIL - Logo NOT correctly positioned'}`);
        }
        
    } catch (error) {
        console.error('Error during test:', error);
        await page.screenshot({ 
            path: `test-error-${new Date().toISOString().replace(/[:.]/g, '-')}.png`, 
            fullPage: true 
        });
    } finally {
        await browser.close();
    }
})();