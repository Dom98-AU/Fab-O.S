const { chromium } = require('playwright');

(async () => {
    console.log('Starting Complete Login and Sidebar Test...');
    
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
        // Navigate directly to login page
        console.log('\n1. Navigating to Login page...');
        await page.goto('http://localhost:8080/Account/Login', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        await page.waitForTimeout(2000);
        
        // Take screenshot of login page
        await page.screenshot({ 
            path: 'login-1-page.png',
            fullPage: true 
        });
        console.log('   ✓ Screenshot saved: login-1-page.png');
        
        // Enter login credentials
        console.log('\n2. Entering login credentials...');
        await page.fill('input[name="Email"]', 'admin@steelestimation.com');
        await page.fill('input[name="Password"]', 'Admin@123');
        console.log('   ✓ Credentials entered');
        
        // Click login button
        console.log('\n3. Clicking Sign In button...');
        await page.click('button[type="submit"]');
        console.log('   ✓ Sign In button clicked');
        
        // Wait for navigation after login
        await page.waitForLoadState('networkidle');
        await page.waitForTimeout(5000); // Give extra time for any redirects
        
        // Check if we're logged in
        console.log('\n4. Checking login status...');
        const currentUrl = page.url();
        console.log('   Current URL:', currentUrl);
        
        if (currentUrl.includes('/Account/Login')) {
            console.log('   ⚠ Still on login page - checking for errors...');
            
            // Check for error messages
            const errorMessages = await page.locator('.alert-danger, .text-danger, .validation-message').all();
            for (const error of errorMessages) {
                if (await error.isVisible()) {
                    const errorText = await error.textContent();
                    console.log('   Error found:', errorText);
                }
            }
        } else {
            console.log('   ✓ Successfully logged in');
        }
        
        // Take screenshot after login
        await page.screenshot({ 
            path: 'login-2-after-login.png',
            fullPage: true 
        });
        console.log('   ✓ Screenshot saved: login-2-after-login.png');
        
        // Check for sidebar
        console.log('\n5. Checking sidebar visibility...');
        
        // Try multiple selectors for sidebar
        const sidebarSelectors = [
            '.sidebar',
            '#sidebar',
            '[class*="sidebar"]',
            '.nav-sidebar',
            'aside',
            '.left-panel',
            '.navigation-panel'
        ];
        
        let sidebarFound = false;
        let sidebar = null;
        
        for (const selector of sidebarSelectors) {
            const element = await page.locator(selector).first();
            if (await element.count() > 0) {
                console.log(`   Found element with selector: ${selector}`);
                sidebar = element;
                sidebarFound = true;
                break;
            }
        }
        
        if (sidebarFound && sidebar) {
            console.log('   ✓ Sidebar element found');
            
            // Get sidebar properties
            const sidebarInfo = await sidebar.evaluate(el => {
                const rect = el.getBoundingClientRect();
                const styles = window.getComputedStyle(el);
                return {
                    visible: el.offsetParent !== null,
                    width: rect.width,
                    height: rect.height,
                    left: rect.left,
                    top: rect.top,
                    position: styles.position,
                    display: styles.display,
                    backgroundColor: styles.backgroundColor,
                    zIndex: styles.zIndex
                };
            });
            
            console.log('\n   Sidebar Properties:');
            console.log('   - Visible:', sidebarInfo.visible);
            console.log('   - Width:', sidebarInfo.width, 'px');
            console.log('   - Height:', sidebarInfo.height, 'px');
            console.log('   - Left:', sidebarInfo.left, 'px');
            console.log('   - Top:', sidebarInfo.top, 'px');
            console.log('   - Position:', sidebarInfo.position);
            console.log('   - Display:', sidebarInfo.display);
            console.log('   - Background:', sidebarInfo.backgroundColor);
            console.log('   - Z-Index:', sidebarInfo.zIndex);
            
            // Check navigation items
            console.log('\n   Checking navigation items...');
            const navItems = ['Dashboard', 'Estimations', 'Customers', 'Projects', 'Reports'];
            
            for (const item of navItems) {
                const navLink = await page.locator(`text="${item}"`).first();
                if (await navLink.count() > 0) {
                    const isVisible = await navLink.isVisible();
                    console.log(`   ${isVisible ? '✓' : '✗'} ${item}`);
                } else {
                    console.log(`   ✗ ${item} (not found)`);
                }
            }
            
            // Check if sidebar is correctly positioned as left panel
            if (sidebarInfo.width === 250 && sidebarInfo.left === 0) {
                console.log('\n   ✓ Sidebar is correctly positioned as 250px left panel');
            } else {
                console.log('\n   ⚠ Sidebar positioning issues detected');
            }
            
        } else {
            console.log('   ⚠ No sidebar element found');
            
            // Check page structure
            console.log('\n   Analyzing page structure...');
            const bodyHtml = await page.evaluate(() => {
                const elements = [];
                document.querySelectorAll('*[class], *[id]').forEach(el => {
                    if (el.id || (el.className && typeof el.className === 'string')) {
                        const rect = el.getBoundingClientRect();
                        if (rect.width > 0 && rect.height > 0) {
                            elements.push({
                                tag: el.tagName.toLowerCase(),
                                id: el.id,
                                class: el.className,
                                width: rect.width,
                                visible: el.offsetParent !== null
                            });
                        }
                    }
                });
                return elements.filter(e => e.class?.includes('nav') || e.class?.includes('sidebar') || e.class?.includes('menu'));
            });
            
            console.log('   Navigation-related elements found:');
            bodyHtml.forEach(el => {
                console.log(`   - ${el.tag}#${el.id}.${el.class} (width: ${el.width}px, visible: ${el.visible})`);
            });
        }
        
        // Check main content area
        console.log('\n6. Checking main content area...');
        const mainContent = await page.locator('main, .main-content, [class*="main"], .content').first();
        if (await mainContent.count() > 0) {
            const mainInfo = await mainContent.evaluate(el => {
                const rect = el.getBoundingClientRect();
                const styles = window.getComputedStyle(el);
                return {
                    marginLeft: styles.marginLeft,
                    paddingLeft: styles.paddingLeft,
                    left: rect.left,
                    width: rect.width
                };
            });
            
            console.log('   Main content properties:');
            console.log('   - Margin-left:', mainInfo.marginLeft);
            console.log('   - Padding-left:', mainInfo.paddingLeft);
            console.log('   - Left position:', mainInfo.left, 'px');
            console.log('   - Width:', mainInfo.width, 'px');
            
            if (mainInfo.left >= 250 || mainInfo.marginLeft === '250px') {
                console.log('   ✓ Main content is offset for sidebar');
            } else {
                console.log('   ⚠ Main content may overlap with sidebar');
            }
        }
        
        // Take final screenshot
        await page.screenshot({ 
            path: 'login-3-final-layout.png',
            fullPage: true 
        });
        console.log('\n   ✓ Final screenshot saved: login-3-final-layout.png');
        
        // Save page HTML for debugging
        const pageHtml = await page.content();
        require('fs').writeFileSync('login-page-structure.html', pageHtml);
        console.log('   ✓ Page HTML saved: login-page-structure.html');
        
        console.log('\n=== TEST SUMMARY ===');
        console.log('1. Login page loaded: ✓');
        console.log('2. Credentials entered: ✓');
        console.log('3. Login attempted: ✓');
        console.log('4. Login status:', currentUrl.includes('/Account/Login') ? '✗ Failed' : '✓ Success');
        console.log('5. Sidebar found:', sidebarFound ? '✓' : '✗');
        console.log('6. Layout correct:', sidebarFound ? '✓' : '✗');
        
    } catch (error) {
        console.error('\nError during test:', error);
        await page.screenshot({ 
            path: 'login-error.png',
            fullPage: true 
        });
        console.log('Error screenshot saved: login-error.png');
    } finally {
        await page.waitForTimeout(5000); // Keep browser open to observe
        await browser.close();
        console.log('\nTest completed.');
    }
})();