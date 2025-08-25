const { chromium } = require('playwright');
const fs = require('fs');

async function testAdminFixAndLogin() {
    console.log('Starting Admin Fix and Login Test (Final)...\n');
    console.log('This test will fix the admin user and verify login/sidebar functionality\n');
    
    const browser = await chromium.launch({ 
        headless: false,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 },
        ignoreHTTPSErrors: true
    });
    
    const page = await context.newPage();
    
    let loginSuccess = false;
    let sidebarFound = false;
    let sidebarInfo = {};

    try {
        // Step 1: Navigate directly to login to test current state
        console.log('Step 1: Testing current login state...');
        await page.goto('http://localhost:8080/Account/Login', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        
        // Try login with existing credentials
        await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
        await page.fill('input[type="password"]', 'Admin@123');
        await page.click('button[type="submit"]');
        await page.waitForTimeout(3000);
        
        let currentUrl = page.url();
        if (currentUrl.includes('/Account/Login')) {
            console.log('  Login failed - admin user needs fixing\n');
            
            // Step 2: Navigate to FixAdmin page
            console.log('Step 2: Navigating to FixAdmin page...');
            await page.goto('http://localhost:8080/FixAdmin', { 
                waitUntil: 'networkidle',
                timeout: 30000 
            });
            
            await page.screenshot({ 
                path: 'final-1-fixadmin-page.png',
                fullPage: true 
            });
            
            // Step 3: Click Fix Admin button
            console.log('Step 3: Clicking Fix Admin User button...');
            
            // Look for the button
            const fixButton = await page.locator('button:has-text("Fix Admin User"), button.btn-primary').first();
            if (await fixButton.count() > 0) {
                await fixButton.click();
                console.log('  Clicked Fix Admin User button');
                await page.waitForTimeout(3000);
                
                // Check for success message
                const successAlert = await page.locator('.alert-success').first();
                if (await successAlert.count() > 0) {
                    const message = await successAlert.textContent();
                    console.log('  Success:', message.trim());
                }
                
                await page.screenshot({ 
                    path: 'final-2-fixadmin-result.png',
                    fullPage: true 
                });
            } else {
                console.log('  Fix Admin button not found - page may not be available');
            }
            
            // Step 4: Navigate back to login
            console.log('\nStep 4: Navigating to login page...');
            await page.goto('http://localhost:8080/Account/Login', { 
                waitUntil: 'networkidle',
                timeout: 30000 
            });
        } else {
            console.log('  Login successful with existing credentials!');
            loginSuccess = true;
        }
        
        // Step 5: Attempt login (if not already logged in)
        if (!loginSuccess) {
            console.log('Step 5: Attempting login with admin credentials...');
            
            await page.screenshot({ 
                path: 'final-3-login-page.png',
                fullPage: true 
            });
            
            // Fill credentials
            await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
            await page.fill('input[type="password"]', 'Admin@123');
            
            console.log('  Credentials entered');
            
            // Submit form
            await page.click('button[type="submit"]');
            console.log('  Login form submitted');
            
            // Wait for navigation
            await page.waitForTimeout(5000);
            
            currentUrl = page.url();
            console.log('  Current URL:', currentUrl);
            
            loginSuccess = !currentUrl.includes('/Account/Login');
            
            if (loginSuccess) {
                console.log('  ✓ Login successful!');
            } else {
                console.log('  ✗ Login failed');
                
                // Check for error messages
                const errors = await page.locator('.text-danger, .alert-danger').allTextContents();
                if (errors.length > 0) {
                    console.log('  Error messages:', errors.filter(e => e.trim()));
                }
            }
            
            await page.screenshot({ 
                path: 'final-4-after-login.png',
                fullPage: true 
            });
        }
        
        // Step 6: Check sidebar (if login successful)
        if (loginSuccess) {
            console.log('\nStep 6: Checking sidebar rendering...');
            await page.waitForTimeout(2000);
            
            // Check multiple selectors for sidebar
            const sidebarSelectors = [
                '.sidebar',
                '#sidebar',
                'nav.sidebar',
                '.nav-sidebar',
                'aside.sidebar',
                '.left-sidebar',
                '.sidebar-wrapper',
                '[class*="sidebar"]'
            ];
            
            for (const selector of sidebarSelectors) {
                const sidebar = await page.locator(selector).first();
                if (await sidebar.count() > 0 && await sidebar.isVisible()) {
                    sidebarFound = true;
                    
                    sidebarInfo = await sidebar.evaluate(el => {
                        const styles = window.getComputedStyle(el);
                        const rect = el.getBoundingClientRect();
                        
                        // Check for nav items
                        const navItems = el.querySelectorAll('.nav-link, .nav-item, a');
                        
                        return {
                            selector: selector,
                            className: el.className,
                            id: el.id,
                            width: rect.width,
                            height: rect.height,
                            left: rect.left,
                            top: rect.top,
                            position: styles.position,
                            display: styles.display,
                            backgroundColor: styles.backgroundColor,
                            navItemCount: navItems.length
                        };
                    });
                    
                    console.log('  ✓ Sidebar found!');
                    console.log('  Sidebar details:');
                    console.log(`    - Width: ${sidebarInfo.width}px ${sidebarInfo.width === 250 ? '✓' : '(Expected: 250px)'}`);
                    console.log(`    - Position: ${sidebarInfo.position}`);
                    console.log(`    - Left: ${sidebarInfo.left}px`);
                    console.log(`    - Nav items: ${sidebarInfo.navItemCount}`);
                    break;
                }
            }
            
            if (!sidebarFound) {
                console.log('  ✗ Sidebar not found or not visible');
                
                // Check page structure
                const pageInfo = await page.evaluate(() => {
                    return {
                        bodyClass: document.body.className,
                        mainLayoutExists: !!document.querySelector('.main-layout, .layout-wrapper, #app'),
                        navElements: Array.from(document.querySelectorAll('nav, aside, [role="navigation"]')).map(el => ({
                            tag: el.tagName,
                            classes: el.className,
                            visible: el.offsetParent !== null
                        }))
                    };
                });
                
                console.log('  Page structure:', JSON.stringify(pageInfo, null, 2));
            }
            
            // Final screenshot
            await page.screenshot({ 
                path: 'final-5-dashboard-with-sidebar.png',
                fullPage: true 
            });
        }
        
        // Generate report
        console.log('\n' + '='.repeat(70));
        console.log('FINAL TEST REPORT');
        console.log('='.repeat(70));
        console.log(`Admin Fix Process: ${loginSuccess ? 'Successful or not needed' : 'May need manual intervention'}`);
        console.log(`Login Status: ${loginSuccess ? '✓ SUCCESSFUL' : '✗ FAILED'}`);
        console.log(`Sidebar Status: ${sidebarFound ? '✓ VISIBLE' : '✗ NOT VISIBLE'}`);
        
        if (sidebarFound) {
            const sidebarCorrect = sidebarInfo.width === 250 && sidebarInfo.left === 0;
            console.log(`Sidebar Configuration: ${sidebarCorrect ? '✓ CORRECT (250px left panel)' : '⚠ Needs adjustment'}`);
        }
        
        console.log('\nScreenshots saved:');
        const screenshots = [
            'final-1-fixadmin-page.png',
            'final-2-fixadmin-result.png',
            'final-3-login-page.png',
            'final-4-after-login.png',
            'final-5-dashboard-with-sidebar.png'
        ];
        
        screenshots.forEach(file => {
            if (fs.existsSync(file)) {
                console.log(`  - ${file}`);
            }
        });
        
        console.log('='.repeat(70));
        
        if (!loginSuccess) {
            console.log('\nACTION REQUIRED:');
            console.log('1. The admin user password fix has been applied');
            console.log('2. Try rebuilding the Docker container with: docker-compose down && docker-compose up --build');
            console.log('3. Ensure the database is accessible and migrations have run');
        }
        
    } catch (error) {
        console.error('\nTest encountered an error:', error.message);
        await page.screenshot({ path: 'final-error-state.png', fullPage: true });
    } finally {
        await browser.close();
        console.log('\nTest completed.');
    }
}

// Run the test
testAdminFixAndLogin().catch(console.error);