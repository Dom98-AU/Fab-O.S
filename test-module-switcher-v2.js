const { chromium } = require('playwright');
const fs = require('fs');

async function testModuleSwitcher() {
    console.log('Starting Module Switcher Test v2...');
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
            path: 'module-test-1-welcome.png',
            fullPage: true 
        });
        console.log('✓ Welcome page screenshot saved');
        
        // Step 2: Click Sign In button to navigate to login page
        console.log('\n2. Clicking Sign In button...');
        
        // Look for the Sign In link/button
        const signInButton = await page.$('a[href="/Account/Login"], button:has-text("Sign In")');
        if (signInButton) {
            await signInButton.click();
            await page.waitForTimeout(3000);
            console.log('✓ Clicked Sign In button');
        } else {
            console.log('✗ Sign In button not found, checking if already on login page...');
        }
        
        // Wait for login page to load
        await page.waitForSelector('input[type="email"], input[type="text"]', { timeout: 10000 });
        
        // Take screenshot of login page
        await page.screenshot({ 
            path: 'module-test-2-login-page.png',
            fullPage: true 
        });
        console.log('✓ Login page screenshot saved');
        
        // Step 3: Fill in login credentials
        console.log('\n3. Filling login form...');
        
        // Find and fill email field
        const emailField = await page.$('input[type="email"], input[name="email"], input#Input_Email');
        if (emailField) {
            await emailField.fill('admin@steelestimation.com');
            console.log('✓ Email entered');
        }
        
        // Find and fill password field
        const passwordField = await page.$('input[type="password"], input[name="password"], input#Input_Password');
        if (passwordField) {
            await passwordField.fill('Admin@123');
            console.log('✓ Password entered');
        }
        
        // Take screenshot with credentials filled
        await page.screenshot({ 
            path: 'module-test-3-login-filled.png',
            fullPage: true 
        });
        console.log('✓ Login form filled screenshot saved');
        
        // Step 4: Submit login form
        console.log('\n4. Submitting login...');
        
        // Find and click the submit button
        const submitButton = await page.$('button[type="submit"], #loginButton');
        if (submitButton) {
            await submitButton.click();
            console.log('✓ Login button clicked');
        } else {
            console.log('✗ Submit button not found');
        }
        
        // Wait for navigation after login
        await page.waitForTimeout(5000);
        
        // Check if login was successful
        const currentUrl = page.url();
        console.log(`Current URL: ${currentUrl}`);
        
        if (currentUrl.includes('/Account/Login') || currentUrl.includes('/login')) {
            console.log('✗ Login may have failed - still on login page');
            await page.screenshot({ 
                path: 'module-test-login-failed.png',
                fullPage: true 
            });
        } else {
            console.log('✓ Login successful - navigated away from login page');
        }
        
        // Step 5: Look for sidebar and module switcher
        console.log('\n5. Checking for sidebar components...');
        
        // Take screenshot of current page
        await page.screenshot({ 
            path: 'module-test-4-dashboard.png',
            fullPage: true 
        });
        console.log('✓ Dashboard screenshot saved');
        
        // Check for sidebar
        const sidebar = await page.$('.sidebar, nav.sidebar, #sidebar, [class*="sidebar"]');
        if (sidebar) {
            console.log('✓ Sidebar found');
            
            // Check for logo
            const logo = await page.$('.sidebar img, .sidebar-logo img, nav img');
            if (logo) {
                const logoSrc = await logo.getAttribute('src');
                console.log(`✓ Logo found: ${logoSrc}`);
                
                // Check for text next to logo
                const logoText = await page.$('.sidebar-logo span, .sidebar .logo-text, .sidebar-logo .text');
                if (logoText) {
                    const text = await logoText.textContent();
                    if (text && text.includes('Fab')) {
                        console.log(`✗ WARNING: Text found next to logo: "${text}"`);
                    }
                } else {
                    console.log('✓ No text next to logo (correct)');
                }
            }
            
            // Check for module switcher
            console.log('\n6. Looking for module switcher...');
            
            // Try different selectors for module switcher
            const moduleSwitcherSelectors = [
                '.module-switcher',
                '.module-selector',
                '.module-dropdown',
                'select.form-select',
                '.sidebar select',
                '.sidebar .dropdown',
                '.sidebar-module',
                '[id*="module"]'
            ];
            
            let foundModuleSwitcher = false;
            for (let selector of moduleSwitcherSelectors) {
                const element = await page.$(selector);
                if (element) {
                    console.log(`✓ Module switcher found with selector: ${selector}`);
                    foundModuleSwitcher = true;
                    
                    // Get the text/value
                    const text = await element.textContent();
                    const value = await element.inputValue().catch(() => null);
                    console.log(`  Current module: ${text || value || 'Unknown'}`);
                    
                    // Try to interact with it
                    try {
                        await element.click();
                        await page.waitForTimeout(1000);
                        
                        await page.screenshot({ 
                            path: 'module-test-5-module-switcher-clicked.png',
                            fullPage: true 
                        });
                        console.log('✓ Module switcher clicked screenshot saved');
                        
                        // Look for options
                        const options = await page.$$('option, .dropdown-item, .module-option');
                        if (options.length > 0) {
                            console.log(`  Found ${options.length} module options:`);
                            for (let i = 0; i < Math.min(options.length, 5); i++) {
                                const optText = await options[i].textContent();
                                console.log(`    - ${optText.trim()}`);
                            }
                        }
                    } catch (e) {
                        console.log(`  Could not interact with module switcher: ${e.message}`);
                    }
                    
                    break;
                }
            }
            
            if (!foundModuleSwitcher) {
                console.log('✗ Module switcher not found');
                
                // Debug: Get all selects and dropdowns on page
                const allSelects = await page.$$('select');
                const allDropdowns = await page.$$('.dropdown, [class*="dropdown"]');
                console.log(`  Debug: Found ${allSelects.length} select elements`);
                console.log(`  Debug: Found ${allDropdowns.length} dropdown elements`);
            }
            
            // Check for hamburger button
            console.log('\n7. Testing hamburger button...');
            
            const hamburgerSelectors = [
                '.hamburger-btn',
                '.sidebar-toggle',
                '.btn-sidebar-toggle',
                'button[onclick*="toggleSidebar"]',
                '[class*="hamburger"]',
                '.toggle-btn'
            ];
            
            let foundHamburger = false;
            for (let selector of hamburgerSelectors) {
                const hamburger = await page.$(selector);
                if (hamburger) {
                    console.log(`✓ Hamburger button found with selector: ${selector}`);
                    foundHamburger = true;
                    
                    // Click to collapse
                    await hamburger.click();
                    await page.waitForTimeout(1500);
                    
                    await page.screenshot({ 
                        path: 'module-test-6-sidebar-collapsed.png',
                        fullPage: true 
                    });
                    console.log('✓ Sidebar collapsed screenshot saved');
                    
                    // Click to expand
                    await hamburger.click();
                    await page.waitForTimeout(1500);
                    
                    await page.screenshot({ 
                        path: 'module-test-7-sidebar-expanded.png',
                        fullPage: true 
                    });
                    console.log('✓ Sidebar expanded screenshot saved');
                    
                    break;
                }
            }
            
            if (!foundHamburger) {
                console.log('✗ Hamburger button not found');
            }
            
        } else {
            console.log('✗ Sidebar not found');
        }
        
        // Step 8: Capture page structure for debugging
        console.log('\n8. Capturing page structure...');
        
        const pageStructure = await page.evaluate(() => {
            const result = {
                url: window.location.href,
                title: document.title,
                sidebar: null,
                selects: [],
                dropdowns: [],
                images: []
            };
            
            // Find sidebar
            const sidebar = document.querySelector('.sidebar, nav.sidebar, #sidebar');
            if (sidebar) {
                result.sidebar = {
                    className: sidebar.className,
                    innerHTML: sidebar.innerHTML.substring(0, 500)
                };
            }
            
            // Find all select elements
            document.querySelectorAll('select').forEach(select => {
                result.selects.push({
                    id: select.id,
                    className: select.className,
                    options: Array.from(select.options).map(opt => opt.text)
                });
            });
            
            // Find all dropdowns
            document.querySelectorAll('.dropdown, [class*="dropdown"]').forEach(dropdown => {
                result.dropdowns.push({
                    className: dropdown.className,
                    text: dropdown.textContent.substring(0, 100)
                });
            });
            
            // Find all images
            document.querySelectorAll('img').forEach(img => {
                if (img.src.includes('logo') || img.src.includes('fab')) {
                    result.images.push({
                        src: img.src,
                        alt: img.alt
                    });
                }
            });
            
            return result;
        });
        
        fs.writeFileSync('module-test-structure.json', JSON.stringify(pageStructure, null, 2));
        console.log('✓ Page structure saved to module-test-structure.json');
        
        // Final summary
        console.log('\n' + '='.repeat(50));
        console.log('TEST SUMMARY');
        console.log('='.repeat(50));
        console.log('Test completed successfully!');
        console.log('\nScreenshots saved:');
        console.log('  1. module-test-1-welcome.png - Welcome page');
        console.log('  2. module-test-2-login-page.png - Login page');
        console.log('  3. module-test-3-login-filled.png - Login form filled');
        console.log('  4. module-test-4-dashboard.png - Dashboard after login');
        console.log('  5. module-test-5-module-switcher-clicked.png - Module switcher interaction');
        console.log('  6. module-test-6-sidebar-collapsed.png - Sidebar collapsed');
        console.log('  7. module-test-7-sidebar-expanded.png - Sidebar expanded');
        console.log('  8. module-test-structure.json - Page structure data');
        
    } catch (error) {
        console.error('\nError during test:', error.message);
        
        // Take error screenshot
        await page.screenshot({ 
            path: 'module-test-error.png',
            fullPage: true 
        });
        console.log('Error screenshot saved as module-test-error.png');
        
        // Save error details
        const errorDetails = {
            error: error.message,
            stack: error.stack,
            url: page.url(),
            timestamp: new Date().toISOString()
        };
        fs.writeFileSync('module-test-error.json', JSON.stringify(errorDetails, null, 2));
        console.log('Error details saved to module-test-error.json');
    } finally {
        // Keep browser open for manual inspection
        console.log('\nKeeping browser open for 10 seconds for manual inspection...');
        await page.waitForTimeout(10000);
        
        await browser.close();
        console.log('Browser closed. Test completed.');
    }
}

// Run the test
testModuleSwitcher().catch(console.error);