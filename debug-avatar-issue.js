const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ 
    headless: false,
    devtools: true 
  });
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
  
  console.log('🔍 Debugging Avatar Issues...\n');
  
  // Enable console logging
  page.on('console', msg => {
    if (msg.type() === 'log' || msg.type() === 'error') {
      console.log(`[Browser ${msg.type()}]: ${msg.text()}`);
    }
  });
  
  try {
    // Login
    console.log('📍 Step 1: Logging in...');
    await page.goto('http://localhost:8080/Account/Login');
    await page.waitForLoadState('networkidle');
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    await page.waitForLoadState('networkidle');

    // Navigate to profile
    console.log('\n📍 Step 2: Navigating to profile...');
    await page.goto('http://localhost:8080/profile');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(3000);
    
    // Check avatar image
    console.log('\n📍 Step 3: Checking avatar image...');
    const avatarImg = await page.locator('.avatar-large').first();
    const avatarExists = await avatarImg.count() > 0;
    console.log(`Avatar element exists: ${avatarExists ? '✅' : '❌'}`);
    
    if (avatarExists) {
      // Get computed styles
      const avatarStyles = await avatarImg.evaluate(el => {
        const computed = window.getComputedStyle(el);
        return {
          width: computed.width,
          height: computed.height,
          objectFit: computed.objectFit,
          borderRadius: computed.borderRadius,
          display: computed.display,
          className: el.className,
          tagName: el.tagName,
          src: el.src || el.getAttribute('src')
        };
      });
      
      console.log('\nAvatar element details:');
      console.log(`  Tag: ${avatarStyles.tagName}`);
      console.log(`  Classes: ${avatarStyles.className}`);
      console.log(`  Width: ${avatarStyles.width}`);
      console.log(`  Height: ${avatarStyles.height}`);
      console.log(`  Object-fit: ${avatarStyles.objectFit}`);
      console.log(`  Border-radius: ${avatarStyles.borderRadius}`);
      console.log(`  Display: ${avatarStyles.display}`);
      console.log(`  Src length: ${avatarStyles.src ? avatarStyles.src.length : 0} chars`);
    }
    
    // Check edit button
    console.log('\n📍 Step 4: Checking avatar edit button...');
    const editBtn = await page.locator('.avatar-change-btn').first();
    const btnExists = await editBtn.count() > 0;
    console.log(`Edit button exists: ${btnExists ? '✅' : '❌'}`);
    
    if (btnExists) {
      const btnVisible = await editBtn.isVisible();
      console.log(`Edit button visible: ${btnVisible ? '✅' : '❌'}`);
      
      const btnStyles = await editBtn.evaluate(el => {
        const computed = window.getComputedStyle(el);
        const rect = el.getBoundingClientRect();
        return {
          position: computed.position,
          zIndex: computed.zIndex,
          display: computed.display,
          width: computed.width,
          height: computed.height,
          top: rect.top,
          left: rect.left,
          clickable: !el.disabled,
          onclick: el.onclick ? 'has onclick' : 'no onclick',
          events: el.getAttributeNames().filter(n => n.startsWith('on')).join(', ')
        };
      });
      
      console.log('\nEdit button details:');
      console.log(`  Position: ${btnStyles.position}`);
      console.log(`  Z-index: ${btnStyles.zIndex}`);
      console.log(`  Display: ${btnStyles.display}`);
      console.log(`  Size: ${btnStyles.width} x ${btnStyles.height}`);
      console.log(`  Location: top=${btnStyles.top}, left=${btnStyles.left}`);
      console.log(`  Clickable: ${btnStyles.clickable ? '✅' : '❌'}`);
      console.log(`  OnClick: ${btnStyles.onclick}`);
      console.log(`  Event attributes: ${btnStyles.events || 'none'}`);
      
      // Try to click it
      console.log('\n📍 Step 5: Attempting to click edit button...');
      try {
        await editBtn.click({ timeout: 5000 });
        console.log('Click succeeded ✅');
        
        // Check if modal opened
        await page.waitForTimeout(2000);
        const modalExists = await page.locator('.modal').count() > 0;
        const modalVisible = await page.locator('.modal.show').isVisible().catch(() => false);
        console.log(`Modal exists: ${modalExists ? '✅' : '❌'}`);
        console.log(`Modal visible: ${modalVisible ? '✅' : '❌'}`);
      } catch (clickError) {
        console.log(`Click failed: ${clickError.message} ❌`);
        
        // Try force click
        console.log('Trying force click...');
        try {
          await editBtn.click({ force: true, timeout: 5000 });
          console.log('Force click succeeded ✅');
        } catch (forceError) {
          console.log(`Force click also failed: ${forceError.message} ❌`);
        }
      }
    }
    
    // Take screenshot
    await page.screenshot({ path: 'avatar-debug.png', fullPage: false });
    console.log('\n📸 Screenshot saved: avatar-debug.png');
    
  } catch (error) {
    console.error('\n❌ Error:', error.message);
    await page.screenshot({ path: 'avatar-error.png', fullPage: false });
  }
  
  console.log('\n⏸️  Browser will remain open for inspection. Press Ctrl+C to close.');
  
  // Keep browser open for manual inspection
  await new Promise(() => {});
})();