const { chromium } = require('playwright');

(async () => {
  console.log('=== Testing Texture Customization ===\n');
  
  const browser = await chromium.launch({ 
    headless: false,
    slowMo: 500
  });
  
  const page = await browser.newPage();
  
  try {
    console.log('1. Quick login...');
    await page.goto('http://localhost:8080/Account/Login');
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    await page.waitForLoadState('networkidle');
    
    console.log('2. Go to profile and open modal...');
    await page.goto('http://localhost:8080/profile');
    await page.waitForTimeout(3000);
    await page.click('button:has-text("Edit Profile")');
    await page.waitForTimeout(2000);
    
    console.log('3. Checking if Bottts is selected...');
    // Check if bottts text is visible (it's already selected)
    const botttsText = await page.locator('text=bottts').count();
    console.log('   Bottts label visible:', botttsText > 0);
    
    console.log('4. Clicking Customize tab...');
    // Click the Customize tab
    const customizeTab = page.locator('.nav-link:has-text("Customize"), button:has-text("Customize")').first();
    if (await customizeTab.count() > 0) {
      await customizeTab.click();
      await page.waitForTimeout(3000); // Wait for customization options to load
      
      console.log('   ✓ Customize tab clicked\n');
      
      // Take screenshot of customize tab
      await page.screenshot({ path: 'texture-customize-tab.png' });
      console.log('5. Screenshot: texture-customize-tab.png\n');
      
      console.log('6. Looking for texture section...');
      // Check for texture label
      const textureLabel = await page.locator('label:has-text("Texture")').count();
      console.log('   Texture label found:', textureLabel > 0);
      
      // Scroll down to find texture section
      await page.evaluate(() => {
        const modal = document.querySelector('.modal-body');
        if (modal) modal.scrollTop = modal.scrollHeight;
      });
      await page.waitForTimeout(1000);
      
      // Count texture buttons
      const textureButtons = await page.locator('.texture-option-btn').all();
      console.log('   Texture option buttons:', textureButtons.length);
      
      if (textureButtons.length > 0) {
        console.log('\n7. Analyzing texture options:');
        
        for (let i = 0; i < Math.min(8, textureButtons.length); i++) {
          const btn = textureButtons[i];
          
          // Get label
          const label = await btn.locator('.option-label').textContent().catch(() => 'unknown');
          
          // Check for image
          const hasImage = await btn.locator('img.option-preview').count() > 0;
          const hasLoading = await btn.locator('.loading-preview').count() > 0;
          
          let previewType = 'No preview';
          if (hasImage) {
            const img = btn.locator('img.option-preview').first();
            const src = await img.getAttribute('src');
            if (src) {
              if (src.startsWith('data:image')) previewType = '✓ Robot image (data URL)';
              else if (src.includes('dicebear')) previewType = '✓ Robot image (DiceBear)';
              else previewType = '? Unknown image';
            }
          } else if (hasLoading) {
            previewType = '⏳ Loading...';
          }
          
          console.log(`   ${i + 1}. ${label}: ${previewType}`);
        }
        
        // Wait for previews to fully load
        console.log('\n8. Waiting for all previews to load...');
        await page.waitForTimeout(5000);
        
        // Re-check after loading
        const loadedImages = await page.locator('.texture-option-btn img.option-preview').count();
        console.log('   Robot previews now loaded:', loadedImages);
        
        // Take screenshot showing texture options
        await page.screenshot({ path: 'texture-options-loaded.png' });
        console.log('   Screenshot: texture-options-loaded.png\n');
        
        console.log('9. Testing texture selection:');
        
        // Test selecting textures
        const texturesToTest = ['circuits', 'dots', 'grunge01'];
        
        for (const textureName of texturesToTest) {
          const textureBtn = page.locator(`.texture-option-btn:has(.option-label:has-text("${textureName}"))`).first();
          
          if (await textureBtn.count() > 0) {
            console.log(`\n   Selecting "${textureName}"...`);
            await textureBtn.click();
            await page.waitForTimeout(2000);
            
            // Check if selected
            const isActive = await textureBtn.evaluate(el => el.classList.contains('active'));
            console.log(`   Active: ${isActive ? '✓' : '✗'}`);
            
            // Check main avatar
            const mainAvatar = await page.locator('.current-avatar img, img[alt*="Avatar"]').first();
            if (await mainAvatar.count() > 0) {
              const src = await mainAvatar.getAttribute('src');
              if (src && src.includes('texture')) {
                const match = src.match(/texture=([^&]*)/);
                console.log(`   Main avatar texture: ${match ? match[1] : 'not found'}`);
              }
            }
            
            await page.screenshot({ path: `texture-selected-${textureName}.png` });
            console.log(`   Screenshot: texture-selected-${textureName}.png`);
          } else {
            console.log(`   ✗ Could not find "${textureName}" button`);
          }
        }
        
        console.log('\n10. Final check - Are previews showing robots?');
        const allTextureImages = await page.locator('.texture-option-btn img.option-preview').all();
        if (allTextureImages.length > 0) {
          const firstImg = allTextureImages[0];
          const src = await firstImg.getAttribute('src');
          if (src && (src.startsWith('data:image/svg') || src.includes('bottts'))) {
            console.log('   ✅ SUCCESS: Texture previews are showing actual robots with textures!');
          } else {
            console.log('   ⚠️  Texture previews found but may not be robots');
          }
        } else {
          console.log('   ❌ FAIL: No texture preview images found');
        }
        
      } else {
        console.log('   ✗ No texture options found');
        
        // Debug: What's in the customize section?
        const customizeContent = await page.locator('.modal-body').textContent();
        console.log('\n   Customize tab content preview:');
        console.log('   ', customizeContent.substring(0, 500));
      }
      
    } else {
      console.log('   ✗ Could not find Customize tab');
    }
    
    await page.screenshot({ path: 'texture-test-final.png', fullPage: true });
    console.log('\n11. Final screenshot: texture-test-final.png');
    
  } catch (error) {
    console.log('\n❌ Error:', error.message);
  }
  
  console.log('\n=== Test Complete ===');
  console.log('Review the screenshots to verify the texture UI is working correctly.');
  
  await browser.close();
})();