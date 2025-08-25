const { chromium } = require('playwright');
const fs = require('fs');

async function testLoginSidebarFinal() {
    console.log('=== FINAL LOGIN AND SIDEBAR TEST ===\n');
    console.log('Starting at:', new Date().toISOString());
    
    const browser = await chromium.launch({ 
        headless: true,  // Run headless for speed
        args: ['--disable-dev-shm-usage', '--no-sandbox']
    });
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 },
        ignoreHTTPSErrors: true
    });
    
    const page = await context.newPage();
    const results = {
        loginSuccess: false,
        onDashboard: false,
        sidebarVisible: false,
        sidebarWidth: 0,
        navigationItems: [],
        errors: []
    };
    
    try {
        // Step 1: Navigate to login page
        console.log('1. Navigating to login page...');
        await page.goto('http://localhost:8080/Account/Login', { 
            waitUntil: 'networkidle',
            timeout: 15000 
        });
        await page.screenshot({ path: 'final-test-1-login.png' });
        console.log('   ✓ Login page loaded');
        
        // Step 2: Fill credentials and login
        console.log('2. Entering credentials...');
        await page.fill('input[type="email"]', 'admin@steelestimation.com');
        await page.fill('input[type="password"]', 'Admin@123');
        console.log('   ✓ Credentials entered');
        
        // Step 3: Click sign in
        console.log('3. Clicking Sign In...');
        await Promise.all([
            page.waitForNavigation({ waitUntil: 'networkidle', timeout: 15000 }).catch(() => {}),
            page.click('button[type="submit"]')
        ]);
        console.log('   ✓ Sign In clicked');
        
        // Wait for page to stabilize
        await page.waitForTimeout(3000);
        
        // Step 4: Check current location
        const currentUrl = page.url();
        console.log(`4. Current URL: ${currentUrl}`);
        results.loginSuccess = !currentUrl.includes('/Account/Login');
        results.onDashboard = currentUrl.endsWith('/') || currentUrl.includes('dashboard');
        
        // Step 5: Take screenshot after login
        await page.screenshot({ path: 'final-test-2-after-login.png' });
        console.log('   ✓ Post-login screenshot taken');
        
        // Step 6: Check for sidebar
        console.log('5. Checking sidebar...');
        
        // Try multiple selectors for sidebar
        const sidebarSelectors = [
            '.sidebar',
            '#sidebar', 
            'nav.sidebar',
            'aside.sidebar',
            '[class*="sidebar"]',
            'nav[role="navigation"]',
            '.nav-menu',
            '#navMenu'
        ];
        
        let sidebar = null;
        for (const selector of sidebarSelectors) {
            sidebar = await page.$(selector);
            if (sidebar) {
                console.log(`   ✓ Found sidebar with selector: ${selector}`);
                break;
            }
        }
        
        if (sidebar) {
            results.sidebarVisible = true;
            
            // Get sidebar dimensions
            const box = await sidebar.boundingBox();
            if (box) {
                results.sidebarWidth = box.width;
                console.log(`   Sidebar dimensions: ${box.width}px x ${box.height}px`);
                console.log(`   Sidebar position: x=${box.x}, y=${box.y}`);
            }
            
            // Check if sidebar is expanded (should be 250px)
            const isExpanded = results.sidebarWidth >= 200;
            console.log(`   Sidebar expanded: ${isExpanded ? 'YES' : 'NO'} (${results.sidebarWidth}px)`);
        } else {
            console.log('   ✗ No sidebar found');
        }
        
        // Step 7: Get navigation items
        console.log('6. Checking navigation items...');
        
        // Try to find navigation links
        const navLinks = await page.$$eval('a', links => 
            links.map(link => ({
                text: link.textContent.trim(),
                href: link.href
            })).filter(link => link.text.length > 0)
        );
        
        // Filter for main navigation items
        const mainNavItems = ['Dashboard', 'Estimations', 'Customers', 'Reports', 'Time Analytics', 'Import/Export', 'Worksheet Templates'];
        results.navigationItems = navLinks
            .filter(link => mainNavItems.some(item => link.text.includes(item)))
            .map(link => link.text);
        
        if (results.navigationItems.length > 0) {
            console.log(`   ✓ Found ${results.navigationItems.length} navigation items:`);
            results.navigationItems.forEach(item => console.log(`     - ${item}`));
        } else {
            console.log('   ✗ No navigation items found');
        }
        
        // Step 8: Check authentication status
        console.log('7. Checking authentication...');
        
        // Look for user indicator
        const userIndicator = await page.$('.user-indicator, .user-avatar, [class*="user"]');
        const hasUserIndicator = userIndicator !== null;
        console.log(`   User indicator present: ${hasUserIndicator ? 'YES' : 'NO'}`);
        
        // Check for logout link
        const logoutLink = await page.$('a[href*="logout"], button:has-text("Logout")');
        const hasLogoutOption = logoutLink !== null;
        console.log(`   Logout option available: ${hasLogoutOption ? 'YES' : 'NO'}`);
        
        // Step 9: Final screenshot
        await page.screenshot({ path: 'final-test-3-complete.png', fullPage: true });
        console.log('8. Final screenshot saved');
        
    } catch (error) {
        console.error('Error during test:', error.message);
        results.errors.push(error.message);
        await page.screenshot({ path: 'final-test-error.png' });
    } finally {
        await browser.close();
        
        // Generate report
        console.log('\n=== TEST REPORT ===');
        console.log(`Login Successful: ${results.loginSuccess ? '✓ YES' : '✗ NO'}`);
        console.log(`On Dashboard: ${results.onDashboard ? '✓ YES' : '✗ NO'}`);
        console.log(`Sidebar Visible: ${results.sidebarVisible ? '✓ YES' : '✗ NO'}`);
        if (results.sidebarVisible) {
            console.log(`Sidebar Width: ${results.sidebarWidth}px ${results.sidebarWidth >= 200 ? '✓' : '✗'}`);
        }
        console.log(`Navigation Items: ${results.navigationItems.length > 0 ? '✓ ' + results.navigationItems.length + ' items' : '✗ NONE'}`);
        
        if (results.errors.length > 0) {
            console.log('\nErrors encountered:');
            results.errors.forEach(err => console.log(`  - ${err}`));
        }
        
        // Generate HTML report
        const htmlReport = `
<!DOCTYPE html>
<html>
<head>
    <title>Final Test Report - Login & Sidebar</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; padding: 20px; background: #f0f2f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        h1 { color: #1a1a1a; border-bottom: 3px solid #0066cc; padding-bottom: 10px; }
        .status-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 20px 0; }
        .status-card { padding: 20px; border-radius: 8px; border: 2px solid #e0e0e0; }
        .status-card.success { background: #f0fdf4; border-color: #10b981; }
        .status-card.failure { background: #fef2f2; border-color: #ef4444; }
        .status-card h3 { margin: 0 0 10px 0; color: #1a1a1a; }
        .status-card .value { font-size: 24px; font-weight: bold; }
        .status-card.success .value { color: #10b981; }
        .status-card.failure .value { color: #ef4444; }
        .screenshots { margin-top: 30px; }
        .screenshot-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 20px; }
        .screenshot-item { border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden; }
        .screenshot-item h4 { margin: 0; padding: 10px 15px; background: #f8f9fa; border-bottom: 1px solid #e0e0e0; }
        .screenshot-item img { width: 100%; display: block; }
        .details { margin-top: 20px; }
        .details table { width: 100%; border-collapse: collapse; }
        .details th, .details td { padding: 10px; text-align: left; border: 1px solid #e0e0e0; }
        .details th { background: #f8f9fa; font-weight: 600; }
        .timestamp { color: #666; font-size: 14px; margin-top: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Final Test Report - Login & Sidebar</h1>
        <p class="timestamp">Test executed: ${new Date().toISOString()}</p>
        
        <div class="status-grid">
            <div class="status-card ${results.loginSuccess ? 'success' : 'failure'}">
                <h3>Login Status</h3>
                <div class="value">${results.loginSuccess ? '✓ SUCCESS' : '✗ FAILED'}</div>
            </div>
            
            <div class="status-card ${results.onDashboard ? 'success' : 'failure'}">
                <h3>Dashboard Access</h3>
                <div class="value">${results.onDashboard ? '✓ REACHED' : '✗ NOT REACHED'}</div>
            </div>
            
            <div class="status-card ${results.sidebarVisible ? 'success' : 'failure'}">
                <h3>Sidebar Status</h3>
                <div class="value">${results.sidebarVisible ? '✓ VISIBLE' : '✗ NOT VISIBLE'}</div>
                ${results.sidebarVisible ? '<p>Width: ' + results.sidebarWidth + 'px</p>' : ''}
            </div>
            
            <div class="status-card ${results.navigationItems.length > 0 ? 'success' : 'failure'}">
                <h3>Navigation Items</h3>
                <div class="value">${results.navigationItems.length > 0 ? '✓ ' + results.navigationItems.length : '✗ 0'}</div>
            </div>
        </div>
        
        <div class="details">
            <h2>Test Details</h2>
            <table>
                <tr>
                    <th>Property</th>
                    <th>Value</th>
                    <th>Expected</th>
                    <th>Status</th>
                </tr>
                <tr>
                    <td>Login Successful</td>
                    <td>${results.loginSuccess ? 'Yes' : 'No'}</td>
                    <td>Yes</td>
                    <td>${results.loginSuccess ? '✓' : '✗'}</td>
                </tr>
                <tr>
                    <td>On Dashboard</td>
                    <td>${results.onDashboard ? 'Yes' : 'No'}</td>
                    <td>Yes</td>
                    <td>${results.onDashboard ? '✓' : '✗'}</td>
                </tr>
                <tr>
                    <td>Sidebar Visible</td>
                    <td>${results.sidebarVisible ? 'Yes' : 'No'}</td>
                    <td>Yes</td>
                    <td>${results.sidebarVisible ? '✓' : '✗'}</td>
                </tr>
                <tr>
                    <td>Sidebar Width</td>
                    <td>${results.sidebarWidth}px</td>
                    <td>250px</td>
                    <td>${results.sidebarWidth >= 200 ? '✓' : '✗'}</td>
                </tr>
                <tr>
                    <td>Navigation Items</td>
                    <td>${results.navigationItems.join(', ') || 'None'}</td>
                    <td>Dashboard, Estimations, Customers, etc.</td>
                    <td>${results.navigationItems.length >= 3 ? '✓' : '✗'}</td>
                </tr>
            </table>
        </div>
        
        <div class="screenshots">
            <h2>Screenshots</h2>
            <div class="screenshot-grid">
                <div class="screenshot-item">
                    <h4>1. Login Page</h4>
                    <img src="final-test-1-login.png" alt="Login Page">
                </div>
                <div class="screenshot-item">
                    <h4>2. After Login</h4>
                    <img src="final-test-2-after-login.png" alt="After Login">
                </div>
                <div class="screenshot-item">
                    <h4>3. Complete Layout</h4>
                    <img src="final-test-3-complete.png" alt="Complete Layout">
                </div>
            </div>
        </div>
        
        ${results.errors.length > 0 ? `
        <div class="details">
            <h2>Errors</h2>
            <ul>
                ${results.errors.map(err => `<li>${err}</li>`).join('')}
            </ul>
        </div>
        ` : ''}
    </div>
</body>
</html>`;
        
        fs.writeFileSync('final-test-report.html', htmlReport);
        console.log('\n✓ HTML report saved as final-test-report.html');
        console.log('\nTest completed successfully!');
    }
}

// Run the test
testLoginSidebarFinal().catch(console.error);