import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

test.describe('Avatar Texture Display', () => {
  test('Verify texture options for Bottts avatar', async ({ page }) => {
    // Set longer timeout
    test.setTimeout(90000);
    
    console.log('Starting test...');
    
    // Navigate directly to login page
    await page.goto('http://localhost:8080/Identity/Account/Login', { 
      waitUntil: 'domcontentloaded',
      timeout: 30000 
    });
    
    console.log('On login page');
    
    // Fill login form
    await page.fill('input[id="Input_Email"]', 'admin@steelestimation.com');
    await page.fill('input[id="Input_Password"]', 'Admin@123');
    
    // Submit form
    await Promise.all([
      page.waitForNavigation({ waitUntil: 'domcontentloaded', timeout: 30000 }),
      page.click('button[type="submit"]')
    ]);
    
    console.log('Logged in successfully');
    
    // Navigate to profile/manage page
    await page.goto('http://localhost:8080/Identity/Account/Manage', { 
      waitUntil: 'domcontentloaded',
      timeout: 30000 
    });
    
    console.log('On profile page');
    
    // Create screenshots directory
    const screenshotsDir = path.join(process.cwd(), 'avatar-texture-screenshots');
    if (!fs.existsSync(screenshotsDir)) {
      fs.mkdirSync(screenshotsDir, { recursive: true });
    }
    
    // Take initial screenshot
    await page.screenshot({ 
      path: path.join(screenshotsDir, '01-profile-page.png'),
      fullPage: false 
    });
    
    // Look for Change Avatar button - try multiple selectors
    const changeAvatarSelectors = [
      'button:has-text("Change Avatar")',
      'button.btn-primary:has-text("Change")',
      '#changeAvatarBtn',
      'button[onclick*="avatar"]',
      'button[data-bs-toggle="modal"]'
    ];
    
    let changeAvatarButton = null;
    for (const selector of changeAvatarSelectors) {
      try {
        changeAvatarButton = await page.waitForSelector(selector, { timeout: 3000 });
        if (changeAvatarButton) {
          console.log(`Found Change Avatar button with selector: ${selector}`);
          break;
        }
      } catch (e) {
        continue;
      }
    }
    
    if (!changeAvatarButton) {
      // Take debug screenshot
      await page.screenshot({ 
        path: path.join(screenshotsDir, 'debug-no-avatar-button.png'),
        fullPage: true 
      });
      throw new Error('Could not find Change Avatar button');
    }
    
    // Click the button
    await changeAvatarButton.click();
    console.log('Clicked Change Avatar button');
    
    // Wait for modal
    await page.waitForSelector('.modal.show, .modal.fade.show, #avatarModal', { 
      state: 'visible',
      timeout: 10000 
    });
    
    console.log('Modal opened');
    
    // Take screenshot of modal
    await page.screenshot({ 
      path: path.join(screenshotsDir, '02-avatar-modal.png'),
      fullPage: false 
    });
    
    // Look for Bottts button - try multiple selectors
    const botttsSelectors = [
      'button[data-avatar-type="bottts"]',
      'button[onclick*="bottts"]',
      '.avatar-type-btn[data-type="bottts"]',
      'button:has-text("Bottts")',
      'button:has-text("Robot")'
    ];
    
    let botttsButton = null;
    for (const selector of botttsSelectors) {
      try {
        botttsButton = await page.waitForSelector(selector, { timeout: 3000 });
        if (botttsButton) {
          console.log(`Found Bottts button with selector: ${selector}`);
          break;
        }
      } catch (e) {
        continue;
      }
    }
    
    if (botttsButton) {
      await botttsButton.click();
      console.log('Selected Bottts avatar type');
      await page.waitForTimeout(1000);
    } else {
      console.log('Could not find Bottts button - continuing anyway');
    }
    
    // Look for Texture tab - try multiple selectors
    const textureTabSelectors = [
      'a[href="#texture"]',
      'button[data-bs-target="#texture"]',
      '.nav-link:has-text("Texture")',
      'a:has-text("Texture")',
      'button:has-text("Texture")'
    ];
    
    let textureTab = null;
    for (const selector of textureTabSelectors) {
      try {
        textureTab = await page.waitForSelector(selector, { timeout: 3000 });
        if (textureTab) {
          console.log(`Found Texture tab with selector: ${selector}`);
          break;
        }
      } catch (e) {
        continue;
      }
    }
    
    if (!textureTab) {
      // Take debug screenshot
      await page.screenshot({ 
        path: path.join(screenshotsDir, 'debug-no-texture-tab.png'),
        fullPage: true 
      });
      
      // List all visible tabs/buttons
      const visibleElements = await page.$$eval('a, button', elements => 
        elements.map(el => ({
          tag: el.tagName,
          text: el.textContent?.trim().substring(0, 50),
          href: el.getAttribute('href'),
          onclick: el.getAttribute('onclick')?.substring(0, 50)
        })).filter(el => el.text)
      );
      
      console.log('Visible interactive elements:', JSON.stringify(visibleElements, null, 2));
      
      throw new Error('Could not find Texture tab');
    }
    
    // Click texture tab
    await textureTab.click();
    console.log('Clicked Texture tab');
    await page.waitForTimeout(1000);
    
    // Take screenshot of texture tab
    await page.screenshot({ 
      path: path.join(screenshotsDir, '03-texture-tab.png'),
      fullPage: false 
    });
    
    // Expected textures
    const expectedTextures = [
      'camo01', 'camo02', 'circuits', 'dirty01',
      'dirty02', 'dots', 'grunge01', 'grunge02'
    ];
    
    console.log('\n=== Analyzing Texture Options ===\n');
    
    // Find all images in the texture tab area
    const textureImages = await page.$$('#texture img, .tab-pane.active img, .texture-option img');
    console.log(`Found ${textureImages.length} images in texture area`);
    
    const textureData = [];
    for (let i = 0; i < textureImages.length; i++) {
      const img = textureImages[i];
      const src = await img.getAttribute('src');
      
      if (src && src.includes('dicebear.com')) {
        // Extract texture parameter
        const textureMatch = src.match(/texture=([^&]+)/);
        const textureName = textureMatch ? textureMatch[1] : 'unknown';
        
        // Check if image is loaded
        const isLoaded = await img.evaluate((el: HTMLImageElement) => 
          el.complete && el.naturalHeight > 0
        );
        
        textureData.push({
          index: i + 1,
          texture: textureName,
          loaded: isLoaded,
          url: src.substring(0, 150)
        });
        
        console.log(`Image ${i + 1}:`);
        console.log(`  Texture: ${textureName}`);
        console.log(`  Loaded: ${isLoaded ? '✓' : '❌'}`);
        console.log(`  URL: ${src.substring(0, 100)}...`);
      }
    }
    
    // Verify all expected textures are present
    console.log('\n=== Texture Verification ===\n');
    for (const expectedTexture of expectedTextures) {
      const found = textureData.some(td => td.texture === expectedTexture);
      console.log(`${expectedTexture}: ${found ? '✓ Found' : '❌ Missing'}`);
    }
    
    // Check for distinct patterns
    const uniqueTextures = new Set(textureData.map(td => td.texture));
    console.log(`\nUnique textures: ${uniqueTextures.size}`);
    console.log(`All loaded: ${textureData.every(td => td.loaded) ? 'Yes' : 'No'}`);
    
    // Click on each texture option to verify selection works
    console.log('\n=== Testing Texture Selection ===\n');
    
    for (const textureName of expectedTextures) {
      // Try to find and click the texture
      const textureElement = await page.$(`[data-texture="${textureName}"], img[src*="texture=${textureName}"]`);
      
      if (textureElement) {
        // Get parent if it's an image
        const clickableElement = await textureElement.evaluateHandle((el) => {
          if (el.tagName === 'IMG') {
            return el.parentElement;
          }
          return el;
        });
        
        await clickableElement.asElement()?.click();
        await page.waitForTimeout(500);
        
        // Check if preview updated
        const previewImg = await page.$('.avatar-preview img, #avatarPreview, .modal img.rounded-circle');
        if (previewImg) {
          const previewSrc = await previewImg.getAttribute('src');
          if (previewSrc?.includes(`texture=${textureName}`)) {
            console.log(`${textureName}: ✓ Selection works`);
          } else {
            console.log(`${textureName}: ⚠ Selected but preview didn't update`);
          }
        }
        
        // Take screenshot of selected texture
        await page.screenshot({ 
          path: path.join(screenshotsDir, `texture-${textureName}.png`),
          fullPage: false 
        });
      } else {
        console.log(`${textureName}: ❌ Not found`);
      }
    }
    
    // Final summary screenshot
    await page.screenshot({ 
      path: path.join(screenshotsDir, '04-final-state.png'),
      fullPage: false 
    });
    
    console.log(`\n=== Test Complete ===`);
    console.log(`Screenshots saved to: ${screenshotsDir}`);
    
    // Assertions
    expect(textureImages.length).toBeGreaterThanOrEqual(8);
    expect(uniqueTextures.size).toBeGreaterThanOrEqual(8);
    expect(textureData.every(td => td.loaded)).toBeTruthy();
  });
});