const { test, expect } = require('@playwright/test');

test.describe('Enhanced Table View Modes - Simple Test', () => {
  test('test HTML file loads and shows view mode controls', async ({ page }) => {
    // Navigate to test file
    await page.goto('file:///mnt/c/Fab%20O.S/test-enhanced-table-views.html');
    
    // Wait for page to load
    await page.waitForLoadState('networkidle');
    
    // Take screenshot of initial state
    await page.screenshot({ path: 'enhanced-table-initial.png' });
    
    // Check that the table exists
    const table = page.locator('.enhanced-table');
    await expect(table).toBeVisible();
    
    // Check table has rows
    const rows = page.locator('.enhanced-table tbody tr');
    const rowCount = await rows.count();
    expect(rowCount).toBe(5); // We have 5 test rows
    
    console.log(`Found ${rowCount} rows in the table`);
    
    // Check for enhanced table initialization
    const enhancedTableContainer = page.locator('.enhanced-table-container');
    await expect(enhancedTableContainer).toBeVisible();
    
    // Take final screenshot
    await page.screenshot({ path: 'enhanced-table-loaded.png', fullPage: true });
  });

  test('verify table structure and content', async ({ page }) => {
    await page.goto('file:///mnt/c/Fab%20O.S/test-enhanced-table-views.html');
    await page.waitForLoadState('networkidle');
    
    // Check headers
    const headers = await page.locator('.enhanced-table thead th').allTextContents();
    expect(headers).toEqual([
      'ID',
      'Item Number',
      'Description',
      'Quantity',
      'Unit Weight',
      'Total Weight',
      'Status',
      'Actions'
    ]);
    
    // Check first row data
    const firstRowCells = await page.locator('.enhanced-table tbody tr:first-child td').allTextContents();
    expect(firstRowCells[0]).toBe('1');
    expect(firstRowCells[1]).toBe('STL-001');
    expect(firstRowCells[2]).toBe('Steel Beam - W12x26');
    
    // Check status badges
    const badges = page.locator('.badge');
    const badgeCount = await badges.count();
    expect(badgeCount).toBeGreaterThan(0);
    
    // Check action buttons
    const editButtons = page.locator('.btn-primary .fa-edit');
    const editCount = await editButtons.count();
    expect(editCount).toBe(5); // One per row
  });

  test('console logs show initialization', async ({ page }) => {
    const consoleLogs = [];
    
    // Capture console logs
    page.on('console', msg => {
      consoleLogs.push({
        type: msg.type(),
        text: msg.text()
      });
    });
    
    await page.goto('file:///mnt/c/Fab%20O.S/test-enhanced-table-views.html');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(1000); // Give time for initialization
    
    // Check for initialization logs
    const initLog = consoleLogs.find(log => 
      log.text.includes('Enhanced table initialized')
    );
    
    expect(initLog).toBeTruthy();
    
    // Print all console logs for debugging
    console.log('Console logs:', consoleLogs);
  });
});