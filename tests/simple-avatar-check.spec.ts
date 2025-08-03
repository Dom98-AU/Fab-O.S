import { test, expect } from '@playwright/test';

test('Simple Avatar Check', async ({ page }) => {
  console.log('Starting test...');
  
  // Navigate directly to login page
  await page.goto('http://localhost:8080/Identity/Account/Login');
  
  // Take screenshot of login page
  await page.screenshot({ path: 'login-page.png' });
  
  // Check what's on the page
  const pageTitle = await page.title();
  console.log('Page title:', pageTitle);
  
  const pageContent = await page.content();
  console.log('Page content length:', pageContent.length);
  
  // Check for specific elements
  const hasEmailInput = await page.locator('input[name="Input.Email"]').count() > 0;
  const hasPasswordInput = await page.locator('input[name="Input.Password"]').count() > 0;
  
  console.log('Has email input:', hasEmailInput);
  console.log('Has password input:', hasPasswordInput);
  
  if (hasEmailInput && hasPasswordInput) {
    // Try to login
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    await page.click('button[type="submit"]');
    
    // Wait for navigation
    await page.waitForLoadState('networkidle');
    
    // Take screenshot after login
    await page.screenshot({ path: 'after-login.png' });
    
    // Navigate to profile
    await page.goto('http://localhost:8080/profile');
    await page.waitForLoadState('networkidle');
    
    // Take screenshot of profile page
    await page.screenshot({ path: 'profile-page.png' });
    
    // Try to find Edit Profile button
    const editProfileButton = await page.locator('text=Edit Profile').count();
    console.log('Edit Profile button count:', editProfileButton);
    
    if (editProfileButton > 0) {
      await page.click('text=Edit Profile');
      await page.waitForTimeout(2000);
      await page.screenshot({ path: 'avatar-modal.png' });
      
      // Check for tab elements
      const navTabs = await page.locator('.nav-tabs').count();
      const tabContent = await page.locator('.tab-content').count();
      console.log('Nav tabs count:', navTabs);
      console.log('Tab content count:', tabContent);
      
      // Get modal content
      const modalContent = await page.locator('.modal-content').innerHTML();
      console.log('Modal content:', modalContent.substring(0, 500) + '...');
    }
  }
});