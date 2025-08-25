const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.launch({ headless: false });
    const context = await browser.newContext();
    const page = await context.newPage();
    
    console.log('1. Navigating to login page...');
    await page.goto('http://localhost:8080/Account/Login');
    await page.waitForSelector('input[name="Input.Email"]', { timeout: 10000 });
    
    console.log('2. Logging in...');
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    
    console.log('3. Waiting for navigation after login...');
    await page.waitForNavigation({ timeout: 10000 });
    
    console.log('4. Navigating to customers page...');
    await page.goto('http://localhost:8080/customers');
    await page.waitForSelector('.container-fluid', { timeout: 10000 });
    
    console.log('5. Checking Native Blazor toggle state...');
    const nativeBlazorToggle = await page.$('#blazorSwitch');
    const isNativeBlazorEnabled = await nativeBlazorToggle.isChecked();
    console.log(`   Native Blazor enabled: ${isNativeBlazorEnabled}`);
    
    // Check the debug output
    console.log('6. Looking for debug output...');
    const debugText = await page.textContent('.text-muted.mb-2').catch(() => null);
    if (debugText) {
        console.log(`   Debug info: ${debugText}`);
    }
    
    console.log('7. Switching to Card view...');
    await page.click('button:has-text("Cards")');
    await page.waitForTimeout(1000);
    
    console.log('8. Checking current view mode...');
    const cardButton = await page.$('button:has-text("Cards")');
    const cardButtonClass = await cardButton.getAttribute('class');
    console.log(`   Card button class: ${cardButtonClass}`);
    
    // Check if we're in Native Blazor mode and card view
    const customerCardsContainer = await page.$('.customer-cards-container');
    if (customerCardsContainer) {
        console.log('9. Found customer-cards-container!');
        
        // Check for the debug output again
        const debugTextAfter = await page.textContent('.text-muted.mb-2').catch(() => null);
        if (debugTextAfter) {
            console.log(`   Debug info in card view: ${debugTextAfter}`);
        }
        
        // Check for empty state message
        const emptyState = await page.$('.alert.alert-info');
        if (emptyState) {
            const emptyText = await emptyState.textContent();
            console.log(`   Empty state message: ${emptyText}`);
        }
        
        // Count customer cards
        const customerCards = await page.$$('.customer-card');
        console.log(`   Number of customer cards found: ${customerCards.length}`);
        
        // Get the HTML structure to debug
        const containerHtml = await customerCardsContainer.innerHTML();
        console.log(`   Container HTML length: ${containerHtml.length} characters`);
        
        // Check if there's a row div
        const rowDiv = await page.$('.customer-cards-container .row');
        if (rowDiv) {
            console.log('   Found Bootstrap row container');
            const cols = await page.$$('.customer-cards-container .row > div[class*="col"]');
            console.log(`   Number of column divs: ${cols.length}`);
        }
    } else {
        console.log('9. Customer cards container NOT found - may be in table view');
        
        // Check if ViewScape table is visible
        const viewscapeContainer = await page.$('#viewscape-container');
        if (viewscapeContainer) {
            console.log('   ViewScape container is visible');
            const tableRows = await page.$$('#viewscape-container tbody tr');
            console.log(`   Number of table rows: ${tableRows.length}`);
        }
    }
    
    console.log('10. Taking screenshot...');
    await page.screenshot({ path: 'customer-cards-debug.png', fullPage: true });
    console.log('    Screenshot saved as customer-cards-debug.png');
    
    // Try toggling Native Blazor off to see if ViewScape works
    console.log('11. Toggling Native Blazor OFF...');
    await page.click('#blazorSwitch');
    await page.waitForTimeout(1000);
    
    const viewscapeAfterToggle = await page.$('#viewscape-container');
    if (viewscapeAfterToggle) {
        console.log('12. ViewScape container now visible');
        const tableRows = await page.$$('#viewscape-container tbody tr');
        console.log(`    Number of table rows in ViewScape: ${tableRows.length}`);
    }
    
    await browser.close();
    console.log('\nTest completed!');
})();