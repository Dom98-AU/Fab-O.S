const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  // Quick login
  await page.goto('http://localhost:8080/Account/Login');
  await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
  await page.fill('input[name="Input.Password"]', 'Admin@123');
  await page.click('button[type="submit"]');
  await page.waitForLoadState('networkidle');
  
  // Go to profile and open modal
  await page.goto('http://localhost:8080/profile');
  await page.waitForTimeout(3000);
  await page.click('button:has-text("Edit Profile")');
  await page.waitForTimeout(3000);
  
  console.log('=== Modal Content Analysis ===\n');
  
  // Check what's in the modal
  const modalTitle = await page.locator('.modal-title').textContent().catch(() => 'No title');
  console.log('Modal Title:', modalTitle);
  
  // Check for tabs
  const tabs = await page.locator('.nav-tabs .nav-link, .nav-tabs button').all();
  console.log('\nTabs found:', tabs.length);
  for (let i = 0; i < tabs.length; i++) {
    const text = await tabs[i].textContent();
    console.log(`  Tab ${i + 1}: "${text.trim()}"`);
  }
  
  // Check if we're directly in customization view
  console.log('\nChecking for customization elements:');
  
  // Check for Bottts style elements
  const botttsElements = await page.locator('text=/bottts/i').count();
  console.log('  Elements with "bottts":', botttsElements);
  
  // Check for texture elements  
  const textureLabel = await page.locator('label:has-text("Texture")').count();
  console.log('  Texture label:', textureLabel > 0);
  
  const textureButtons = await page.locator('.texture-option-btn').count();
  console.log('  Texture option buttons:', textureButtons);
  
  // Check for any visual option buttons
  const visualButtons = await page.locator('.visual-option-btn').count();
  console.log('  Visual option buttons:', visualButtons);
  
  // Check modal body content
  const modalBody = await page.locator('.modal-body').first();
  const modalText = await modalBody.textContent();
  console.log('\nModal body preview (first 500 chars):');
  console.log(modalText.substring(0, 500));
  
  // Scroll down to see if there's more content
  await page.evaluate(() => {
    const modal = document.querySelector('.modal-body');
    if (modal) {
      modal.scrollTop = modal.scrollHeight / 2;
    }
  });
  await page.waitForTimeout(1000);
  
  await page.screenshot({ path: 'modal-content-check.png', fullPage: false });
  console.log('\nScreenshot saved: modal-content-check.png');
  
  // Scroll more
  await page.evaluate(() => {
    const modal = document.querySelector('.modal-body');
    if (modal) {
      modal.scrollTop = modal.scrollHeight;
    }
  });
  await page.waitForTimeout(1000);
  
  await page.screenshot({ path: 'modal-content-scrolled.png', fullPage: false });
  console.log('Screenshot saved: modal-content-scrolled.png');
  
  await browser.close();
})();