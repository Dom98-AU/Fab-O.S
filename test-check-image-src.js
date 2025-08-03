const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🚀 Checking Avatar Image Sources...\n');
  
  try {
    // Quick login and navigate
    await page.goto('http://localhost:8080/Account/Login');
    await page.waitForLoadState('networkidle');
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    await page.waitForLoadState('networkidle');
    await page.goto('http://localhost:8080/profile');
    await page.waitForLoadState('networkidle');
    await page.click('button:has-text("Edit Profile")');
    await page.waitForTimeout(2000);
    
    // Click Bottts
    await page.locator('.dicebear-style-option:has(.style-name:text("Bottts"))').first().click();
    await page.waitForTimeout(10000); // Wait 10 seconds
    
    // Get all images in preview wrappers
    console.log('🔍 Analyzing all images in preview wrappers...\n');
    
    const images = await page.locator('.dicebear-preview-wrapper img').all();
    console.log(`Total images found: ${images.length}\n`);
    
    // Check first 5 images in detail
    for (let i = 0; i < Math.min(5, images.length); i++) {
      const img = images[i];
      const src = await img.getAttribute('src');
      const alt = await img.getAttribute('alt');
      const naturalWidth = await img.evaluate(el => el.naturalWidth);
      const complete = await img.evaluate(el => el.complete);
      
      console.log(`Image ${i + 1}:`);
      console.log(`  Alt: ${alt}`);
      console.log(`  Complete: ${complete}`);
      console.log(`  Natural Width: ${naturalWidth}`);
      console.log(`  Src type: ${src ? (src.startsWith('data:') ? 'Data URL' : src.startsWith('http') ? 'HTTP URL' : 'Other') : 'No src'}`);
      
      if (src) {
        if (src.startsWith('data:')) {
          console.log(`  Data URL preview: ${src.substring(0, 100)}...`);
        } else {
          console.log(`  Full src: ${src}`);
        }
      }
      console.log('');
    }
    
    // Check if DiceBearService is being called
    console.log('🔧 Checking DiceBearService calls...');
    
    // Inject console log monitoring
    await page.evaluate(() => {
      const originalLog = console.log;
      window.capturedLogs = [];
      console.log = function(...args) {
        window.capturedLogs.push(args.join(' '));
        originalLog.apply(console, args);
      };
    });
    
    // Click another style to trigger logs
    await page.locator('.dicebear-style-option:has(.style-name:text("Adventurer"))').first().click();
    await page.waitForTimeout(2000);
    
    // Get captured logs
    const logs = await page.evaluate(() => window.capturedLogs);
    console.log('\nCaptured console logs:');
    logs.forEach(log => console.log(`  ${log}`));
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  
  console.log('\n✅ Test complete. Browser will remain open for 30 seconds...');
  await page.waitForTimeout(30000);
  await browser.close();
})();