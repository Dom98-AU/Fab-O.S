const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.launch({ 
        headless: false,
        slowMo: 500 
    });
    
    const context = await browser.newContext({
        ignoreHTTPSErrors: true,
        viewport: { width: 1920, height: 1080 }
    });
    
    const page = await context.newPage();
    
    try {
        console.log('1. Navigating to login page...');
        await page.goto('http://localhost:8080/Account/Login', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        
        console.log('2. Performing login...');
        await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
        await page.fill('input[name="Input.Password"]', 'Admin@123');
        await page.click('button[type="submit"]');
        
        // Wait for navigation after login
        await page.waitForLoadState('networkidle');
        console.log('3. Login successful, waiting for redirect...');
        
        // Navigate to customers page
        console.log('4. Navigating to customers page...');
        await page.goto('http://localhost:8080/customers', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        
        // Wait for the page to fully load
        await page.waitForTimeout(3000);
        
        // Take screenshot
        console.log('5. Taking screenshot of customers page...');
        await page.screenshot({ 
            path: 'customers-page-view-switcher.png',
            fullPage: true 
        });
        
        // Check for view mode switcher elements
        console.log('6. Checking for view mode switcher...');
        
        // Look for view switcher button group
        const viewSwitcher = await page.locator('.btn-group').filter({ hasText: /Standard|Enhanced/ }).first();
        const viewSwitcherVisible = await viewSwitcher.isVisible().catch(() => false);
        
        if (viewSwitcherVisible) {
            console.log('✓ View mode switcher is VISIBLE');
            
            // Check for individual buttons
            const standardButton = await page.locator('button', { hasText: 'Standard View' }).first();
            const enhancedButton = await page.locator('button', { hasText: 'Enhanced View' }).first();
            
            const standardVisible = await standardButton.isVisible().catch(() => false);
            const enhancedVisible = await enhancedButton.isVisible().catch(() => false);
            
            console.log(`  - Standard View button: ${standardVisible ? 'VISIBLE' : 'NOT VISIBLE'}`);
            console.log(`  - Enhanced View button: ${enhancedVisible ? 'VISIBLE' : 'NOT VISIBLE'}`);
            
            // Check which view is active
            const standardActive = await standardButton.evaluate(el => el.classList.contains('btn-primary')).catch(() => false);
            const enhancedActive = await enhancedButton.evaluate(el => el.classList.contains('btn-primary')).catch(() => false);
            
            if (standardActive) {
                console.log('  - Current active view: STANDARD');
            } else if (enhancedActive) {
                console.log('  - Current active view: ENHANCED');
            }
            
            // Get button HTML for inspection
            const buttonGroupHTML = await viewSwitcher.innerHTML().catch(() => 'Could not get HTML');
            console.log('\n7. View switcher HTML structure:');
            console.log(buttonGroupHTML);
            
        } else {
            console.log('✗ View mode switcher is NOT VISIBLE');
            
            // Try alternative selectors
            console.log('\n7. Searching for alternative view switcher elements...');
            
            // Check for any buttons with view-related text
            const anyViewButtons = await page.locator('button').filter({ hasText: /view/i }).all();
            console.log(`  - Found ${anyViewButtons.length} buttons with "view" text`);
            
            for (let i = 0; i < anyViewButtons.length; i++) {
                const text = await anyViewButtons[i].textContent();
                const isVisible = await anyViewButtons[i].isVisible();
                console.log(`    Button ${i + 1}: "${text.trim()}" - ${isVisible ? 'VISIBLE' : 'HIDDEN'}`);
            }
            
            // Check page source for view switcher code
            const pageContent = await page.content();
            const hasViewSwitcherCode = pageContent.includes('Standard View') || pageContent.includes('Enhanced View');
            console.log(`  - Page contains view switcher code: ${hasViewSwitcherCode}`);
        }
        
        // Check for enhanced table elements
        console.log('\n8. Checking for enhanced table features...');
        const searchBox = await page.locator('input[placeholder*="Search"]').first();
        const searchVisible = await searchBox.isVisible().catch(() => false);
        console.log(`  - Search box: ${searchVisible ? 'VISIBLE' : 'NOT VISIBLE'}`);
        
        const table = await page.locator('table').first();
        const tableVisible = await table.isVisible().catch(() => false);
        console.log(`  - Table: ${tableVisible ? 'VISIBLE' : 'NOT VISIBLE'}`);
        
        if (tableVisible) {
            const rows = await page.locator('table tbody tr').count();
            console.log(`  - Table rows: ${rows}`);
        }
        
        console.log('\n9. Test completed successfully!');
        console.log('Screenshot saved as: customers-page-view-switcher.png');
        
    } catch (error) {
        console.error('Error during test:', error);
        
        // Take error screenshot
        await page.screenshot({ 
            path: 'customers-error-screenshot.png',
            fullPage: true 
        });
        console.log('Error screenshot saved as: customers-error-screenshot.png');
    } finally {
        await browser.close();
    }
})();