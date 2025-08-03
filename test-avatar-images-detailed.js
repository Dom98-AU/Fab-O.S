const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🚀 Detailed Avatar Image Test...\n');
  
  try {
    // Navigate to the test page
    console.log('📍 Navigating to test-dicebear-images...');
    await page.goto('http://localhost:8080/test-dicebear-images');
    await page.waitForLoadState('networkidle');
    
    // Wait for images to load
    await page.waitForTimeout(5000);
    
    console.log('🔍 Analyzing DiceBear images...\n');
    
    // Get all images with DiceBear URLs
    const images = await page.locator('img[src*="dicebear"], img[src*="api.dicebear.com"]').all();
    
    console.log(`Found ${images.length} DiceBear images\n`);
    
    // Check each image
    for (let i = 0; i < images.length; i++) {
      const img = images[i];
      console.log(`\n📸 Image ${i + 1}:`);
      
      // Get image attributes
      const src = await img.getAttribute('src');
      const alt = await img.getAttribute('alt') || 'No alt text';
      const width = await img.getAttribute('width') || 'Not specified';
      const height = await img.getAttribute('height') || 'Not specified';
      
      console.log(`  URL: ${src?.substring(0, 100)}...`);
      console.log(`  Alt: ${alt}`);
      console.log(`  Size: ${width}x${height}`);
      
      // Check if image is visible
      const isVisible = await img.isVisible();
      console.log(`  Visible: ${isVisible ? '✅' : '❌'}`);
      
      // Check actual rendered size
      const box = await img.boundingBox();
      if (box) {
        console.log(`  Rendered size: ${box.width}x${box.height}`);
      }
      
      // Check if image loaded successfully
      const loadedStatus = await img.evaluate((element) => {
        return {
          complete: element.complete,
          naturalWidth: element.naturalWidth,
          naturalHeight: element.naturalHeight,
          currentSrc: element.currentSrc
        };
      });
      
      console.log(`  Loaded: ${loadedStatus.complete && loadedStatus.naturalWidth > 0 ? '✅' : '❌'}`);
      if (loadedStatus.naturalWidth > 0) {
        console.log(`  Natural size: ${loadedStatus.naturalWidth}x${loadedStatus.naturalHeight}`);
      }
    }
    
    // Check for the enhanced avatar selector
    console.log('\n\n🎨 Looking for Enhanced Avatar Selector...');
    
    // Navigate to test customization page
    await page.goto('http://localhost:8080/test-dicebear-customization');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(3000);
    
    // Check for avatar selector components
    const avatarSelector = await page.locator('.avatar-selector').count();
    console.log(`Avatar selector components: ${avatarSelector}`);
    
    const previewWrappers = await page.locator('.dicebear-preview-wrapper').count();
    console.log(`Preview wrapper components: ${previewWrappers}`);
    
    const styleOptions = await page.locator('.dicebear-style-option').count();
    console.log(`Style option buttons: ${styleOptions}`);
    
    // Look for specific UI elements
    const hasBotttsOption = await page.locator('text=Bottts').count();
    console.log(`Bottts style option: ${hasBotttsOption > 0 ? '✅' : '❌'}`);
    
    // Check for customization options
    const customizationSections = await page.locator('.customization-section').count();
    console.log(`Customization sections: ${customizationSections}`);
    
    // Take detailed screenshot
    await page.screenshot({ path: 'avatar-detailed-test.png', fullPage: true });
    console.log('\n📸 Screenshot saved: avatar-detailed-test.png');
    
    // Check for any errors in console
    const consoleErrors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        consoleErrors.push(msg.text());
      }
    });
    
    // Check network requests to DiceBear API
    console.log('\n🌐 Monitoring DiceBear API requests...');
    const apiRequests = [];
    
    page.on('request', request => {
      if (request.url().includes('dicebear.com')) {
        apiRequests.push({
          url: request.url(),
          method: request.method()
        });
      }
    });
    
    page.on('response', response => {
      if (response.url().includes('dicebear.com')) {
        console.log(`  API Response: ${response.status()} - ${response.url().substring(0, 80)}...`);
      }
    });
    
    // Try clicking on Bottts style if available
    if (hasBotttsOption > 0) {
      console.log('\n🤖 Clicking on Bottts style...');
      await page.locator('text=Bottts').first().click();
      await page.waitForTimeout(3000);
      
      // Check for preview images after selection
      const loadedPreviews = await page.locator('.dicebear-preview-wrapper img').count();
      console.log(`Loaded preview images: ${loadedPreviews}`);
      
      const errorPreviews = await page.locator('.preview-error').count();
      console.log(`Error previews: ${errorPreviews}`);
      
      const loadingSpinners = await page.locator('.spinner-border').count();
      console.log(`Loading spinners: ${loadingSpinners}`);
    }
    
    // Final summary
    console.log('\n\n📊 Test Summary:');
    console.log('================');
    console.log(`Total DiceBear images found: ${images.length}`);
    console.log(`Console errors: ${consoleErrors.length}`);
    console.log(`API requests made: ${apiRequests.length}`);
    
    if (consoleErrors.length > 0) {
      console.log('\n❌ Console Errors:');
      consoleErrors.forEach(err => console.log(`  - ${err}`));
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    await page.screenshot({ path: 'error-detailed.png' });
  }
  
  console.log('\n✅ Test complete. Browser will remain open for 30 seconds...');
  await page.waitForTimeout(30000);
  await browser.close();
})();