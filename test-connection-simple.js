const { chromium } = require('playwright');

(async () => {
  console.log('Starting connection test...');
  
  const browser = await chromium.launch({ 
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  
  try {
    const page = await browser.newPage();
    
    console.log('Testing connection to http://localhost:8080...');
    const response = await page.goto('http://localhost:8080', {
      waitUntil: 'domcontentloaded',
      timeout: 10000
    });
    
    console.log('Response status:', response.status());
    console.log('Page URL:', page.url());
    
    if (response.ok()) {
      console.log('✅ Connection successful!');
      
      // Check if we're redirected to login
      if (page.url().includes('login')) {
        console.log('✅ Redirected to login page as expected');
      }
    } else {
      console.log('❌ Connection failed');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await browser.close();
    console.log('Browser closed');
  }
})();