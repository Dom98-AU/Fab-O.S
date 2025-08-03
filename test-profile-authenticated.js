const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🚀 Testing Profile with Proper Authentication...\n');
  
  try {
    // Navigate to application
    console.log('📍 Navigating to application...');
    await page.goto('http://localhost:8080');
    await page.waitForLoadState('networkidle');
    
    const currentUrl = page.url();
    console.log(`Current URL: ${currentUrl}`);
    
    // Login if needed
    if (currentUrl.includes('login') || currentUrl.includes('Login')) {
      console.log('🔐 Logging in...');
      
      const usernameField = await page.locator('input[name="Input.Username"], input[placeholder*="username" i]').first();
      const passwordField = await page.locator('input[type="password"]').first();
      
      if (await usernameField.isVisible()) {
        await usernameField.fill('admin@steelestimation.com');
        await passwordField.fill('Admin@123');
        
        const submitButton = await page.locator('button[type="submit"]').first();
        await submitButton.click();
        
        // Wait for navigation after login
        await page.waitForLoadState('networkidle');
        await page.waitForTimeout(2000);
        
        console.log('✅ Login successful');
        console.log(`Post-login URL: ${page.url()}`);
      }
    }
    
    // Now click on Profile link instead of direct navigation
    console.log('\n👤 Looking for Profile link...');
    
    // Try to find profile link in navigation
    const profileLinks = await page.locator('a:has-text("Profile"), a[href*="/profile"], nav a:has-text("My Profile")').count();
    console.log(`Profile links found: ${profileLinks}`);
    
    if (profileLinks > 0) {
      console.log('Clicking profile link...');
      await page.locator('a:has-text("Profile"), a[href*="/profile"]').first().click();
      await page.waitForLoadState('networkidle');
      await page.waitForTimeout(2000);
    } else {
      // Fallback: navigate directly but in same session
      console.log('No profile link found, navigating directly...');
      await page.goto('http://localhost:8080/profile', { waitUntil: 'networkidle' });
      await page.waitForTimeout(2000);
    }
    
    console.log(`Profile URL: ${page.url()}`);
    
    // Check authentication state
    const profileHeader = await page.locator('.profile-header').count();
    console.log(`Profile header found: ${profileHeader > 0 ? '✅' : '❌'}`);
    
    // Check for user's name
    const userFullName = await page.locator('h2').first().textContent();
    console.log(`User name displayed: ${userFullName || 'Not found'}`);
    
    // Check for edit buttons
    console.log('\n✏️ Looking for Edit Profile button...');
    const editButtons = await page.locator('button:has-text("Edit"), button:has-text("Edit Profile")').count();
    console.log(`Edit buttons found: ${editButtons}`);
    
    // Check for specific edit button with icon
    const editWithIcon = await page.locator('button:has(i.fa-edit)').count();
    console.log(`Edit buttons with icon: ${editWithIcon}`);
    
    // Check if we see "Profile Not Found" message
    const notFound = await page.locator('text=Profile Not Found').count();
    console.log(`Profile not found message: ${notFound > 0 ? '❌ Yes' : '✅ No'}`);
    
    // Take screenshot
    await page.screenshot({ path: 'profile-authenticated.png', fullPage: true });
    console.log('\n📸 Screenshot saved: profile-authenticated.png');
    
    // If edit button exists, click it
    if (editButtons > 0) {
      console.log('\n🎨 Clicking Edit Profile button...');
      await page.locator('button:has-text("Edit Profile")').first().click();
      await page.waitForTimeout(2000);
      
      // Check for modal
      const modal = await page.locator('.modal.show').count();
      console.log(`Edit modal visible: ${modal > 0 ? '✅' : '❌'}`);
      
      // Check for avatar selector
      const avatarSelector = await page.locator('.avatar-selector, [class*="avatar-selector"]').count();
      console.log(`Avatar selector found: ${avatarSelector > 0 ? '✅' : '❌'}`);
      
      await page.screenshot({ path: 'profile-edit-modal.png', fullPage: true });
      console.log('📸 Screenshot saved: profile-edit-modal.png');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    await page.screenshot({ path: 'profile-error.png' });
  }
  
  console.log('\n✅ Test complete. Browser will remain open for 30 seconds...');
  await page.waitForTimeout(30000);
  await browser.close();
})();