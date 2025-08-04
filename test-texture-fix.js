const { chromium } = require('playwright');

(async () => {
  console.log('=== Testing Fixed Texture UI Implementation ===\n');
  
  const browser = await chromium.launch({ 
    headless: false,
    slowMo: 300
  });
  
  const context = await browser.newContext();
  const page = await context.newPage();
  
  // Capture console errors
  page.on('console', msg => {
    if (msg.type() === 'error') {
      console.log('❌ Browser error:', msg.text());
    }
  });
  
  try {
    console.log('1. Logging in...');
    await page.goto('http://localhost:8080/Account/Login', { timeout: 10000 });
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    await page.waitForLoadState('networkidle');
    console.log('   ✓ Logged in\n');
    
    console.log('2. Navigating to profile...');
    await page.goto('http://localhost:8080/profile');
    await page.waitForTimeout(5000); // Wait for page to fully load
    
    // Take screenshot of profile page
    await page.screenshot({ path: 'test-1-profile.png' });
    console.log('   ✓ Profile loaded (screenshot: test-1-profile.png)\n');
    
    console.log('3. Opening avatar editor...');
    // Try multiple methods to open modal
    let modalOpened = false;
    
    // Method 1: Click Edit Profile button
    const editBtn = page.locator('button:has-text("Edit Profile")').first();
    if (await editBtn.isVisible()) {
      console.log('   Clicking Edit Profile button...');
      await editBtn.click();
      await page.waitForTimeout(3000);
      modalOpened = await page.locator('.modal.show, .modal.fade.show').count() > 0;
    }
    
    if (!modalOpened) {
      // Method 2: Try avatar edit button
      console.log('   Trying avatar edit button...');
      const avatarBtn = page.locator('.avatar-change-btn').first();
      if (await avatarBtn.count() > 0) {
        await avatarBtn.click({ force: true });
        await page.waitForTimeout(3000);
        modalOpened = await page.locator('.modal.show, .modal.fade.show').count() > 0;
      }
    }
    
    if (!modalOpened) {
      // Method 3: JavaScript click
      console.log('   Trying JavaScript click...');
      await page.evaluate(() => {
        const buttons = Array.from(document.querySelectorAll('button'));
        const editButton = buttons.find(b => b.textContent && b.textContent.includes('Edit Profile'));
        if (editButton) {
          editButton.click();
          return true;
        }
        return false;
      });
      await page.waitForTimeout(3000);
      modalOpened = await page.locator('.modal.show, .modal.fade.show').count() > 0;
    }
    
    console.log('   Modal opened:', modalOpened);
    
    if (modalOpened) {
      await page.screenshot({ path: 'test-2-modal-opened.png' });
      console.log('   ✓ Modal opened (screenshot: test-2-modal-opened.png)\n');
      
      console.log('4. Selecting Bottts avatar style...');
      // Look for Bottts option
      const botttsSelectors = [
        'button:has-text("Bottts")',
        '.dicebear-style-option:has-text("Bottts")',
        'button.dicebear-style-option:has-text("Bottts")'
      ];
      
      let botttsFound = false;
      for (const selector of botttsSelectors) {
        const bottts = page.locator(selector).first();
        if (await bottts.count() > 0) {
          console.log('   Found Bottts with selector:', selector);
          const isActive = await bottts.evaluate(el => el.classList.contains('active'));
          if (!isActive) {
            await bottts.click();
            await page.waitForTimeout(2000);
          }
          botttsFound = true;
          break;
        }
      }
      
      if (botttsFound) {
        console.log('   ✓ Bottts style selected\n');
        
        console.log('5. Checking texture options...');
        await page.waitForTimeout(2000); // Wait for previews to load
        
        // Look for texture section
        const textureLabel = await page.locator('label:has-text("Texture")').count();
        console.log('   Texture label found:', textureLabel > 0);
        
        // Count texture option buttons
        const textureButtons = await page.locator('.texture-option-btn').all();
        console.log('   Number of texture options:', textureButtons.length);
        
        if (textureButtons.length > 0) {
          console.log('\n6. Checking texture previews...');
          
          // Check for robot previews in texture options
          const textureImages = await page.locator('.texture-option-btn img.option-preview').all();
          console.log('   Texture options with robot previews:', textureImages.length);
          
          // Check for loading spinners (if previews are still loading)
          const loadingPreviews = await page.locator('.texture-option-btn .loading-preview').count();
          console.log('   Loading previews:', loadingPreviews);
          
          // Get texture names
          console.log('\n   Available textures:');
          for (let i = 0; i < textureButtons.length; i++) {
            const labelElement = await textureButtons[i].locator('.option-label').first();
            const label = await labelElement.textContent().catch(() => null);
            
            // Check if this texture has an image preview
            const hasImage = await textureButtons[i].locator('img.option-preview').count() > 0;
            const hasLoading = await textureButtons[i].locator('.loading-preview').count() > 0;
            
            console.log(`     ${i + 1}. ${label || 'unnamed'} - Preview: ${hasImage ? '✓ Robot image' : hasLoading ? '⏳ Loading' : '✗ No preview'}`);
          }
          
          // Wait a bit more for all previews to load
          console.log('\n   Waiting for all previews to load...');
          await page.waitForTimeout(5000);
          
          // Re-check after waiting
          const loadedImages = await page.locator('.texture-option-btn img.option-preview').count();
          console.log('   Robot previews loaded:', loadedImages, 'of', textureButtons.length);
          
          await page.screenshot({ path: 'test-3-texture-options.png' });
          console.log('   Screenshot: test-3-texture-options.png\n');
          
          console.log('7. Testing texture selection...');
          if (textureButtons.length >= 3) {
            // Test selecting different textures
            const texturesToTest = Math.min(3, textureButtons.length);
            
            for (let i = 0; i < texturesToTest; i++) {
              const label = await textureButtons[i].locator('.option-label').textContent().catch(() => `Texture ${i + 1}`);
              console.log(`\n   Testing texture: ${label}`);
              
              await textureButtons[i].click();
              await page.waitForTimeout(1500);
              
              // Check if this texture is now active
              const isActive = await textureButtons[i].evaluate(el => el.classList.contains('active'));
              console.log(`     Active: ${isActive ? '✓' : '✗'}`);
              
              // Check main avatar preview updated
              const mainAvatar = await page.locator('.avatar-preview img, .current-avatar img').first();
              if (await mainAvatar.count() > 0) {
                const src = await mainAvatar.getAttribute('src');
                const hasTexture = src && src.includes(`texture=${label}`);
                console.log(`     Main avatar has ${label}: ${hasTexture ? '✓' : '✗'}`);
              }
              
              await page.screenshot({ path: `test-4-texture-${i + 1}.png` });
              console.log(`     Screenshot: test-4-texture-${i + 1}.png`);
            }
          }
          
          console.log('\n8. Checking texture preview quality...');
          // Verify that texture previews are actual robot images
          const firstTextureImg = await page.locator('.texture-option-btn img.option-preview').first();
          if (await firstTextureImg.count() > 0) {
            const imgSrc = await firstTextureImg.getAttribute('src');
            if (imgSrc) {
              const isDataUrl = imgSrc.startsWith('data:image');
              const isDiceBearUrl = imgSrc.includes('dicebear') || imgSrc.includes('api.dicebear.com');
              console.log('   Preview image type:');
              console.log('     Is data URL:', isDataUrl ? '✓' : '✗');
              console.log('     Is DiceBear URL:', isDiceBearUrl ? '✓' : '✗');
              
              if (isDataUrl || isDiceBearUrl) {
                console.log('   ✓ Texture previews are showing actual robot images!');
              } else {
                console.log('   ✗ Texture previews may not be showing robots');
              }
            }
          }
          
        } else {
          console.log('   ✗ No texture options found\n');
          
          // Debug: Check what's visible in the modal
          const modalText = await page.locator('.modal-body').textContent();
          console.log('   Modal content preview:', modalText.substring(0, 300));
        }
        
      } else {
        console.log('   ✗ Could not find/select Bottts style\n');
      }
      
    } else {
      console.log('   ✗ Could not open modal\n');
      
      // Debug info
      const pageTitle = await page.title();
      console.log('   Page title:', pageTitle);
      const buttons = await page.locator('button').count();
      console.log('   Total buttons on page:', buttons);
    }
    
    // Final full page screenshot
    await page.screenshot({ path: 'test-final-full.png', fullPage: true });
    console.log('\n9. Final screenshot: test-final-full.png');
    
  } catch (error) {
    console.log('\n❌ Test error:', error.message);
    await page.screenshot({ path: 'test-error.png' });
  }
  
  console.log('\n=== Test Summary ===');
  console.log('Check the screenshots to verify:');
  console.log('1. test-1-profile.png - Profile page loaded');
  console.log('2. test-2-modal-opened.png - Avatar editor modal');
  console.log('3. test-3-texture-options.png - Texture options with robot previews');
  console.log('4. test-4-texture-*.png - Different textures selected');
  console.log('5. test-final-full.png - Final state');
  
  await browser.close();
})();