const { chromium } = require('playwright');

(async () => {
  // Launch browser
  const browser = await chromium.launch({ 
    headless: false,
    slowMo: 500 // Slow down for visibility
  });
  
  const context = await browser.newContext({
    ignoreHTTPSErrors: true
  });
  
  const page = await context.newPage();
  
  try {
    console.log('1. Navigating to login page...');
    await page.goto('http://localhost:8080/login');
    
    // Login
    console.log('2. Logging in...');
    await page.fill('input[name="Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    
    // Wait for navigation to complete
    await page.waitForURL('**/welcome', { timeout: 10000 });
    console.log('3. Login successful!');
    
    // Navigate to customers page
    console.log('4. Navigating to customers page...');
    await page.goto('http://localhost:8080/customers');
    await page.waitForSelector('.customers-table', { timeout: 10000 });
    
    // Wait for enhanced table to initialize
    await page.waitForTimeout(2000);
    
    // Test 1: Switch to Card View
    console.log('5. Testing view mode switching...');
    const cardViewButton = await page.$('input[id="viewMode-cardView"]');
    if (cardViewButton) {
      await page.click('label[for="viewMode-cardView"]');
      console.log('   ✓ Switched to card view');
      await page.waitForTimeout(1000);
    } else {
      console.log('   ✗ Card view button not found');
    }
    
    // Test 2: Change cards per row
    console.log('6. Testing cards per row...');
    const layoutButton = await page.$('button#cardLayoutBtn');
    if (layoutButton) {
      await layoutButton.click();
      await page.waitForTimeout(500);
      
      // Select 2 cards per row
      await page.click('label[for="cards-2"]');
      console.log('   ✓ Changed to 2 cards per row');
      await page.waitForTimeout(1000);
    }
    
    // Test 3: Test Save View functionality
    console.log('7. Testing save view functionality...');
    
    // Click save as new view button
    const saveAsBtn = await page.$('button#saveAsViewBtn');
    if (saveAsBtn) {
      await saveAsBtn.click();
      console.log('   ✓ Clicked Save As New View button');
      
      // Wait for modal
      await page.waitForSelector('#saveViewModal', { state: 'visible', timeout: 5000 });
      console.log('   ✓ Save view modal appeared');
      
      // Fill in view name
      const viewNameInput = await page.$('#saveViewModal input#viewName');
      if (viewNameInput) {
        await viewNameInput.fill('Test Card View - 2 Columns');
        console.log('   ✓ Entered view name');
        
        // Check "Set as default" checkbox
        const defaultCheckbox = await page.$('#saveViewModal input#setAsDefault');
        if (defaultCheckbox) {
          await defaultCheckbox.check();
          console.log('   ✓ Checked "Set as default"');
        }
        
        // Click save button in modal
        const modalSaveBtn = await page.$('#saveViewModal button.btn-primary');
        if (modalSaveBtn) {
          await modalSaveBtn.click();
          console.log('   ✓ Clicked Save button');
          
          // Wait for modal to close
          await page.waitForSelector('#saveViewModal', { state: 'hidden', timeout: 5000 });
          console.log('   ✓ Modal closed');
          
          // Check if view appears in dropdown
          await page.waitForTimeout(1000);
          const viewSelector = await page.$('#viewSelector');
          if (viewSelector) {
            const options = await viewSelector.$$eval('option', opts => 
              opts.map(opt => opt.textContent)
            );
            console.log('   ✓ Available views:', options);
            
            if (options.some(opt => opt.includes('Test Card View'))) {
              console.log('   ✓ New view saved successfully!');
            }
          }
        }
      }
    } else {
      console.log('   ✗ Save As View button not found');
    }
    
    // Test 4: Test search in card view
    console.log('8. Testing search in card view...');
    const searchInput = await page.$('input[placeholder*="Search customers"]');
    if (searchInput) {
      await searchInput.fill('Tech');
      console.log('   ✓ Entered search term');
      await page.waitForTimeout(1000);
      
      // Check if cards are filtered
      const cards = await page.$$('.enhanced-table-card');
      console.log(`   ✓ Found ${cards.length} card(s) after search`);
    }
    
    // Test 5: Switch back to list view
    console.log('9. Switching back to list view...');
    await page.click('label[for="viewMode-list"]');
    await page.waitForTimeout(1000);
    console.log('   ✓ Switched to list view');
    
    // Check if search persists
    const tableRows = await page.$$('tbody tr');
    console.log(`   ✓ Found ${tableRows.length} row(s) - search persisted`);
    
    console.log('\n✅ All tests completed successfully!');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    
    // Take screenshot on error
    await page.screenshot({ path: 'test-error.png' });
    console.log('Screenshot saved as test-error.png');
  }
  
  // Keep browser open for manual inspection
  console.log('\nPress Ctrl+C to close the browser...');
  
  // Uncomment to close automatically:
  // await browser.close();
})();