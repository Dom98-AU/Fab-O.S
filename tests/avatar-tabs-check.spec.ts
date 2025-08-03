import { test, expect } from '@playwright/test';

test('Avatar Tabs Check', async ({ page }) => {
  // Navigate to home
  await page.goto('http://localhost:8080');
  await page.waitForLoadState('networkidle');
  
  // Take screenshot of home page
  await page.screenshot({ path: 'home-page.png' });
  
  // Click Sign In if present
  const signInButton = await page.locator('text=Sign In').count();
  if (signInButton > 0) {
    console.log('Found Sign In button, clicking...');
    await page.click('text=Sign In');
    await page.waitForLoadState('networkidle');
    await page.screenshot({ path: 'after-signin-click.png' });
  }
  
  // Check current URL
  console.log('Current URL:', page.url());
  
  // Check for login form elements
  const emailInputs = await page.locator('input[type="email"], input[name*="email" i], input[name*="Email" i]').count();
  const passwordInputs = await page.locator('input[type="password"], input[name*="password" i]').count();
  
  console.log('Email inputs found:', emailInputs);
  console.log('Password inputs found:', passwordInputs);
  
  if (emailInputs > 0 && passwordInputs > 0) {
    // Fill login form
    await page.locator('input[type="email"], input[name*="email" i], input[name*="Email" i]').first().fill('admin@steelestimation.com');
    await page.locator('input[type="password"], input[name*="password" i]').first().fill('Admin@123');
    
    // Find and click submit button
    await page.locator('button[type="submit"], input[type="submit"]').first().click();
    
    // Wait for navigation
    await page.waitForLoadState('networkidle');
    console.log('After login URL:', page.url());
    await page.screenshot({ path: 'after-login-attempt.png' });
    
    // Try to navigate to profile
    await page.goto('http://localhost:8080/profile');
    await page.waitForLoadState('networkidle');
    await page.screenshot({ path: 'profile-attempt.png' });
    
    // Check if we're on profile page
    const profileElements = await page.locator('text=/edit profile/i').count();
    console.log('Profile elements found:', profileElements);
    
    if (profileElements > 0) {
      // Click Edit Profile
      await page.locator('text=/edit profile/i').first().click();
      await page.waitForTimeout(2000);
      
      // Take screenshot of modal
      await page.screenshot({ path: 'avatar-modal-open.png', fullPage: true });
      
      // Check for tabs
      const navTabs = await page.locator('.nav-tabs').count();
      const tabContent = await page.locator('.tab-content').count();
      const avatarComponent = await page.locator('[data-component="enhanced-avatar-selector"]').count();
      
      console.log('=== TAB STRUCTURE CHECK ===');
      console.log('.nav-tabs found:', navTabs);
      console.log('.tab-content found:', tabContent);
      console.log('Avatar component found:', avatarComponent);
      
      // Get modal HTML
      const modalExists = await page.locator('.modal-content').count() > 0;
      if (modalExists) {
        const modalHtml = await page.locator('.modal-content').innerHTML();
        console.log('=== MODAL HTML (first 1000 chars) ===');
        console.log(modalHtml.substring(0, 1000));
      }
      
      // Check for any Blazor errors
      const blazorErrors = await page.locator('.blazor-error-ui').count();
      if (blazorErrors > 0) {
        const errorText = await page.locator('.blazor-error-ui').textContent();
        console.log('=== BLAZOR ERRORS ===');
        console.log(errorText);
      }
    }
  }
  
  // Get page HTML for debugging
  const pageHtml = await page.content();
  console.log('=== FULL PAGE LENGTH ===');
  console.log('Page HTML length:', pageHtml.length);
});