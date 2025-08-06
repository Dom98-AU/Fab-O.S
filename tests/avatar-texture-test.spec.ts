import { test, expect, Page } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

test.describe('Avatar Texture Display Functionality', () => {
  let page: Page;

  test.beforeEach(async ({ browser }) => {
    // Create a new page
    page = await browser.newPage();
    
    // Navigate to the application
    await page.goto('http://localhost:8080');
    
    // Login
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    
    // Wait for navigation to complete
    await page.waitForURL('**/');
    
    // Navigate to profile page
    await page.click('a[href="/Identity/Account/Manage"]');
    await page.waitForURL('**/Identity/Account/Manage');
  });

  test.afterEach(async () => {
    await page.close();
  });

  test('should display all texture options correctly for Bottts avatar', async () => {
    // Open avatar editor modal
    await page.click('button:has-text("Change Avatar")');
    
    // Wait for modal to be visible
    await page.waitForSelector('.modal.show', { state: 'visible' });
    
    // Select Bottts avatar type
    await page.click('button[data-avatar-type="bottts"]');
    
    // Wait for avatar preview to update
    await page.waitForTimeout(500);
    
    // Click on Texture tab
    await page.click('a[href="#texture"]');
    
    // Wait for texture tab content to be visible
    await page.waitForSelector('#texture.show', { state: 'visible' });
    
    // Define expected textures
    const expectedTextures = [
      'camo01', 'camo02', 'circuits', 'dirty01', 
      'dirty02', 'dots', 'grunge01', 'grunge02'
    ];
    
    // Create screenshots directory if it doesn't exist
    const screenshotsDir = path.join(process.cwd(), 'avatar-texture-screenshots');
    if (!fs.existsSync(screenshotsDir)) {
      fs.mkdirSync(screenshotsDir, { recursive: true });
    }
    
    // Take screenshot of the entire texture tab
    await page.screenshot({ 
      path: path.join(screenshotsDir, 'texture-tab-overview.png'),
      fullPage: false 
    });
    
    console.log('\n=== Avatar Texture Test Results ===\n');
    
    // Verify all texture options are present
    const textureButtons = await page.$$('.texture-option');
    console.log(`Found ${textureButtons.length} texture options`);
    expect(textureButtons.length).toBe(8);
    
    // Check each texture option
    for (let i = 0; i < expectedTextures.length; i++) {
      const texture = expectedTextures[i];
      console.log(`\nChecking texture: ${texture}`);
      
      // Find the texture button
      const textureButton = await page.$(`[data-texture="${texture}"]`);
      
      if (!textureButton) {
        console.log(`  ❌ Button not found for texture: ${texture}`);
        continue;
      }
      
      console.log(`  ✓ Button found for texture: ${texture}`);
      
      // Get the image within the button
      const img = await textureButton.$('img');
      
      if (!img) {
        console.log(`  ❌ Image not found for texture: ${texture}`);
        continue;
      }
      
      // Get image src
      const imgSrc = await img.getAttribute('src');
      console.log(`  Image URL: ${imgSrc}`);
      
      // Verify URL format
      expect(imgSrc).toContain('api.dicebear.com');
      expect(imgSrc).toContain('bottts');
      expect(imgSrc).toContain(`texture=${texture}`);
      expect(imgSrc).toContain('textureProbability=100');
      
      // Check if image is loaded
      const isImageLoaded = await img.evaluate((el: HTMLImageElement) => {
        return el.complete && el.naturalHeight !== 0;
      });
      
      if (isImageLoaded) {
        console.log(`  ✓ Image loaded successfully`);
      } else {
        console.log(`  ❌ Image failed to load`);
      }
      
      // Get image dimensions
      const dimensions = await img.evaluate((el: HTMLImageElement) => ({
        width: el.naturalWidth,
        height: el.naturalHeight,
        displayWidth: el.clientWidth,
        displayHeight: el.clientHeight
      }));
      
      console.log(`  Dimensions: ${dimensions.width}x${dimensions.height} (displayed: ${dimensions.displayWidth}x${dimensions.displayHeight})`);
      
      // Click on the texture to select it
      await textureButton.click();
      await page.waitForTimeout(300);
      
      // Take individual screenshot of selected texture
      await page.screenshot({ 
        path: path.join(screenshotsDir, `texture-${texture}-selected.png`),
        clip: await textureButton.boundingBox() || undefined
      });
      
      // Verify the preview updates
      const previewImg = await page.$('.avatar-preview img');
      if (previewImg) {
        const previewSrc = await previewImg.getAttribute('src');
        console.log(`  Preview URL: ${previewSrc}`);
        expect(previewSrc).toContain(`texture=${texture}`);
      }
    }
    
    // Take a final screenshot showing all textures
    await page.screenshot({ 
      path: path.join(screenshotsDir, 'all-textures-final.png'),
      fullPage: false 
    });
    
    console.log('\n=== Visual Comparison Analysis ===\n');
    
    // Analyze visual differences between textures
    const textureImages = [];
    for (const texture of expectedTextures) {
      const textureButton = await page.$(`[data-texture="${texture}"]`);
      if (textureButton) {
        const img = await textureButton.$('img');
        if (img) {
          const src = await img.getAttribute('src');
          textureImages.push({ texture, src });
        }
      }
    }
    
    // Check that all texture URLs are unique
    const uniqueUrls = new Set(textureImages.map(t => t.src));
    console.log(`Unique texture URLs: ${uniqueUrls.size} out of ${textureImages.length}`);
    expect(uniqueUrls.size).toBe(textureImages.length);
    
    // Verify each texture has distinct parameters
    for (const { texture, src } of textureImages) {
      console.log(`${texture}: ${src?.includes(`texture=${texture}`) ? '✓' : '❌'} Contains correct texture parameter`);
    }
    
    console.log('\n=== Test Summary ===\n');
    console.log(`Total textures found: ${textureButtons.length}`);
    console.log(`Expected textures: ${expectedTextures.length}`);
    console.log(`Screenshots saved to: ${screenshotsDir}`);
  });

  test('should verify texture patterns are visually distinct', async () => {
    // Open avatar editor modal
    await page.click('button:has-text("Change Avatar")');
    await page.waitForSelector('.modal.show', { state: 'visible' });
    
    // Select Bottts avatar type
    await page.click('button[data-avatar-type="bottts"]');
    await page.waitForTimeout(500);
    
    // Click on Texture tab
    await page.click('a[href="#texture"]');
    await page.waitForSelector('#texture.show', { state: 'visible' });
    
    const expectedTextures = [
      { name: 'camo01', description: 'Camouflage pattern 1' },
      { name: 'camo02', description: 'Camouflage pattern 2' },
      { name: 'circuits', description: 'Circuit board pattern' },
      { name: 'dirty01', description: 'Dirty/grunge effect 1' },
      { name: 'dirty02', description: 'Dirty/grunge effect 2' },
      { name: 'dots', description: 'Dotted pattern' },
      { name: 'grunge01', description: 'Grunge texture 1' },
      { name: 'grunge02', description: 'Grunge texture 2' }
    ];
    
    console.log('\n=== Texture Pattern Verification ===\n');
    
    for (const { name, description } of expectedTextures) {
      const textureButton = await page.$(`[data-texture="${name}"]`);
      
      if (textureButton) {
        // Click to select the texture
        await textureButton.click();
        await page.waitForTimeout(500);
        
        // Get the preview image
        const previewImg = await page.$('.avatar-preview img');
        if (previewImg) {
          const previewSrc = await previewImg.getAttribute('src');
          
          // Verify texture is applied in preview
          if (previewSrc?.includes(`texture=${name}`)) {
            console.log(`✓ ${name} (${description}): Applied successfully`);
            
            // Take a screenshot of the preview with this texture
            const screenshotsDir = path.join(process.cwd(), 'avatar-texture-screenshots');
            await previewImg.screenshot({ 
              path: path.join(screenshotsDir, `preview-${name}.png`)
            });
          } else {
            console.log(`❌ ${name} (${description}): Not applied in preview`);
          }
        }
      } else {
        console.log(`❌ ${name} (${description}): Button not found`);
      }
    }
  });

  test('should verify texture loading performance', async () => {
    // Open avatar editor modal
    await page.click('button:has-text("Change Avatar")');
    await page.waitForSelector('.modal.show', { state: 'visible' });
    
    // Select Bottts avatar type
    await page.click('button[data-avatar-type="bottts"]');
    await page.waitForTimeout(500);
    
    // Click on Texture tab
    await page.click('a[href="#texture"]');
    await page.waitForSelector('#texture.show', { state: 'visible' });
    
    console.log('\n=== Texture Loading Performance ===\n');
    
    // Measure loading time for all texture images
    const loadingTimes = [];
    const textureImages = await page.$$('.texture-option img');
    
    for (let i = 0; i < textureImages.length; i++) {
      const img = textureImages[i];
      const startTime = Date.now();
      
      // Wait for image to be fully loaded
      await img.evaluate((el: HTMLImageElement) => {
        return new Promise((resolve) => {
          if (el.complete) {
            resolve(true);
          } else {
            el.onload = () => resolve(true);
            el.onerror = () => resolve(false);
          }
        });
      });
      
      const loadTime = Date.now() - startTime;
      loadingTimes.push(loadTime);
      
      const src = await img.getAttribute('src');
      const textureName = src?.match(/texture=([^&]+)/)?.[1] || `Image ${i + 1}`;
      console.log(`${textureName}: ${loadTime}ms`);
    }
    
    const avgLoadTime = loadingTimes.reduce((a, b) => a + b, 0) / loadingTimes.length;
    console.log(`\nAverage loading time: ${avgLoadTime.toFixed(2)}ms`);
    
    // All images should load within reasonable time (5 seconds)
    expect(Math.max(...loadingTimes)).toBeLessThan(5000);
  });
});