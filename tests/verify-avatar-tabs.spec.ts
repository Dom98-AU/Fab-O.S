import { test, expect } from '@playwright/test';

test('Verify Avatar Tabs Render', async ({ page }) => {
  console.log('Starting avatar tabs verification...');
  
  // Navigate to home and sign in
  await page.goto('http://localhost:8080');
  await page.waitForLoadState('networkidle');
  
  // Click Sign In
  await page.click('text=Sign In');
  await page.waitForLoadState('networkidle');
  
  // Login
  await page.fill('input[type="email"]', 'admin@steelestimation.com');
  await page.fill('input[type="password"]', 'Admin@123');
  await page.click('button[type="submit"]');
  
  // Wait for navigation
  await page.waitForURL('**/dashboard', { timeout: 10000 });
  console.log('Logged in successfully');
  
  // Navigate to profile
  await page.goto('http://localhost:8080/profile');
  await page.waitForLoadState('networkidle');
  
  // Click Edit Profile
  await page.click('text=Edit Profile');
  
  // Wait for modal
  await page.waitForSelector('#avatarModal', { state: 'visible' });
  await page.waitForTimeout(1000); // Let component fully render
  
  // Take screenshot
  await page.screenshot({ path: 'avatar-tabs-fixed.png', fullPage: true });
  
  // Check for tab elements
  const navTabs = await page.locator('.nav-tabs').count();
  const tabButtons = await page.locator('.nav-tabs button').count();
  const tabContent = await page.locator('.tab-content').count();
  const tabPanes = await page.locator('.tab-pane').count();
  
  console.log('=== TAB STRUCTURE ===');
  console.log('Nav tabs found:', navTabs);
  console.log('Tab buttons found:', tabButtons);
  console.log('Tab content found:', tabContent);
  console.log('Tab panes found:', tabPanes);
  
  // Check tab text
  const typeTabExists = await page.locator('text=Type').count() > 0;
  const customizeTabExists = await page.locator('text=Customize').count() > 0;
  
  console.log('Type tab exists:', typeTabExists);
  console.log('Customize tab exists:', customizeTabExists);
  
  // Check if tabs are clickable
  if (tabButtons > 0) {
    // Click Type tab
    await page.click('.nav-tabs button:has-text("Type")');
    await page.waitForTimeout(500);
    
    // Check if Type tab content is visible
    const typeTabActive = await page.locator('.tab-pane.show.active').count() > 0;
    console.log('Type tab content active:', typeTabActive);
    
    // Select an avatar style to enable Customize tab
    const avatarStyles = await page.locator('.dicebear-style-option').count();
    console.log('Avatar styles found:', avatarStyles);
    
    if (avatarStyles > 0) {
      // Click first avatar style
      await page.locator('.dicebear-style-option').first().click();
      await page.waitForTimeout(1000);
      
      // Check if Customize tab is now enabled
      const customizeTabEnabled = await page.locator('.nav-tabs button:has-text("Customize"):not([disabled])').count() > 0;
      console.log('Customize tab enabled after style selection:', customizeTabEnabled);
      
      // Take final screenshot
      await page.screenshot({ path: 'avatar-tabs-with-style.png', fullPage: true });
    }
  }
  
  // Get modal HTML for debugging
  const modalHtml = await page.locator('.modal-content').innerHTML();
  console.log('=== MODAL HTML (first 500 chars) ===');
  console.log(modalHtml.substring(0, 500) + '...');
});