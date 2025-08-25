const { chromium } = require('playwright');

async function testSidebar() {
    const browser = await chromium.launch({ 
        headless: false,
        args: ['--disable-web-security']
    });
    
    const context = await browser.newContext({
        ignoreHTTPSErrors: true,
        viewport: { width: 1920, height: 1080 }
    });
    
    const page = await context.newPage();
    
    // Enable console logging
    page.on('console', msg => {
        console.log(`Browser console [${msg.type()}]:`, msg.text());
    });
    
    page.on('pageerror', err => {
        console.error('Page error:', err.message);
    });

    try {
        console.log('1. Navigating to http://localhost:8080...');
        await page.goto('http://localhost:8080', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        
        // Take screenshot of landing page
        await page.screenshot({ 
            path: 'sidebar-test-1-landing.png', 
            fullPage: true 
        });
        console.log('Screenshot saved: sidebar-test-1-landing.png');
        
        // Wait for page to fully load
        await page.waitForTimeout(2000);
        
        console.log('2. Attempting login...');
        
        // Check if we need to login
        const loginForm = await page.$('form');
        if (loginForm) {
            // Fill login credentials
            await page.fill('input[type="email"], input[name="Input.Email"], #Input_Email', 'admin@steelestimation.com');
            await page.fill('input[type="password"], input[name="Input.Password"], #Input_Password', 'Admin@123');
            
            // Take screenshot before login
            await page.screenshot({ 
                path: 'sidebar-test-2-login-form.png', 
                fullPage: true 
            });
            console.log('Screenshot saved: sidebar-test-2-login-form.png');
            
            // Submit login
            await page.click('button[type="submit"]');
            
            // Wait for navigation after login
            await page.waitForTimeout(3000);
        }
        
        console.log('3. Checking page after login...');
        await page.screenshot({ 
            path: 'sidebar-test-3-after-login.png', 
            fullPage: true 
        });
        console.log('Screenshot saved: sidebar-test-3-after-login.png');
        
        console.log('4. Checking sidebar existence and structure...');
        
        // Check for different possible sidebar selectors
        const sidebarSelectors = [
            '.custom-sidebar',
            '.sidebar',
            '#sidebar',
            '[class*="sidebar"]',
            'nav.sidebar',
            'aside.sidebar',
            '.nav-sidebar',
            '.main-sidebar'
        ];
        
        let sidebarFound = false;
        for (const selector of sidebarSelectors) {
            const element = await page.$(selector);
            if (element) {
                console.log(`✓ Found sidebar with selector: ${selector}`);
                sidebarFound = true;
                
                // Get computed styles
                const styles = await page.evaluate((sel) => {
                    const el = document.querySelector(sel);
                    if (!el) return null;
                    const computed = window.getComputedStyle(el);
                    return {
                        width: computed.width,
                        position: computed.position,
                        backgroundColor: computed.backgroundColor,
                        display: computed.display,
                        visibility: computed.visibility,
                        left: computed.left,
                        top: computed.top,
                        height: computed.height,
                        zIndex: computed.zIndex
                    };
                }, selector);
                
                console.log(`Computed styles for ${selector}:`, styles);
            }
        }
        
        if (!sidebarFound) {
            console.log('✗ No sidebar element found with common selectors');
        }
        
        console.log('5. Checking CSS files loaded...');
        const cssFiles = await page.evaluate(() => {
            const sheets = [];
            for (let sheet of document.styleSheets) {
                if (sheet.href) {
                    sheets.push(sheet.href);
                }
            }
            return sheets;
        });
        
        console.log('Loaded CSS files:');
        cssFiles.forEach(file => {
            console.log(`  - ${file}`);
            if (file.includes('sidebar') || file.includes('site.css') || file.includes('viewscape')) {
                console.log(`    ✓ Contains sidebar-related styles`);
            }
        });
        
        console.log('6. Checking navigation menu structure...');
        const navMenuCheck = await page.evaluate(() => {
            const results = {};
            
            // Check for nav menu
            const navMenu = document.querySelector('.nav-menu, .navbar-nav, nav ul, .navigation');
            results.navMenuExists = !!navMenu;
            if (navMenu) {
                results.navMenuClass = navMenu.className;
                results.navMenuTag = navMenu.tagName;
            }
            
            // Check for nav links
            const navLinks = document.querySelectorAll('a[href*="/"], nav a, .nav-link');
            results.navLinksCount = navLinks.length;
            results.navLinks = Array.from(navLinks).slice(0, 10).map(link => ({
                text: link.textContent.trim(),
                href: link.href,
                className: link.className
            }));
            
            // Check for icons
            const icons = document.querySelectorAll('i[class*="fa"], i[class*="bi"], svg, .icon');
            results.iconsCount = icons.length;
            
            return results;
        });
        
        console.log('Navigation structure:', navMenuCheck);
        
        console.log('7. Running comprehensive sidebar diagnostics...');
        const diagnostics = await page.evaluate(() => {
            const results = {
                sidebarElements: [],
                mainContentArea: null,
                layoutStructure: {},
                cssVariables: {}
            };
            
            // Find all elements that might be sidebar
            const potentialSidebars = document.querySelectorAll('[class*="sidebar"], [id*="sidebar"], aside, nav');
            potentialSidebars.forEach(el => {
                const rect = el.getBoundingClientRect();
                if (rect.width > 0 && rect.height > 0) {
                    results.sidebarElements.push({
                        tag: el.tagName,
                        id: el.id,
                        className: el.className,
                        width: rect.width,
                        height: rect.height,
                        left: rect.left,
                        top: rect.top,
                        childrenCount: el.children.length
                    });
                }
            });
            
            // Check main content area
            const mainContent = document.querySelector('.main-content, main, [class*="content"], .container-fluid');
            if (mainContent) {
                const rect = mainContent.getBoundingClientRect();
                results.mainContentArea = {
                    tag: mainContent.tagName,
                    className: mainContent.className,
                    marginLeft: window.getComputedStyle(mainContent).marginLeft,
                    paddingLeft: window.getComputedStyle(mainContent).paddingLeft,
                    width: rect.width
                };
            }
            
            // Check layout structure
            const body = document.body;
            const firstLevelChildren = Array.from(body.children).map(child => ({
                tag: child.tagName,
                id: child.id,
                className: child.className,
                display: window.getComputedStyle(child).display,
                position: window.getComputedStyle(child).position
            }));
            results.layoutStructure.firstLevelChildren = firstLevelChildren;
            
            // Check CSS custom properties
            const rootStyles = window.getComputedStyle(document.documentElement);
            const customProps = ['--sidebar-width', '--sidebar-collapsed-width', '--main-content-margin'];
            customProps.forEach(prop => {
                const value = rootStyles.getPropertyValue(prop);
                if (value) {
                    results.cssVariables[prop] = value;
                }
            });
            
            return results;
        });
        
        console.log('Sidebar diagnostics:', JSON.stringify(diagnostics, null, 2));
        
        console.log('8. Checking for sidebar toggle functionality...');
        
        // Try to find and click sidebar toggle
        const toggleSelectors = [
            '.sidebar-toggle',
            '.toggle-sidebar',
            '#sidebarToggle',
            'button[onclick*="sidebar"]',
            '[data-toggle="sidebar"]',
            '.hamburger',
            '.menu-toggle'
        ];
        
        let toggleFound = false;
        for (const selector of toggleSelectors) {
            const toggle = await page.$(selector);
            if (toggle) {
                console.log(`✓ Found toggle button: ${selector}`);
                toggleFound = true;
                
                // Click toggle
                await toggle.click();
                await page.waitForTimeout(1000);
                
                // Take screenshot after toggle
                await page.screenshot({ 
                    path: 'sidebar-test-4-after-toggle.png', 
                    fullPage: true 
                });
                console.log('Screenshot saved: sidebar-test-4-after-toggle.png');
                
                // Click again to restore
                await toggle.click();
                await page.waitForTimeout(1000);
                
                break;
            }
        }
        
        if (!toggleFound) {
            console.log('✗ No sidebar toggle button found');
        }
        
        console.log('9. Final page state check...');
        
        // Get final HTML structure
        const htmlStructure = await page.evaluate(() => {
            const getStructure = (element, depth = 0, maxDepth = 3) => {
                if (!element || depth > maxDepth) return null;
                
                const children = Array.from(element.children)
                    .filter(child => {
                        const tag = child.tagName.toLowerCase();
                        return !['script', 'style', 'link'].includes(tag);
                    })
                    .slice(0, 5)
                    .map(child => getStructure(child, depth + 1, maxDepth));
                
                return {
                    tag: element.tagName.toLowerCase(),
                    id: element.id || undefined,
                    className: element.className || undefined,
                    children: children.length > 0 ? children : undefined
                };
            };
            
            return getStructure(document.body);
        });
        
        console.log('HTML Structure:', JSON.stringify(htmlStructure, null, 2));
        
        // Final screenshot
        await page.screenshot({ 
            path: 'sidebar-test-5-final.png', 
            fullPage: true 
        });
        console.log('Screenshot saved: sidebar-test-5-final.png');
        
        console.log('\n=== Test Complete ===');
        console.log('Screenshots saved:');
        console.log('  - sidebar-test-1-landing.png');
        console.log('  - sidebar-test-2-login-form.png');
        console.log('  - sidebar-test-3-after-login.png');
        console.log('  - sidebar-test-4-after-toggle.png');
        console.log('  - sidebar-test-5-final.png');
        
    } catch (error) {
        console.error('Test failed:', error);
        await page.screenshot({ 
            path: 'sidebar-test-error.png', 
            fullPage: true 
        });
        console.log('Error screenshot saved: sidebar-test-error.png');
    } finally {
        await browser.close();
    }
}

testSidebar().catch(console.error);