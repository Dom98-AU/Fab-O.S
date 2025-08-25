const { chromium } = require('playwright');

async function testSidebar() {
    const browser = await chromium.launch({ 
        headless: false,
        slowMo: 500 
    });
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 },
        ignoreHTTPSErrors: true
    });
    
    const page = await context.newPage();
    
    console.log('🔍 Starting Sidebar Tests...\n');
    
    try {
        // Test 1: Navigate to the application
        console.log('📍 Test 1: Navigating to http://localhost:8080...');
        await page.goto('http://localhost:8080', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        console.log('✅ Page loaded successfully\n');
        
        // Take initial screenshot
        await page.screenshot({ 
            path: 'sidebar-test-initial.png', 
            fullPage: true 
        });
        
        // Test 2: Check if sidebar is visible
        console.log('📍 Test 2: Checking sidebar visibility...');
        const sidebar = await page.locator('.sidebar, nav.sidebar, #sidebar, [class*="sidebar"]').first();
        const sidebarVisible = await sidebar.isVisible().catch(() => false);
        
        if (sidebarVisible) {
            console.log('✅ Sidebar is visible');
            
            // Test 3: Check sidebar width
            console.log('\n📍 Test 3: Checking sidebar width...');
            const sidebarBox = await sidebar.boundingBox();
            if (sidebarBox) {
                console.log(`   Sidebar width: ${sidebarBox.width}px`);
                if (Math.abs(sidebarBox.width - 250) < 10) {
                    console.log('✅ Sidebar width is approximately 250px');
                } else {
                    console.log(`⚠️  Sidebar width is ${sidebarBox.width}px (expected ~250px)`);
                }
            }
            
            // Test 4: Check for navigation items
            console.log('\n📍 Test 4: Checking for navigation items...');
            const navItems = await page.locator('.sidebar a, .sidebar .nav-link, .sidebar [role="menuitem"], .sidebar li').all();
            console.log(`   Found ${navItems.length} navigation items`);
            
            if (navItems.length > 0) {
                console.log('✅ Navigation items found:');
                for (let i = 0; i < Math.min(navItems.length, 10); i++) {
                    const text = await navItems[i].textContent().catch(() => '');
                    if (text.trim()) {
                        console.log(`   - ${text.trim()}`);
                    }
                }
            } else {
                console.log('⚠️  No navigation items found');
            }
            
            // Test 5: Check for collapse/expand button
            console.log('\n📍 Test 5: Testing collapse/expand functionality...');
            const collapseButton = await page.locator('[aria-label*="toggle"], [title*="toggle"], .sidebar-toggle, .collapse-btn, button:has-text("☰"), button:has-text("≡"), [class*="toggle"]').first();
            
            if (await collapseButton.isVisible().catch(() => false)) {
                console.log('   Found collapse/expand button');
                
                // Take screenshot before collapse
                await page.screenshot({ 
                    path: 'sidebar-test-expanded.png', 
                    fullPage: true 
                });
                
                // Click to collapse
                await collapseButton.click();
                await page.waitForTimeout(1000);
                
                // Check if sidebar collapsed
                const sidebarAfterClick = await sidebar.boundingBox();
                if (sidebarAfterClick) {
                    console.log(`   Sidebar width after toggle: ${sidebarAfterClick.width}px`);
                    if (sidebarAfterClick.width < sidebarBox.width) {
                        console.log('✅ Sidebar collapse functionality works');
                    } else {
                        console.log('⚠️  Sidebar did not collapse as expected');
                    }
                }
                
                // Take screenshot after collapse
                await page.screenshot({ 
                    path: 'sidebar-test-collapsed.png', 
                    fullPage: true 
                });
                
                // Click to expand again
                await collapseButton.click();
                await page.waitForTimeout(1000);
                
                const sidebarAfterExpand = await sidebar.boundingBox();
                if (sidebarAfterExpand && Math.abs(sidebarAfterExpand.width - sidebarBox.width) < 10) {
                    console.log('✅ Sidebar expand functionality works');
                }
                
                // Take final screenshot
                await page.screenshot({ 
                    path: 'sidebar-test-final.png', 
                    fullPage: true 
                });
                
            } else {
                console.log('⚠️  No collapse/expand button found');
            }
            
        } else {
            console.log('❌ Sidebar is not visible on page load');
            console.log('   Attempting to check for authentication requirement...\n');
            
            // Check if we're on a login page
            const isLoginPage = await page.locator('input[type="email"], input[type="password"], form[action*="login"], [class*="login"]').first().isVisible().catch(() => false);
            
            if (isLoginPage) {
                console.log('📍 Login page detected. Attempting to authenticate...');
                
                // Try to login
                const emailInput = await page.locator('input[type="email"], input[name*="email"], input[id*="email"]').first();
                const passwordInput = await page.locator('input[type="password"]').first();
                
                if (await emailInput.isVisible() && await passwordInput.isVisible()) {
                    await emailInput.fill('admin@steelestimation.com');
                    await passwordInput.fill('Admin@123');
                    
                    // Take screenshot of login page
                    await page.screenshot({ 
                        path: 'sidebar-test-login.png', 
                        fullPage: true 
                    });
                    
                    // Find and click login button
                    const loginButton = await page.locator('button[type="submit"], input[type="submit"], button:has-text("Login"), button:has-text("Sign in")').first();
                    if (await loginButton.isVisible()) {
                        await loginButton.click();
                        
                        // Wait for navigation
                        await page.waitForLoadState('networkidle');
                        await page.waitForTimeout(2000);
                        
                        console.log('✅ Login attempted, checking for sidebar after authentication...\n');
                        
                        // Re-check for sidebar after login
                        const sidebarAfterLogin = await page.locator('.sidebar, nav.sidebar, #sidebar, [class*="sidebar"]').first();
                        if (await sidebarAfterLogin.isVisible().catch(() => false)) {
                            console.log('✅ Sidebar is now visible after authentication');
                            
                            // Take screenshot after login
                            await page.screenshot({ 
                                path: 'sidebar-test-authenticated.png', 
                                fullPage: true 
                            });
                            
                            // Re-run sidebar tests
                            const sidebarBox = await sidebarAfterLogin.boundingBox();
                            if (sidebarBox) {
                                console.log(`   Sidebar width: ${sidebarBox.width}px`);
                            }
                            
                            const navItems = await page.locator('.sidebar a, .sidebar .nav-link').all();
                            console.log(`   Found ${navItems.length} navigation items after login`);
                        } else {
                            console.log('⚠️  Sidebar still not visible after authentication');
                        }
                    }
                }
            } else {
                console.log('   No login form found. The sidebar might require authentication.');
            }
        }
        
        // Additional debugging information
        console.log('\n📊 Additional Debugging Information:');
        
        // Check for any sidebar-related elements
        const allSidebarElements = await page.locator('[class*="sidebar"], [id*="sidebar"], nav, aside').all();
        console.log(`   Total potential sidebar elements: ${allSidebarElements.length}`);
        
        // Check page title
        const pageTitle = await page.title();
        console.log(`   Page title: ${pageTitle}`);
        
        // Check for any error messages
        const errorMessages = await page.locator('.error, .alert-danger, [class*="error"]').all();
        if (errorMessages.length > 0) {
            console.log(`   ⚠️  Found ${errorMessages.length} error message(s) on page`);
        }
        
    } catch (error) {
        console.error('❌ Test failed with error:', error.message);
        
        // Take error screenshot
        await page.screenshot({ 
            path: 'sidebar-test-error.png', 
            fullPage: true 
        });
    }
    
    console.log('\n✨ Sidebar tests completed!');
    console.log('📸 Screenshots saved:');
    console.log('   - sidebar-test-initial.png');
    console.log('   - sidebar-test-expanded.png');
    console.log('   - sidebar-test-collapsed.png');
    console.log('   - sidebar-test-final.png');
    console.log('   - sidebar-test-authenticated.png (if login was required)');
    
    await browser.close();
}

// Run the tests
testSidebar().catch(console.error);