const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🚀 Checking Modal Width Configuration...\n');
  
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
    
    // Check modal dialog classes and computed styles
    const modalDialog = await page.locator('.modal-dialog').first();
    const classes = await modalDialog.getAttribute('class');
    console.log(`Modal classes: ${classes}`);
    
    // Get computed styles
    const styles = await modalDialog.evaluate(el => {
      const computed = window.getComputedStyle(el);
      return {
        width: computed.width,
        maxWidth: computed.maxWidth,
        margin: computed.margin,
        inlineStyle: el.getAttribute('style')
      };
    });
    
    console.log('\n📐 Modal Styles:');
    console.log(`  Width: ${styles.width}`);
    console.log(`  Max-width: ${styles.maxWidth}`);
    console.log(`  Margin: ${styles.margin}`);
    console.log(`  Inline style: ${styles.inlineStyle || 'none'}`);
    
    // Check parent modal width
    const modal = await page.locator('.modal').first();
    const modalWidth = await modal.evaluate(el => window.getComputedStyle(el).width);
    console.log(`  Parent modal width: ${modalWidth}`);
    
    // Check viewport width
    const viewport = page.viewportSize();
    console.log(`\n📱 Viewport: ${viewport.width}px × ${viewport.height}px`);
    
    // Try to find the avatar modal dialog specifically
    const avatarModalDialog = await page.locator('.avatar-modal-dialog').count();
    console.log(`\n🎭 Avatar modal dialog class found: ${avatarModalDialog > 0 ? '✅ Yes' : '❌ No'}`);
    
    // Check Bootstrap modal-xl default
    const modalXlDialog = await page.locator('.modal-xl').first();
    if (await modalXlDialog.count() > 0) {
      const xlStyles = await modalXlDialog.evaluate(el => {
        const computed = window.getComputedStyle(el);
        return {
          width: computed.width,
          maxWidth: computed.maxWidth
        };
      });
      console.log(`\n📏 Bootstrap modal-xl computed styles:`);
      console.log(`  Width: ${xlStyles.width}`);
      console.log(`  Max-width: ${xlStyles.maxWidth}`);
    }
    
    // Take screenshot
    await page.screenshot({ path: 'modal-width-debug.png', fullPage: true });
    console.log('\n📸 Screenshot saved: modal-width-debug.png');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  
  console.log('\nBrowser will remain open for 30 seconds for inspection...');
  await page.waitForTimeout(30000);
  await browser.close();
})();