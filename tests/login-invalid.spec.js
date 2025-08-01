const { test, expect } = require('@playwright/test');

test('invalid login shows error message', async ({ page }) => {
  await page.goto('http://localhost:8080/Account/Login');
  
  // Try invalid credentials
  await page.fill('input[name="Input.Email"]', 'invalid@test.com');
  await page.fill('input[name="Input.Password"]', 'WrongPassword123');
  
  await page.click('button[type="submit"]');
  
  // Wait for response
  await page.waitForLoadState('networkidle');
  
  // Should still be on login page
  expect(page.url()).toContain('/Account/Login');
  
  // Check for error message
  const errorSummary = page.locator('.validation-summary-errors');
  await expect(errorSummary).toBeVisible();
  
  const errorText = await errorSummary.textContent();
  console.log('Error message:', errorText);
  
  // Should contain "Invalid" in the error message
  expect(errorText).toMatch(/Invalid/i);
});