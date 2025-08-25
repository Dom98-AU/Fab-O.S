const { chromium } = require('playwright');

async function testSidebarWithAuth() {
    const browser = await chromium.launch({ 
        headless: false,
        slowMo: 300 
    });
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 },
        ignoreHTTPSErrors: true
    });
    
    const page = await context.newPage();
    
    console.log('🔍 Starting Comprehensive Sidebar Tests...\n');
    
    try {
        // Step 1: Navigate and Sign In
        console.log('📍 Step 1: Navigating to http://localhost:8080...');
        await page.goto('http://localhost:8080', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        console.log('✅ Page loaded successfully\n');
        
        // Take screenshot of landing page
        await page.screenshot({ 
            path: 'sidebar-auth-1-landing.png', 
            fullPage: true 
        });
        
        // Click Sign In button
        console.log('📍 Step 2: Clicking Sign In button...');
        const signInButton = await page.locator('button:has-text("Sign In"), a:has-text("Sign In")').first();
        if (await signInButton.isVisible()) {
            await signInButton.click();
            await page.waitForLoadState('networkidle');
            console.log('✅ Navigated to login page\n');
        }
        
        // Take screenshot of login page
        await page.screenshot({ 
            path: 'sidebar-auth-2-login-page.png', 
            fullPage: true 
        });
        
        // Fill in login credentials
        console.log('📍 Step 3: Entering login credentials...');
        const emailInput = await page.locator('input[type="email"], input[name*="email"], input[id*="email"], input[name="Input.Email"]').first();
        const passwordInput = await page.locator('input[type="password"], input[name="Input.Password"]').first();
        
        if (await emailInput.isVisible() && await passwordInput.isVisible()) {
            await emailInput.fill('admin@steelestimation.com');
            await passwordInput.fill('Admin@123');
            console.log('✅ Credentials entered\n');
            
            // Submit login form
            console.log('📍 Step 4: Submitting login form...');
            const submitButton = await page.locator('button[type="submit"], input[type="submit"], button:has-text("Log in")').first();
            if (await submitButton.isVisible()) {
                await submitButton.click();
                
                // Wait for navigation after login
                await page.waitForLoadState('networkidle');
                await page.waitForTimeout(2000);
                console.log('✅ Login submitted, waiting for redirect...\n');
            }
        }
        
        // Take screenshot after login
        await page.screenshot({ 
            path: 'sidebar-auth-3-after-login.png', 
            fullPage: true 
        });
        
        // Now test the sidebar
        console.log('📍 Step 5: Testing Sidebar After Authentication...\n');
        
        // Test 1: Check if sidebar is visible
        console.log('🔹 Test 1: Checking sidebar visibility...');
        const sidebarSelectors = [
            '.sidebar',
            'nav.sidebar',
            '#sidebar',
            '[class*="sidebar"]',
            'aside',
            '.nav-menu',
            '#navMenu'
        ];
        
        let sidebar = null;
        for (const selector of sidebarSelectors) {
            const element = await page.locator(selector).first();
            if (await element.isVisible().catch(() => false)) {
                sidebar = element;
                console.log(`✅ Sidebar found using selector: ${selector}`);
                break;
            }
        }
        
        if (sidebar) {
            // Test 2: Check sidebar dimensions
            console.log('\n🔹 Test 2: Checking sidebar dimensions...');
            const sidebarBox = await sidebar.boundingBox();
            if (sidebarBox) {
                console.log(`   Width: ${sidebarBox.width}px`);
                console.log(`   Height: ${sidebarBox.height}px`);
                console.log(`   Position: x=${sidebarBox.x}, y=${sidebarBox.y}`);
                
                if (Math.abs(sidebarBox.width - 250) < 20) {
                    console.log('✅ Sidebar width is approximately 250px');
                } else if (sidebarBox.width < 100) {
                    console.log('⚠️  Sidebar appears to be collapsed (width < 100px)');
                } else {
                    console.log(`⚠️  Sidebar width is ${sidebarBox.width}px (expected ~250px)`);
                }
            }
            
            // Test 3: Check navigation items
            console.log('\n🔹 Test 3: Checking navigation items...');
            const navItemSelectors = [
                '.sidebar a',
                '.sidebar .nav-link',
                '.sidebar [role="menuitem"]',
                '.sidebar li a',
                '.nav-menu a',
                'nav a'
            ];
            
            let navItems = [];
            for (const selector of navItemSelectors) {
                const items = await page.locator(selector).all();
                if (items.length > 0) {
                    navItems = items;
                    console.log(`   Found ${items.length} navigation items using: ${selector}`);
                    break;
                }
            }
            
            if (navItems.length > 0) {
                console.log('✅ Navigation items found:');
                for (let i = 0; i < Math.min(navItems.length, 15); i++) {
                    const text = await navItems[i].textContent().catch(() => '');
                    const href = await navItems[i].getAttribute('href').catch(() => '');
                    if (text.trim()) {
                        console.log(`   ${i + 1}. "${text.trim()}" -> ${href || 'no href'}`);
                    }
                }
            } else {
                console.log('⚠️  No navigation items found');
            }
            
            // Test 4: Check for collapse/expand functionality
            console.log('\n🔹 Test 4: Testing collapse/expand functionality...');
            const toggleSelectors = [
                '[aria-label*="toggle"]',
                '[title*="toggle"]',
                '.sidebar-toggle',
                '.collapse-btn',
                'button:has-text("☰")',
                'button:has-text("≡")',
                '[class*="toggle"]',
                '.hamburger',
                '#sidebarToggle'
            ];
            
            let toggleButton = null;
            for (const selector of toggleSelectors) {
                const element = await page.locator(selector).first();
                if (await element.isVisible().catch(() => false)) {
                    toggleButton = element;
                    console.log(`   Found toggle button using: ${selector}`);
                    break;
                }
            }
            
            if (toggleButton) {
                const initialWidth = sidebarBox ? sidebarBox.width : 0;
                
                // Click to toggle
                await toggleButton.click();
                await page.waitForTimeout(1000);
                
                // Take screenshot after toggle
                await page.screenshot({ 
                    path: 'sidebar-auth-4-after-toggle.png', 
                    fullPage: true 
                });
                
                // Check new width
                const newBox = await sidebar.boundingBox();
                if (newBox) {
                    console.log(`   Width after toggle: ${newBox.width}px`);
                    
                    if (Math.abs(newBox.width - initialWidth) > 50) {
                        console.log('✅ Toggle functionality works (significant width change detected)');
                        
                        // Toggle back
                        await toggleButton.click();
                        await page.waitForTimeout(1000);
                        
                        const finalBox = await sidebar.boundingBox();
                        if (finalBox && Math.abs(finalBox.width - initialWidth) < 20) {
                            console.log('✅ Toggle back to original state works');
                        }
                    } else {
                        console.log('⚠️  Toggle did not significantly change sidebar width');
                    }
                }
                
                // Final screenshot
                await page.screenshot({ 
                    path: 'sidebar-auth-5-final-state.png', 
                    fullPage: true 
                });
            } else {
                console.log('⚠️  No toggle button found');
            }
            
        } else {
            console.log('❌ No sidebar element found after authentication');
            
            // Debug: List all visible elements with "nav" or "sidebar" in their class/id
            console.log('\n🔍 Debugging - Looking for navigation elements:');
            const allElements = await page.locator('*').all();
            let foundElements = [];
            
            for (const element of allElements.slice(0, 100)) { // Check first 100 elements
                const className = await element.getAttribute('class').catch(() => '');
                const id = await element.getAttribute('id').catch(() => '');
                const tagName = await element.evaluate(el => el.tagName.toLowerCase()).catch(() => '');
                
                if (className && (className.includes('nav') || className.includes('sidebar'))) {
                    const isVisible = await element.isVisible().catch(() => false);
                    foundElements.push(`   <${tagName}> class="${className}" visible=${isVisible}`);
                }
                if (id && (id.includes('nav') || id.includes('sidebar'))) {
                    const isVisible = await element.isVisible().catch(() => false);
                    foundElements.push(`   <${tagName}> id="${id}" visible=${isVisible}`);
                }
            }
            
            if (foundElements.length > 0) {
                console.log('Found potential navigation elements:');
                foundElements.slice(0, 10).forEach(el => console.log(el));
            }
        }
        
        // Additional page information
        console.log('\n📊 Page Information:');
        const pageTitle = await page.title();
        const pageUrl = page.url();
        console.log(`   Title: ${pageTitle}`);
        console.log(`   URL: ${pageUrl}`);
        
        // Check if we're still on login page
        if (pageUrl.includes('login') || pageUrl.includes('signin')) {
            console.log('⚠️  Still on login page - authentication may have failed');
        }
        
    } catch (error) {
        console.error('❌ Test failed with error:', error.message);
        
        // Take error screenshot
        await page.screenshot({ 
            path: 'sidebar-auth-error.png', 
            fullPage: true 
        });
    }
    
    console.log('\n✨ Sidebar tests completed!');
    console.log('📸 Screenshots saved:');
    console.log('   - sidebar-auth-1-landing.png');
    console.log('   - sidebar-auth-2-login-page.png');
    console.log('   - sidebar-auth-3-after-login.png');
    console.log('   - sidebar-auth-4-after-toggle.png');
    console.log('   - sidebar-auth-5-final-state.png');
    
    await browser.close();
}

// Run the tests
testSidebarWithAuth().catch(console.error);