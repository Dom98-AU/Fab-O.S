const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🚀 Testing DiceBear Components Directly...\n');
  
  try {
    // First, let's check the test page
    console.log('📍 Going to test-dicebear-images page...');
    await page.goto('http://localhost:8080/test-dicebear-images');
    await page.waitForLoadState('networkidle');
    
    // Check if we're redirected to login
    const currentUrl = page.url();
    console.log(`Current URL: ${currentUrl}`);
    
    if (currentUrl.includes('login') || currentUrl.includes('Login')) {
      console.log('🔐 Redirected to login page. Attempting login...');
      
      // Look for the actual form fields
      const formFields = await page.evaluate(() => {
        const inputs = Array.from(document.querySelectorAll('input'));
        return inputs.map(input => ({
          type: input.type,
          name: input.name,
          id: input.id,
          placeholder: input.placeholder,
          className: input.className
        }));
      });
      
      console.log('\nForm fields found:');
      formFields.forEach(field => {
        console.log(`- Type: ${field.type}, Name: ${field.name}, ID: ${field.id}, Placeholder: ${field.placeholder}`);
      });
      
      // Try different login approaches
      // First check for username field
      const usernameField = await page.locator('input[name="Input.Username"], input[name="Username"], input[placeholder*="username" i]').first();
      const emailField = await page.locator('input[name="Input.Email"], input[type="email"]').first();
      const passwordField = await page.locator('input[name="Input.Password"], input[type="password"]').first();
      
      if (await usernameField.isVisible()) {
        console.log('Found username field, using username login...');
        await usernameField.fill('admin@steelestimation.com');
      } else if (await emailField.isVisible()) {
        console.log('Found email field, using email login...');
        await emailField.fill('admin@steelestimation.com');
      }
      
      if (await passwordField.isVisible()) {
        await passwordField.fill('Admin@123');
      }
      
      // Find and click submit button
      const submitButton = await page.locator('button[type="submit"], input[type="submit"], button:has-text("Log in"), button:has-text("Login")').first();
      if (await submitButton.isVisible()) {
        console.log('Clicking submit button...');
        await submitButton.click();
        await page.waitForLoadState('networkidle');
      }
    }
    
    // Check if we made it to the test page
    console.log('\n🔍 Checking for DiceBear content...');
    
    // Wait a bit for any dynamic content
    await page.waitForTimeout(3000);
    
    // Check current URL again
    console.log(`Current URL after login: ${page.url()}`);
    
    // Look for any DiceBear related content
    const dicebearImages = await page.locator('img[src*="dicebear"], img[src*="api.dicebear.com"]').count();
    console.log(`DiceBear API images found: ${dicebearImages}`);
    
    const dataUrlImages = await page.locator('img[src^="data:image/svg"]').count();
    console.log(`Data URL SVG images found: ${dataUrlImages}`);
    
    const avatarSelectors = await page.locator('.avatar-selector, .dicebear-preview-wrapper, .avatar-preview').count();
    console.log(`Avatar selector components found: ${avatarSelectors}`);
    
    // Check page content
    const pageText = await page.textContent('body');
    const hasDiceBearText = pageText.toLowerCase().includes('dicebear');
    const hasAvatarText = pageText.toLowerCase().includes('avatar');
    console.log(`Page mentions DiceBear: ${hasDiceBearText}`);
    console.log(`Page mentions Avatar: ${hasAvatarText}`);
    
    // Take screenshot
    await page.screenshot({ path: 'dicebear-test-final.png', fullPage: true });
    console.log('\n📸 Screenshot saved: dicebear-test-final.png');
    
    // Try to inspect the actual HTML
    console.log('\n📄 Page structure:');
    const bodyHTML = await page.evaluate(() => {
      const body = document.body;
      // Get first 500 chars of body HTML
      return body.innerHTML.substring(0, 500);
    });
    console.log(bodyHTML + '...');
    
    // Check console for errors
    page.on('console', msg => {
      if (msg.type() === 'error') {
        console.log('❌ Console error:', msg.text());
      }
    });
    
    // Try to navigate to profile if we're logged in
    console.log('\n👤 Looking for user profile options...');
    const profileLinks = await page.locator('a:has-text("Profile"), a:has-text("Settings"), a[href*="profile"]').count();
    console.log(`Profile links found: ${profileLinks}`);
    
    if (profileLinks > 0) {
      const profileLink = await page.locator('a:has-text("Profile"), a:has-text("Settings"), a[href*="profile"]').first();
      await profileLink.click();
      await page.waitForLoadState('networkidle');
      
      console.log('Navigated to profile page');
      await page.screenshot({ path: 'profile-page.png', fullPage: true });
      console.log('📸 Screenshot saved: profile-page.png');
      
      // Check for avatar selector on profile page
      const profileAvatars = await page.locator('.avatar-selector, .avatar-preview, [class*="avatar"]').count();
      console.log(`Avatar elements on profile page: ${profileAvatars}`);
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    await page.screenshot({ path: 'error-final.png' });
  }
  
  console.log('\n✅ Test complete. Browser will remain open for 30 seconds...');
  await page.waitForTimeout(30000);
  await browser.close();
})();