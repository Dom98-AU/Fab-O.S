const { chromium } = require('playwright');
const fs = require('fs');

async function testModuleSwitcher() {
    console.log('Starting Module Switcher Test - Final Version...');
    const browser = await chromium.launch({ 
        headless: false,
        slowMo: 300 
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
            path: 'module-final-1-welcome.png',
            fullPage: true 
        });
        console.log('✓ Welcome page screenshot saved');
        
        // Step 2: Click Sign In button
        console.log('\n2. Clicking Sign In button...');
        await page.click('a[href="/Account/Login"]');
        await page.waitForTimeout(3000);
        console.log('✓ Navigated to login page');
        
        // Take screenshot of login page
        await page.screenshot({ 
            path: 'module-final-2-login-page.png',
            fullPage: true 
        });
        console.log('✓ Login page screenshot saved');
        
        // Step 3: Fill in login credentials
        console.log('\n3. Filling login form...');
        
        // Fill email - use the id selector
        const emailInput = await page.locator('#email').first();
        await emailInput.click();
        await emailInput.fill('admin@steelestimation.com');
        console.log('✓ Email entered');
        
        // Fill password
        const passwordInput = await page.locator('input[type="password"]').first();
        await passwordInput.click();
        await passwordInput.fill('Admin@123');
        console.log('✓ Password entered');
        
        // Take screenshot with credentials filled
        await page.screenshot({ 
            path: 'module-final-3-login-filled.png',
            fullPage: true 
        });
        console.log('✓ Login form filled screenshot saved');
        
        // Step 4: Submit login form
        console.log('\n4. Submitting login...');
        await page.click('button:has-text("Sign In")');
        console.log('✓ Login button clicked');
        
        // Wait for navigation
        await page.waitForTimeout(7000);
        
        // Check if login was successful
        const currentUrl = page.url();
        console.log(`Current URL after login: ${currentUrl}`);
        
        if (currentUrl.includes('/Account/Login') || currentUrl.includes('/login')) {
            console.log('✗ Still on login page - checking for errors...');
            const errorMessage = await page.locator('.text-danger, .validation-summary-errors').textContent().catch(() => null);
            if (errorMessage) {
                console.log(`  Error message: ${errorMessage}`);
            }
            await page.screenshot({ 
                path: 'module-final-login-error.png',
                fullPage: true 
            });
        } else {
            console.log('✓ Login successful - navigated to: ' + currentUrl);
        }
        
        // Step 5: Check for sidebar and components
        console.log('\n5. Checking for sidebar components...');
        
        // Take screenshot of current page (should be dashboard)
        await page.screenshot({ 
            path: 'module-final-4-dashboard.png',
            fullPage: true 
        });
        console.log('✓ Dashboard screenshot saved');
        
        // Wait for sidebar to be visible
        await page.waitForSelector('.sidebar, nav.sidebar, #sidebar', { timeout: 5000 }).catch(() => {
            console.log('  Sidebar not found within 5 seconds');
        });
        
        // Check for sidebar
        const sidebar = await page.locator('.sidebar, nav.sidebar, #sidebar').first();
        const sidebarExists = await sidebar.count() > 0;
        
        if (sidebarExists) {
            console.log('✓ Sidebar found');
            
            // Check for logo
            const logo = await page.locator('.sidebar img, nav img').first();
            const logoExists = await logo.count() > 0;
            
            if (logoExists) {
                const logoSrc = await logo.getAttribute('src');
                console.log(`✓ Logo found: ${logoSrc}`);
                
                // Check for "Fab O.S" text next to logo
                const textElements = await page.locator('.sidebar-logo span, .logo-text, .sidebar-header span').all();
                let foundFabText = false;
                
                for (const element of textElements) {
                    const text = await element.textContent();
                    if (text && text.includes('Fab')) {
                        foundFabText = true;
                        console.log(`✗ WARNING: Found "Fab O.S" text: "${text}"`);
                        break;
                    }
                }
                
                if (!foundFabText) {
                    console.log('✓ No "Fab O.S" text next to logo (correct - logo only)');
                }
            } else {
                console.log('✗ Logo not found');
            }
            
            // Step 6: Check for module switcher
            console.log('\n6. Looking for module switcher...');
            
            // Look for module switcher with various selectors
            const moduleSwitcherSelectors = [
                '.module-switcher',
                '.module-selector',
                '.module-dropdown',
                'select.form-select',
                '.sidebar select',
                '.sidebar .dropdown:has-text("Estimate")',
                '.sidebar .dropdown:has-text("Module")',
                '[class*="module"]'
            ];
            
            let moduleSwitcher = null;
            for (const selector of moduleSwitcherSelectors) {
                const element = await page.locator(selector).first();
                if (await element.count() > 0) {
                    moduleSwitcher = element;
                    console.log(`✓ Module switcher found with selector: ${selector}`);
                    
                    // Get the current module text
                    const text = await element.textContent();
                    console.log(`  Current module: ${text}`);
                    
                    // Take screenshot
                    await page.screenshot({ 
                        path: 'module-final-5-module-switcher.png',
                        fullPage: true 
                    });
                    console.log('✓ Module switcher screenshot saved');
                    
                    // Try to click it
                    try {
                        await element.click();
                        await page.waitForTimeout(1500);
                        
                        // Take screenshot with dropdown open
                        await page.screenshot({ 
                            path: 'module-final-6-dropdown-open.png',
                            fullPage: true 
                        });
                        console.log('✓ Dropdown open screenshot saved');
                        
                        // Look for module options
                        const options = await page.locator('option, .dropdown-item, .module-option').all();
                        if (options.length > 0) {
                            console.log(`  Found ${options.length} module options:`);
                            for (let i = 0; i < Math.min(options.length, 5); i++) {
                                const optText = await options[i].textContent();
                                console.log(`    - ${optText.trim()}`);
                            }
                        }
                        
                        // Close dropdown by clicking elsewhere
                        await page.click('body');
                        await page.waitForTimeout(1000);
                    } catch (e) {
                        console.log(`  Could not interact with module switcher: ${e.message}`);
                    }
                    
                    break;
                }
            }
            
            if (!moduleSwitcher) {
                console.log('✗ Module switcher not found');
                console.log('  Debugging: Looking for any select or dropdown elements...');
                
                const allSelects = await page.locator('select').all();
                const allDropdowns = await page.locator('.dropdown, [class*="dropdown"]').all();
                
                console.log(`  Found ${allSelects.length} select elements on page`);
                console.log(`  Found ${allDropdowns.length} dropdown elements on page`);
                
                if (allSelects.length > 0) {
                    for (let i = 0; i < Math.min(allSelects.length, 3); i++) {
                        const id = await allSelects[i].getAttribute('id');
                        const className = await allSelects[i].getAttribute('class');
                        console.log(`    Select ${i+1}: id="${id}", class="${className}"`);
                    }
                }
            }
            
            // Step 7: Test hamburger button
            console.log('\n7. Testing hamburger button...');
            
            const hamburger = await page.locator('.hamburger-btn, .sidebar-toggle, [onclick*="toggleSidebar"]').first();
            const hamburgerExists = await hamburger.count() > 0;
            
            if (hamburgerExists) {
                console.log('✓ Hamburger button found');
                
                // Click to collapse
                await hamburger.click();
                await page.waitForTimeout(1500);
                
                await page.screenshot({ 
                    path: 'module-final-7-sidebar-collapsed.png',
                    fullPage: true 
                });
                console.log('✓ Sidebar collapsed screenshot saved');
                
                // Check if logo is still visible when collapsed
                const collapsedLogo = await page.locator('.sidebar img, nav img').first();
                if (await collapsedLogo.count() > 0) {
                    console.log('✓ Logo still visible in collapsed state');
                }
                
                // Click to expand
                await hamburger.click();
                await page.waitForTimeout(1500);
                
                await page.screenshot({ 
                    path: 'module-final-8-sidebar-expanded.png',
                    fullPage: true 
                });
                console.log('✓ Sidebar re-expanded screenshot saved');
            } else {
                console.log('✗ Hamburger button not found');
            }
            
        } else {
            console.log('✗ Sidebar not found');
        }
        
        // Step 8: Capture detailed page structure
        console.log('\n8. Capturing page structure for analysis...');
        
        const pageStructure = await page.evaluate(() => {
            const result = {
                url: window.location.href,
                title: document.title,
                authenticated: !window.location.href.includes('/Account/Login'),
                sidebar: null,
                moduleElements: [],
                navigation: []
            };
            
            // Find sidebar
            const sidebar = document.querySelector('.sidebar, nav.sidebar, #sidebar');
            if (sidebar) {
                result.sidebar = {
                    found: true,
                    className: sidebar.className,
                    hasLogo: !!sidebar.querySelector('img'),
                    hasText: sidebar.textContent.includes('Fab O.S')
                };
                
                // Look for module-related elements within sidebar
                const moduleElements = sidebar.querySelectorAll('select, .dropdown, [class*="module"]');
                moduleElements.forEach(el => {
                    result.moduleElements.push({
                        tagName: el.tagName,
                        className: el.className,
                        id: el.id,
                        text: el.textContent.substring(0, 50)
                    });
                });
            }
            
            // Find navigation items
            const navItems = document.querySelectorAll('.nav-item a, .sidebar a');
            navItems.forEach(item => {
                const text = item.textContent.trim();
                if (text && text.length > 0) {
                    result.navigation.push(text);
                }
            });
            
            return result;
        });
        
        fs.writeFileSync('module-final-structure.json', JSON.stringify(pageStructure, null, 2));
        console.log('✓ Page structure saved to module-final-structure.json');
        
        // Final summary
        console.log('\n' + '='.repeat(60));
        console.log('MODULE SWITCHER TEST SUMMARY');
        console.log('='.repeat(60));
        
        console.log('\nTest Results:');
        console.log('  ✓ Application accessible');
        console.log('  ✓ Login page functional');
        console.log(`  ${pageStructure.authenticated ? '✓' : '✗'} Authentication successful`);
        console.log(`  ${pageStructure.sidebar ? '✓' : '✗'} Sidebar present`);
        console.log(`  ${pageStructure.sidebar && pageStructure.sidebar.hasLogo ? '✓' : '✗'} Logo displayed`);
        console.log(`  ${pageStructure.sidebar && !pageStructure.sidebar.hasText ? '✓' : '✗'} No "Fab O.S" text (logo only)`);
        console.log(`  ${pageStructure.moduleElements.length > 0 ? '✓' : '✗'} Module switcher elements found`);
        
        console.log('\nScreenshots saved:');
        console.log('  1. module-final-1-welcome.png');
        console.log('  2. module-final-2-login-page.png');
        console.log('  3. module-final-3-login-filled.png');
        console.log('  4. module-final-4-dashboard.png');
        console.log('  5. module-final-5-module-switcher.png');
        console.log('  6. module-final-6-dropdown-open.png');
        console.log('  7. module-final-7-sidebar-collapsed.png');
        console.log('  8. module-final-8-sidebar-expanded.png');
        console.log('  9. module-final-structure.json');
        
        if (pageStructure.moduleElements.length === 0) {
            console.log('\n⚠ MODULE SWITCHER NOT FOUND');
            console.log('The module switcher dropdown was not detected in the sidebar.');
            console.log('Please ensure it has been implemented with one of these selectors:');
            console.log('  - .module-switcher');
            console.log('  - .module-selector');
            console.log('  - .module-dropdown');
            console.log('  - select.form-select (in sidebar)');
        }
        
    } catch (error) {
        console.error('\nError during test:', error.message);
        
        // Take error screenshot
        await page.screenshot({ 
            path: 'module-final-error.png',
            fullPage: true 
        });
        console.log('Error screenshot saved as module-final-error.png');
        
        // Save error details
        fs.writeFileSync('module-final-error.json', JSON.stringify({
            error: error.message,
            stack: error.stack,
            url: page.url(),
            timestamp: new Date().toISOString()
        }, null, 2));
    } finally {
        console.log('\nKeeping browser open for 10 seconds for inspection...');
        await page.waitForTimeout(10000);
        
        await browser.close();
        console.log('Test completed.');
    }
}

// Run the test
testModuleSwitcher().catch(console.error);