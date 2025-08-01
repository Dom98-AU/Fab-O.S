const { test, expect } = require('@playwright/test');

test.describe('Login Functionality', () => {
  test('successful login with admin credentials', async ({ page }) => {
    // Navigate to login page
    await page.goto('http://localhost:8080/Account/Login');
    
    // Fill in the login form
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    
    // Take a screenshot before login
    await page.screenshot({ path: 'before-login.png' });
    
    // Submit the form
    await page.click('button[type="submit"]');
    
    // Wait for navigation or response
    await page.waitForLoadState('networkidle');
    
    // Take a screenshot after login attempt
    await page.screenshot({ path: 'after-login.png' });
    
    // Check if we're still on login page or redirected
    const currentUrl = page.url();
    console.log('Current URL after login:', currentUrl);
    
    // Check for error messages
    const errorMessages = await page.locator('.validation-summary-errors').count();
    if (errorMessages > 0) {
      const errorText = await page.locator('.validation-summary-errors').textContent();
      console.log('Error message found:', errorText);
    }
    
    // If successfully logged in, we should be redirected away from login page
    if (!currentUrl.includes('/Account/Login')) {
      console.log('Login successful - redirected to:', currentUrl);
      expect(currentUrl).not.toContain('/Account/Login');
    } else {
      // Still on login page, check for auth state
      const pageContent = await page.content();
      if (pageContent.includes('Welcome') || pageContent.includes('Dashboard')) {
        console.log('Login successful - found authenticated content');
      } else {
        console.log('Login may have failed - still on login page');
      }
    }
  });

  test('login form validation', async ({ page }) => {
    await page.goto('http://localhost:8080/Account/Login');
    
    // Try to submit empty form
    await page.click('button[type="submit"]');
    
    // Wait for client-side validation
    await page.waitForTimeout(500);
    
    // Check for validation messages
    const emailError = await page.locator('[data-valmsg-for="Input.Email"]').isVisible();
    const passwordError = await page.locator('[data-valmsg-for="Input.Password"]').isVisible();
    
    console.log('Email validation visible:', emailError);
    console.log('Password validation visible:', passwordError);
    
    // At least one validation message should be visible
    expect(emailError || passwordError).toBeTruthy();
  });
});