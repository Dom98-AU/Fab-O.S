const { test, expect } = require('@playwright/test');

test.describe('Steel Estimation Login Page', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the login page
    await page.goto('http://localhost:8080/Account/Login');
  });

  test('login page loads correctly', async ({ page }) => {
    // Check page title
    await expect(page).toHaveTitle(/Login - Steel Estimation Platform/);
    
    // Check login form elements exist
    await expect(page.locator('input[name="Input.Email"]')).toBeVisible();
    await expect(page.locator('input[name="Input.Password"]')).toBeVisible();
    await expect(page.locator('button[type="submit"]')).toBeVisible();
    
    // Check form labels
    await expect(page.locator('label[for="Input_Email"]')).toContainText('Email or Username');
    await expect(page.locator('label[for="Input_Password"]')).toContainText('Password');
  });

  test('shows validation errors for empty form submission', async ({ page }) => {
    // Click submit without filling form
    await page.click('button[type="submit"]');
    
    // Check for validation messages
    await expect(page.locator('.field-validation-error')).toBeVisible();
  });

  test('successful login with admin credentials', async ({ page }) => {
    // Fill in the login form
    await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
    await page.fill('input[name="Input.Password"]', 'Admin@123');
    
    // Submit the form
    await page.click('button[type="submit"]');
    
    // Wait for navigation after successful login
    await page.waitForNavigation();
    
    // Check we're redirected away from login page
    expect(page.url()).not.toContain('/Account/Login');
    
    // Check for authenticated user elements
    await expect(page.locator('.navbar')).toBeVisible();
  });

  test('shows error for invalid credentials', async ({ page }) => {
    // Fill in the login form with invalid credentials
    await page.fill('input[name="Input.Email"]', 'invalid@example.com');
    await page.fill('input[name="Input.Password"]', 'WrongPassword123');
    
    // Submit the form
    await page.click('button[type="submit"]');
    
    // Check for error message
    await expect(page.locator('.validation-summary-errors')).toBeVisible();
    await expect(page.locator('.validation-summary-errors')).toContainText(/Invalid/i);
  });

  test('Microsoft login button is visible when configured', async ({ page }) => {
    // Check if Microsoft login button exists
    const microsoftButton = page.locator('button:has-text("Sign in with Microsoft")');
    
    // This will pass if the button exists, or skip if it doesn't
    if (await microsoftButton.count() > 0) {
      await expect(microsoftButton).toBeVisible();
    }
  });

  test('responsive design on mobile', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    
    // Check form is still accessible
    await expect(page.locator('input[name="Input.Email"]')).toBeVisible();
    await expect(page.locator('input[name="Input.Password"]')).toBeVisible();
    await expect(page.locator('button[type="submit"]')).toBeVisible();
  });
});