const { test, expect } = require('@playwright/test');

test.describe('Enhanced Table JavaScript Unit Tests', () => {
  test('enhanced table view mode functionality', async ({ page }) => {
    // Create a test page with our enhanced table JavaScript
    await page.setContent(`
      <!DOCTYPE html>
      <html>
      <head>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
        <style>
          .enhanced-table { width: 100%; }
          .compact-list-view .table td { padding: 0.3rem; }
          .card-view-container { background: #f8f9fa; padding: 1rem; }
          .item-card { background: white; border: 1px solid #dee2e6; padding: 1rem; margin: 0.5rem; }
        </style>
      </head>
      <body>
        <div class="container mt-4">
          <div id="tableContainer">
            <table class="table enhanced-table">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Name</th>
                  <th>Value</th>
                </tr>
              </thead>
              <tbody>
                <tr><td>1</td><td>Item 1</td><td>100</td></tr>
                <tr><td>2</td><td>Item 2</td><td>200</td></tr>
                <tr><td>3</td><td>Item 3</td><td>300</td></tr>
              </tbody>
            </table>
          </div>
        </div>
      </body>
      </html>
    `);
    
    // Load the enhanced table JavaScript
    await page.addScriptTag({ path: 'SteelEstimation.Web/wwwroot/js/enhanced-table.js' });
    
    // Test the view mode constants
    const viewModes = await page.evaluate(() => {
      return window.enhancedTable.VIEW_MODES;
    });
    
    expect(viewModes).toEqual({
      LIST: 'list',
      COMPACT_LIST: 'compactList',
      CARD_VIEW: 'cardView'
    });
    
    // Test feature compatibility matrix
    const compatibility = await page.evaluate(() => {
      return window.enhancedTable.featureCompatibility;
    });
    
    expect(compatibility.list).toEqual({
      freezeColumns: true,
      resize: true,
      reorder: true,
      filter: true,
      sort: true
    });
    
    expect(compatibility.cardView).toEqual({
      freezeColumns: false,
      resize: false,
      reorder: false,
      filter: true,
      sort: true
    });
    
    // Test view mode switching function
    const hasSwitch = await page.evaluate(() => {
      return typeof window.enhancedTable.switchViewMode === 'function';
    });
    expect(hasSwitch).toBe(true);
    
    // Test card creation function
    const hasCreateCard = await page.evaluate(() => {
      return typeof window.enhancedTable.createCard === 'function';
    });
    expect(hasCreateCard).toBe(true);
    
    console.log('✓ View modes constants defined correctly');
    console.log('✓ Feature compatibility matrix configured');
    console.log('✓ View mode switching function exists');
    console.log('✓ Card creation function exists');
  });

  test('view mode rendering functions', async ({ page }) => {
    await page.setContent(`
      <!DOCTYPE html>
      <html>
      <body>
        <div id="container"></div>
        <table class="enhanced-table">
          <thead><tr><th>Col1</th><th>Col2</th></tr></thead>
          <tbody><tr><td>Data1</td><td>Data2</td></tr></tbody>
        </table>
      </body>
      </html>
    `);
    
    await page.addScriptTag({ path: 'SteelEstimation.Web/wwwroot/js/enhanced-table.js' });
    
    // Test render functions exist
    const renderFunctions = await page.evaluate(() => {
      return {
        hasRenderList: typeof window.enhancedTable.renderListView === 'function',
        hasRenderCompact: typeof window.enhancedTable.renderCompactListView === 'function',
        hasRenderCard: typeof window.enhancedTable.renderCardView === 'function'
      };
    });
    
    expect(renderFunctions.hasRenderList).toBe(true);
    expect(renderFunctions.hasRenderCompact).toBe(true);
    expect(renderFunctions.hasRenderCard).toBe(true);
    
    // Test apply view mode
    await page.evaluate(() => {
      const table = document.querySelector('.enhanced-table');
      const settings = { viewMode: 'compactList' };
      window.enhancedTable.applyViewMode(table, settings);
    });
    
    // Check that compact list class was applied
    const hasCompactClass = await page.evaluate(() => {
      const wrapper = document.querySelector('.table-wrapper');
      return wrapper && wrapper.classList.contains('compact-list-view');
    });
    
    expect(hasCompactClass).toBe(true);
    
    console.log('✓ All render functions exist');
    console.log('✓ View mode can be applied to table');
  });

  test('getCurrentTableState includes view mode', async ({ page }) => {
    await page.setContent(`
      <!DOCTYPE html>
      <html>
      <body>
        <input type="radio" name="viewMode" value="cardView" checked>
        <table class="enhanced-table">
          <thead><tr><th>Column1</th></tr></thead>
          <tbody><tr><td>Data</td></tr></tbody>
        </table>
      </body>
      </html>
    `);
    
    await page.addScriptTag({ path: 'SteelEstimation.Web/wwwroot/js/enhanced-table.js' });
    
    // Get current table state
    const state = await page.evaluate(() => {
      return window.enhancedTable.getCurrentTableState();
    });
    
    // Check that view mode is included
    expect(state.viewMode).toBe('cardView');
    expect(state.columnOrder).toBeDefined();
    expect(state.columnWidths).toBeDefined();
    expect(state.columnVisibility).toBeDefined();
    
    console.log('✓ getCurrentTableState includes view mode');
    console.log('✓ State object has all required properties');
  });
});