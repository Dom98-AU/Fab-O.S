const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
  
  console.log('🚀 Testing Wider Modal and Tab Alignment...\n');
  
  try {
    // Login
    console.log('📍 Logging in...');
    await page.goto('http://localhost:8080/Account/Login');
    await page.waitForLoadState('networkidle');
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    await page.waitForLoadState('networkidle');

    // Navigate to profile
    await page.goto('http://localhost:8080/profile');
    await page.waitForLoadState('networkidle');
    await page.click('button:has-text("Edit Profile")');
    await page.waitForTimeout(2000);
    
    console.log('🔍 Checking Modal Width...');
    
    // Check modal width
    const modalDialog = await page.locator('.modal-dialog').first();
    const modalBounds = await modalDialog.boundingBox();
    console.log(`📐 Modal width: ${modalBounds.width}px`);
    
    // Get viewport width
    const viewport = page.viewportSize();
    console.log(`📱 Viewport width: ${viewport.width}px`);
    console.log(`📊 Modal uses ${Math.round((modalBounds.width / viewport.width) * 100)}% of viewport`);
    
    // Count avatar styles per row
    const styleGrid = await page.locator('.dicebear-styles-grid').first();
    const gridBounds = await styleGrid.boundingBox();
    const firstStyle = await page.locator('.dicebear-style-option').first();
    const styleBounds = await firstStyle.boundingBox();
    
    if (gridBounds && styleBounds) {
      const stylesPerRow = Math.floor(gridBounds.width / (styleBounds.width + 15));
      console.log(`\n🎨 Avatar styles per row: ${stylesPerRow}`);
      console.log(`📐 Grid width: ${gridBounds.width}px`);
    }
    
    console.log('\n🔍 Checking Tab Alignment...');
    
    // Check tab positions
    const typeTab = await page.locator('.nav-link:has-text("Type")').first();
    const customizeTab = await page.locator('.nav-link:has-text("Customize")').first();
    
    const typeBounds = await typeTab.boundingBox();
    const customizeBounds = await customizeTab.boundingBox();
    
    console.log(`\n📍 Type tab position: top=${typeBounds.y}, left=${typeBounds.x}`);
    console.log(`📍 Customize tab position: top=${customizeBounds.y}, left=${customizeBounds.x}`);
    
    const verticalAlignment = Math.abs(typeBounds.y - customizeBounds.y);
    console.log(`📏 Vertical alignment difference: ${verticalAlignment}px ${verticalAlignment < 2 ? '✅' : '❌'}`);
    
    // Check tab container
    const tabContainer = await page.locator('.nav-tabs').first();
    const tabContainerBounds = await tabContainer.boundingBox();
    console.log(`\n📐 Tab container width: ${tabContainerBounds.width}px`);
    
    // Take screenshots
    await page.screenshot({ path: 'wider-modal-full.png', fullPage: true });
    console.log('\n📸 Screenshot saved: wider-modal-full.png');
    
    // Click on an avatar style to see customization
    const adventurer = page.locator('.dicebear-style-option:has(.style-name:text("Adventurer"))').first();
    await adventurer.click();
    await page.waitForTimeout(2000);
    
    await page.screenshot({ path: 'wider-modal-customize.png', fullPage: true });
    console.log('📸 Screenshot saved: wider-modal-customize.png');
    
    console.log('\n✅ Test complete!');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    await page.screenshot({ path: 'wider-modal-error.png' });
  }
  
  console.log('\nBrowser will remain open for 30 seconds for inspection...');
  await page.waitForTimeout(30000);
  await browser.close();
})();