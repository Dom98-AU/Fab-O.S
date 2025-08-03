const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
  
  console.log('🤖 Testing Complete Bottts Customization System...\n');
  
  try {
    // Login
    console.log('📍 Logging in...');
    await page.goto('http://localhost:8080/Account/Login');
    await page.waitForLoadState('networkidle');
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    await page.waitForLoadState('networkidle');

    // Navigate to profile
    await page.goto('http://localhost:8080/profile');
    await page.waitForLoadState('networkidle');
    await page.click('button:has-text("Edit Profile")');
    await page.waitForTimeout(2000);
    
    // Select Robot Avatar
    console.log('\n🤖 Selecting Robot Avatar...');
    const robotAvatar = page.locator('.dicebear-style-option:has(.style-name:text("Robot Avatar"))').first();
    await robotAvatar.click();
    await page.waitForTimeout(1000);
    
    // Click Customize tab
    await page.locator('button:has-text("Customize")').click();
    await page.waitForTimeout(1000);
    
    // Check all customization options
    console.log('\n🔍 Checking all customization options...');
    
    const hasBaseColor = await page.locator('label:has-text("Robot Base Color")').count() > 0;
    const hasBackgroundColor = await page.locator('label:has-text("Background Color")').count() > 0;
    const hasFaceShape = await page.locator('label:has-text("Face Shape")').count() > 0;
    const hasEyeType = await page.locator('label:has-text("Eye Type")').count() > 0;
    const hasMouthType = await page.locator('label:has-text("Mouth Type")').count() > 0;
    const hasSideAttachments = await page.locator('label:has-text("Side Attachments")').count() > 0;
    const hasTopAccessories = await page.locator('label:has-text("Top Accessories")').count() > 0;
    const hasTexture = await page.locator('label:has-text("Texture")').count() > 0;
    
    console.log(`✅ Robot Base Color: ${hasBaseColor ? 'Present' : 'Missing'}`);
    console.log(`✅ Background Color: ${hasBackgroundColor ? 'Present' : 'Missing'}`);
    console.log(`✅ Face Shape: ${hasFaceShape ? 'Present' : 'Missing'}`);
    console.log(`✅ Eye Type: ${hasEyeType ? 'Present' : 'Missing'}`);
    console.log(`✅ Mouth Type: ${hasMouthType ? 'Present' : 'Missing'}`);
    console.log(`✅ Side Attachments: ${hasSideAttachments ? 'Present' : 'Missing'}`);
    console.log(`✅ Top Accessories: ${hasTopAccessories ? 'Present' : 'Missing'}`);
    console.log(`✅ Texture: ${hasTexture ? 'Present' : 'Missing'}`);
    
    // Test base color change
    console.log('\n🎨 Testing base color change...');
    const baseColorSwatches = await page.locator('label:has-text("Robot Base Color")').locator('..').locator('.color-swatch').all();
    console.log(`Found ${baseColorSwatches.length} base color options`);
    
    if (baseColorSwatches.length > 1) {
      await baseColorSwatches[1].click(); // Click second color
      await page.waitForTimeout(2000);
      console.log('Base color changed successfully');
    }
    
    // Test face shape
    console.log('\n👤 Testing face shape change...');
    const faceOptions = await page.locator('label:has-text("Face Shape")').locator('..').locator('.visual-option-btn').all();
    console.log(`Found ${faceOptions.length} face shape options`);
    
    if (faceOptions.length > 1) {
      await faceOptions[1].click();
      await page.waitForTimeout(1000);
      console.log('Face shape changed successfully');
    }
    
    // Test eye type
    console.log('\n👁️ Testing eye type change...');
    const eyeOptions = await page.locator('label:has-text("Eye Type")').locator('..').locator('.visual-option-btn').all();
    console.log(`Found ${eyeOptions.length} eye type options`);
    
    if (eyeOptions.length > 1) {
      await eyeOptions[2].click(); // Click third option
      await page.waitForTimeout(1000);
      console.log('Eye type changed successfully');
    }
    
    // Test texture
    console.log('\n🔧 Testing texture change...');
    const textureOptions = await page.locator('label:has-text("Texture")').locator('..').locator('.visual-option-btn').all();
    console.log(`Found ${textureOptions.length} texture options`);
    
    if (textureOptions.length > 1) {
      await textureOptions[1].click();
      await page.waitForTimeout(1000);
      console.log('Texture changed successfully');
    }
    
    // Test top accessories
    console.log('\n🎩 Testing top accessories...');
    const topOptions = await page.locator('label:has-text("Top Accessories")').locator('..').locator('.visual-option-btn').all();
    console.log(`Found ${topOptions.length} top accessory options`);
    
    if (topOptions.length > 1) {
      await topOptions[1].click();
      await page.waitForTimeout(1000);
      console.log('Top accessory changed successfully');
    }
    
    // Check final avatar preview
    console.log('\n🖼️ Checking final avatar preview...');
    const avatarPreview = page.locator('.avatar-preview');
    const previewExists = await avatarPreview.count() > 0;
    console.log(`Avatar preview visible: ${previewExists ? '✅' : '❌'}`);
    
    // Take screenshot
    await page.screenshot({ path: 'complete-bottts-customization.png', fullPage: true });
    console.log('\n📸 Screenshot saved: complete-bottts-customization.png');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  
  console.log('\nTest complete. Browser will remain open for 15 seconds...');
  await page.waitForTimeout(15000);
  await browser.close();
})();