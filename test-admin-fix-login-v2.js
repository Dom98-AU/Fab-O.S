const { chromium } = require('playwright');
const fs = require('fs');

async function testAdminFixAndLogin() {
    console.log('Starting Admin Fix and Login Test v2...\n');
    
    const browser = await chromium.launch({ 
        headless: false,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 },
        ignoreHTTPSErrors: true
    });
    
    const page = await context.newPage();
    
    // Enable console logging
    page.on('console', msg => {
        if (msg.type() === 'error') {
            console.log('Browser Console Error:', msg.text());
        }
    });

    let loginSuccess = false;
    let sidebarFound = false;
    let sidebarInfo = {};

    try {
        // Step 1: Navigate to FixAdmin page
        console.log('Step 1: Navigating to FixAdmin page...');
        const fixAdminResponse = await page.goto('http://localhost:8080/FixAdmin', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        
        console.log(`  Response status: ${fixAdminResponse ? fixAdminResponse.status() : 'N/A'}`);
        await page.waitForTimeout(2000);
        
        // Step 2: Take screenshot and analyze page
        console.log('Step 2: Analyzing FixAdmin page...');
        await page.screenshot({ 
            path: 'test-1-fixadmin-page.png',
            fullPage: true 
        });
        
        // Check if we were redirected
        const currentUrl = page.url();
        console.log(`  Current URL: ${currentUrl}`);
        
        if (currentUrl.includes('/Account/Login')) {
            console.log('  Redirected to login page - admin may already be fixed');
        } else {
            // Step 3: Try to click Fix Admin button
            console.log('Step 3: Looking for Fix Admin User button...');
            
            // Get all buttons on the page
            const buttons = await page.locator('button, input[type="submit"], input[type="button"]').all();
            console.log(`  Found ${buttons.length} button elements`);
            
            for (let i = 0; i < buttons.length; i++) {
                const buttonText = await buttons[i].textContent().catch(() => '');
                const buttonValue = await buttons[i].getAttribute('value').catch(() => '');
                console.log(`    Button ${i + 1}: "${buttonText || buttonValue}"`);
            }
            
            // Try to click the fix button
            try {
                await page.locator('button, input[type="submit"]').first().click();
                console.log('  Clicked first button/submit element');
                await page.waitForTimeout(3000);
            } catch (e) {
                console.log('  Could not click button:', e.message);
            }
            
            await page.screenshot({ 
                path: 'test-2-fixadmin-result.png',
                fullPage: true 
            });
        }
        
        // Step 4: Navigate to login page
        console.log('Step 4: Navigating to login page...');
        await page.goto('http://localhost:8080/Account/Login', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        await page.waitForTimeout(2000);
        
        // Step 5: Analyze login page structure
        console.log('Step 5: Analyzing login page structure...');
        
        // Get all form inputs
        const inputs = await page.locator('input').all();
        console.log(`  Found ${inputs.length} input fields:`);
        
        for (let i = 0; i < inputs.length; i++) {
            const inputName = await inputs[i].getAttribute('name').catch(() => '');
            const inputType = await inputs[i].getAttribute('type').catch(() => '');
            const inputId = await inputs[i].getAttribute('id').catch(() => '');
            const inputPlaceholder = await inputs[i].getAttribute('placeholder').catch(() => '');
            console.log(`    Input ${i + 1}: name="${inputName}", type="${inputType}", id="${inputId}", placeholder="${inputPlaceholder}"`);
        }
        
        await page.screenshot({ 
            path: 'test-3-login-page.png',
            fullPage: true 
        });
        
        // Step 6: Fill in credentials with better detection
        console.log('Step 6: Filling login form...');
        
        // Look for username/email field
        const usernameField = await page.locator('input[name="Username"], input[name="Email"], input[name="UserName"], input[type="email"]:not([type="hidden"])').first();
        if (await usernameField.count() > 0) {
            await usernameField.fill('admin@steelestimation.com');
            console.log('  ✓ Username/Email filled');
        } else {
            // Try visible text input that's not password
            const textInput = await page.locator('input[type="text"]:visible').first();
            if (await textInput.count() > 0) {
                await textInput.fill('admin@steelestimation.com');
                console.log('  ✓ Username filled (text input)');
            } else {
                console.log('  ✗ Could not find username field');
            }
        }
        
        // Fill password
        const passwordField = await page.locator('input[type="password"]').first();
        if (await passwordField.count() > 0) {
            await passwordField.fill('Admin@123');
            console.log('  ✓ Password filled');
        } else {
            console.log('  ✗ Could not find password field');
        }
        
        // Step 7: Submit form
        console.log('Step 7: Submitting login form...');
        
        // Try multiple methods to submit
        try {
            // Method 1: Click submit button
            const submitButton = await page.locator('button[type="submit"], input[type="submit"]').first();
            if (await submitButton.count() > 0) {
                await submitButton.click();
                console.log('  Clicked submit button');
            } else {
                // Method 2: Press Enter in password field
                await passwordField.press('Enter');
                console.log('  Pressed Enter in password field');
            }
        } catch (e) {
            console.log('  Error submitting form:', e.message);
        }
        
        // Step 8: Wait for navigation
        console.log('Step 8: Waiting for login result...');
        await page.waitForTimeout(5000);
        
        const afterLoginUrl = page.url();
        console.log(`  URL after login: ${afterLoginUrl}`);
        
        await page.screenshot({ 
            path: 'test-4-after-login.png',
            fullPage: true 
        });
        
        // Step 9: Check login success
        console.log('Step 9: Checking login status...');
        
        loginSuccess = !afterLoginUrl.includes('/Account/Login') && 
                      !afterLoginUrl.includes('/login');
        
        if (loginSuccess) {
            console.log('  ✓ Login successful!');
            
            // Step 10: Check sidebar
            console.log('Step 10: Checking sidebar...');
            await page.waitForTimeout(2000);
            
            // Look for sidebar with multiple strategies
            const sidebarElement = await page.locator('.sidebar, #sidebar, nav.sidebar, .nav-sidebar, aside.sidebar, .left-sidebar, .sidebar-panel').first();
            
            if (await sidebarElement.count() > 0) {
                sidebarFound = true;
                
                sidebarInfo = await sidebarElement.evaluate(el => {
                    const styles = window.getComputedStyle(el);
                    const rect = el.getBoundingClientRect();
                    return {
                        className: el.className,
                        id: el.id,
                        width: rect.width,
                        height: rect.height,
                        left: rect.left,
                        position: styles.position,
                        display: styles.display,
                        visibility: styles.visibility
                    };
                });
                
                console.log('  ✓ Sidebar found!');
                console.log('  Sidebar properties:', JSON.stringify(sidebarInfo, null, 2));
            } else {
                console.log('  ✗ Sidebar not found');
                
                // Check main layout structure
                const layoutInfo = await page.evaluate(() => {
                    const info = {
                        bodyClasses: document.body.className,
                        mainElements: []
                    };
                    
                    document.querySelectorAll('nav, aside, .sidebar, [class*="sidebar"], [class*="nav"]').forEach(el => {
                        info.mainElements.push({
                            tag: el.tagName,
                            classes: el.className,
                            id: el.id,
                            visible: el.offsetParent !== null
                        });
                    });
                    
                    return info;
                });
                
                console.log('  Page layout info:', JSON.stringify(layoutInfo, null, 2));
            }
        } else {
            console.log('  ✗ Login failed');
            
            // Check for errors
            const errors = await page.locator('.text-danger, .alert-danger, .validation-summary-errors, .field-validation-error').allTextContents();
            if (errors.length > 0) {
                console.log('  Error messages:', errors.filter(e => e.trim()));
            }
        }
        
        // Step 11: Final screenshot
        console.log('Step 11: Taking final screenshot...');
        await page.screenshot({ 
            path: 'test-5-final-state.png',
            fullPage: true 
        });
        
        // Generate summary
        console.log('\n' + '='.repeat(70));
        console.log('TEST RESULTS SUMMARY');
        console.log('='.repeat(70));
        console.log(`Admin Fix Process: Completed`);
        console.log(`Login Status: ${loginSuccess ? '✓ SUCCESSFUL' : '✗ FAILED'}`);
        console.log(`Sidebar Status: ${sidebarFound ? '✓ FOUND' : '✗ NOT FOUND'}`);
        
        if (sidebarFound && sidebarInfo) {
            console.log(`Sidebar Width: ${sidebarInfo.width}px ${sidebarInfo.width === 250 ? '✓' : '(Expected: 250px)'}`);
            console.log(`Sidebar Position: Left=${sidebarInfo.left}px`);
            
            if (sidebarInfo.width === 250 && sidebarInfo.left === 0) {
                console.log('✓ Sidebar is correctly configured as 250px left panel');
            } else {
                console.log('⚠ Sidebar dimensions need adjustment');
            }
        }
        
        if (!loginSuccess) {
            console.log('\nTROUBLESHOOTING:');
            console.log('- Check if admin user exists in database');
            console.log('- Verify password hash is correct');
            console.log('- Check application logs for authentication errors');
            console.log('- Ensure database connection is working');
        }
        
        console.log('='.repeat(70));
        console.log('\nScreenshots saved:');
        console.log('  - test-1-fixadmin-page.png');
        console.log('  - test-2-fixadmin-result.png');
        console.log('  - test-3-login-page.png');
        console.log('  - test-4-after-login.png');
        console.log('  - test-5-final-state.png');
        
    } catch (error) {
        console.error('\nTest failed with error:', error);
        await page.screenshot({ path: 'test-error-critical.png', fullPage: true });
    } finally {
        await browser.close();
        console.log('\nTest completed.');
    }
}

// Run the test
testAdminFixAndLogin().catch(console.error);