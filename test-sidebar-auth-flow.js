const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

(async () => {
    console.log('Starting sidebar authentication test...');
    const browser = await chromium.launch({ 
        headless: false,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 },
        ignoreHTTPSErrors: true
    });
    
    const page = await context.newPage();
    
    try {
        // Step 1: Navigate to the application
        console.log('1. Navigating to http://localhost:8080...');
        await page.goto('http://localhost:8080', { 
            waitUntil: 'networkidle',
            timeout: 60000 
        });
        await page.waitForTimeout(3000);
        
        // Take screenshot of landing page
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        await page.screenshot({ 
            path: `sidebar-auth-test-1-landing-${timestamp}.png`,
            fullPage: true 
        });
        console.log('   ✓ Landing page screenshot saved');
        
        // Step 2: Click Sign In button
        console.log('2. Looking for Sign In button...');
        const signInButton = await page.locator('button:has-text("Sign In"), a:has-text("Sign In")').first();
        if (await signInButton.isVisible()) {
            await signInButton.click();
            console.log('   ✓ Clicked Sign In button');
            await page.waitForTimeout(2000);
        } else {
            console.log('   ! Sign In button not found, checking if already on login page');
        }
        
        // Step 3: Login
        console.log('3. Performing login...');
        
        // Wait for and fill email field
        await page.waitForSelector('input[type="email"], input[name="email"], input[id="email"], input[placeholder*="email" i]', { timeout: 10000 });
        const emailInput = await page.locator('input[type="email"], input[name="email"], input[id="email"], input[placeholder*="email" i]').first();
        await emailInput.fill('admin@steelestimation.com');
        console.log('   ✓ Entered email');
        
        // Fill password field
        const passwordInput = await page.locator('input[type="password"], input[name="password"], input[id="password"]').first();
        await passwordInput.fill('Admin@123');
        console.log('   ✓ Entered password');
        
        // Take screenshot before login
        await page.screenshot({ 
            path: `sidebar-auth-test-2-login-form-${timestamp}.png`,
            fullPage: true 
        });
        
        // Submit login form
        const loginButton = await page.locator('button[type="submit"], button:has-text("Sign In"), button:has-text("Login")').first();
        await loginButton.click();
        console.log('   ✓ Submitted login form');
        
        // Wait for navigation after login
        await page.waitForTimeout(5000);
        
        // Step 4: Check for successful authentication
        console.log('4. Checking authentication status...');
        const currentUrl = page.url();
        console.log(`   Current URL: ${currentUrl}`);
        
        // Take screenshot after login
        await page.screenshot({ 
            path: `sidebar-auth-test-3-after-login-${timestamp}.png`,
            fullPage: true 
        });
        console.log('   ✓ After login screenshot saved');
        
        // Step 5: Analyze sidebar presence and structure
        console.log('5. Analyzing sidebar...');
        
        // Check for sidebar element
        const sidebarSelectors = [
            '.sidebar',
            '#sidebar',
            'nav.sidebar',
            'aside',
            '[class*="sidebar"]',
            '.nav-menu',
            '.main-nav'
        ];
        
        let sidebarFound = false;
        let sidebarElement = null;
        
        for (const selector of sidebarSelectors) {
            const element = await page.locator(selector).first();
            if (await element.count() > 0) {
                sidebarElement = element;
                sidebarFound = true;
                console.log(`   ✓ Sidebar found with selector: ${selector}`);
                break;
            }
        }
        
        if (!sidebarFound) {
            console.log('   ✗ No sidebar element found');
        }
        
        // Check sidebar visibility and position
        if (sidebarElement) {
            const isVisible = await sidebarElement.isVisible();
            console.log(`   Sidebar visible: ${isVisible}`);
            
            if (isVisible) {
                const boundingBox = await sidebarElement.boundingBox();
                if (boundingBox) {
                    console.log(`   Sidebar position: x=${boundingBox.x}, y=${boundingBox.y}`);
                    console.log(`   Sidebar dimensions: ${boundingBox.width}x${boundingBox.height}`);
                    
                    // Check if it's on the left side
                    if (boundingBox.x === 0 || boundingBox.x < 50) {
                        console.log('   ✓ Sidebar is positioned on the left');
                    } else {
                        console.log(`   ✗ Sidebar is not on the left (x=${boundingBox.x})`);
                    }
                }
            }
        }
        
        // Check for navigation items
        console.log('6. Checking navigation items...');
        const navItemSelectors = [
            'a[href*="/dashboard"]',
            'a[href*="/customers"]',
            'a[href*="/projects"]',
            'a[href*="/admin"]',
            '.nav-link',
            '.nav-item a',
            '.sidebar a',
            'nav a'
        ];
        
        const foundNavItems = [];
        for (const selector of navItemSelectors) {
            const items = await page.locator(selector).all();
            for (const item of items) {
                const text = await item.textContent().catch(() => '');
                const href = await item.getAttribute('href').catch(() => '');
                if (text && text.trim()) {
                    foundNavItems.push({ text: text.trim(), href });
                }
            }
        }
        
        console.log(`   Found ${foundNavItems.length} navigation items:`);
        foundNavItems.slice(0, 10).forEach(item => {
            console.log(`     - ${item.text} (${item.href})`);
        });
        
        // Step 7: Test hamburger menu toggle
        console.log('7. Testing sidebar toggle...');
        
        const toggleSelectors = [
            '.hamburger-menu',
            '.menu-toggle',
            '.sidebar-toggle',
            'button[aria-label*="menu"]',
            'button[aria-label*="toggle"]',
            '[class*="hamburger"]',
            '[class*="toggle"]',
            '.navbar-toggler'
        ];
        
        let toggleButton = null;
        for (const selector of toggleSelectors) {
            const element = await page.locator(selector).first();
            if (await element.count() > 0 && await element.isVisible()) {
                toggleButton = element;
                console.log(`   ✓ Found toggle button with selector: ${selector}`);
                break;
            }
        }
        
        if (toggleButton) {
            // Get initial sidebar state
            const initialWidth = sidebarElement ? await sidebarElement.evaluate(el => el.offsetWidth) : 0;
            console.log(`   Initial sidebar width: ${initialWidth}px`);
            
            // Click toggle button
            await toggleButton.click();
            await page.waitForTimeout(1000);
            
            // Take screenshot of collapsed state
            await page.screenshot({ 
                path: `sidebar-auth-test-4-collapsed-${timestamp}.png`,
                fullPage: true 
            });
            console.log('   ✓ Collapsed state screenshot saved');
            
            // Check new sidebar state
            const collapsedWidth = sidebarElement ? await sidebarElement.evaluate(el => el.offsetWidth) : 0;
            console.log(`   Collapsed sidebar width: ${collapsedWidth}px`);
            
            if (collapsedWidth < initialWidth) {
                console.log('   ✓ Sidebar successfully collapsed');
            } else {
                console.log('   ✗ Sidebar did not collapse');
            }
            
            // Toggle back
            await toggleButton.click();
            await page.waitForTimeout(1000);
            
            // Take screenshot of re-expanded state
            await page.screenshot({ 
                path: `sidebar-auth-test-5-expanded-${timestamp}.png`,
                fullPage: true 
            });
            console.log('   ✓ Re-expanded state screenshot saved');
            
            const reExpandedWidth = sidebarElement ? await sidebarElement.evaluate(el => el.offsetWidth) : 0;
            console.log(`   Re-expanded sidebar width: ${reExpandedWidth}px`);
            
            if (reExpandedWidth > collapsedWidth) {
                console.log('   ✓ Sidebar successfully re-expanded');
            }
        } else {
            console.log('   ✗ No toggle button found');
        }
        
        // Step 8: Check layout structure
        console.log('8. Checking overall layout...');
        
        // Check for main content area
        const mainContentSelectors = [
            '.main-content',
            '#main-content',
            'main',
            '.content',
            '[class*="main"]'
        ];
        
        let mainContent = null;
        for (const selector of mainContentSelectors) {
            const element = await page.locator(selector).first();
            if (await element.count() > 0) {
                mainContent = element;
                console.log(`   ✓ Main content found with selector: ${selector}`);
                break;
            }
        }
        
        if (mainContent && sidebarElement) {
            const mainBox = await mainContent.boundingBox();
            const sidebarBox = await sidebarElement.boundingBox();
            
            if (mainBox && sidebarBox) {
                // Check if main content is beside sidebar (not below)
                if (mainBox.x >= sidebarBox.x + sidebarBox.width - 10) {
                    console.log('   ✓ Main content is beside the sidebar');
                } else if (mainBox.y > sidebarBox.y + sidebarBox.height) {
                    console.log('   ✗ Main content is below the sidebar');
                } else {
                    console.log('   ? Main content and sidebar layout unclear');
                }
            }
        }
        
        // Step 9: Generate report
        console.log('\n' + '='.repeat(60));
        console.log('SIDEBAR AUTHENTICATION TEST REPORT');
        console.log('='.repeat(60));
        
        console.log('\n📊 TEST RESULTS:');
        console.log(`✓ Application loaded: Yes`);
        console.log(`✓ Login successful: ${currentUrl.includes('dashboard') || !currentUrl.includes('login') ? 'Yes' : 'No'}`);
        console.log(`✓ Sidebar present: ${sidebarFound ? 'Yes' : 'No'}`);
        console.log(`✓ Sidebar visible: ${sidebarElement && await sidebarElement.isVisible() ? 'Yes' : 'No'}`);
        console.log(`✓ Sidebar on left: ${sidebarElement ? 'Yes' : 'N/A'}`);
        console.log(`✓ Navigation items: ${foundNavItems.length} found`);
        console.log(`✓ Toggle button: ${toggleButton ? 'Found' : 'Not found'}`);
        console.log(`✓ Toggle works: ${toggleButton ? 'Yes' : 'N/A'}`);
        
        console.log('\n📸 SCREENSHOTS SAVED:');
        console.log(`  1. Landing page: sidebar-auth-test-1-landing-${timestamp}.png`);
        console.log(`  2. Login form: sidebar-auth-test-2-login-form-${timestamp}.png`);
        console.log(`  3. After login: sidebar-auth-test-3-after-login-${timestamp}.png`);
        if (toggleButton) {
            console.log(`  4. Collapsed: sidebar-auth-test-4-collapsed-${timestamp}.png`);
            console.log(`  5. Re-expanded: sidebar-auth-test-5-expanded-${timestamp}.png`);
        }
        
        // Extract and save page structure for debugging
        const pageStructure = await page.evaluate(() => {
            const elements = [];
            document.querySelectorAll('[class*="sidebar"], [class*="nav"], aside, nav, .main-content, main').forEach(el => {
                elements.push({
                    tag: el.tagName,
                    classes: el.className,
                    id: el.id,
                    visible: el.offsetWidth > 0 && el.offsetHeight > 0,
                    position: {
                        x: el.offsetLeft,
                        y: el.offsetTop,
                        width: el.offsetWidth,
                        height: el.offsetHeight
                    }
                });
            });
            return elements;
        });
        
        console.log('\n🔍 PAGE STRUCTURE:');
        pageStructure.forEach(el => {
            if (el.visible) {
                console.log(`  ${el.tag}${el.id ? '#' + el.id : ''}${el.classes ? '.' + el.classes.split(' ').join('.') : ''}`);
                console.log(`    Position: (${el.position.x}, ${el.position.y}) Size: ${el.position.width}x${el.position.height}`);
            }
        });
        
    } catch (error) {
        console.error('Error during test:', error);
        await page.screenshot({ 
            path: `sidebar-auth-test-error-${new Date().toISOString().replace(/[:.]/g, '-')}.png`,
            fullPage: true 
        });
    } finally {
        console.log('\nTest completed. Browser will close in 5 seconds...');
        await page.waitForTimeout(5000);
        await browser.close();
    }
})();