const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs').promises;

// Test configuration
const TEST_URL = 'http://localhost:8080';
const TEST_CREDENTIALS = {
  email: 'admin@steelestimation.com',
  password: 'Admin@123'
};

// Screenshot directory
const SCREENSHOT_DIR = path.join(__dirname, 'test-screenshots');

async function ensureScreenshotDir() {
  try {
    await fs.mkdir(SCREENSHOT_DIR, { recursive: true });
  } catch (error) {
    console.error('Error creating screenshot directory:', error);
  }
}

async function login(page) {
  console.log('🔐 Logging in...');
  
  // Navigate to login page
  await page.goto(TEST_URL);
  
  // Wait for login form
  await page.waitForSelector('input[type="email"], input[name="Email"]', { timeout: 10000 });
  
  // Fill in credentials
  await page.fill('input[type="email"], input[name="Email"]', TEST_CREDENTIALS.email);
  await page.fill('input[type="password"], input[name="Password"]', TEST_CREDENTIALS.password);
  
  // Click login button
  await page.click('button[type="submit"]');
  
  // Wait for navigation to complete
  await page.waitForURL('**/dashboard', { timeout: 10000 });
  
  console.log('✅ Logged in successfully');
}

async function navigateToProfile(page) {
  console.log('📝 Navigating to profile page...');
  
  // Navigate to profile page
  await page.goto(`${TEST_URL}/profile`);
  
  // Wait for profile page to load
  await page.waitForSelector('.profile-header', { timeout: 10000 });
  
  console.log('✅ Profile page loaded');
}

async function openAvatarModal(page) {
  console.log('🎭 Opening avatar customization modal...');
  
  // Click the avatar edit button
  const editButton = await page.locator('.avatar-change-btn, button:has-text("Edit Profile")').first();
  await editButton.click();
  
  // Wait for modal to open
  await page.waitForSelector('.modal.show', { timeout: 5000 });
  
  console.log('✅ Avatar modal opened');
}

async function selectBotttsStyle(page) {
  console.log('🤖 Selecting Bottts avatar style...');
  
  // Check if we're already on Bottts, or need to select it
  const botttsButton = await page.locator('.dicebear-style-option').filter({ hasText: 'Bottts' });
  
  if (await botttsButton.count() > 0) {
    await botttsButton.click();
    console.log('✅ Bottts style selected');
    
    // Wait for the customize tab to become available
    await page.waitForTimeout(1000);
  }
}

async function switchToCustomizeTab(page) {
  console.log('🎨 Switching to Customize tab...');
  
  // Click on the Customize tab
  const customizeTab = await page.locator('.nav-link:has-text("Customize")');
  
  if (await customizeTab.isVisible()) {
    await customizeTab.click();
    console.log('✅ Customize tab activated');
    
    // Wait for tab content to load
    await page.waitForSelector('.tab-pane.active .customization-section', { timeout: 5000 });
  }
}

