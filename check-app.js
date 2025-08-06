const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  
  console.log('Checking application at http://localhost:8080...\n');
  
  await page.goto('http://localhost:8080');
  
  console.log('URL:', page.url());
  console.log('Title:', await page.title());
  
  // Check for login elements
  const hasLoginForm = await page.$('input[type="email"], input[type="text"][name*="user" i], input[id*="email" i]') !== null;
  const hasPasswordField = await page.$('input[type="password"]') !== null;
  
  console.log('Has login form:', hasLoginForm);
  console.log('Has password field:', hasPasswordField);
  
  if (hasLoginForm && hasPasswordField) {
    console.log('\nLogin page detected. Trying to log in...');
    
    // Find and fill email field
    const emailField = await page.$('input[type="email"], input[type="text"][name*="user" i], input[id*="email" i]');
    if (emailField) {
      await emailField.fill('admin@steelestimation.com');
    }
    
    // Fill password
    const passwordField = await page.$('input[type="password"]');
    if (passwordField) {
      await passwordField.fill('Admin@123');
    }
    
    // Submit
    const submitBtn = await page.$('button[type="submit"], input[type="submit"]');
    if (submitBtn) {
      await submitBtn.click();
      await page.waitForNavigation({ waitUntil: 'domcontentloaded' }).catch(() => {});
      
      console.log('After login - URL:', page.url());
      console.log('After login - Title:', await page.title());
    }
  } else {
    console.log('\nNot a login page. Looking for navigation links...');
    
    const links = await page.$$eval('a', anchors => 
      anchors.map(a => ({
        text: a.textContent?.trim(),
        href: a.href
      })).filter(a => a.text && a.href)
    );
    
    console.log('Found links:');
    links.slice(0, 10).forEach(link => {
      console.log(`  - ${link.text}: ${link.href}`);
    });
  }
  
  await browser.close();
})();