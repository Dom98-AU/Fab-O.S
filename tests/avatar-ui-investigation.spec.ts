import { test, expect } from '@playwright/test';

test('Avatar UI Investigation', async ({ page }) => {
  // Navigate to the login page
  await page.goto('http://localhost:8080');
  
  // Wait for the page to load
  await page.waitForLoadState('networkidle');
  
  // Click Sign In button
  await page.click('text=Sign In');
  
  // Wait for login form
  await page.waitForSelector('input[name="Input.Email"]', { state: 'visible' });
  
  // Login
  await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
  await page.fill('input[name="Input.Password"]', 'Admin@123');
  await page.click('button[type="submit"]');
  
  // Wait for navigation to complete
  await page.waitForNavigation();
  
  // Navigate to profile page
  await page.goto('http://localhost:8080/profile');
  await page.waitForLoadState('networkidle');
  
  // Click Edit Profile button
  await page.click('text=Edit Profile');
  
  // Wait for modal to appear
  await page.waitForSelector('#avatarModal', { state: 'visible' });
  
  // Wait a moment for any dynamic content to load
  await page.waitForTimeout(2000);
  
  // Take screenshot
  await page.screenshot({ path: 'avatar-modal-screenshot.png', fullPage: true });
  
  // Get page content
  const pageContent = await page.content();
  console.log('=== PAGE HTML ===');
  console.log(pageContent);
  
  // Check for console errors
  const consoleMessages = [];
  page.on('console', msg => consoleMessages.push({ type: msg.type(), text: msg.text() }));
  
  // Get any console errors
  await page.evaluate(() => {
    console.log('Test log from page context');
  });
  
  // Check for specific elements
  const hasNavTabs = await page.locator('.nav-tabs').count() > 0;
  const hasTabContent = await page.locator('.tab-content').count() > 0;
  
  console.log('=== ELEMENT CHECKS ===');
  console.log('Has .nav-tabs:', hasNavTabs);
  console.log('Has .tab-content:', hasTabContent);
  
  // Check for avatar selector component
  const avatarSelectorExists = await page.locator('[data-component="enhanced-avatar-selector"]').count() > 0;
  console.log('Avatar selector component exists:', avatarSelectorExists);
  
  // Get inner HTML of modal body
  const modalBodyHtml = await page.locator('.modal-body').innerHTML();
  console.log('=== MODAL BODY HTML ===');
  console.log(modalBodyHtml);
  
  // Check for any error messages
  const errorMessages = await page.locator('.text-danger, .alert-danger').allTextContents();
  if (errorMessages.length > 0) {
    console.log('=== ERROR MESSAGES ===');
    console.log(errorMessages);
  }
  
  // Wait a bit more to capture any delayed console messages
  await page.waitForTimeout(1000);
  
  console.log('=== CONSOLE MESSAGES ===');
  console.log(consoleMessages);
});