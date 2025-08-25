const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

async function testAdminFixAndLogin() {
    console.log('Starting Admin Fix and Login Test...\n');
    
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
    
    page.on('pageerror', err => {
        console.log('Page Error:', err.message);
    });

    try {
        // Step 1: Navigate to FixAdmin page
        console.log('Step 1: Navigating to FixAdmin page...');
        await page.goto('http://localhost:8080/FixAdmin', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        await page.waitForTimeout(2000);
        
        // Step 2: Take screenshot of fix admin page
        console.log('Step 2: Taking screenshot of FixAdmin page...');
        await page.screenshot({ 
            path: 'test-1-fixadmin-page.png',
            fullPage: true 
        });
        
        // Step 3: Click Fix Admin User button
        console.log('Step 3: Looking for Fix Admin User button...');
        
        // Try multiple selectors for the button
        const buttonSelectors = [
            'button:has-text("Fix Admin User")',
            'button.btn-primary:has-text("Fix")',
            'button.btn:has-text("Fix")',
            'input[type="submit"][value*="Fix"]',
            'button[type="submit"]:has-text("Fix")',
            '.btn-primary'
        ];
        
        let buttonClicked = false;
        for (const selector of buttonSelectors) {
            try {
                const button = await page.locator(selector).first();
                if (await button.isVisible()) {
                    console.log(`  Found button with selector: ${selector}`);
                    await button.click();
                    buttonClicked = true;
                    break;
                }
            } catch (e) {
                // Continue trying other selectors
            }
        }
        
        if (!buttonClicked) {
            console.log('  Warning: Could not find Fix Admin User button, checking page content...');
            const pageContent = await page.content();
            if (pageContent.includes('success') || pageContent.includes('fixed')) {
                console.log('  Admin may already be fixed based on page content');
            }
        }
        
        // Step 4: Wait for response and take screenshot
        console.log('Step 4: Waiting for response...');
        await page.waitForTimeout(3000);
        
        // Check for success message or redirect
        const currentUrl = page.url();
        console.log(`  Current URL: ${currentUrl}`);
        
        await page.screenshot({ 
            path: 'test-2-fixadmin-result.png',
            fullPage: true 
        });
        
        // Step 5: Navigate to login page
        console.log('Step 5: Navigating to login page...');
        
        // Check if we were redirected to login, otherwise navigate manually
        if (!currentUrl.includes('/Account/Login')) {
            await page.goto('http://localhost:8080/Account/Login', { 
                waitUntil: 'networkidle',
                timeout: 30000 
            });
            await page.waitForTimeout(2000);
        }
        
        await page.screenshot({ 
            path: 'test-3-login-page.png',
            fullPage: true 
        });
        
        // Step 6: Enter credentials
        console.log('Step 6: Entering login credentials...');
        
        // Try different selectors for email field
        const emailSelectors = [
            'input[name="Email"]',
            'input[type="email"]',
            '#Email',
            'input[placeholder*="email" i]',
            'input[name="Username"]',
            '#Username'
        ];
        
        let emailEntered = false;
        for (const selector of emailSelectors) {
            try {
                const emailField = await page.locator(selector).first();
                if (await emailField.isVisible()) {
                    await emailField.fill('admin@steelestimation.com');
                    console.log(`  Email entered using selector: ${selector}`);
                    emailEntered = true;
                    break;
                }
            } catch (e) {
                // Continue trying
            }
        }
        
        if (!emailEntered) {
            console.log('  ERROR: Could not find email field!');
        }
        
        // Try different selectors for password field
        const passwordSelectors = [
            'input[name="Password"]',
            'input[type="password"]',
            '#Password'
        ];
        
        let passwordEntered = false;
        for (const selector of passwordSelectors) {
            try {
                const passwordField = await page.locator(selector).first();
                if (await passwordField.isVisible()) {
                    await passwordField.fill('Admin@123');
                    console.log(`  Password entered using selector: ${selector}`);
                    passwordEntered = true;
                    break;
                }
            } catch (e) {
                // Continue trying
            }
        }
        
        if (!passwordEntered) {
            console.log('  ERROR: Could not find password field!');
        }
        
        // Step 7: Click login button
        console.log('Step 7: Clicking login button...');
        
        const loginButtonSelectors = [
            'button[type="submit"]',
            'button:has-text("Log in")',
            'button:has-text("Login")',
            'button:has-text("Sign in")',
            'input[type="submit"]',
            '.btn-primary[type="submit"]'
        ];
        
        let loginClicked = false;
        for (const selector of loginButtonSelectors) {
            try {
                const loginButton = await page.locator(selector).first();
                if (await loginButton.isVisible()) {
                    console.log(`  Clicking login button with selector: ${selector}`);
                    await loginButton.click();
                    loginClicked = true;
                    break;
                }
            } catch (e) {
                // Continue trying
            }
        }
        
        if (!loginClicked) {
            console.log('  ERROR: Could not find login button!');
        }
        
        // Step 8: Wait for navigation and take screenshot
        console.log('Step 8: Waiting for login result...');
        await page.waitForTimeout(5000);
        
        const afterLoginUrl = page.url();
        console.log(`  URL after login: ${afterLoginUrl}`);
        
        await page.screenshot({ 
            path: 'test-4-after-login.png',
            fullPage: true 
        });
        
        // Step 9: Check if login was successful
        console.log('Step 9: Checking login success...');
        
        const loginSuccess = !afterLoginUrl.includes('/Account/Login') && 
                           !afterLoginUrl.includes('/login');
        
        if (loginSuccess) {
            console.log('  ✓ Login successful! Redirected to:', afterLoginUrl);
        } else {
            console.log('  ✗ Login failed - still on login page');
            
            // Check for error messages
            const errorMessages = await page.locator('.text-danger, .alert-danger, .validation-summary-errors').allTextContents();
            if (errorMessages.length > 0) {
                console.log('  Error messages found:', errorMessages);
            }
        }
        
        // Step 10: Check sidebar rendering
        console.log('Step 10: Checking sidebar rendering...');
        
        if (loginSuccess) {
            // Wait for sidebar to load
            await page.waitForTimeout(2000);
            
            // Check for sidebar element
            const sidebarSelectors = [
                '.sidebar',
                '#sidebar',
                'nav.sidebar',
                '.left-panel',
                '.nav-sidebar',
                '[class*="sidebar"]'
            ];
            
            let sidebarFound = false;
            let sidebarInfo = {};
            
            for (const selector of sidebarSelectors) {
                try {
                    const sidebar = await page.locator(selector).first();
                    if (await sidebar.isVisible()) {
                        sidebarFound = true;
                        
                        // Get sidebar dimensions and styles
                        sidebarInfo = await sidebar.evaluate(el => {
                            const styles = window.getComputedStyle(el);
                            const rect = el.getBoundingClientRect();
                            return {
                                selector: el.className || el.id || 'sidebar',
                                width: rect.width,
                                height: rect.height,
                                position: styles.position,
                                left: rect.left,
                                top: rect.top,
                                display: styles.display,
                                backgroundColor: styles.backgroundColor,
                                zIndex: styles.zIndex
                            };
                        });
                        
                        console.log(`  ✓ Sidebar found with selector: ${selector}`);
                        console.log('  Sidebar properties:', JSON.stringify(sidebarInfo, null, 2));
                        break;
                    }
                } catch (e) {
                    // Continue trying
                }
            }
            
            if (!sidebarFound) {
                console.log('  ✗ Sidebar not found or not visible');
                
                // Check page structure
                const pageStructure = await page.evaluate(() => {
                    const elements = [];
                    document.querySelectorAll('[class*="sidebar"], [class*="nav"], [class*="menu"]').forEach(el => {
                        elements.push({
                            tag: el.tagName,
                            classes: el.className,
                            visible: el.offsetParent !== null,
                            width: el.offsetWidth
                        });
                    });
                    return elements;
                });
                
                if (pageStructure.length > 0) {
                    console.log('  Found navigation-related elements:', JSON.stringify(pageStructure, null, 2));
                }
            } else {
                // Check if sidebar is properly positioned as left panel
                if (sidebarInfo.width === 250 && sidebarInfo.left === 0) {
                    console.log('  ✓ Sidebar is correctly positioned as 250px left panel');
                } else if (sidebarInfo.width > 0) {
                    console.log(`  ⚠ Sidebar width is ${sidebarInfo.width}px (expected 250px), left position: ${sidebarInfo.left}px`);
                }
            }
        }
        
        // Step 11: Take final screenshot
        console.log('Step 11: Taking final screenshot...');
        await page.screenshot({ 
            path: 'test-5-final-state.png',
            fullPage: true 
        });
        
        // Generate HTML report
        console.log('\nGenerating test report...');
        
        const reportHtml = `
<!DOCTYPE html>
<html>
<head>
    <title>Admin Fix and Login Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1400px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
        h1 { color: #333; border-bottom: 2px solid #007bff; padding-bottom: 10px; }
        h2 { color: #555; margin-top: 30px; }
        .status { padding: 10px; margin: 10px 0; border-radius: 4px; }
        .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .warning { background: #fff3cd; color: #856404; border: 1px solid #ffeeba; }
        .info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
        .screenshot { margin: 20px 0; border: 1px solid #ddd; border-radius: 4px; overflow: hidden; }
        .screenshot img { width: 100%; display: block; }
        .screenshot h3 { margin: 0; padding: 10px; background: #f8f9fa; border-bottom: 1px solid #ddd; }
        .details { background: #f8f9fa; padding: 15px; border-radius: 4px; margin: 10px 0; }
        pre { background: #282c34; color: #abb2bf; padding: 10px; border-radius: 4px; overflow-x: auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Admin Fix and Login Test Report</h1>
        <p>Test executed at: ${new Date().toISOString()}</p>
        
        <h2>Test Results Summary</h2>
        <div class="status ${loginSuccess ? 'success' : 'error'}">
            Login Status: ${loginSuccess ? '✓ Successful' : '✗ Failed'}
        </div>
        <div class="status ${sidebarFound ? 'success' : 'warning'}">
            Sidebar Status: ${sidebarFound ? '✓ Found' : '⚠ Not Found'}
        </div>
        ${sidebarFound && sidebarInfo.width ? `
        <div class="status ${sidebarInfo.width === 250 ? 'success' : 'warning'}">
            Sidebar Width: ${sidebarInfo.width}px ${sidebarInfo.width === 250 ? '✓' : '(Expected: 250px)'}
        </div>
        ` : ''}
        
        <h2>Test Steps</h2>
        <div class="details">
            <ol>
                <li>Navigate to FixAdmin page ✓</li>
                <li>Take screenshot of fix admin page ✓</li>
                <li>Click Fix Admin User button ${buttonClicked ? '✓' : '⚠'}</li>
                <li>Wait for success message ✓</li>
                <li>Navigate to login page ✓</li>
                <li>Enter credentials ${emailEntered && passwordEntered ? '✓' : '✗'}</li>
                <li>Click login button ${loginClicked ? '✓' : '✗'}</li>
                <li>Check login success ${loginSuccess ? '✓' : '✗'}</li>
                <li>Check sidebar rendering ${sidebarFound ? '✓' : '✗'}</li>
                <li>Take final screenshot ✓</li>
            </ol>
        </div>
        
        ${sidebarFound && sidebarInfo ? `
        <h2>Sidebar Properties</h2>
        <div class="details">
            <pre>${JSON.stringify(sidebarInfo, null, 2)}</pre>
        </div>
        ` : ''}
        
        <h2>Screenshots</h2>
        
        <div class="screenshot">
            <h3>1. Fix Admin Page</h3>
            <img src="test-1-fixadmin-page.png" alt="Fix Admin Page">
        </div>
        
        <div class="screenshot">
            <h3>2. After Fix Admin Click</h3>
            <img src="test-2-fixadmin-result.png" alt="Fix Admin Result">
        </div>
        
        <div class="screenshot">
            <h3>3. Login Page</h3>
            <img src="test-3-login-page.png" alt="Login Page">
        </div>
        
        <div class="screenshot">
            <h3>4. After Login Attempt</h3>
            <img src="test-4-after-login.png" alt="After Login">
        </div>
        
        <div class="screenshot">
            <h3>5. Final State</h3>
            <img src="test-5-final-state.png" alt="Final State">
        </div>
    </div>
</body>
</html>
        `;
        
        fs.writeFileSync('test-report-admin-fix.html', reportHtml);
        console.log('Report saved as: test-report-admin-fix.html');
        
        // Final summary
        console.log('\n' + '='.repeat(60));
        console.log('TEST SUMMARY');
        console.log('='.repeat(60));
        console.log(`Fix Admin Process: ${buttonClicked ? 'Button clicked' : 'Button not found (may already be fixed)'}`);
        console.log(`Login Status: ${loginSuccess ? '✓ SUCCESSFUL' : '✗ FAILED'}`);
        console.log(`Sidebar Display: ${sidebarFound ? '✓ FOUND' : '✗ NOT FOUND'}`);
        if (sidebarFound && sidebarInfo.width) {
            console.log(`Sidebar Width: ${sidebarInfo.width}px ${sidebarInfo.width === 250 ? '(correct)' : '(incorrect - should be 250px)'}`);
            console.log(`Sidebar Position: Left: ${sidebarInfo.left}px, Top: ${sidebarInfo.top}px`);
        }
        console.log('='.repeat(60));
        
    } catch (error) {
        console.error('Test failed with error:', error);
        await page.screenshot({ path: 'test-error-state.png', fullPage: true });
    } finally {
        await browser.close();
    }
}

// Run the test
testAdminFixAndLogin().catch(console.error);