import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

test.describe('Avatar Texture Display Test', () => {
  test('Check texture display for Bottts avatar', async ({ page }) => {
    console.log('Starting avatar texture test...');
    
    // Set timeout for this test
    test.setTimeout(60000);
    
    // Navigate to the application
    console.log('Navigating to http://localhost:8080...');
    await page.goto('http://localhost:8080', { waitUntil: 'networkidle' });
    
    // Login
    console.log('Logging in...');
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    
    // Wait for login to complete
    await page.waitForURL('**/', { timeout: 10000 });
    console.log('Login successful');
    
    // Navigate to profile page
    console.log('Navigating to profile page...');
    await page.goto('http://localhost:8080/Identity/Account/Manage', { waitUntil: 'networkidle' });
    
    // Open avatar editor modal
    console.log('Opening avatar editor...');
    const changeAvatarButton = await page.waitForSelector('button:has-text("Change Avatar")', { timeout: 5000 });
    await changeAvatarButton.click();
    
    // Wait for modal to be visible
    await page.waitForSelector('.modal.show', { state: 'visible', timeout: 5000 });
    console.log('Modal opened');
    
    // Select Bottts avatar type
    console.log('Selecting Bottts avatar type...');
    const botttsButton = await page.waitForSelector('button[data-avatar-type="bottts"]', { timeout: 5000 });
    await botttsButton.click();
    
    // Wait a moment for the UI to update
    await page.waitForTimeout(1000);
    
    // Click on Texture tab
    console.log('Clicking on Texture tab...');
    const textureTab = await page.waitForSelector('a[href="#texture"]', { timeout: 5000 });
    await textureTab.click();
    
    // Wait for texture tab content to be visible
    await page.waitForSelector('#texture', { state: 'visible', timeout: 5000 });
    console.log('Texture tab opened');
    
    // Create screenshots directory
    const screenshotsDir = path.join(process.cwd(), 'avatar-texture-screenshots');
    if (!fs.existsSync(screenshotsDir)) {
      fs.mkdirSync(screenshotsDir, { recursive: true });
    }
    
    // Take screenshot of the texture tab
    const screenshotPath = path.join(screenshotsDir, 'texture-tab.png');
    await page.screenshot({ path: screenshotPath, fullPage: false });
    console.log(`Screenshot saved to: ${screenshotPath}`);
    
    // Define expected textures
    const expectedTextures = [
      'camo01', 'camo02', 'circuits', 'dirty01', 
      'dirty02', 'dots', 'grunge01', 'grunge02'
    ];
    
    console.log('\n=== Checking Texture Options ===\n');
    
    // Try to find texture options
    const textureOptions = await page.$$('.texture-option, [data-texture], button[onclick*="texture"]');
    console.log(`Found ${textureOptions.length} texture option elements`);
    
    // If no texture options found with those selectors, try to find images in the texture tab
    if (textureOptions.length === 0) {
      const textureImages = await page.$$('#texture img');
      console.log(`Found ${textureImages.length} images in texture tab`);
      
      for (let i = 0; i < textureImages.length; i++) {
        const img = textureImages[i];
        const src = await img.getAttribute('src');
        console.log(`Image ${i + 1}: ${src}`);
        
        // Check if it's a DiceBear URL with texture
        if (src && src.includes('dicebear.com')) {
          const textureMatch = src.match(/texture=([^&]+)/);
          if (textureMatch) {
            console.log(`  - Texture: ${textureMatch[1]}`);
          }
        }
      }
    } else {
      // Check each texture option found
      for (let i = 0; i < textureOptions.length; i++) {
        const option = textureOptions[i];
        
        // Try to get texture identifier
        const dataTexture = await option.getAttribute('data-texture');
        const onclick = await option.getAttribute('onclick');
        
        if (dataTexture) {
          console.log(`Option ${i + 1}: data-texture="${dataTexture}"`);
        } else if (onclick && onclick.includes('texture')) {
          const textureMatch = onclick.match(/texture['"]=?\s*['"]([\w]+)/);
          if (textureMatch) {
            console.log(`Option ${i + 1}: texture from onclick="${textureMatch[1]}"`);
          }
        }
        
        // Check for image within the option
        const img = await option.$('img');
        if (img) {
          const src = await img.getAttribute('src');
          if (src) {
            console.log(`  Image URL: ${src.substring(0, 100)}...`);
            
            // Verify it's a valid DiceBear URL
            if (src.includes('api.dicebear.com') && src.includes('bottts')) {
              console.log('  ✓ Valid DiceBear Bottts URL');
              
              // Check for texture parameter
              const textureMatch = src.match(/texture=([^&]+)/);
              if (textureMatch) {
                console.log(`  ✓ Has texture: ${textureMatch[1]}`);
              } else {
                console.log('  ❌ No texture parameter found');
              }
            }
          }
        }
      }
    }
    
    // Take a screenshot of each texture by clicking on it
    console.log('\n=== Testing Texture Selection ===\n');
    
    for (const textureName of expectedTextures) {
      console.log(`Testing texture: ${textureName}`);
      
      // Try multiple selectors to find the texture
      const selectors = [
        `[data-texture="${textureName}"]`,
        `button[onclick*="${textureName}"]`,
        `div[onclick*="${textureName}"]`,
        `img[src*="texture=${textureName}"]`
      ];
      
      let found = false;
      for (const selector of selectors) {
        const element = await page.$(selector);
        if (element) {
          console.log(`  Found with selector: ${selector}`);
          
          // Click on it if it's clickable
          const tagName = await element.evaluate(el => el.tagName.toLowerCase());
          if (tagName === 'button' || tagName === 'div') {
            await element.click();
            await page.waitForTimeout(500);
            
            // Check if preview updated
            const previewImg = await page.$('.avatar-preview img, #avatarPreview');
            if (previewImg) {
              const previewSrc = await previewImg.getAttribute('src');
              if (previewSrc && previewSrc.includes(`texture=${textureName}`)) {
                console.log('  ✓ Preview updated successfully');
              }
            }
          }
          
          found = true;
          break;
        }
      }
      
      if (!found) {
        console.log(`  ❌ Texture "${textureName}" not found`);
      }
    }
    
    // Final screenshot
    const finalScreenshotPath = path.join(screenshotsDir, 'texture-tab-final.png');
    await page.screenshot({ path: finalScreenshotPath, fullPage: false });
    console.log(`\nFinal screenshot saved to: ${finalScreenshotPath}`);
    
    console.log('\n=== Test Complete ===');
  });
});