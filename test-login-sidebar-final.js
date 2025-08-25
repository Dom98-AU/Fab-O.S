const { chromium } = require('playwright');
const fs = require('fs');

async function testLoginAndSidebar() {
    console.log('Starting login and sidebar test...');
    const browser = await chromium.launch({ 
        headless: false,
        args: ['--disable-dev-shm-usage']
    });
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 },
        ignoreHTTPSErrors: true
    });
    
    const page = await context.newPage();
    
    try {
        // Step 1: Navigate to login page
        console.log('\n1. Navigating to login page...');
        await page.goto('http://localhost:8080/Account/Login', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        
        // Take screenshot of login page
        await page.screenshot({ 
            path: 'test-1-login-page.png',
            fullPage: true 
        });
        console.log('✓ Login page loaded and screenshot saved');
        
        // Step 2: Enter credentials
        console.log('\n2. Entering credentials...');
        await page.waitForSelector('input[type="email"], input[name="email"], #email', { timeout: 10000 });
        
        // Fill in email
        const emailInput = await page.$('input[type="email"], input[name="email"], #email');
        if (emailInput) {
            await emailInput.fill('admin@steelestimation.com');
            console.log('✓ Email entered');
        }
        
        // Fill in password
        const passwordInput = await page.$('input[type="password"], input[name="password"], #password');
        if (passwordInput) {
            await passwordInput.fill('Admin@123');
            console.log('✓ Password entered');
        }
        
        // Step 3: Click Sign In button
        console.log('\n3. Clicking Sign In button...');
        const signInButton = await page.$('button[type="submit"], input[type="submit"], button:has-text("Sign In")');
        if (signInButton) {
            await signInButton.click();
            console.log('✓ Sign In button clicked');
        }
        
        // Step 4: Wait for navigation after login
        console.log('\n4. Waiting for page to load after login...');
        await page.waitForNavigation({ 
            waitUntil: 'networkidle',
            timeout: 30000 
        }).catch(() => {
            console.log('Navigation timeout - checking current state...');
        });
        
        // Additional wait for any dynamic content
        await page.waitForTimeout(3000);
        
        // Step 5: Take screenshot after login
        console.log('\n5. Taking screenshot after login...');
        const currentUrl = page.url();
        console.log(`Current URL: ${currentUrl}`);
        
        await page.screenshot({ 
            path: 'test-2-after-login.png',
            fullPage: true 
        });
        console.log('✓ Post-login screenshot saved');
        
        // Step 6: Check if on dashboard
        console.log('\n6. Checking if on dashboard...');
        const isDashboard = currentUrl.includes('/') && !currentUrl.includes('/Account/Login');
        console.log(`On dashboard: ${isDashboard ? 'YES' : 'NO'}`);
        
        // Step 7: Check sidebar visibility
        console.log('\n7. Checking sidebar visibility...');
        
        // Look for sidebar element
        const sidebar = await page.$('.sidebar, #sidebar, nav.sidebar, aside.sidebar, [class*="sidebar"]');
        const sidebarVisible = sidebar !== null;
        
        if (sidebarVisible) {
            console.log('✓ Sidebar element found');
            
            // Get sidebar dimensions and position
            const sidebarBox = await sidebar.boundingBox();
            if (sidebarBox) {
                console.log(`Sidebar dimensions: ${sidebarBox.width}px x ${sidebarBox.height}px`);
                console.log(`Sidebar position: x=${sidebarBox.x}, y=${sidebarBox.y}`);
                console.log(`Sidebar width is 250px: ${sidebarBox.width === 250 ? 'YES' : 'NO (actual: ' + sidebarBox.width + 'px)'}`);
            }
            
            // Check sidebar CSS
            const sidebarStyles = await sidebar.evaluate(el => {
                const styles = window.getComputedStyle(el);
                return {
                    width: styles.width,
                    position: styles.position,
                    left: styles.left,
                    display: styles.display,
                    visibility: styles.visibility,
                    backgroundColor: styles.backgroundColor
                };
            });
            console.log('Sidebar styles:', sidebarStyles);
        } else {
            console.log('✗ Sidebar not found');
        }
        
        // Step 8: Check navigation items
        console.log('\n8. Checking navigation items...');
        const navItems = await page.$$eval('.sidebar a, .sidebar button, nav a, aside a', elements => 
            elements.map(el => el.textContent.trim()).filter(text => text.length > 0)
        );
        
        if (navItems.length > 0) {
            console.log(`✓ Found ${navItems.length} navigation items:`);
            navItems.forEach(item => console.log(`  - ${item}`));
        } else {
            console.log('✗ No navigation items found');
        }
        
        // Step 9: Check main content area
        console.log('\n9. Checking main content area...');
        const mainContent = await page.$('main, .main-content, #main-content, [class*="main-content"]');
        if (mainContent) {
            const mainBox = await mainContent.boundingBox();
            if (mainBox) {
                console.log(`✓ Main content found at x=${mainBox.x}, width=${mainBox.width}px`);
                const hasLeftMargin = mainBox.x >= 250;
                console.log(`Main content has left margin for sidebar: ${hasLeftMargin ? 'YES' : 'NO'}`);
            }
        }
        
        // Step 10: Take final screenshot
        console.log('\n10. Taking final screenshot...');
        await page.screenshot({ 
            path: 'test-3-final-layout.png',
            fullPage: true 
        });
        console.log('✓ Final screenshot saved');
        
        // Generate HTML report
        console.log('\n=== TEST REPORT ===');
        console.log(`Login successful: ${isDashboard ? 'YES' : 'NO'}`);
        console.log(`Current page: ${currentUrl}`);
        console.log(`Sidebar visible: ${sidebarVisible ? 'YES' : 'NO'}`);
        console.log(`Navigation items found: ${navItems.length}`);
        
        // Check for authentication cookie
        const cookies = await context.cookies();
        const authCookie = cookies.find(c => c.name.includes('Auth') || c.name.includes('Identity'));
        console.log(`Authentication cookie present: ${authCookie ? 'YES' : 'NO'}`);
        
        // Create detailed HTML report
        const htmlReport = `
<!DOCTYPE html>
<html>
<head>
    <title>Login & Sidebar Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
        h1 { color: #333; border-bottom: 2px solid #007bff; padding-bottom: 10px; }
        h2 { color: #555; margin-top: 30px; }
        .status { padding: 10px; margin: 10px 0; border-radius: 4px; }
        .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .failure { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
        img { max-width: 100%; border: 2px solid #ddd; margin: 10px 0; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        th, td { padding: 8px; text-align: left; border: 1px solid #ddd; }
        th { background: #f8f9fa; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Login & Sidebar Test Report</h1>
        <p>Test executed at: ${new Date().toISOString()}</p>
        
        <h2>Test Results Summary</h2>
        <div class="status ${isDashboard ? 'success' : 'failure'}">
            Login Status: ${isDashboard ? '✓ SUCCESSFUL' : '✗ FAILED'}
        </div>
        <div class="status ${sidebarVisible ? 'success' : 'failure'}">
            Sidebar Visibility: ${sidebarVisible ? '✓ VISIBLE' : '✗ NOT VISIBLE'}
        </div>
        <div class="status ${navItems.length > 0 ? 'success' : 'failure'}">
            Navigation Items: ${navItems.length > 0 ? '✓ FOUND (' + navItems.length + ' items)' : '✗ NOT FOUND'}
        </div>
        
        <h2>Details</h2>
        <table>
            <tr><th>Property</th><th>Value</th></tr>
            <tr><td>Current URL</td><td>${currentUrl}</td></tr>
            <tr><td>Authentication Cookie</td><td>${authCookie ? 'Present' : 'Not Found'}</td></tr>
            <tr><td>Sidebar Width</td><td>${sidebarVisible && sidebarBox ? sidebarBox.width + 'px' : 'N/A'}</td></tr>
            <tr><td>Navigation Items</td><td>${navItems.join(', ') || 'None'}</td></tr>
        </table>
        
        <h2>Screenshots</h2>
        <div class="grid">
            <div>
                <h3>1. Login Page</h3>
                <img src="test-1-login-page.png" alt="Login Page">
            </div>
            <div>
                <h3>2. After Login</h3>
                <img src="test-2-after-login.png" alt="After Login">
            </div>
        </div>
        <div>
            <h3>3. Final Layout</h3>
            <img src="test-3-final-layout.png" alt="Final Layout">
        </div>
    </div>
</body>
</html>`;
        
        fs.writeFileSync('test-report.html', htmlReport);
        console.log('\n✓ HTML report saved as test-report.html');
        
    } catch (error) {
        console.error('Test failed with error:', error);
        await page.screenshot({ 
            path: 'test-error.png',
            fullPage: true 
        });
    } finally {
        await browser.close();
        console.log('\nTest completed. Check the screenshots and test-report.html for details.');
    }
}

// Run the test
testLoginAndSidebar().catch(console.error);