const { chromium } = require('playwright');
const fs = require('fs');

(async () => {
    console.log('Starting Admin Fix and Sidebar Layout Test...');
    
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
        // Step 1: Navigate to FixAdmin page
        console.log('\n1. Navigating to FixAdmin page...');
        await page.goto('http://localhost:8080/FixAdmin', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        await page.waitForTimeout(2000);
        
        // Take screenshot of fix admin page
        await page.screenshot({ 
            path: 'test-1-fix-admin-page.png',
            fullPage: true 
        });
        console.log('   ✓ Screenshot saved: test-1-fix-admin-page.png');
        
        // Step 2: Click Fix Admin User button
        console.log('\n2. Clicking Fix Admin User button...');
        const fixButton = await page.locator('button:has-text("Fix Admin User")').first();
        if (await fixButton.isVisible()) {
            await fixButton.click();
            console.log('   ✓ Clicked Fix Admin User button');
            
            // Wait for success message
            await page.waitForTimeout(5000); // Give time for database operation
            
            // Take screenshot showing success message
            await page.screenshot({ 
                path: 'test-2-fix-admin-success.png',
                fullPage: true 
            });
            console.log('   ✓ Screenshot saved: test-2-fix-admin-success.png');
            
            // Check for success message
            const successMessage = await page.locator('text=/successfully fixed/i').first();
            if (await successMessage.isVisible()) {
                console.log('   ✓ Success message displayed');
            } else {
                console.log('   ⚠ Success message not found');
            }
        } else {
            console.log('   ⚠ Fix Admin User button not found');
        }
        
        // Step 3: Navigate to Login page
        console.log('\n3. Navigating to Login page...');
        const loginLink = await page.locator('a:has-text("Go to Login")').first();
        if (await loginLink.isVisible()) {
            await loginLink.click();
            await page.waitForLoadState('networkidle');
        } else {
            await page.goto('http://localhost:8080/Account/Login', { 
                waitUntil: 'networkidle',
                timeout: 30000 
            });
        }
        await page.waitForTimeout(2000);
        
        // Take screenshot of login page
        await page.screenshot({ 
            path: 'test-3-login-page.png',
            fullPage: true 
        });
        console.log('   ✓ Screenshot saved: test-3-login-page.png');
        
        // Step 4: Enter login credentials
        console.log('\n4. Entering login credentials...');
        await page.fill('input[name="Email"]', 'admin@steelestimation.com');
        await page.fill('input[name="Password"]', 'Admin@123');
        console.log('   ✓ Credentials entered');
        
        // Step 5: Click login button
        console.log('\n5. Clicking login button...');
        await page.click('button[type="submit"]');
        console.log('   ✓ Login button clicked');
        
        // Wait for navigation after login
        await page.waitForLoadState('networkidle');
        await page.waitForTimeout(3000);
        
        // Step 6: Check if we're logged in
        console.log('\n6. Checking login status...');
        const currentUrl = page.url();
        console.log('   Current URL:', currentUrl);
        
        if (currentUrl.includes('/Account/Login')) {
            console.log('   ⚠ Still on login page - login may have failed');
            
            // Check for error messages
            const errorMessage = await page.locator('.alert-danger, .text-danger').first();
            if (await errorMessage.isVisible()) {
                const errorText = await errorMessage.textContent();
                console.log('   Error message:', errorText);
            }
        } else {
            console.log('   ✓ Successfully logged in');
        }
        
        // Take screenshot after login attempt
        await page.screenshot({ 
            path: 'test-4-after-login.png',
            fullPage: true 
        });
        console.log('   ✓ Screenshot saved: test-4-after-login.png');
        
        // Step 7: Check sidebar visibility and layout
        console.log('\n7. Checking sidebar layout...');
        
        // Look for sidebar element
        const sidebar = await page.locator('.sidebar, #sidebar, [class*="sidebar"]').first();
        
        if (await sidebar.isVisible()) {
            console.log('   ✓ Sidebar is visible');
            
            // Get sidebar computed styles
            const sidebarStyles = await sidebar.evaluate(el => {
                const styles = window.getComputedStyle(el);
                return {
                    width: styles.width,
                    position: styles.position,
                    left: styles.left,
                    top: styles.top,
                    display: styles.display,
                    backgroundColor: styles.backgroundColor
                };
            });
            
            console.log('\n   Sidebar Styles:');
            console.log('   - Width:', sidebarStyles.width);
            console.log('   - Position:', sidebarStyles.position);
            console.log('   - Left:', sidebarStyles.left);
            console.log('   - Top:', sidebarStyles.top);
            console.log('   - Display:', sidebarStyles.display);
            console.log('   - Background:', sidebarStyles.backgroundColor);
            
            // Check if sidebar is positioned as left panel
            if (sidebarStyles.width === '250px') {
                console.log('   ✓ Sidebar has correct width (250px)');
            } else {
                console.log('   ⚠ Sidebar width is not 250px:', sidebarStyles.width);
            }
            
            if (sidebarStyles.position === 'fixed' || sidebarStyles.position === 'absolute') {
                console.log('   ✓ Sidebar has fixed/absolute positioning');
            } else {
                console.log('   ⚠ Sidebar position:', sidebarStyles.position);
            }
            
            // Check for navigation items
            console.log('\n   Checking navigation items...');
            const navItems = [
                'Dashboard',
                'Estimations',
                'Customers',
                'Projects',
                'Reports',
                'Settings'
            ];
            
            for (const item of navItems) {
                const navLink = await sidebar.locator(`text="${item}"`).first();
                if (await navLink.isVisible()) {
                    console.log(`   ✓ Found: ${item}`);
                } else {
                    console.log(`   ⚠ Missing: ${item}`);
                }
            }
            
            // Check main content area
            const mainContent = await page.locator('.main-content, main, [class*="main"]').first();
            if (await mainContent.isVisible()) {
                const mainStyles = await mainContent.evaluate(el => {
                    const styles = window.getComputedStyle(el);
                    return {
                        marginLeft: styles.marginLeft,
                        paddingLeft: styles.paddingLeft,
                        position: styles.position
                    };
                });
                
                console.log('\n   Main Content Styles:');
                console.log('   - Margin-left:', mainStyles.marginLeft);
                console.log('   - Padding-left:', mainStyles.paddingLeft);
                console.log('   - Position:', mainStyles.position);
                
                if (mainStyles.marginLeft === '250px' || mainStyles.paddingLeft === '250px') {
                    console.log('   ✓ Main content has correct offset for sidebar');
                } else {
                    console.log('   ⚠ Main content may not have correct offset');
                }
            }
            
        } else {
            console.log('   ⚠ Sidebar not found or not visible');
            
            // Try to find any element that might be the sidebar
            const possibleSidebar = await page.locator('[class*="nav"], nav, .navigation').first();
            if (await possibleSidebar.isVisible()) {
                console.log('   Found navigation element, checking position...');
                const navStyles = await possibleSidebar.evaluate(el => {
                    const styles = window.getComputedStyle(el);
                    return {
                        position: styles.position,
                        display: styles.display,
                        width: styles.width
                    };
                });
                console.log('   Navigation element styles:', navStyles);
            }
        }
        
        // Step 8: Take final screenshot
        console.log('\n8. Taking final screenshot...');
        await page.screenshot({ 
            path: 'test-5-final-layout.png',
            fullPage: true 
        });
        console.log('   ✓ Screenshot saved: test-5-final-layout.png');
        
        // Additional debugging: Get page HTML structure
        console.log('\n9. Analyzing page structure...');
        const bodyClasses = await page.locator('body').getAttribute('class');
        console.log('   Body classes:', bodyClasses || 'none');
        
        const pageStructure = await page.evaluate(() => {
            const elements = [];
            // Find all major structural elements
            document.querySelectorAll('[class*="sidebar"], [class*="nav"], [class*="main"], header, main, aside').forEach(el => {
                elements.push({
                    tag: el.tagName.toLowerCase(),
                    classes: el.className,
                    id: el.id || 'none',
                    visible: el.offsetParent !== null
                });
            });
            return elements;
        });
        
        console.log('\n   Page structural elements:');
        pageStructure.forEach(el => {
            console.log(`   - ${el.tag}#${el.id}.${el.classes} (visible: ${el.visible})`);
        });
        
        // Save page HTML for inspection
        const pageContent = await page.content();
        fs.writeFileSync('test-page-structure.html', pageContent);
        console.log('\n   ✓ Page HTML saved to test-page-structure.html');
        
        console.log('\n=== TEST SUMMARY ===');
        console.log('Screenshots saved:');
        console.log('  1. test-1-fix-admin-page.png');
        console.log('  2. test-2-fix-admin-success.png');
        console.log('  3. test-3-login-page.png');
        console.log('  4. test-4-after-login.png');
        console.log('  5. test-5-final-layout.png');
        console.log('Page HTML saved: test-page-structure.html');
        
    } catch (error) {
        console.error('\nError during test:', error);
        await page.screenshot({ 
            path: 'test-error.png',
            fullPage: true 
        });
        console.log('Error screenshot saved: test-error.png');
    } finally {
        await page.waitForTimeout(3000); // Keep browser open briefly to observe
        await browser.close();
        console.log('\nTest completed.');
    }
})();