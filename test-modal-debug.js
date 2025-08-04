const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  // Capture console messages
  page.on('console', msg => {
    if (msg.type() === 'error') {
      console.log('Browser console error:', msg.text());
    }
  });
  
  console.log('1. Logging in...');
  await page.goto('http://localhost:8080/Account/Login');
  await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
  await page.fill('input[name="Input.Password"]', 'Admin@123');
  await page.click('button[type="submit"]');
  await page.waitForLoadState('networkidle');

  console.log('2. Navigating to profile...');
  await page.goto('http://localhost:8080/profile');
  await page.waitForTimeout(5000); // Longer wait for JavaScript to initialize
  
  console.log('3. Checking for Edit Profile button...');
  const editButtons = await page.locator('button').all();
  console.log('   Total buttons on page:', editButtons.length);
  
  for (let btn of editButtons) {
    const text = await btn.textContent();
    if (text && text.includes('Edit')) {
      console.log('   Found button with text:', text.trim());
    }
  }
  
  console.log('4. Trying to click Edit Profile...');
  // Try different selectors
  const selectors = [
    'button:has-text("Edit Profile")',
    '.btn:has-text("Edit Profile")',
    'button.btn-primary:has-text("Edit Profile")',
    'button[class*="btn"]:has-text("Edit Profile")'
  ];
  
  let clicked = false;
  for (let selector of selectors) {
    const btn = await page.locator(selector).first();
    if (await btn.count() > 0) {
      console.log('   Clicking with selector:', selector);
      try {
        await btn.click({ timeout: 5000 });
        clicked = true;
        break;
      } catch (e) {
        console.log('   Click failed:', e.message);
      }
    }
  }
  
  if (!clicked) {
    console.log('   Trying JavaScript click...');
    await page.evaluate(() => {
      const buttons = Array.from(document.querySelectorAll('button'));
      const editBtn = buttons.find(b => b.textContent.includes('Edit Profile'));
      if (editBtn) {
        console.log('Found Edit Profile button via JS');
        editBtn.click();
        return true;
      }
      return false;
    });
  }
  
  await page.waitForTimeout(3000);
  
  console.log('5. Checking for modal...');
  // Check various modal selectors
  const modalSelectors = [
    '.modal.show',
    '.modal.fade.show',
    '.modal[style*="display: block"]',
    '.modal-dialog',
    '[role="dialog"]'
  ];
  
  for (let selector of modalSelectors) {
    const modal = await page.locator(selector).first();
    if (await modal.count() > 0) {
      console.log('   Modal found with selector:', selector);
      const isVisible = await modal.isVisible();
      console.log('   Modal visible:', isVisible);
      
      // Get modal title if exists
      const title = await modal.locator('.modal-title').first();
      if (await title.count() > 0) {
        const titleText = await title.textContent();
        console.log('   Modal title:', titleText);
      }
      
      break;
    }
  }
  
  // Check page HTML for modal
  const hasModalBackdrop = await page.locator('.modal-backdrop').count() > 0;
  console.log('   Modal backdrop exists:', hasModalBackdrop);
  
  const pageHtml = await page.content();
  const hasModalInDOM = pageHtml.includes('modal') && pageHtml.includes('Choose Your Avatar');
  console.log('   Modal HTML in DOM:', hasModalInDOM);
  
  // Try to find texture options regardless of modal
  console.log('6. Looking for texture elements in DOM...');
  const textureElements = await page.locator('.texture-option-btn, [class*="texture"]').all();
  console.log('   Elements with texture class:', textureElements.length);
  
  await page.screenshot({ path: 'modal-debug.png', fullPage: true });
  console.log('7. Screenshot saved: modal-debug.png');
  
  await browser.close();
})();