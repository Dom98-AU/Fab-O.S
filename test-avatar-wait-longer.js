const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🚀 Testing Avatar Image Loading with Longer Wait...\n');
  
  try {
    // Navigate to login page
    console.log('📍 Logging in...');
    await page.goto('http://localhost:8080/Account/Login');
    await page.waitForLoadState('networkidle');
    
    // Login
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);
    
    // Navigate to profile
    console.log('👤 Navigating to profile...');
    await page.goto('http://localhost:8080/profile');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);
    
    // Click Edit Profile button
    console.log('✏️ Clicking Edit Profile...');
    await page.click('button:has-text("Edit Profile")');
    await page.waitForTimeout(2000);
    
    // Click Bottts style
    console.log('🤖 Clicking Bottts style...');
    const botttsOption = await page.locator('.dicebear-style-option:has(.style-name:text("Bottts"))').first();
    await botttsOption.click();
    
    // Wait longer for images to load
    console.log('\n⏳ Waiting 15 seconds for images to load...');
    await page.waitForTimeout(15000);
    
    // Check image loading status
    console.log('\n🖼️ Checking image loading status:');
    
    const totalWrappers = await page.locator('.dicebear-preview-wrapper').count();
    const loadedImages = await page.locator('.dicebear-preview-wrapper img').count();
    const spinners = await page.locator('.dicebear-preview-wrapper .spinner-border').count();
    const errors = await page.locator('.preview-error').count();
    
    console.log(`Total preview wrappers: ${totalWrappers}`);
    console.log(`Loaded images: ${loadedImages}`);
    console.log(`Still loading (spinners): ${spinners}`);
    console.log(`Errors: ${errors}`);
    
    // Check network activity
    console.log('\n🌐 Checking for DiceBear API calls...');
    
    // Listen for responses
    const apiCalls = [];
    page.on('response', response => {
      if (response.url().includes('dicebear') || response.url().includes('api.dicebear.com')) {
        apiCalls.push({
          url: response.url(),
          status: response.status()
        });
      }
    });
    
    // Trigger a refresh to see network activity
    await page.reload();
    await page.waitForTimeout(5000);
    
    console.log(`DiceBear API calls detected: ${apiCalls.length}`);
    if (apiCalls.length > 0) {
      console.log('First 5 API calls:');
      apiCalls.slice(0, 5).forEach((call, i) => {
        console.log(`  ${i + 1}. Status: ${call.status} - ${call.url.substring(0, 80)}...`);
      });
    }
    
    // Check if images have valid src
    const images = await page.locator('.dicebear-preview-wrapper img').all();
    console.log('\n📊 Image source analysis:');
    
    let dataUrlCount = 0;
    let httpUrlCount = 0;
    let emptyCount = 0;
    
    for (const img of images) {
      const src = await img.getAttribute('src') || '';
      if (src.startsWith('data:')) dataUrlCount++;
      else if (src.startsWith('http')) httpUrlCount++;
      else if (!src) emptyCount++;
    }
    
    console.log(`  Data URLs: ${dataUrlCount}`);
    console.log(`  HTTP URLs: ${httpUrlCount}`);
    console.log(`  Empty/No src: ${emptyCount}`);
    
    // Take final screenshot
    await page.screenshot({ path: 'avatar-loading-final.png', fullPage: true });
    console.log('\n📸 Screenshot saved: avatar-loading-final.png');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    await page.screenshot({ path: 'avatar-loading-error.png' });
  }
  
  console.log('\n✅ Test complete. Browser will remain open for 30 seconds...');
  await page.waitForTimeout(30000);
  await browser.close();
})();