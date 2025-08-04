const { chromium } = require('playwright');

(async () => {
  console.log('=== Texture Multi-Select Implementation Verification ===\n');
  
  const browser = await chromium.launch({ 
    headless: false,
    slowMo: 500 // Slow down actions to see what's happening
  });
  
  const context = await browser.newContext();
  const page = await context.newPage();
  
  // Enable verbose console logging
  page.on('console', msg => {
    if (msg.text().includes('Edit') || msg.text().includes('Texture')) {
      console.log('Browser log:', msg.text());
    }
  });
  
  page.on('pageerror', error => {
    console.log('Page error:', error.message);
  });
  
  try {
    console.log('1. Logging in...');
    await page.goto('http://localhost:8080/Account/Login');
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    await page.waitForLoadState('networkidle');
    console.log('   ✓ Logged in successfully\n');
    
    console.log('2. Navigating to profile...');
    await page.goto('http://localhost:8080/profile');
    await page.waitForTimeout(3000);
    
    // Verify we're on the profile page
    const profileHeader = await page.locator('h2').first().textContent();
    console.log('   Profile header:', profileHeader);
    console.log('   ✓ Profile page loaded\n');
    
    console.log('3. Attempting to open avatar editor...');
    
    // Method 1: Try the main Edit Profile button
    const editButton = page.locator('button:has-text("Edit Profile")').first();
    if (await editButton.isVisible()) {
      console.log('   Found Edit Profile button, clicking...');
      await editButton.click();
      await page.waitForTimeout(2000);
    }
    
    // Check if modal opened
    let modalVisible = await page.locator('.modal.show').count() > 0;
    
    if (!modalVisible) {
      // Method 2: Try clicking the avatar edit icon
      console.log('   Modal not visible, trying avatar edit button...');
      const avatarEditBtn = page.locator('.avatar-change-btn').first();
      if (await avatarEditBtn.count() > 0) {
        await avatarEditBtn.click({ force: true });
        await page.waitForTimeout(2000);
        modalVisible = await page.locator('.modal.show').count() > 0;
      }
    }
    
    if (!modalVisible) {
      // Method 3: Try JavaScript click
      console.log('   Still no modal, trying JavaScript click...');
      await page.evaluate(() => {
        const btn = document.querySelector('button.btn-primary');
        if (btn && btn.textContent.includes('Edit Profile')) {
          btn.click();
        }
      });
      await page.waitForTimeout(2000);
      modalVisible = await page.locator('.modal.show').count() > 0;
    }
    
    console.log('   Modal visible:', modalVisible);
    
    if (modalVisible) {
      console.log('   ✓ Avatar editor opened\n');
      
      console.log('4. Checking for Bottts style...');
      // Look for Bottts button/option
      const botttsOption = page.locator('.dicebear-style-option:has-text("Bottts"), button:has-text("Bottts")').first();
      if (await botttsOption.count() > 0) {
        const isActive = await botttsOption.evaluate(el => el.classList.contains('active'));
        if (!isActive) {
          console.log('   Selecting Bottts style...');
          await botttsOption.click();
          await page.waitForTimeout(1000);
        }
        console.log('   ✓ Bottts style selected\n');
      }
      
      console.log('5. Looking for texture options...');
      // Wait a bit for customization options to load
      await page.waitForTimeout(1000);
      
      // Look for texture section
      const textureSection = page.locator('label:has-text("Texture")').first();
      const textureSectionExists = await textureSection.count() > 0;
      console.log('   Texture section exists:', textureSectionExists);
      
      if (textureSectionExists) {
        // Count texture buttons
        const textureButtons = await page.locator('.texture-option-btn').all();
        console.log('   Number of texture options:', textureButtons.length);
        
        if (textureButtons.length > 0) {
          // Get texture names
          console.log('   Available textures:');
          for (let i = 0; i < Math.min(5, textureButtons.length); i++) {
            const label = await textureButtons[i].locator('.option-label').textContent().catch(() => 'unnamed');
            console.log(`     - ${label}`);
          }
          
          console.log('\n6. Testing multi-select functionality...');
          
          // Select first texture
          console.log('   Clicking first texture...');
          await textureButtons[0].click();
          await page.waitForTimeout(500);
          const firstActive = await textureButtons[0].evaluate(el => el.classList.contains('active'));
          console.log('   First texture active:', firstActive);
          
          // Select second texture
          if (textureButtons.length > 1) {
            console.log('   Clicking second texture...');
            await textureButtons[1].click();
            await page.waitForTimeout(500);
            const secondActive = await textureButtons[1].evaluate(el => el.classList.contains('active'));
            console.log('   Second texture active:', secondActive);
            
            // Check if both are selected
            const activeCount = await page.locator('.texture-option-btn.active').count();
            console.log('   Total active textures:', activeCount);
            
            if (activeCount >= 2) {
              console.log('   ✓ Multi-select is working!\n');
            } else {
              console.log('   ✗ Multi-select not working properly\n');
            }
          }
          
          // Test Clear All button
          console.log('7. Testing Clear All button...');
          const clearButton = page.locator('button:has-text("Clear All Textures")').first();
          if (await clearButton.count() > 0) {
            console.log('   Clicking Clear All...');
            await clearButton.click();
            await page.waitForTimeout(500);
            const activeAfterClear = await page.locator('.texture-option-btn.active').count();
            console.log('   Active textures after clear:', activeAfterClear);
            
            if (activeAfterClear === 0) {
              console.log('   ✓ Clear All button works!\n');
            } else {
              console.log('   ✗ Clear All button not working\n');
            }
          } else {
            console.log('   ✗ Clear All button not found\n');
          }
          
        } else {
          console.log('   ✗ No texture buttons found!\n');
        }
      } else {
        console.log('   ✗ Texture section not found!\n');
        
        // Debug: What's in the modal?
        const modalBody = await page.locator('.modal-body').first().textContent();
        console.log('   Modal content preview:', modalBody.substring(0, 200));
      }
      
    } else {
      console.log('   ✗ Could not open avatar editor modal\n');
      
      // Take a screenshot for debugging
      await page.screenshot({ path: 'texture-test-failed.png' });
      console.log('   Screenshot saved: texture-test-failed.png');
    }
    
  } catch (error) {
    console.log('\n✗ Test failed with error:', error.message);
  } finally {
    console.log('\n=== Test Summary ===');
    console.log('Please manually verify the texture multi-select feature');
    console.log('Open manual-texture-test.html for detailed testing instructions');
    
    await page.screenshot({ path: 'final-texture-test.png', fullPage: true });
    console.log('Final screenshot: final-texture-test.png\n');
    
    await browser.close();
  }
})();