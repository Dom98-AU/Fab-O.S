const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🚀 Testing Updated Avatar Modal...\n');
  
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
    
    console.log('🔍 Checking Modal Changes...');
    
    // Check modal width
    const modalDialog = await page.locator('.modal-dialog').first();
    const modalClasses = await modalDialog.getAttribute('class');
    console.log(`  Modal size class: ${modalClasses.includes('modal-xl') ? '✅ modal-xl (extra large)' : '❌ Not modal-xl'}`);
    
    // Check modal title
    const modalTitle = await page.locator('.modal-title').first().textContent();
    console.log(`  Modal title: "${modalTitle}" ${modalTitle.includes('Choose Your Avatar') ? '✅' : '❌'}`);
    
    // Check for removed fields
    const jobTitleField = await page.locator('label:has-text("Job Title")').count();
    const departmentField = await page.locator('label:has-text("Department")').count();
    const bioField = await page.locator('label:has-text("Bio")').count();
    const skillsField = await page.locator('label:has-text("Skills")').count();
    const privacySection = await page.locator('h6:has-text("Privacy Settings")').count();
    
    console.log('\n📋 Removed Fields Check:');
    console.log(`  Job Title field: ${jobTitleField === 0 ? '✅ Removed' : '❌ Still present'}`);
    console.log(`  Department field: ${departmentField === 0 ? '✅ Removed' : '❌ Still present'}`);
    console.log(`  Bio field: ${bioField === 0 ? '✅ Removed' : '❌ Still present'}`);
    console.log(`  Skills field: ${skillsField === 0 ? '✅ Removed' : '❌ Still present'}`);
    console.log(`  Privacy settings: ${privacySection === 0 ? '✅ Removed' : '❌ Still present'}`);
    
    // Check avatar selector presence
    const avatarSelector = await page.locator('.avatar-selector').count();
    console.log(`\n🎭 Avatar selector present: ${avatarSelector > 0 ? '✅' : '❌'}`);
    
    // Check tabbed UI
    const typeTab = await page.locator('.nav-link:has-text("Type")').count();
    const customizeTab = await page.locator('.nav-link:has-text("Customize")').count();
    console.log(`  Type tab: ${typeTab > 0 ? '✅' : '❌'}`);
    console.log(`  Customize tab: ${customizeTab > 0 ? '✅' : '❌'}`);
    
    // Get modal dimensions
    const modalBounds = await modalDialog.boundingBox();
    if (modalBounds) {
      console.log(`\n📐 Modal dimensions: ${modalBounds.width}px × ${modalBounds.height}px`);
    }
    
    // Take screenshot
    await page.screenshot({ path: 'avatar-modal-updated.png', fullPage: true });
    console.log('\n📸 Screenshot saved: avatar-modal-updated.png');
    
    console.log('\n✅ Modal update test complete!');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    await page.screenshot({ path: 'avatar-modal-error.png' });
  }
  
  console.log('\nBrowser will remain open for 30 seconds for inspection...');
  await page.waitForTimeout(30000);
  await browser.close();
})();