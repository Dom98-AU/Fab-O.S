const { test, expect } = require('@playwright/test');

test.describe('Enhanced Table View Modes', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to a page with enhanced table
    // Update this URL to match your actual application URL
    await page.goto('http://localhost:8080/ProcessingWorksheet');
    
    // Wait for the enhanced table to be initialized
    await page.waitForSelector('.enhanced-table', { timeout: 10000 });
  });

  test('view mode selector is visible and has all three options', async ({ page }) => {
    // Check that view mode selector exists
    const viewModeSelector = page.locator('.view-mode-selector');
    await expect(viewModeSelector).toBeVisible();
    
    // Check all three view mode buttons exist
    await expect(page.locator('input[value="list"]')).toBeAttached();
    await expect(page.locator('input[value="compactList"]')).toBeAttached();
    await expect(page.locator('input[value="cardView"]')).toBeAttached();
    
    // Check that list view is selected by default
    const listRadio = page.locator('input[value="list"]');
    await expect(listRadio).toBeChecked();
  });

  test('switching to compact list view applies correct styling', async ({ page }) => {
    // Click on compact list view
    await page.click('label[for*="compactList"]');
    
    // Wait for view transition
    await page.waitForTimeout(500);
    
    // Check that compact list class is applied
    const tableWrapper = page.locator('.table-wrapper, .enhanced-table-container');
    await expect(tableWrapper).toHaveClass(/compact-list-view/);
    
    // Verify that table cells have reduced padding
    const firstCell = page.locator('.enhanced-table td').first();
    const padding = await firstCell.evaluate(el => 
      window.getComputedStyle(el).padding
    );
    
    // Compact list should have smaller padding
    expect(padding).toMatch(/0\.3rem|4\.8px/);
  });

  test('switching to card view renders cards instead of table', async ({ page }) => {
    // Click on card view
    await page.click('label[for*="cardView"]');
    
    // Wait for view transition
    await page.waitForTimeout(500);
    
    // Check that card view container exists
    await expect(page.locator('.card-view-container')).toBeVisible();
    
    // Check that cards are rendered
    const cards = page.locator('.item-card');
    const cardCount = await cards.count();
    expect(cardCount).toBeGreaterThan(0);
    
    // Check that table is hidden
    await expect(page.locator('.enhanced-table')).toBeHidden();
  });

  test('card view displays correct item information', async ({ page }) => {
    // Switch to card view
    await page.click('label[for*="cardView"]');
    await page.waitForSelector('.item-card');
    
    // Get first card
    const firstCard = page.locator('.item-card').first();
    
    // Check card structure
    await expect(firstCard.locator('.card-title-custom')).toBeVisible();
    await expect(firstCard.locator('.card-body-custom')).toBeVisible();
    await expect(firstCard.locator('.card-actions')).toBeVisible();
    
    // Check that card has fields
    const fields = firstCard.locator('.card-field');
    const fieldCount = await fields.count();
    expect(fieldCount).toBeGreaterThan(0);
  });

  test('filters work in all view modes', async ({ page }) => {
    // Test filter in list view
    const filterInput = page.locator('.filter-input').first();
    await filterInput.fill('test');
    await page.waitForTimeout(300); // Debounce delay
    
    // Switch to compact list
    await page.click('label[for*="compactList"]');
    await page.waitForTimeout(300);
    
    // Filter should still be applied
    const filterValue = await filterInput.inputValue();
    expect(filterValue).toBe('test');
    
    // Switch to card view
    await page.click('label[for*="cardView"]');
    await page.waitForTimeout(300);
    
    // Filter should still work in card view
    // Check that cards are filtered (fewer cards visible)
    const cards = page.locator('.item-card:visible');
    const cardCount = await cards.count();
    
    // Clear filter
    await filterInput.clear();
    await page.waitForTimeout(300);
    
    // More cards should be visible now
    const allCards = page.locator('.item-card:visible');
    const allCardCount = await allCards.count();
    expect(allCardCount).toBeGreaterThanOrEqual(cardCount);
  });

  test('frozen columns feature shows disabled message in card view', async ({ page }) => {
    // Switch to card view
    await page.click('label[for*="cardView"]');
    await page.waitForTimeout(300);
    
    // Try to access frozen columns feature
    const freezeColumnBtn = page.locator('button:has-text("Freeze Columns")');
    if (await freezeColumnBtn.isVisible()) {
      await freezeColumnBtn.click();
      
      // Check for disabled feature message
      await expect(page.locator('.feature-disabled-overlay')).toBeVisible();
      await expect(page.locator('.feature-disabled-message')).toContainText(/not available in card view/i);
    }
  });

  test('view mode is saved with view state', async ({ page }) => {
    // Switch to card view
    await page.click('label[for*="cardView"]');
    await page.waitForTimeout(300);
    
    // Save view
    const saveAsBtn = page.locator('#saveAsViewBtn');
    await saveAsBtn.click();
    
    // Fill in view name in modal
    await page.waitForSelector('#saveViewModal');
    await page.fill('#viewNameInput', 'Test Card View');
    
    // Save the view
    await page.click('#saveViewBtn');
    await page.waitForTimeout(500);
    
    // Switch back to list view
    await page.click('label[for*="list"]');
    await page.waitForTimeout(300);
    
    // Load the saved view
    const viewSelector = page.locator('#viewSelector');
    await viewSelector.selectOption({ label: 'Test Card View' });
    
    const loadBtn = page.locator('#loadViewBtn');
    await loadBtn.click();
    await page.waitForTimeout(500);
    
    // Should be back in card view
    await expect(page.locator('.card-view-container')).toBeVisible();
    const cardViewRadio = page.locator('input[value="cardView"]');
    await expect(cardViewRadio).toBeChecked();
  });

  test('responsive behavior - card view adjusts columns on mobile', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    
    // Switch to card view
    await page.click('label[for*="cardView"]');
    await page.waitForTimeout(300);
    
    // Check that cards stack in single column
    const cardGrid = page.locator('.card-view-grid');
    const gridStyle = await cardGrid.evaluate(el => 
      window.getComputedStyle(el).gridTemplateColumns
    );
    
    // Should be single column on mobile
    expect(gridStyle).toMatch(/1fr|none|378px/);
  });

  test('pack bundle badges are visually distinct from delivery bundles', async ({ page }) => {
    // Look for pack bundle badges
    const packBundleBadge = page.locator('.pack-bundle-badge').first();
    
    if (await packBundleBadge.isVisible()) {
      // Check background color is info blue
      const bgColor = await packBundleBadge.evaluate(el => 
        window.getComputedStyle(el).backgroundColor
      );
      
      // Should be info blue color (#0dcaf0)
      expect(bgColor).toMatch(/rgb\(13, 202, 240\)/);
      
      // Compare with delivery bundle badge
      const deliveryBundleBadge = page.locator('.bundle-badge').first();
      if (await deliveryBundleBadge.isVisible()) {
        const deliveryBgColor = await deliveryBundleBadge.evaluate(el => 
          window.getComputedStyle(el).backgroundColor
        );
        
        // Should be different colors
        expect(bgColor).not.toBe(deliveryBgColor);
      }
    }
  });

  test('view mode switching maintains scroll position', async ({ page }) => {
    // Scroll down in list view
    await page.evaluate(() => window.scrollTo(0, 500));
    const initialScrollY = await page.evaluate(() => window.scrollY);
    
    // Switch to card view
    await page.click('label[for*="cardView"]');
    await page.waitForTimeout(300);
    
    // Check scroll position is maintained (approximately)
    const cardScrollY = await page.evaluate(() => window.scrollY);
    expect(Math.abs(cardScrollY - initialScrollY)).toBeLessThan(100);
    
    // Switch back to list view
    await page.click('label[for*="list"]');
    await page.waitForTimeout(300);
    
    // Scroll position should be maintained
    const finalScrollY = await page.evaluate(() => window.scrollY);
    expect(Math.abs(finalScrollY - initialScrollY)).toBeLessThan(100);
  });
});

test.describe('Enhanced Table Performance', () => {
  test('view mode switching is smooth and fast', async ({ page }) => {
    await page.goto('http://localhost:8080/ProcessingWorksheet');
    await page.waitForSelector('.enhanced-table');
    
    // Measure view switching performance
    const startTime = Date.now();
    
    // Switch to card view
    await page.click('label[for*="cardView"]');
    await page.waitForSelector('.card-view-container');
    
    // Switch to compact list
    await page.click('label[for*="compactList"]');
    await page.waitForSelector('.compact-list-view');
    
    // Switch back to list
    await page.click('label[for*="list"]');
    await page.waitForSelector('.enhanced-table:not(.d-none)');
    
    const endTime = Date.now();
    const totalTime = endTime - startTime;
    
    // All three switches should complete in under 2 seconds
    expect(totalTime).toBeLessThan(2000);
  });
});