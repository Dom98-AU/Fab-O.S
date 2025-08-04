const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  
  // Login
  await page.goto('http://localhost:8080/Account/Login');
  await page.fill('input[name="Input.Email"]', 'admin@steelestimation.com');
  await page.fill('input[name="Input.Password"]', 'Admin@123');
  await page.click('button[type="submit"]');
  await page.waitForLoadState('networkidle');

  // Go to profile
  await page.goto('http://localhost:8080/profile');
  await page.waitForTimeout(3000);
  
  // Check avatar
  const avatar = await page.locator('.avatar-large').first();
  const avatarHTML = await avatar.evaluate(el => el.outerHTML);
  console.log('Avatar HTML:', avatarHTML.substring(0, 200));
  
  // Check button
  const button = await page.locator('.avatar-change-btn').first();
  const buttonExists = await button.count() > 0;
  console.log('Button exists:', buttonExists);
  
  if (buttonExists) {
    const buttonHTML = await button.evaluate(el => el.outerHTML);
    console.log('Button HTML:', buttonHTML);
    
    // Get all styles
    const styles = await page.evaluate(() => {
      const styleSheets = Array.from(document.styleSheets);
      const avatarStyles = [];
      styleSheets.forEach(sheet => {
        try {
          const rules = Array.from(sheet.cssRules || sheet.rules);
          rules.forEach(rule => {
            if (rule.selectorText && (
              rule.selectorText.includes('avatar-large') ||
              rule.selectorText.includes('dicebear-avatar') ||
              rule.selectorText.includes('avatar-change-btn')
            )) {
              avatarStyles.push(`${rule.selectorText} { ${rule.style.cssText} }`);
            }
          });
        } catch (e) {}
      });
      return avatarStyles;
    });
    
    console.log('\nRelevant CSS:');
    styles.forEach(s => console.log(s));
  }
  
  await page.screenshot({ path: 'profile-page.png' });
  console.log('\nScreenshot saved: profile-page.png');
  
  await browser.close();
})();