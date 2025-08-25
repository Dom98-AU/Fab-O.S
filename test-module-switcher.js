const { chromium } = require('playwright');
const fs = require('fs');

async function testModuleSwitcher() {
    console.log('Starting Module Switcher Test...');
    const browser = await chromium.launch({ 
        headless: false,
        slowMo: 500 
    });
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 },
        ignoreHTTPSErrors: true
    });
    
    const page = await context.newPage();
    
    try {
        // Step 1: Navigate to the application
        console.log('\n1. Navigating to http://localhost:8080...');
        await page.goto('http://localhost:8080', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        await page.waitForTimeout(2000);
        
        // Take screenshot of landing page
        await page.screenshot({ 
            path: 'module-test-1-landing.png',
            fullPage: true 
        });
        console.log('✓ Landing page screenshot saved');
        
        // Step 2: Login - we're already on the login page
        console.log('\n2. Logging in...');
        
        // Wait for login form to be ready
        await page.waitForSelector('input[type="email"]', { timeout: 10000 });
        
        // Fill login form - using the actual selector from the page
        await page.fill('input[type="email"]', 'admin@steelestimation.com');
        await page.fill('input[type="password"]', 'Admin@123');
        
        // Take screenshot before login
        await page.screenshot({ 
            path: 'module-test-2-login-form.png',
            fullPage: true 
        });
        console.log('✓ Login form screenshot saved');
        
        // Submit login - look for the actual login button
        const loginButton = await page.$('#loginButton, button[type="submit"]:has-text("Sign In")');
        if (loginButton) {
            await loginButton.click();
        } else {
            // Fallback to any submit button
            await page.click('button[type="submit"]');
        }
        
        // Wait for navigation after login
        await page.waitForTimeout(5000);
        
        // Check if we're still on login page (login failed)
        const currentUrl = page.url();
        if (currentUrl.includes('/Account/Login') || currentUrl.includes('/login')) {
            console.log('✗ Login failed - still on login page');
            await page.screenshot({ 
                path: 'module-test-login-failed.png',
                fullPage: true 
            });
            throw new Error('Login failed');
        }
        
        // Wait for dashboard/main page to load
        console.log('Waiting for dashboard to load...');
        
        // Step 3: Verify sidebar and logo
        console.log('\n3. Verifying sidebar and logo...');
        await page.waitForTimeout(2000);
        
        // Take screenshot of dashboard with sidebar
        await page.screenshot({ 
            path: 'module-test-3-dashboard.png',
            fullPage: true 
        });
        console.log('✓ Dashboard screenshot saved');
        
        // Look for sidebar with various possible selectors
        const sidebarSelectors = [
            '.sidebar',
            'nav.sidebar',
            '#sidebar',
            '.navigation-sidebar',
            '.left-sidebar',
            '[class*="sidebar"]'
        ];
        
        let sidebar = null;
        for (let selector of sidebarSelectors) {
            sidebar = await page.$(selector);
            if (sidebar) {
                console.log(`✓ Sidebar found with selector: ${selector}`);
                break;
            }
        }
        
        if (!sidebar) {
            console.log('✗ Sidebar not found');
        }
        
        // Check for logo
        const logoSelectors = [
            '.sidebar img',
            '.sidebar-logo img',
            '.logo img',
            'nav img',
            '.sidebar-header img'
        ];
        
        let logo = null;
        for (let selector of logoSelectors) {
            logo = await page.$(selector);
            if (logo) {
                console.log(`✓ Logo found with selector: ${selector}`);
                break;
            }
        }
        
        // Check for "Fab O.S" text next to logo
        const textSelectors = [
            '.sidebar-logo .logo-text',
            '.sidebar .logo-text',
            '.sidebar-header .text',
            '.sidebar span:has-text("Fab O.S")',
            '.logo-text'
        ];
        
        let hasText = false;
        for (let selector of textSelectors) {
            const textElement = await page.$(selector);
            if (textElement) {
                const text = await textElement.textContent();
                if (text && text.includes('Fab')) {
                    hasText = true;
                    console.log(`✗ WARNING: Found "Fab O.S" text with selector: ${selector}`);
                    break;
                }
            }
        }
        
        if (!hasText) {
            console.log('✓ No "Fab O.S" text next to logo (correct)');
        }
        
        // Step 4: Check for module switcher
        console.log('\n4. Checking for module switcher...');
        
        const moduleSwitcherSelectors = [
            '.module-switcher',
            '.module-dropdown',
            '.sidebar select',
            'select.form-select',
            '.sidebar-module-switcher',
            '.module-selector',
            '[class*="module"]',
            '.sidebar .dropdown'
        ];
        
        let moduleSwitcher = null;
        for (let selector of moduleSwitcherSelectors) {
            moduleSwitcher = await page.$(selector);
            if (moduleSwitcher) {
                console.log(`✓ Module switcher found with selector: ${selector}`);
                
                // Get the current module text
                const text = await moduleSwitcher.textContent();
                console.log(`  Current module: ${text || 'Unknown'}`);
                
                // Take screenshot
                await page.screenshot({ 
                    path: 'module-test-4-module-switcher.png',
                    fullPage: true 
                });
                console.log('✓ Module switcher screenshot saved');
                
                // Try to click it
                try {
                    await moduleSwitcher.click();
                    await page.waitForTimeout(1000);
                    
                    // Take screenshot with dropdown open
                    await page.screenshot({ 
                        path: 'module-test-5-dropdown-open.png',
                        fullPage: true 
                    });
                    console.log('✓ Dropdown open screenshot saved');
                    
                    // Look for dropdown options
                    const optionSelectors = [
                        'option',
                        '.dropdown-item',
                        '.module-option',
                        '[role="option"]'
                    ];
                    
                    for (let optSelector of optionSelectors) {
                        const options = await page.$$(optSelector);
                        if (options.length > 0) {
                            console.log(`  Found ${options.length} options with selector: ${optSelector}`);
                            for (let option of options) {
                                const optText = await option.textContent();
                                if (optText) {
                                    console.log(`    - ${optText.trim()}`);
                                }
                            }
                            break;
                        }
                    }
                    
                    // Close dropdown
                    await page.click('body');
                    await page.waitForTimeout(1000);
                } catch (e) {
                    console.log('  Could not interact with module switcher:', e.message);
                }
                
                break;
            }
        }
        
        if (!moduleSwitcher) {
            console.log('✗ Module switcher not found');
        }
        
        // Step 5: Test sidebar collapse/expand
        console.log('\n5. Testing sidebar collapse/expand...');
        
        const hamburgerSelectors = [
            '.hamburger-btn',
            '.sidebar-toggle',
            'button[onclick*="toggleSidebar"]',
            '.btn-sidebar-toggle',
            '.toggle-sidebar',
            '[class*="hamburger"]',
            '[class*="toggle"]'
        ];
        
        let hamburger = null;
        for (let selector of hamburgerSelectors) {
            hamburger = await page.$(selector);
            if (hamburger) {
                console.log(`✓ Hamburger button found with selector: ${selector}`);
                
                // Collapse sidebar
                await hamburger.click();
                await page.waitForTimeout(1500);
                
                await page.screenshot({ 
                    path: 'module-test-6-sidebar-collapsed.png',
                    fullPage: true 
                });
                console.log('✓ Sidebar collapsed screenshot saved');
                
                // Expand sidebar again
                await hamburger.click();
                await page.waitForTimeout(1500);
                
                await page.screenshot({ 
                    path: 'module-test-7-sidebar-expanded.png',
                    fullPage: true 
                });
                console.log('✓ Sidebar re-expanded screenshot saved');
                
                break;
            }
        }
        
        if (!hamburger) {
            console.log('✗ Hamburger button not found');
        }
        
        // Step 6: Detailed structure analysis
        console.log('\n6. Analyzing page structure...');
        
        // Get and save the page structure
        const pageStructure = await page.evaluate(() => {
            const result = {
                sidebar: null,
                logo: null,
                moduleSwitcher: null,
                hamburger: null,
                elements: []
            };
            
            // Find sidebar
            const sidebarEl = document.querySelector('.sidebar, nav.sidebar, #sidebar, [class*="sidebar"]');
            if (sidebarEl) {
                result.sidebar = {
                    className: sidebarEl.className,
                    id: sidebarEl.id,
                    tagName: sidebarEl.tagName
                };
            }
            
            // Find all images (potential logos)
            const images = document.querySelectorAll('img');
            images.forEach(img => {
                if (img.src.includes('logo') || img.alt.includes('logo') || img.src.includes('fab')) {
                    result.logo = {
                        src: img.src,
                        alt: img.alt,
                        className: img.className
                    };
                }
            });
            
            // Find selects and dropdowns
            const selects = document.querySelectorAll('select, .dropdown, [class*="module"]');
            selects.forEach(el => {
                result.elements.push({
                    tagName: el.tagName,
                    className: el.className,
                    text: el.textContent ? el.textContent.substring(0, 50) : ''
                });
            });
            
            return result;
        });
        
        console.log('Page structure:', JSON.stringify(pageStructure, null, 2));
        
        // Save structure to file
        fs.writeFileSync('module-test-structure.json', JSON.stringify(pageStructure, null, 2));
        console.log('✓ Page structure saved to module-test-structure.json');
        
        // Final summary
        console.log('\n' + '='.repeat(50));
        console.log('TEST SUMMARY');
        console.log('='.repeat(50));
        console.log('Screenshots saved:');
        console.log('  1. module-test-1-landing.png');
        console.log('  2. module-test-2-login-form.png');
        console.log('  3. module-test-3-dashboard.png');
        console.log('  4. module-test-4-module-switcher.png');
        console.log('  5. module-test-5-dropdown-open.png');
        console.log('  6. module-test-6-sidebar-collapsed.png');
        console.log('  7. module-test-7-sidebar-expanded.png');
        console.log('  8. module-test-structure.json');
        
    } catch (error) {
        console.error('\nError during test:', error.message);
        
        // Take error screenshot
        await page.screenshot({ 
            path: 'module-test-error.png',
            fullPage: true 
        });
        console.log('Error screenshot saved as module-test-error.png');
        
        // Log page content for debugging
        const pageContent = await page.content();
        fs.writeFileSync('module-test-error-page.html', pageContent);
        console.log('Error page HTML saved as module-test-error-page.html');
    } finally {
        await browser.close();
        console.log('\nTest completed.');
    }
}

// Run the test
testModuleSwitcher().catch(console.error);