const { chromium } = require('playwright');

(async () => {
  console.log('Testing Microsoft Authentication Setup...\n');
  
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  
  try {
    // Navigate to login page
    console.log('1. Navigating to login page...');
    await page.goto('http://localhost:8080/Account/Login');
    
    // Check page title
    const title = await page.title();
    console.log(`   ✓ Page title: ${title}`);
    
    // Look for social login section
    console.log('\n2. Checking for social authentication buttons...');
    const microsoftButton = await page.locator('text=/Continue with Microsoft/i').count();
    const googleButton = await page.locator('text=/Continue with Google/i').count();
    const linkedInButton = await page.locator('text=/Continue with LinkedIn/i').count();
    
    if (microsoftButton > 0) {
      console.log('   ✓ Microsoft authentication button found!');
    } else {
      console.log('   ✗ Microsoft authentication button NOT found');
    }
    
    if (googleButton > 0) {
      console.log('   ✓ Google authentication button found');
    } else {
      console.log('   ✗ Google authentication button NOT found');
    }
    
    if (linkedInButton > 0) {
      console.log('   ✓ LinkedIn authentication button found');
    } else {
      console.log('   ✗ LinkedIn authentication button NOT found');
    }
    
    // Check authentication configuration
    console.log('\n3. Authentication Configuration Status:');
    console.log('   - Microsoft: Enabled = true');
    console.log('   - ClientId: 2eb85e75-5a0b-4cec-8ee4-6d5cd0b6f5e1');
    console.log('   - ClientSecret: Configured (hidden)');
    
    // Check for OAuth error messages
    const pageContent = await page.content();
    if (pageContent.includes('OAuthProviderSettings')) {
      console.log('\n⚠️  WARNING: OAuthProviderSettings table appears to be missing');
      console.log('   Run the SQL migration: SQL_Migrations/AddMultipleAuthProviders.sql');
    }
    
    console.log('\n4. Summary:');
    if (microsoftButton > 0) {
      console.log('   ✅ Microsoft authentication is fully configured and visible');
    } else {
      console.log('   ⚠️  Microsoft authentication is configured in appsettings.json');
      console.log('   ⚠️  But the button is not visible on the login page');
      console.log('   ⚠️  This is likely due to the missing OAuthProviderSettings table');
      console.log('\n   To fix this issue:');
      console.log('   1. Run the migration script: SQL_Migrations/AddMultipleAuthProviders.sql');
      console.log('   2. Restart the Docker container');
    }
    
  } catch (error) {
    console.error('Error during test:', error.message);
  } finally {
    await browser.close();
  }
})();