const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
  
  console.log('🚀 Testing Modal Width Constraints...\n');
  
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
    
    console.log('🔍 Checking Width Constraints...\n');
    
    // Check each level
    const elements = [
      { selector: '.modal-dialog', name: 'Modal Dialog' },
      { selector: '.modal-content', name: 'Modal Content' },
      { selector: '.modal-body', name: 'Modal Body' },
      { selector: 'form', name: 'Form' },
      { selector: '.avatar-selector', name: 'Avatar Selector' },
      { selector: '.avatar-tabs-container', name: 'Tabs Container' },
      { selector: '.customization-section', name: 'Customization Section' },
      { selector: '.dicebear-styles-grid', name: 'Avatar Grid' }
    ];
    
    for (const elem of elements) {
      const el = await page.locator(elem.selector).first();
      if (await el.count() > 0) {
        const bounds = await el.boundingBox();
        const styles = await el.evaluate(e => {
          const computed = window.getComputedStyle(e);
          return {
            width: computed.width,
            maxWidth: computed.maxWidth,
            padding: computed.padding,
            margin: computed.margin
          };
        });
        
        console.log(`📐 ${elem.name}:`);
        console.log(`   Actual width: ${bounds.width}px`);
        console.log(`   CSS width: ${styles.width}`);
        console.log(`   Max-width: ${styles.maxWidth}`);
        console.log(`   Padding: ${styles.padding}`);
        console.log(`   Margin: ${styles.margin}`);
        console.log('');
      }
    }
    
    // Check if Bootstrap is limiting form width
    const bootstrapForm = await page.evaluate(() => {
      const form = document.querySelector('form');
      if (form) {
        const classes = form.className;
        const parent = form.parentElement;
        return {
          formClasses: classes,
          parentClasses: parent ? parent.className : 'none',
          parentWidth: parent ? window.getComputedStyle(parent).width : 'none'
        };
      }
      return null;
    });
    
    if (bootstrapForm) {
      console.log('📋 Form Analysis:');
      console.log(`   Form classes: ${bootstrapForm.formClasses || 'none'}`);
      console.log(`   Parent classes: ${bootstrapForm.parentClasses}`);
      console.log(`   Parent width: ${bootstrapForm.parentWidth}`);
    }
    
    await page.screenshot({ path: 'modal-constraints.png', fullPage: true });
    console.log('\n📸 Screenshot saved: modal-constraints.png');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  
  console.log('\nBrowser will remain open for 30 seconds for inspection...');
  await page.waitForTimeout(30000);
  await browser.close();
})();