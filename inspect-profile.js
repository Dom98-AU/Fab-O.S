const { chromium } = require('playwright');

async function inspectProfile() {
  const browser = await chromium.launch({ headless: true });
  
  try {
    const page = await browser.newPage();
    
    // Login
    await page.goto('http://localhost:8080/Account/Login');
    
    const emailField = await page.$('input[type="email"], input[type="text"]');
    if (emailField) await emailField.fill('admin@steelestimation.com');
    
    const passwordField = await page.$('input[type="password"]');
    if (passwordField) await passwordField.fill('Admin@123');
    
    const submitButton = await page.$('button[type="submit"]');
    if (submitButton) {
      await Promise.all([
        page.waitForNavigation(),
        submitButton.click()
      ]);
    }
    
    console.log('Logged in. Current URL:', page.url());
    
    // Try to find profile/manage links
    console.log('\nLooking for profile/account management links...');
    
    const links = await page.$$eval('a', anchors => 
      anchors.map(a => ({
        text: a.textContent?.trim(),
        href: a.href
      })).filter(a => a.text && (
        a.href.includes('Account') || 
        a.href.includes('Profile') || 
        a.href.includes('Manage') ||
        a.href.includes('Settings')
      ))
    );
    
    console.log('Found account-related links:');
    links.forEach(link => {
      console.log(`  - "${link.text}": ${link.href}`);
    });
    
    // Try common profile URLs
    const profileUrls = [
      '/Account/Manage',
      '/Identity/Account/Manage',
      '/Profile',
      '/Settings',
      '/Account',
      '/User/Profile'
    ];
    
    console.log('\nTrying common profile URLs...');
    
    for (const url of profileUrls) {
      const fullUrl = `http://localhost:8080${url}`;
      const response = await page.goto(fullUrl, { waitUntil: 'domcontentloaded' }).catch(() => null);
      
      if (response && response.status() === 200) {
        console.log(`\n✓ Found valid page at: ${url}`);
        console.log('  Page title:', await page.title());
        
        // Look for avatar-related elements
        const avatarElements = await page.$$eval('*', elements => 
          elements
            .filter(el => {
              const text = el.textContent?.toLowerCase() || '';
              const onclick = el.getAttribute('onclick')?.toLowerCase() || '';
              const className = el.className?.toLowerCase() || '';
              return text.includes('avatar') || onclick.includes('avatar') || className.includes('avatar');
            })
            .map(el => ({
              tag: el.tagName,
              text: el.textContent?.trim().substring(0, 50),
              class: el.className,
              onclick: el.getAttribute('onclick')?.substring(0, 50)
            }))
            .slice(0, 10)
        );
        
        if (avatarElements.length > 0) {
          console.log('  Found avatar-related elements:');
          avatarElements.forEach(el => {
            console.log(`    - <${el.tag}> "${el.text}"`);
          });
        }
        
        // Look for buttons
        const buttons = await page.$$eval('button', btns => 
          btns.map(b => b.textContent?.trim()).filter(Boolean)
        );
        
        if (buttons.length > 0) {
          console.log('  Buttons on page:', buttons);
        }
      }
    }
    
    // Check if we're using a different UI framework
    console.log('\n\nChecking for UI framework...');
    
    // Check for Blazor
    const hasBlazor = await page.evaluate(() => {
      return typeof window.Blazor !== 'undefined';
    });
    
    if (hasBlazor) {
      console.log('✓ This appears to be a Blazor application');
      
      // For Blazor apps, avatar functionality might be in a component
      const blazorComponents = await page.$$eval('[id*="avatar"], [class*="avatar"]', elements =>
        elements.map(el => ({
          id: el.id,
          class: el.className,
          tag: el.tagName
        }))
      );
      
      console.log('Blazor avatar components found:', blazorComponents);
    }
    
    // Check the main navigation
    console.log('\n\nMain navigation structure:');
    const navItems = await page.$$eval('nav a, .navbar a, .sidebar a', links =>
      links.map(a => ({
        text: a.textContent?.trim(),
        href: a.href
      })).filter(a => a.text)
    );
    
    navItems.forEach(item => {
      console.log(`  - "${item.text}": ${item.href}`);
    });
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await browser.close();
  }
}

inspectProfile();