const { chromium } = require('playwright');
const fs = require('fs');

(async () => {
    console.log('Starting Sidebar Layout Verification Test...');
    console.log('=====================================\n');
    
    const browser = await chromium.launch({ 
        headless: true,  // Run headless for speed
        args: ['--start-maximized']
    });
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 },
        ignoreHTTPSErrors: true
    });
    
    const page = await context.newPage();
    
    try {
        // Step 1: Go directly to login
        console.log('Step 1: Navigating to login page...');
        await page.goto('http://localhost:8080/Account/Login', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        
        // Step 2: Login with admin credentials
        console.log('Step 2: Logging in with admin credentials...');
        await page.fill('input[name="Email"]', 'admin@steelestimation.com');
        await page.fill('input[name="Password"]', 'Admin@123');
        await page.click('button[type="submit"]');
        
        // Wait for navigation
        await page.waitForLoadState('networkidle');
        await page.waitForTimeout(3000);
        
        const currentUrl = page.url();
        console.log('   Current URL:', currentUrl);
        
        if (!currentUrl.includes('/Account/Login')) {
            console.log('   ✓ Login successful\n');
        } else {
            console.log('   ✗ Login failed - still on login page\n');
            
            // Check for errors
            const errors = await page.locator('.alert-danger, .text-danger').all();
            for (const error of errors) {
                if (await error.isVisible()) {
                    console.log('   Error:', await error.textContent());
                }
            }
        }
        
        // Step 3: Analyze page layout
        console.log('Step 3: Analyzing page layout...');
        
        // Check if sidebar exists
        const sidebarExists = await page.locator('.sidebar, #main-sidebar').count() > 0;
        console.log('   Sidebar element exists:', sidebarExists);
        
        if (sidebarExists) {
            // Get sidebar properties using JavaScript evaluation
            const sidebarData = await page.evaluate(() => {
                const sidebar = document.querySelector('.sidebar, #main-sidebar');
                if (!sidebar) return null;
                
                const rect = sidebar.getBoundingClientRect();
                const styles = window.getComputedStyle(sidebar);
                
                // Check visibility
                const isVisible = sidebar.offsetParent !== null && 
                                styles.display !== 'none' && 
                                styles.visibility !== 'hidden';
                
                // Get transform value
                const transform = styles.transform;
                let transformX = 0;
                if (transform && transform !== 'none') {
                    const matrix = transform.match(/matrix.*\((.+)\)/);
                    if (matrix) {
                        const values = matrix[1].split(', ');
                        transformX = parseFloat(values[4] || 0);
                    }
                }
                
                return {
                    exists: true,
                    visible: isVisible,
                    width: rect.width,
                    height: rect.height,
                    left: rect.left,
                    top: rect.top,
                    position: styles.position,
                    display: styles.display,
                    transform: styles.transform,
                    transformX: transformX,
                    zIndex: styles.zIndex,
                    backgroundColor: styles.backgroundColor
                };
            });
            
            if (sidebarData) {
                console.log('\n   Sidebar Properties:');
                console.log('   ├─ Visible:', sidebarData.visible);
                console.log('   ├─ Width:', sidebarData.width, 'px');
                console.log('   ├─ Height:', sidebarData.height, 'px');
                console.log('   ├─ Position:', sidebarData.position);
                console.log('   ├─ Left:', sidebarData.left, 'px');
                console.log('   ├─ Transform:', sidebarData.transform);
                console.log('   └─ Z-Index:', sidebarData.zIndex);
                
                // Check if sidebar is properly positioned
                if (sidebarData.position === 'fixed' && sidebarData.width === 250) {
                    if (sidebarData.transformX === -250 || sidebarData.left === -250) {
                        console.log('\n   ⚠ Sidebar is collapsed (hidden to the left)');
                    } else if (sidebarData.left === 0) {
                        console.log('\n   ✓ Sidebar is properly positioned as left panel');
                    } else {
                        console.log('\n   ⚠ Sidebar position issue detected');
                    }
                } else {
                    console.log('\n   ⚠ Sidebar not configured as fixed 250px panel');
                }
            }
        } else {
            console.log('   ✗ No sidebar element found\n');
        }
        
        // Check main content offset
        const mainData = await page.evaluate(() => {
            const main = document.querySelector('main, #main-content');
            if (!main) return null;
            
            const rect = main.getBoundingClientRect();
            const styles = window.getComputedStyle(main);
            
            return {
                exists: true,
                marginLeft: styles.marginLeft,
                paddingLeft: styles.paddingLeft,
                left: rect.left,
                width: rect.width
            };
        });
        
        if (mainData) {
            console.log('\n   Main Content Properties:');
            console.log('   ├─ Margin-left:', mainData.marginLeft);
            console.log('   ├─ Padding-left:', mainData.paddingLeft);
            console.log('   ├─ Left position:', mainData.left, 'px');
            console.log('   └─ Width:', mainData.width, 'px');
            
            if (mainData.marginLeft === '250px' || mainData.left >= 250) {
                console.log('\n   ✓ Main content properly offset for sidebar');
            } else if (mainData.marginLeft === '0px' || mainData.left === 0) {
                console.log('\n   ⚠ Main content not offset (sidebar may be collapsed)');
            }
        }
        
        // Check for navigation items
        console.log('\nStep 4: Checking navigation items...');
        const navItems = ['Dashboard', 'Estimations', 'Customers', 'Projects'];
        let foundItems = 0;
        
        for (const item of navItems) {
            const exists = await page.locator(`text="${item}"`).count() > 0;
            if (exists) {
                foundItems++;
                console.log(`   ✓ ${item}`);
            } else {
                console.log(`   ✗ ${item}`);
            }
        }
        
        console.log(`\n   Found ${foundItems}/${navItems.length} navigation items`);
        
        // Take screenshots
        await page.screenshot({ path: 'sidebar-test-final.png', fullPage: true });
        console.log('\nScreenshot saved: sidebar-test-final.png');
        
        // Save HTML for debugging
        const html = await page.content();
        fs.writeFileSync('sidebar-test-page.html', html);
        console.log('Page HTML saved: sidebar-test-page.html');
        
        // Final summary
        console.log('\n=====================================');
        console.log('TEST SUMMARY:');
        console.log('=====================================');
        console.log(`Login Status: ${!currentUrl.includes('/Account/Login') ? '✓ Success' : '✗ Failed'}`);
        console.log(`Sidebar Found: ${sidebarExists ? '✓ Yes' : '✗ No'}`);
        console.log(`Navigation Items: ${foundItems}/${navItems.length} found`);
        
        if (sidebarExists && mainData) {
            const sidebarOk = await page.evaluate(() => {
                const sidebar = document.querySelector('.sidebar, #main-sidebar');
                if (!sidebar) return false;
                const styles = window.getComputedStyle(sidebar);
                const transform = styles.transform;
                if (transform && transform.includes('translateX(-250px)')) return false;
                return sidebar.offsetParent !== null;
            });
            
            if (sidebarOk && (mainData.marginLeft === '250px' || mainData.left >= 250)) {
                console.log('\nLayout Status: ✓ Sidebar is properly displayed as left panel');
            } else if (!sidebarOk || mainData.marginLeft === '0px') {
                console.log('\nLayout Status: ⚠ Sidebar appears to be collapsed');
                console.log('  → Try clicking the menu toggle button to expand it');
            } else {
                console.log('\nLayout Status: ⚠ Layout issues detected');
            }
        }
        
    } catch (error) {
        console.error('\nError during test:', error.message);
        await page.screenshot({ path: 'sidebar-error.png', fullPage: true });
        console.log('Error screenshot saved: sidebar-error.png');
    } finally {
        await browser.close();
        console.log('\n=====================================');
        console.log('Test completed.');
    }
})();