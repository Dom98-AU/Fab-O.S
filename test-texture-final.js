const { chromium } = require('playwright');

(async () => {
  console.log('=== Final Texture UI Test ===\n');
  
  const browser = await chromium.launch({ 
    headless: false,
    slowMo: 500
  });
  
  const page = await browser.newPage();
  
  try {
    console.log('1. Fresh login...');
    await page.goto('http://localhost:8080/Account/Login');
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    await page.waitForLoadState('networkidle');
    console.log('   ✓ Logged in\n');
    
    console.log('2. Navigate to profile immediately...');
    await page.goto('http://localhost:8080/profile');
    await page.waitForTimeout(2000);
    
    // Close any existing modals first
    const closeButtons = await page.locator('.modal.show .btn-close, .modal.show button:has-text("Cancel")').all();
    for (const btn of closeButtons) {
      await btn.click().catch(() => {});
    }
    await page.waitForTimeout(1000);
    
    console.log('3. Opening avatar editor (trying multiple methods)...');
    
    // Method 1: Click main Edit Profile button
    let modalOpened = false;
    const editProfileBtn = page.locator('button.btn-primary:has-text("Edit Profile")').first();
    if (await editProfileBtn.isVisible()) {
      console.log('   Clicking Edit Profile button...');
      await editProfileBtn.click();
      await page.waitForTimeout(3000);
      
      // Check if correct modal opened
      const modalTitle = await page.locator('.modal-title').textContent().catch(() => '');
      console.log('   Modal title:', modalTitle);
      
      if (modalTitle.includes('Avatar') || modalTitle.includes('Choose')) {
        modalOpened = true;
        console.log('   ✓ Avatar editor opened!\n');
      } else if (modalTitle.includes('Session') || modalTitle.includes('Timeout')) {
        console.log('   Session timeout modal appeared, closing it...');
        // Close timeout modal
        await page.locator('.modal.show button:has-text("Cancel")').click().catch(() => {});
        await page.waitForTimeout(1000);
        
        // Try opening avatar editor again
        await editProfileBtn.click();
        await page.waitForTimeout(3000);
        const newTitle = await page.locator('.modal-title').textContent().catch(() => '');
        if (newTitle.includes('Avatar') || newTitle.includes('Choose')) {
          modalOpened = true;
          console.log('   ✓ Avatar editor opened on second try!\n');
        }
      }
    }
    
    if (!modalOpened) {
      // Method 2: Try clicking avatar edit button
      console.log('   Trying avatar edit button...');
      const avatarBtn = page.locator('.avatar-change-btn').first();
      if (await avatarBtn.count() > 0) {
        await avatarBtn.click({ force: true });
        await page.waitForTimeout(3000);
        const title = await page.locator('.modal-title').textContent().catch(() => '');
        if (title.includes('Avatar') || title.includes('Choose')) {
          modalOpened = true;
          console.log('   ✓ Avatar editor opened via avatar button!\n');
        }
      }
    }
    
    if (modalOpened) {
      await page.screenshot({ path: 'texture-1-modal.png' });
      console.log('4. Modal screenshot: texture-1-modal.png\n');
      
      console.log('5. Looking for avatar style options...');
      // Check if we're on the style selection page
      const styleOptions = await page.locator('.dicebear-style-option').count();
      console.log('   Style options found:', styleOptions);
      
      if (styleOptions > 0) {
        // We're on style selection, select Bottts
        const botttsOption = page.locator('.dicebear-style-option:has-text("Bottts"), .dicebear-style-option:has-text("bottts")').first();
        if (await botttsOption.count() > 0) {
          console.log('   Selecting Bottts style...');
          await botttsOption.click();
          await page.waitForTimeout(2000);
        }
      }
      
      // Check if tabs exist
      const tabs = await page.locator('.nav-tabs .nav-link').all();
      console.log('   Tabs found:', tabs.length);
      
      if (tabs.length > 0) {
        for (const tab of tabs) {
          const text = await tab.textContent();
          console.log('     -', text.trim());
        }
        
        // Click Customize tab if it exists
        const customizeTab = page.locator('.nav-link:has-text("Customize")').first();
        if (await customizeTab.count() > 0) {
          console.log('\n6. Clicking Customize tab...');
          await customizeTab.click();
          await page.waitForTimeout(3000);
        }
      }
      
      console.log('\n7. Looking for texture customization...');
      
      // Scroll to find texture section
      await page.evaluate(() => {
        const modal = document.querySelector('.modal-body');
        if (modal) {
          // Scroll in steps to trigger lazy loading
          modal.scrollTop = modal.scrollHeight / 3;
        }
      });
      await page.waitForTimeout(1000);
      
      // Check for texture elements
      const textureLabel = await page.locator('label:has-text("Texture")').count();
      console.log('   Texture label found:', textureLabel > 0);
      
      const textureButtons = await page.locator('.texture-option-btn').all();
      console.log('   Texture option buttons:', textureButtons.length);
      
      if (textureButtons.length > 0) {
        console.log('\n8. Analyzing texture options:');
        
        // Wait for images to load
        await page.waitForTimeout(3000);
        
        for (let i = 0; i < Math.min(8, textureButtons.length); i++) {
          const btn = textureButtons[i];
          const label = await btn.locator('.option-label').textContent().catch(() => 'unknown');
          const hasImage = await btn.locator('img.option-preview').count() > 0;
          const hasLoading = await btn.locator('.loading-preview').count() > 0;
          
          if (hasImage) {
            console.log(`   ✓ ${label}: Robot preview loaded`);
          } else if (hasLoading) {
            console.log(`   ⏳ ${label}: Loading...`);
          } else {
            console.log(`   ✗ ${label}: No preview`);
          }
        }
        
        // Wait more for all previews
        console.log('\n   Waiting for all previews to load...');
        await page.waitForTimeout(5000);
        
        // Take screenshot
        await page.screenshot({ path: 'texture-2-options.png' });
        console.log('   Screenshot: texture-2-options.png\n');
        
        // Test selection
        console.log('9. Testing texture selection:');
        if (textureButtons.length >= 3) {
          for (let i = 0; i < 3; i++) {
            const btn = textureButtons[i];
            const label = await btn.locator('.option-label').textContent().catch(() => `Texture ${i}`);
            
            console.log(`   Selecting: ${label}`);
            await btn.click();
            await page.waitForTimeout(2000);
            
            const isActive = await btn.evaluate(el => el.classList.contains('active'));
            console.log(`   Active: ${isActive ? '✓' : '✗'}`);
            
            await page.screenshot({ path: `texture-3-selected-${i}.png` });
          }
        }
        
        console.log('\n10. Final verification:');
        const robotPreviews = await page.locator('.texture-option-btn img.option-preview').count();
        if (robotPreviews > 0) {
          console.log('   ✅ SUCCESS: Texture options showing robot previews!');
          
          // Check one image source
          const firstImg = page.locator('.texture-option-btn img.option-preview').first();
          const src = await firstImg.getAttribute('src');
          if (src) {
            if (src.startsWith('data:image/svg')) {
              console.log('   ✅ Images are SVG data URLs (correct!)');
            } else if (src.includes('dicebear')) {
              console.log('   ✅ Images are from DiceBear API (correct!)');
            }
          }
        } else {
          console.log('   ❌ No robot previews found in texture options');
        }
        
      } else {
        console.log('   ✗ No texture options found\n');
        
        // Debug what's visible
        const visibleText = await page.locator('.modal-body').textContent();
        console.log('   Modal content preview:', visibleText.substring(0, 400));
      }
      
    } else {
      console.log('   ❌ Could not open avatar editor modal\n');
    }
    
    await page.screenshot({ path: 'texture-4-final.png', fullPage: true });
    console.log('\n11. Final screenshot: texture-4-final.png');
    
  } catch (error) {
    console.log('\n❌ Error:', error.message);
  }
  
  console.log('\n=== Test Summary ===');
  console.log('Check screenshots:');
  console.log('- texture-1-modal.png: Avatar editor modal');
  console.log('- texture-2-options.png: Texture options with robot previews');
  console.log('- texture-3-selected-*.png: Different textures selected');
  console.log('- texture-4-final.png: Final state');
  
  await browser.close();
})();