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
    
    // Click submit and wait for either navigation or URL change
    await Promise.all([
        page.click('button[type="submit"]'),
        page.waitForURL('**/', { timeout: 10000 }).catch(() => 
            page.waitForTimeout(3000)
        )
    ]);
    
    console.log('3. Login complete, navigating to customers...');
    await page.goto('http://localhost:8080/customers');
    await page.waitForSelector('.container-fluid', { timeout: 10000 });
    
    console.log('4. Page loaded, checking initial state...');
    
    // Check the Native Blazor toggle
    const nativeBlazorToggle = await page.$('#blazorSwitch');
    if (nativeBlazorToggle) {
        const isChecked = await nativeBlazorToggle.isChecked();
        console.log(`   Native Blazor is: ${isChecked ? 'ON' : 'OFF'}`);
        
        // Make sure it's ON
        if (!isChecked) {
            console.log('   Turning Native Blazor ON...');
            await page.click('#blazorSwitch');
            await page.waitForTimeout(500);
        }
    }
    
    // Check current view mode
    const cardButton = await page.$('button:has-text("Cards")');
    const cardButtonClass = await cardButton.getAttribute('class');
    const isCardViewActive = cardButtonClass.includes('btn-primary');
    console.log(`   Card view is: ${isCardViewActive ? 'ACTIVE' : 'NOT ACTIVE'}`);
    
    // Switch to card view if not already
    if (!isCardViewActive) {
        console.log('5. Switching to Card view...');
        await page.click('button:has-text("Cards")');
        await page.waitForTimeout(1000);
    }
    
    console.log('6. Checking for debug output...');
    const debugElements = await page.$$('.text-muted.mb-2');
    for (let i = 0; i < debugElements.length; i++) {
        const text = await debugElements[i].textContent();
        console.log(`   Debug text ${i + 1}: ${text}`);
    }
    
    console.log('7. Looking for customer cards container...');
    const container = await page.$('.customer-cards-container');
    if (container) {
        console.log('   ✓ Found customer-cards-container');
        
        // Check for alert/empty state
        const alert = await container.$('.alert.alert-info');
        if (alert) {
            const alertText = await alert.textContent();
            console.log(`   ⚠️ Alert message: ${alertText}`);
        }
        
        // Check for row container
        const row = await container.$('.row');
        if (row) {
            console.log('   ✓ Found Bootstrap row');
            
            // Count column divs
            const cols = await row.$$('div[class*="col"]');
            console.log(`   Found ${cols.length} column divs`);
            
            // Count actual customer cards
            const cards = await container.$$('.customer-card');
            console.log(`   Found ${cards.length} customer cards`);
            
            // Get first card's content if any exist
            if (cards.length > 0) {
                const firstCardText = await cards[0].textContent();
                console.log(`   First card preview: ${firstCardText.substring(0, 100)}...`);
            }
        }
    } else {
        console.log('   ✗ Customer cards container not found');
        
        // Check if we're seeing the table instead
        const table = await page.$('.customers-table');
        if (table) {
            console.log('   Found table view instead');
            const rows = await table.$$('tbody tr');
            console.log(`   Table has ${rows.length} rows`);
        }
    }
    
    console.log('8. Taking screenshot...');
    await page.screenshot({ path: 'customer-cards-final.png', fullPage: true });
    
    console.log('9. Checking page HTML structure...');
    const cardBody = await page.$('.card-body');
    if (cardBody) {
        const children = await cardBody.$$('> *');
        console.log(`   Card body has ${children.length} direct children`);
        
        for (let i = 0; i < Math.min(3, children.length); i++) {
            const tagName = await children[i].evaluate(el => el.tagName);
            const className = await children[i].evaluate(el => el.className);
            console.log(`   Child ${i + 1}: <${tagName}> class="${className}"`);
        }
    }
    
    await browser.close();
    console.log('\n✓ Test completed! Check customer-cards-final.png');
})();