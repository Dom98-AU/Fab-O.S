const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🚀 Testing Profile Edit Mode with Avatar Selector...\n');
  
  try {
    // Navigate and login
    console.log('📍 Navigating to application...');
    await page.goto('http://localhost:8080');
    await page.waitForLoadState('networkidle');
    
    const currentUrl = page.url();
    
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
        await page.waitForLoadState('networkidle');
      }
    }
    
    // Go to profile
    console.log('\n👤 Navigating to profile...');
    await page.goto('http://localhost:8080/profile');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);
    
    // Look for edit button
    console.log('\n✏️ Looking for Edit Profile button...');
    const editButtons = await page.locator('button:has-text("Edit"), button:has-text("Edit Profile"), a:has-text("Edit")').count();
    console.log(`Edit buttons found: ${editButtons}`);
    
    if (editButtons > 0) {
      console.log('Clicking edit button...');
      await page.locator('button:has-text("Edit"), button:has-text("Edit Profile")').first().click();
      await page.waitForTimeout(3000);
      
      // Now check for avatar selector in edit mode
      console.log('\n🎨 Checking for avatar selector in edit mode...');
      
      const avatarSelector = await page.locator('.avatar-selector').count();
      console.log(`Avatar selector components: ${avatarSelector}`);
      
      const enhancedSelector = await page.locator('text=EnhancedAvatarSelectorV2').count();
      console.log(`Enhanced selector references: ${enhancedSelector}`);
      
      const dicebearStyles = await page.locator('.dicebear-style-option, .dicebear-styles-grid').count();
      console.log(`DiceBear style options: ${dicebearStyles}`);
      
      const categoryTitles = await page.locator('.category-title').count();
      console.log(`Category titles: ${categoryTitles}`);
      
      // Check for specific avatar styles
      const avatarStyles = ['Adventurer', 'Avataaars', 'Bottts', 'Big Ears', 'Pixel Art'];
      console.log('\n🎭 Checking for avatar styles:');
      for (const style of avatarStyles) {
        const hasStyle = await page.locator(`text=${style}`).count();
        console.log(`  ${style}: ${hasStyle > 0 ? '✅' : '❌'}`);
      }
      
      // Take screenshot of edit mode
      await page.screenshot({ path: 'profile-edit-mode.png', fullPage: true });
      console.log('\n📸 Screenshot saved: profile-edit-mode.png');
    }
    
    // Check page HTML for component
    console.log('\n🔍 Checking page source for avatar components...');
    const pageContent = await page.content();
    
    const hasEnhancedSelector = pageContent.includes('EnhancedAvatarSelectorV2');
    const hasAvatarSelector = pageContent.includes('avatar-selector');
    const hasDiceBearPreview = pageContent.includes('dicebear-preview-wrapper');
    
    console.log(`Page contains EnhancedAvatarSelectorV2: ${hasEnhancedSelector ? '✅' : '❌'}`);
    console.log(`Page contains avatar-selector class: ${hasAvatarSelector ? '✅' : '❌'}`);
    console.log(`Page contains dicebear-preview-wrapper: ${hasDiceBearPreview ? '✅' : '❌'}`);
    
    // Check for any blazor errors
    const blazorErrors = await page.locator('#blazor-error-ui:visible').count();
    if (blazorErrors > 0) {
      console.log('\n❌ Blazor error detected!');
      const errorText = await page.locator('#blazor-error-ui').textContent();
      console.log(`Error: ${errorText}`);
    }
    
    // Check console for errors
    const errors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });
    
    // Wait a bit for any errors to appear
    await page.waitForTimeout(2000);
    
    if (errors.length > 0) {
      console.log('\n❌ Console errors:');
      errors.forEach(err => console.log(`  - ${err}`));
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    await page.screenshot({ path: 'profile-test-error.png' });
  }
  
  console.log('\n✅ Test complete. Browser will remain open for 30 seconds...');
  await page.waitForTimeout(30000);
  await browser.close();
})();