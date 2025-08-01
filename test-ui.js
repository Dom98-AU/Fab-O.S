const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// Create screenshots directory if it doesn't exist
const screenshotsDir = path.join(__dirname, 'playwright-screenshots');
if (!fs.existsSync(screenshotsDir)) {
    fs.mkdirSync(screenshotsDir);
}

async function testSteelEstimationUI() {
    console.log('Starting Steel Estimation Platform UI tests...\n');
    
    const browser = await chromium.launch({ 
        headless: false, // Set to true for CI/CD
        slowMo: 500 // Slow down for visibility
    });
    
    const context = await browser.newContext({
        ignoreHTTPSErrors: true, // For self-signed certificates
        viewport: { width: 1920, height: 1080 }
    });
    
    const page = await context.newPage();
    
    try {
        // 1. Navigate to the application
        console.log('1. Navigating to https://localhost:5003...');
        await page.goto('https://localhost:5003', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        
        // 2. Take screenshot of login page
        console.log('2. Taking screenshot of login page...');
        await page.screenshot({ 
            path: path.join(screenshotsDir, '01-login-page.png'),
            fullPage: true 
        });
        
        // 3. Verify login page loaded
        console.log('3. Verifying login page elements...');
        const loginForm = await page.waitForSelector('form', { timeout: 5000 });
        if (loginForm) {
            console.log('   ✓ Login form found');
        }
        
        // Check for any console errors
        page.on('console', msg => {
            if (msg.type() === 'error') {
                console.log('   ✗ Console error:', msg.text());
            }
        });
        
        // 4. Fill in login form
        console.log('4. Filling in login credentials...');
        
        // Try different possible selectors for email field
        const emailSelectors = [
            'input[type="email"]',
            'input[name="email"]',
            'input[id="email"]',
            'input[placeholder*="email" i]',
            'input[placeholder*="username" i]'
        ];
        
        let emailFilled = false;
        for (const selector of emailSelectors) {
            try {
                await page.fill(selector, 'admin@steelestimation.com');
                console.log(`   ✓ Email filled using selector: ${selector}`);
                emailFilled = true;
                break;
            } catch (e) {
                // Continue to next selector
            }
        }
        
        if (!emailFilled) {
            console.log('   ✗ Could not find email input field');
        }
        
        // Try different possible selectors for password field
        const passwordSelectors = [
            'input[type="password"]',
            'input[name="password"]',
            'input[id="password"]',
            'input[placeholder*="password" i]'
        ];
        
        let passwordFilled = false;
        for (const selector of passwordSelectors) {
            try {
                await page.fill(selector, 'Admin@123');
                console.log(`   ✓ Password filled using selector: ${selector}`);
                passwordFilled = true;
                break;
            } catch (e) {
                // Continue to next selector
            }
        }
        
        if (!passwordFilled) {
            console.log('   ✗ Could not find password input field');
        }
        
        // Take screenshot after filling form
        await page.screenshot({ 
            path: path.join(screenshotsDir, '02-login-filled.png'),
            fullPage: true 
        });
        
        // 5. Click login button
        console.log('5. Clicking login button...');
        
        const loginButtonSelectors = [
            'button[type="submit"]',
            'input[type="submit"]',
            'button:has-text("Login")',
            'button:has-text("Sign in")',
            'button:has-text("Log in")',
            '*[type="submit"]'
        ];
        
        let loginClicked = false;
        for (const selector of loginButtonSelectors) {
            try {
                await page.click(selector);
                console.log(`   ✓ Login button clicked using selector: ${selector}`);
                loginClicked = true;
                break;
            } catch (e) {
                // Continue to next selector
            }
        }
        
        if (!loginClicked) {
            console.log('   ✗ Could not find login button');
        }
        
        // 6. Wait for navigation/response
        console.log('6. Waiting for login response...');
        
        try {
            // Wait for either navigation or error message
            await Promise.race([
                page.waitForNavigation({ timeout: 10000 }),
                page.waitForSelector('.alert-danger', { timeout: 10000 }),
                page.waitForSelector('.validation-message', { timeout: 10000 })
            ]);
        } catch (e) {
            console.log('   ! Timeout waiting for response');
        }
        
        await page.waitForTimeout(2000); // Additional wait for any redirects
        
        // 7. Take screenshot after login attempt
        console.log('7. Taking screenshot after login attempt...');
        await page.screenshot({ 
            path: path.join(screenshotsDir, '03-after-login.png'),
            fullPage: true 
        });
        
        // Check if login was successful
        const currentUrl = page.url();
        console.log(`   Current URL: ${currentUrl}`);
        
        // Check for error messages
        const errorMessages = await page.$$('.alert-danger, .validation-message, .error-message');
        if (errorMessages.length > 0) {
            console.log('   ✗ Login failed - error messages found');
            for (const msg of errorMessages) {
                const text = await msg.textContent();
                console.log(`     Error: ${text}`);
            }
        } else if (currentUrl.includes('login') || currentUrl === 'https://localhost:5003/') {
            console.log('   ? Login status unclear - still on login page');
        } else {
            console.log('   ✓ Login appears successful - navigated away from login page');
            
            // 8. If login successful, navigate to main sections
            console.log('\n8. Testing main sections...');
            
            const sections = [
                { name: 'Dashboard', url: '/dashboard', selectors: ['a[href*="dashboard"]', 'a:has-text("Dashboard")'] },
                { name: 'Projects', url: '/projects', selectors: ['a[href*="projects"]', 'a:has-text("Projects")'] },
                { name: 'Customers', url: '/customers', selectors: ['a[href*="customers"]', 'a:has-text("Customers")'] }
            ];
            
            for (const section of sections) {
                console.log(`\n   Testing ${section.name}...`);
                
                let navigationSuccess = false;
                
                // Try clicking navigation link
                for (const selector of section.selectors) {
                    try {
                        await page.click(selector);
                        await page.waitForTimeout(2000);
                        navigationSuccess = true;
                        break;
                    } catch (e) {
                        // Try direct navigation if clicking fails
                        try {
                            await page.goto(`https://localhost:5003${section.url}`, { waitUntil: 'networkidle' });
                            navigationSuccess = true;
                            break;
                        } catch (navError) {
                            // Continue
                        }
                    }
                }
                
                if (navigationSuccess) {
                    console.log(`   ✓ Navigated to ${section.name}`);
                    await page.screenshot({ 
                        path: path.join(screenshotsDir, `04-${section.name.toLowerCase()}.png`),
                        fullPage: true 
                    });
                } else {
                    console.log(`   ✗ Could not navigate to ${section.name}`);
                }
            }
        }
        
        // 9. Final summary
        console.log('\n9. Test Summary:');
        console.log('   Screenshots saved in:', screenshotsDir);
        console.log('   Please review the screenshots for visual verification');
        
    } catch (error) {
        console.error('\n✗ Test failed with error:', error.message);
        
        // Take error screenshot
        try {
            await page.screenshot({ 
                path: path.join(screenshotsDir, 'error-state.png'),
                fullPage: true 
            });
        } catch (e) {
            // Ignore screenshot error
        }
    } finally {
        await browser.close();
        console.log('\nTests completed.');
    }
}

// Run the tests
testSteelEstimationUI().catch(console.error);