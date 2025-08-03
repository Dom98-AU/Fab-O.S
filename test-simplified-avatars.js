const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
  
  console.log('🎭 Testing Simplified Avatar System (Bottts & Initials only)...\n');
  
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
    
    // Check available avatar types
    console.log('\n🔍 Checking available avatar types...');
    const avatarOptions = await page.locator('.dicebear-style-option').all();
    console.log(`Found ${avatarOptions.length} avatar types`);
    
    for (let i = 0; i < avatarOptions.length; i++) {
      const name = await avatarOptions[i].locator('.style-name').textContent();
      console.log(`  ${i + 1}. ${name}`);
    }
    
    // Test Bottts
    console.log('\n🤖 Testing Robot Avatar (Bottts)...');
    await avatarOptions[0].click();
    await page.waitForTimeout(1000);
    
    // Check if Customize tab is enabled
    const customizeTab = page.locator('button:has-text("Customize")');
    const isDisabled = await customizeTab.getAttribute('disabled');
    console.log(`Customize tab enabled: ${isDisabled === null ? '✅' : '❌'}`);
    
    // Click Customize tab
    await customizeTab.click();
    await page.waitForTimeout(1000);
    
    // Check Bottts customization options
    const botttsOptions = await page.locator('.customization-section').filter({ hasText: 'Customize Your Avatar' });
    const hasEyeOptions = await page.locator('label:has-text("Eye Type")').count() > 0;
    const hasColorOptions = await page.locator('label:has-text("Primary Color")').count() > 0;
    console.log(`Has eye customization: ${hasEyeOptions ? '✅' : '❌'}`);
    console.log(`Has color customization: ${hasColorOptions ? '✅' : '❌'}`);
    
    // Test Initials
    console.log('\n📝 Testing Text Initials...');
    await page.locator('button:has-text("Type")').click();
    await page.waitForTimeout(1000);
    await avatarOptions[1].click();
    await page.waitForTimeout(1000);
    
    // Click Customize tab again
    await customizeTab.click();
    await page.waitForTimeout(1000);
    
    // Check Initials customization
    const hasTextInput = await page.locator('input[placeholder*="initials"]').count() > 0;
    const hasFontSize = await page.locator('label:has-text("Font Size")').count() > 0;
    const hasFontFamily = await page.locator('label:has-text("Font Style")').count() > 0;
    console.log(`Has text input: ${hasTextInput ? '✅' : '❌'}`);
    console.log(`Has font size options: ${hasFontSize ? '✅' : '❌'}`);
    console.log(`Has font style options: ${hasFontFamily ? '✅' : '❌'}`);
    
    // Type some initials
    if (hasTextInput) {
      await page.fill('input[placeholder*="initials"]', 'JS');
      await page.waitForTimeout(1000);
      console.log('Entered initials: JS');
    }
    
    // Take screenshot
    await page.screenshot({ path: 'simplified-avatars.png', fullPage: true });
    console.log('\n📸 Screenshot saved: simplified-avatars.png');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  
  console.log('\nTest complete. Browser will remain open for 10 seconds...');
  await page.waitForTimeout(10000);
  await browser.close();
})();