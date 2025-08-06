const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.launch({ 
        headless: true
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
            path: 'screenshots/customers-page-full.png',
            fullPage: true 
        });
        
        // Also take a focused screenshot of the header area
        const headerArea = await page.locator('.container-fluid').first();
        if (await headerArea.isVisible()) {
            await headerArea.screenshot({ 
                path: 'screenshots/customers-header-area.png' 
            });
        }
        
        // Check for view mode switcher elements
        console.log('\n6. CHECKING FOR VIEW MODE SWITCHER...');
        console.log('='*50);
        
        // Method 1: Look for btn-group with view buttons
        const viewSwitcherGroup = await page.locator('.btn-group').all();
        console.log(`Found ${viewSwitcherGroup.length} button groups on page`);
        
        for (let i = 0; i < viewSwitcherGroup.length; i++) {
            const text = await viewSwitcherGroup[i].textContent();
            if (text.includes('View')) {
                console.log(`Button group ${i + 1} contains view controls: "${text.trim()}"`);
                const isVisible = await viewSwitcherGroup[i].isVisible();
                console.log(`  Visibility: ${isVisible}`);
            }
        }
        
        // Method 2: Direct button search
        console.log('\n7. SEARCHING FOR VIEW BUTTONS...');
        const standardButton = await page.locator('button:has-text("Standard View")').first();
        const enhancedButton = await page.locator('button:has-text("Enhanced View")').first();
        
        const standardExists = await standardButton.count() > 0;
        const enhancedExists = await enhancedButton.count() > 0;
        
        console.log(`Standard View button exists: ${standardExists}`);
        console.log(`Enhanced View button exists: ${enhancedExists}`);
        
        if (standardExists) {
            const standardVisible = await standardButton.isVisible();
            console.log(`  - Standard View button visible: ${standardVisible}`);
            if (standardVisible) {
                const classes = await standardButton.getAttribute('class');
                console.log(`  - Standard button classes: ${classes}`);
            }
        }
        
        if (enhancedExists) {
            const enhancedVisible = await enhancedButton.isVisible();
            console.log(`  - Enhanced View button visible: ${enhancedVisible}`);
            if (enhancedVisible) {
                const classes = await enhancedButton.getAttribute('class');
                console.log(`  - Enhanced button classes: ${classes}`);
            }
        }
        
        // Method 3: Check page HTML for view switcher code
        console.log('\n8. CHECKING PAGE SOURCE...');
        const pageContent = await page.content();
        const hasStandardView = pageContent.includes('Standard View');
        const hasEnhancedView = pageContent.includes('Enhanced View');
        const hasBtnGroup = pageContent.includes('btn-group');
        
        console.log(`Page contains "Standard View" text: ${hasStandardView}`);
        console.log(`Page contains "Enhanced View" text: ${hasEnhancedView}`);
        console.log(`Page contains "btn-group" class: ${hasBtnGroup}`);
        
        // Extract relevant HTML if view switcher exists
        if (hasStandardView || hasEnhancedView) {
            const startIndex = pageContent.indexOf('<div class="btn-group"');
            if (startIndex > -1) {
                const endIndex = pageContent.indexOf('</div>', startIndex) + 6;
                const viewSwitcherHTML = pageContent.substring(startIndex, endIndex);
                console.log('\nView Switcher HTML (first occurrence):');
                console.log(viewSwitcherHTML.substring(0, 500));
            }
        }
        
        // Check table and enhanced features
        console.log('\n9. CHECKING TABLE FEATURES...');
        const table = await page.locator('table').first();
        const tableVisible = await table.isVisible().catch(() => false);
        console.log(`Table visible: ${tableVisible}`);
        
        if (tableVisible) {
            // Check for sortable headers
            const sortableHeaders = await page.locator('th[onclick], th[style*="cursor"]').count();
            console.log(`Sortable headers: ${sortableHeaders}`);
            
            // Check for search functionality
            const searchInput = await page.locator('input[type="search"], input[placeholder*="Search"], input[placeholder*="search"]').first();
            const searchVisible = await searchInput.isVisible().catch(() => false);
            console.log(`Search input visible: ${searchVisible}`);
            
            // Count table rows
            const rows = await page.locator('table tbody tr').count();
            console.log(`Table rows: ${rows}`);
        }
        
        // Final summary
        console.log('\n10. SUMMARY:');
        console.log('='*50);
        if (standardExists && enhancedExists) {
            console.log('✓ View mode switcher buttons FOUND in page');
            if (await standardButton.isVisible() && await enhancedButton.isVisible()) {
                console.log('✓ View mode switcher is VISIBLE');
            } else {
                console.log('✗ View mode switcher exists but is NOT VISIBLE');
            }
        } else {
            console.log('✗ View mode switcher buttons NOT FOUND');
        }
        
        console.log('\nScreenshots saved:');
        console.log('  - screenshots/customers-page-full.png');
        console.log('  - screenshots/customers-header-area.png');
        
    } catch (error) {
        console.error('Error during test:', error);
        
        // Take error screenshot
        await page.screenshot({ 
            path: 'screenshots/customers-error.png',
            fullPage: true 
        });
        console.log('Error screenshot saved as: screenshots/customers-error.png');
    } finally {
        await browser.close();
    }
})();