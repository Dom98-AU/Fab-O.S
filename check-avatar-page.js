const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🚀 Checking Avatar Pages...\n');
  
  try {
    // Navigate to the application
    console.log('📍 Navigating to application...');
    await page.goto('http://localhost:8080');
    await page.waitForLoadState('networkidle');
    
    // Take screenshot of landing page
    await page.screenshot({ path: 'landing-page.png', fullPage: true });
    console.log('📸 Screenshot saved: landing-page.png');
    
    // Check what's on the page
    const pageContent = await page.content();
    console.log('\n🔍 Page analysis:');
    
    // Check for login form
    const hasEmailInput = await page.locator('input[type="email"], input[name="email"], input[id*="email" i]').count();
    const hasPasswordInput = await page.locator('input[type="password"], input[name="password"]').count();
    const hasUsernameInput = await page.locator('input[name="username"], input[id*="username" i]').count();
    
    console.log(`Email inputs found: ${hasEmailInput}`);
    console.log(`Password inputs found: ${hasPasswordInput}`);
    console.log(`Username inputs found: ${hasUsernameInput}`);
    
    // Check for submit button
    const submitButtons = await page.locator('button[type="submit"], input[type="submit"], button:has-text("Login"), button:has-text("Sign in")').count();
    console.log(`Submit buttons found: ${submitButtons}`);
    
    // Try to find any login-related elements
    console.log('\n📝 Login elements search:');
    const loginSelectors = [
      'form',
      '.login-form',
      '#loginForm',
      '[class*="login"]',
      '[id*="login"]'
    ];
    
    for (const selector of loginSelectors) {
      const count = await page.locator(selector).count();
      if (count > 0) {
        console.log(`Found ${count} elements matching: ${selector}`);
      }
    }
    
    // Print all input fields
    console.log('\n📋 All input fields on page:');
    const inputs = await page.locator('input:visible').all();
    for (let i = 0; i < inputs.length; i++) {
      const input = inputs[i];
      const type = await input.getAttribute('type') || 'text';
      const name = await input.getAttribute('name') || '';
      const id = await input.getAttribute('id') || '';
      const placeholder = await input.getAttribute('placeholder') || '';
      console.log(`Input ${i + 1}: type="${type}", name="${name}", id="${id}", placeholder="${placeholder}"`);
    }
    
    // Check if already logged in
    const userMenus = await page.locator('[class*="user"], [class*="profile"], [class*="avatar"]').count();
    console.log(`\nUser/Profile elements found: ${userMenus}`);
    
    // Try test pages directly
    console.log('\n🧪 Checking test pages:');
    const testUrls = [
      'http://localhost:8080/test-dicebear',
      'http://localhost:8080/test-dicebear-images',
      'http://localhost:8080/test-dicebear-customization'
    ];
    
    for (const url of testUrls) {
      try {
        console.log(`\nChecking ${url}...`);
        await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 10000 });
        const title = await page.title();
        const has404 = await page.locator('text=/404|not found/i').count();
        
        if (has404 === 0) {
          console.log(`✅ Page exists: ${title}`);
          
          // Check for avatar images
          const avatarImages = await page.locator('img[src*="dicebear"], img[src^="data:image/svg"]').count();
          console.log(`   Avatar images found: ${avatarImages}`);
          
          // Check for avatar components
          const avatarComponents = await page.locator('.avatar-selector, .dicebear-preview-wrapper, [class*="avatar"]').count();
          console.log(`   Avatar components found: ${avatarComponents}`);
          
          // Take screenshot
          const filename = url.split('/').pop() + '.png';
          await page.screenshot({ path: filename, fullPage: true });
          console.log(`   📸 Screenshot saved: ${filename}`);
        } else {
          console.log(`❌ Page not found (404)`);
        }
      } catch (error) {
        console.log(`❌ Error accessing page: ${error.message}`);
      }
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  
  console.log('\n✅ Check complete. Browser will close in 10 seconds...');
  await page.waitForTimeout(10000);
  await browser.close();
})();