import { test, expect } from '@playwright/test';

test('Manual Avatar Check', async ({ page }) => {
  // Set a longer timeout for manual testing
  test.setTimeout(60000);
  
  console.log('Starting manual avatar check...');
  
  // Navigate directly to the Steel Estimation login
  await page.goto('http://localhost:8080/Identity/Account/Login');
  await page.waitForLoadState('networkidle');
  
  // Take screenshot of whatever loads
  await page.screenshot({ path: 'direct-login-page.png' });
  
  // Check if we're on a login page
  const hasEmailInput = await page.locator('input[name="Input.Email"]').count() > 0;
  console.log('Has email input:', hasEmailInput);
  
  if (hasEmailInput) {
    // Fill login form
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    
    // Wait for navigation
    await page.waitForLoadState('networkidle');
    await page.screenshot({ path: 'after-login.png' });
    
    // Navigate to profile
    await page.goto('http://localhost:8080/profile');
    await page.waitForLoadState('networkidle');
    await page.screenshot({ path: 'profile-page.png' });
    
    // Look for Edit Profile button
    const editProfileButton = await page.locator('button:has-text("Edit Profile")').count();
    console.log('Edit Profile button found:', editProfileButton);
    
    if (editProfileButton > 0) {
      // Click Edit Profile
      await page.click('button:has-text("Edit Profile")');
      await page.waitForTimeout(2000); // Wait for modal to appear
      
      // Take screenshot of modal
      await page.screenshot({ path: 'avatar-modal-after-fix.png', fullPage: true });
      
      // Check for tabs
      const navTabs = await page.locator('.nav-tabs').count();
      const typeTab = await page.locator('.nav-tabs button:has-text("Type")').count();
      const customizeTab = await page.locator('.nav-tabs button:has-text("Customize")').count();
      
      console.log('=== TAB VERIFICATION ===');
      console.log('.nav-tabs found:', navTabs);
      console.log('Type tab found:', typeTab);
      console.log('Customize tab found:', customizeTab);
      
      // Check tab content structure
      const tabContent = await page.locator('.tab-content').count();
      const tabPanes = await page.locator('.tab-pane').count();
      
      console.log('.tab-content found:', tabContent);
      console.log('.tab-pane found:', tabPanes);
      
      // Get the HTML of the avatar selector component
      const avatarSelectorHtml = await page.locator('.avatar-selector').innerHTML();
      console.log('=== AVATAR SELECTOR HTML (first 1000 chars) ===');
      console.log(avatarSelectorHtml.substring(0, 1000));
    }
  } else {
    console.log('Login page not found at expected URL');
    const pageUrl = page.url();
    console.log('Current URL:', pageUrl);
  }
});