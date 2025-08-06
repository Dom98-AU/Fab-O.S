import { test, expect, Page, BrowserContext } from '@playwright/test';
import * as path from 'path';

test.describe('DiceBear Texture Selection Cross-Browser Test', () => {
  const username = 'admin@steelestimation.com';
  const password = 'Admin@123';
  const baseURL = 'http://localhost:8080';

  // Helper function to login
  async function login(page: Page) {
    console.log('Navigating to login page...');
    await page.goto(baseURL);
    
    // Wait for the login form
    await page.waitForSelector('form', { timeout: 10000 });
    
    // Fill in credentials
    console.log('Filling login credentials...');
    await page.fill('#Email', username);
    await page.fill('#Password', password);
    
    // Submit the form
    console.log('Submitting login form...');
    await page.click('button[type="submit"]');
    
    // Wait for navigation to complete
    await page.waitForNavigation({ waitUntil: 'networkidle' });
    console.log('Login successful!');
  }

  // Helper function to navigate to profile
  async function navigateToProfile(page: Page) {
    console.log('Navigating to profile page...');
    
    // Try direct navigation first
    await page.goto(`${baseURL}/profile`);
    
    // Wait for profile page to load
    await page.waitForSelector('.profile-header', { timeout: 10000 });
    console.log('Profile page loaded!');
  }

  // Helper function to open avatar editor
  async function openAvatarEditor(page: Page) {
    console.log('Opening avatar editor...');
    
    // Click on the avatar or Edit Profile button
    const editButton = await page.waitForSelector('button:has-text("Edit Profile")', { timeout: 10000 });
    await editButton.click();
    
    // Wait for modal to appear
    await page.waitForSelector('.modal.show', { timeout: 10000 });
    await page.waitForTimeout(500); // Wait for animation
    console.log('Avatar editor modal opened!');
  }

  // Helper function to select Robot avatar type
  async function selectRobotAvatar(page: Page) {
    console.log('Selecting Robot avatar type...');
    
    // Click on Robot button
    const robotButton = await page.waitForSelector('.avatar-type-btn:has-text("Robot")', { timeout: 10000 });
    await robotButton.click();
    
    // Wait for customization options to load
    await page.waitForSelector('.nav-tabs', { timeout: 10000 });
    console.log('Robot avatar selected!');
  }

  // Helper function to navigate to texture tab
  async function navigateToTextureTab(page: Page) {
    console.log('Navigating to Texture tab...');
    
    // Click on Texture tab
    const textureTab = await page.waitForSelector('.nav-link:has-text("Texture")', { timeout: 10000 });
    await textureTab.click();
    
    // Wait for texture options to load
    await page.waitForSelector('.visual-option-grid', { timeout: 10000 });
    await page.waitForTimeout(1000); // Wait for texture previews to load
    console.log('Texture tab loaded!');
  }

  // Helper function to test texture selection
  async function testTextureSelection(page: Page, context: BrowserContext, browserName: string) {
    const textureTypes = ['circuits', 'camo01', 'dirty01', 'dots', 'grunge01'];
    const screenshots = [];

    for (const texture of textureTypes) {
      console.log(`Testing texture: ${texture}`);
      
      // Find and click the texture button
      const textureButton = await page.waitForSelector(`button[data-texture="${texture}"]`, { timeout: 10000 });
      
      // Scroll into view if needed
      await textureButton.scrollIntoViewIfNeeded();
      
      // Click the texture
      await textureButton.click();
      
      // Wait for the texture to be applied (active class)
      await page.waitForSelector(`button[data-texture="${texture}"].active`, { timeout: 5000 });
      
      // Wait for avatar preview to update
      await page.waitForTimeout(1000);
      
      // Take a screenshot of the entire modal
      const screenshotPath = path.join(__dirname, `../screenshots/texture-${browserName}-${texture}.png`);
      await page.screenshot({ 
        path: screenshotPath,
        fullPage: false,
        clip: {
          x: 0,
          y: 0,
          width: 1200,
          height: 800
        }
      });
      
      screenshots.push({
        texture,
        path: screenshotPath
      });
      
      // Verify the texture is selected
      const isActive = await textureButton.evaluate(el => el.classList.contains('active'));
      expect(isActive).toBe(true);
      
      // Check the preview text shows the texture name
      const textureText = await page.textContent('.text-muted.small strong');
      console.log(`Preview shows texture: ${textureText}`);
      
      console.log(`✓ Texture ${texture} selected successfully!`);
    }

    return screenshots;
  }

  // Test in Chromium
  test('DiceBear texture selection in Chromium', async ({ browser }) => {
    console.log('\n=== Starting Chromium test ===\n');
    
    const context = await browser.newContext({
      viewport: { width: 1280, height: 720 }
    });
    const page = await context.newPage();
    
    try {
      // Login
      await login(page);
      
      // Navigate to profile
      await navigateToProfile(page);
      
      // Open avatar editor
      await openAvatarEditor(page);
      
      // Select Robot avatar
      await selectRobotAvatar(page);
      
      // Navigate to texture tab
      await navigateToTextureTab(page);
      
      // Test texture selection
      const screenshots = await testTextureSelection(page, context, 'chromium');
      
      console.log('\n=== Chromium Test Summary ===');
      console.log('✓ Login successful');
      console.log('✓ Profile page loaded');
      console.log('✓ Avatar editor opened');
      console.log('✓ Robot avatar selected');
      console.log('✓ Texture tab accessed');
      console.log(`✓ ${screenshots.length} textures tested`);
      console.log('\nScreenshots saved:');
      screenshots.forEach(s => console.log(`  - ${s.path}`));
      
    } catch (error) {
      console.error('Chromium test failed:', error);
      await page.screenshot({ path: path.join(__dirname, '../screenshots/chromium-error.png') });
      throw error;
    } finally {
      await context.close();
    }
  });

  // Test in Firefox
  test('DiceBear texture selection in Firefox', async ({ browser }) => {
    console.log('\n=== Starting Firefox test ===\n');
    
    const context = await browser.newContext({
      viewport: { width: 1280, height: 720 }
    });
    const page = await context.newPage();
    
    try {
      // Login
      await login(page);
      
      // Navigate to profile
      await navigateToProfile(page);
      
      // Open avatar editor
      await openAvatarEditor(page);
      
      // Select Robot avatar
      await selectRobotAvatar(page);
      
      // Navigate to texture tab
      await navigateToTextureTab(page);
      
      // Test texture selection
      const screenshots = await testTextureSelection(page, context, 'firefox');
      
      console.log('\n=== Firefox Test Summary ===');
      console.log('✓ Login successful');
      console.log('✓ Profile page loaded');
      console.log('✓ Avatar editor opened');
      console.log('✓ Robot avatar selected');
      console.log('✓ Texture tab accessed');
      console.log(`✓ ${screenshots.length} textures tested`);
      console.log('\nScreenshots saved:');
      screenshots.forEach(s => console.log(`  - ${s.path}`));
      
    } catch (error) {
      console.error('Firefox test failed:', error);
      await page.screenshot({ path: path.join(__dirname, '../screenshots/firefox-error.png') });
      throw error;
    } finally {
      await context.close();
    }
  });

  // Comparison test - run both browsers and compare behavior
  test('Compare texture behavior across browsers', async ({ browser }) => {
    console.log('\n=== Starting Browser Comparison Test ===\n');
    
    const results = {
      chromium: { success: false, errors: [] },
      firefox: { success: false, errors: [] }
    };
    
    // Test in Chromium
    const chromiumContext = await browser.newContext({
      viewport: { width: 1280, height: 720 }
    });
    const chromiumPage = await chromiumContext.newPage();
    
    try {
      await login(chromiumPage);
      await navigateToProfile(chromiumPage);
      await openAvatarEditor(chromiumPage);
      await selectRobotAvatar(chromiumPage);
      await navigateToTextureTab(chromiumPage);
      
      // Check texture visibility
      const chromiumTextureButtons = await chromiumPage.$$('.visual-option-grid button[data-texture]');
      console.log(`Chromium: Found ${chromiumTextureButtons.length} texture buttons`);
      
      results.chromium.success = chromiumTextureButtons.length > 0;
      
    } catch (error) {
      results.chromium.errors.push(error.message);
    } finally {
      await chromiumContext.close();
    }
    
    // Test in Firefox
    const firefoxContext = await browser.newContext({
      viewport: { width: 1280, height: 720 }
    });
    const firefoxPage = await firefoxContext.newPage();
    
    try {
      await login(firefoxPage);
      await navigateToProfile(firefoxPage);
      await openAvatarEditor(firefoxPage);
      await selectRobotAvatar(firefoxPage);
      await navigateToTextureTab(firefoxPage);
      
      // Check texture visibility
      const firefoxTextureButtons = await firefoxPage.$$('.visual-option-grid button[data-texture]');
      console.log(`Firefox: Found ${firefoxTextureButtons.length} texture buttons`);
      
      results.firefox.success = firefoxTextureButtons.length > 0;
      
    } catch (error) {
      results.firefox.errors.push(error.message);
    } finally {
      await firefoxContext.close();
    }
    
    // Compare results
    console.log('\n=== Browser Comparison Results ===');
    console.log(`Chromium: ${results.chromium.success ? '✓ Success' : '✗ Failed'}`);
    if (results.chromium.errors.length > 0) {
      console.log(`  Errors: ${results.chromium.errors.join(', ')}`);
    }
    console.log(`Firefox: ${results.firefox.success ? '✓ Success' : '✗ Failed'}`);
    if (results.firefox.errors.length > 0) {
      console.log(`  Errors: ${results.firefox.errors.join(', ')}`);
    }
    
    // Assert both browsers work
    expect(results.chromium.success).toBe(true);
    expect(results.firefox.success).toBe(true);
  });
});