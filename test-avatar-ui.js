const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext({
    ignoreHTTPSErrors: true,
    viewport: { width: 1280, height: 720 }
  });
  
  const page = await context.newPage();
  
  console.log('🚀 Starting Avatar UI Test...\n');
  
  try {
    // Navigate to login page
    console.log('📍 Navigating to application...');
    await page.goto('http://localhost:8080');
    
    // Handle potential certificate warning
    const title = await page.title();
    console.log(`Page title: ${title}`);
    
    // Login
    console.log('🔐 Logging in...');
    await page.fill('input[type="email"]', 'admin@steelestimation.com');
    await page.fill('input[type="password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    
    // Wait for navigation
    await page.waitForLoadState('networkidle');
    console.log('✅ Logged in successfully\n');
    
    // Navigate to profile or avatar customization page
    console.log('👤 Looking for profile/avatar options...');
    
    // Try to find user menu or profile link
    const userMenuSelector = 'button[aria-label*="user" i], .user-menu, .user-dropdown, [data-bs-toggle="dropdown"]';
    const userMenu = await page.locator(userMenuSelector).first();
    
    if (await userMenu.isVisible()) {
      console.log('Found user menu, clicking...');
      await userMenu.click();
      await page.waitForTimeout(500);
      
      // Look for profile option
      const profileLink = await page.locator('a:has-text("Profile"), a:has-text("My Profile"), a:has-text("Settings")').first();
      if (await profileLink.isVisible()) {
        console.log('Clicking profile link...');
        await profileLink.click();
        await page.waitForLoadState('networkidle');
      }
    }
    
    // Check for avatar selector component
    console.log('\n🎨 Checking for avatar customization components...');
    
    // Look for EnhancedAvatarSelector
    const avatarSelector = await page.locator('.avatar-selector, [class*="avatar-selector"]').first();
    const hasAvatarSelector = await avatarSelector.isVisible();
    console.log(`Avatar selector found: ${hasAvatarSelector}`);
    
    if (hasAvatarSelector) {
      // Take screenshot of current state
      await page.screenshot({ path: 'avatar-selector-initial.png', fullPage: true });
      console.log('📸 Screenshot saved: avatar-selector-initial.png');
      
      // Check for DiceBear style options
      console.log('\n🔍 Checking DiceBear avatar styles...');
      const styleOptions = await page.locator('.dicebear-style-option, .dicebear-styles-grid').count();
      console.log(`Found ${styleOptions} style option elements`);
      
      // Check for Bottts style specifically
      const botttsStyle = await page.locator('.dicebear-style-option:has-text("Bottts")').first();
      if (await botttsStyle.isVisible()) {
        console.log('✅ Found Bottts style, clicking...');
        await botttsStyle.click();
        await page.waitForTimeout(1000);
        
        // Check for customization options
        console.log('\n🎛️ Checking customization options...');
        
        // Check for preview images
        const previewWrappers = await page.locator('.dicebear-preview-wrapper').count();
        console.log(`Found ${previewWrappers} preview wrappers`);
        
        // Check for actual images loaded
        const loadedImages = await page.locator('.dicebear-preview-wrapper img[src^="data:"]').count();
        console.log(`Found ${loadedImages} loaded preview images`);
        
        // Check for error states
        const errorPreviews = await page.locator('.preview-error').count();
        console.log(`Found ${errorPreviews} error previews`);
        
        // Check for loading spinners
        const loadingSpinners = await page.locator('.dicebear-preview-wrapper .spinner-border').count();
        console.log(`Found ${loadingSpinners} loading spinners`);
        
        // Take screenshot of customization state
        await page.screenshot({ path: 'avatar-customization.png', fullPage: true });
        console.log('📸 Screenshot saved: avatar-customization.png');
        
        // Test clicking on an eye type option
        const eyeOption = await page.locator('.visual-option-btn:has-text("eva")').first();
        if (await eyeOption.isVisible()) {
          console.log('\n👁️ Testing eye type selection...');
          await eyeOption.click();
          await page.waitForTimeout(500);
          
          // Check if main preview updated
          const mainPreview = await page.locator('.avatar-preview-container img').first();
          if (await mainPreview.isVisible()) {
            const previewSrc = await mainPreview.getAttribute('src');
            console.log(`Main preview source: ${previewSrc?.substring(0, 50)}...`);
          }
        }
        
        // Check for new parameters (face, top)
        console.log('\n🆕 Checking for new parameters...');
        const hasFaceOptions = await page.locator('label:has-text("Face Shape")').isVisible();
        const hasTopOptions = await page.locator('label:has-text("Top Accessories")').isVisible();
        const hasRotation = await page.locator('label:has-text("Rotation")').isVisible();
        const hasScale = await page.locator('label:has-text("Scale")').isVisible();
        
        console.log(`Face Shape options: ${hasFaceOptions}`);
        console.log(`Top Accessories options: ${hasTopOptions}`);
        console.log(`Rotation control: ${hasRotation}`);
        console.log(`Scale control: ${hasScale}`);
      }
    }
    
    // Try direct navigation to test pages
    console.log('\n📄 Checking test pages...');
    const testPages = [
      '/test-dicebear',
      '/test-dicebear-images',
      '/test-dicebear-customization'
    ];
    
    for (const testPage of testPages) {
      try {
        console.log(`\nTrying ${testPage}...`);
        await page.goto(`http://localhost:8080${testPage}`);
        await page.waitForLoadState('networkidle', { timeout: 5000 });
        
        const hasContent = await page.locator('body').textContent();
        if (hasContent && !hasContent.includes('404')) {
          console.log(`✅ Found test page: ${testPage}`);
          
          // Check for images on test page
          const images = await page.locator('img[src*="dicebear"]').count();
          console.log(`Found ${images} DiceBear images`);
          
          // Take screenshot
          await page.screenshot({ path: `test-page-${testPage.replace('/', '')}.png` });
          console.log(`📸 Screenshot saved: test-page-${testPage.replace('/', '')}.png`);
        }
      } catch (error) {
        console.log(`❌ Could not access ${testPage}`);
      }
    }
    
    // Final summary
    console.log('\n📊 Test Summary:');
    console.log('================');
    console.log(`- Avatar selector component: ${hasAvatarSelector ? '✅ Found' : '❌ Not found'}`);
    console.log(`- Preview images loaded: ${loadedImages || 0}`);
    console.log(`- Error states: ${errorPreviews || 0}`);
    console.log(`- Loading states: ${loadingSpinners || 0}`);
    
  } catch (error) {
    console.error('❌ Error during test:', error.message);
    await page.screenshot({ path: 'error-screenshot.png' });
    console.log('📸 Error screenshot saved: error-screenshot.png');
  }
  
  console.log('\n⏸️  Browser will remain open for manual inspection...');
  console.log('Press Ctrl+C to close when done.');
  
  // Keep browser open for inspection
  await page.waitForTimeout(300000); // 5 minutes
  
})();