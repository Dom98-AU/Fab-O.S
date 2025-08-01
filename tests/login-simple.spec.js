const { test, expect } = require('@playwright/test');

test('can reach login page', async ({ page }) => {
  try {
    // Try to navigate to the login page with a 5 second timeout
    await page.goto('http://localhost:8080/Account/Login', { 
      waitUntil: 'domcontentloaded',
      timeout: 5000 
    });
    
    // Check if we got a response
    const title = await page.title();
    console.log('Page title:', title);
    
    // Simple check that we loaded something
    expect(title).toBeTruthy();
  } catch (error) {
    console.error('Error accessing login page:', error.message);
    throw error;
  }
});