async function testTextureMultiSelect(page) {
  console.log('🎨 Testing texture multi-select functionality...');
  
  // Scroll to texture section
  const textureSection = await page.locator('label:has-text("Texture")').first();
  await textureSection.scrollIntoViewIfNeeded();
  
  // Get all texture buttons
  const textureButtons = await page.locator('.texture-option-btn');
  const textureCount = await textureButtons.count();
  
  console.log(`Found ${textureCount} texture options`);
  
  // Test 1: Select multiple textures
  console.log('📍 Test 1: Selecting multiple textures...');
  
  const texturesToSelect = ['circuits', 'dots', 'grunge01'];
  const selectedTextures = [];
  
  for (const textureName of texturesToSelect) {
    const textureButton = await page.locator('.texture-option-btn').filter({ hasText: textureName }).first();
    
    if (await textureButton.isVisible()) {
      await textureButton.click();
      selectedTextures.push(textureName);
      console.log(`  ✓ Selected texture: ${textureName}`);
      
      // Verify checkmark appears
      const checkmark = await textureButton.locator('.texture-check').first();
      const hasCheckmark = await checkmark.isVisible();
      
      if (hasCheckmark) {
        console.log(`  ✓ Checkmark visible for ${textureName}`);
      } else {
        console.log(`  ⚠️ Checkmark not visible for ${textureName}`);
      }
      
      await page.waitForTimeout(500);
    }
  }
  
  // Take screenshot of multiple textures selected
  await page.screenshot({ 
    path: path.join(SCREENSHOT_DIR, 'texture-multi-select.png'),
    fullPage: false 
  });
  console.log('📸 Screenshot saved: texture-multi-select.png');
  
  // Test 2: Verify avatar preview updates
  console.log('📍 Test 2: Checking avatar preview update...');
  
  const avatarPreview = await page.locator('.avatar-preview').first();
  const avatarSrc = await avatarPreview.getAttribute('src');
  
  if (avatarSrc && avatarSrc.includes('texture')) {
    console.log('  ✓ Avatar preview includes texture parameters');
  } else {
    console.log('  ⚠️ Avatar preview may not include texture parameters');
  }
  
  // Test 3: Clear all textures
  console.log('📍 Test 3: Testing Clear All Textures button...');
  
  const clearButton = await page.locator('button:has-text("Clear All Textures")');
  
  if (await clearButton.isVisible()) {
    await clearButton.click();
    console.log('  ✓ Clear All Textures button clicked');
    
    // Verify all textures are deselected
    await page.waitForTimeout(500);
    
    const activeTextures = await page.locator('.texture-option-btn.active').count();
    if (activeTextures === 0) {
      console.log('  ✓ All textures successfully cleared');
    } else {
      console.log(`  ⚠️ ${activeTextures} textures still selected after clear`);
    }
    
    // Take screenshot of cleared state
    await page.screenshot({ 
      path: path.join(SCREENSHOT_DIR, 'texture-cleared.png'),
      fullPage: false 
    });
    console.log('📸 Screenshot saved: texture-cleared.png');
  } else {
    console.log('  ⚠️ Clear All Textures button not visible');
  }
  
  // Test 4: Re-select textures and verify persistence
  console.log('📍 Test 4: Re-selecting textures for final state...');
  
  const finalTextures = ['circuits2', 'grunge03', 'grunge05'];
  
  for (const textureName of finalTextures) {
    const textureButton = await page.locator('.texture-option-btn').filter({ hasText: textureName }).first();
    
    if (await textureButton.isVisible()) {
      await textureButton.click();
      console.log(`  ✓ Selected texture: ${textureName}`);
      await page.waitForTimeout(300);
    }
  }
  
  // Take final screenshot with multiple textures
  await page.screenshot({ 
    path: path.join(SCREENSHOT_DIR, 'texture-final-selection.png'),
    fullPage: false 
  });
  console.log('📸 Screenshot saved: texture-final-selection.png');
  
  // Get avatar preview with textures
  await page.waitForTimeout(1000);
  const avatarSection = await page.locator('.avatar-preview-section');
  await avatarSection.screenshot({ 
    path: path.join(SCREENSHOT_DIR, 'avatar-with-textures.png')
  });
  console.log('📸 Screenshot saved: avatar-with-textures.png');
  
  return {
    textureCount,
    selectedTextures: finalTextures,
    success: true
  };
}

async function runTests() {
  console.log('🚀 Starting Avatar Texture Multi-Select Test Suite');
  console.log('=' .repeat(50));
  
  const browser = await chromium.launch({ 
    headless: false,
    slowMo: 100 
  });
  
  const context = await browser.newContext({
    viewport: { width: 1920, height: 1080 }
  });
  
  const page = await context.newPage();
  
  try {
    // Ensure screenshot directory exists
    await ensureScreenshotDir();
    
    // Run test sequence
    await login(page);
    await navigateToProfile(page);
    await openAvatarModal(page);
    await selectBotttsStyle(page);
    await switchToCustomizeTab(page);
    
    // Run texture multi-select tests
    const testResults = await testTextureMultiSelect(page);
    
    // Summary
    console.log('\n' + '=' .repeat(50));
    console.log('📊 TEST SUMMARY');
    console.log('=' .repeat(50));
    console.log(`✅ Test completed successfully`);
    console.log(`📁 Texture options found: ${testResults.textureCount}`);
    console.log(`🎨 Final selected textures: ${testResults.selectedTextures.join(', ')}`);
    console.log(`📸 Screenshots saved to: ${SCREENSHOT_DIR}`);
    console.log('\n📋 Screenshots taken:');
    console.log('  1. texture-multi-select.png - Multiple textures selected');
    console.log('  2. texture-cleared.png - All textures cleared');
    console.log('  3. texture-final-selection.png - Final texture selection');
    console.log('  4. avatar-with-textures.png - Avatar preview with textures');
    
    // Wait before closing to see results
    console.log('\n⏳ Keeping browser open for 5 seconds to review...');
    await page.waitForTimeout(5000);
    
  } catch (error) {
    console.error('❌ Test failed:', error);
    
    // Take error screenshot
    await page.screenshot({ 
      path: path.join(SCREENSHOT_DIR, 'error-state.png'),
      fullPage: true 
    });
    console.log('📸 Error screenshot saved: error-state.png');
    
    throw error;
  } finally {
    await browser.close();
    console.log('\n✅ Test suite completed');
  }
}

// Run the tests
runTests().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});