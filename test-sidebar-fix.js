const { chromium } = require('playwright');

(async () => {
    console.log('Starting sidebar CSS fix investigation...');
    const browser = await chromium.launch({ 
        headless: false,
        slowMo: 500
    });
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 }
    });
    const page = await context.newPage();

    try {
        // Navigate to the application
        console.log('1. Navigating to http://localhost:8080...');
        await page.goto('http://localhost:8080', { waitUntil: 'networkidle' });
        
        // Check what CSS files are loaded
        console.log('2. Checking loaded CSS files...');
        const cssFiles = await page.evaluate(() => {
            const links = Array.from(document.querySelectorAll('link[rel="stylesheet"]'));
            return links.map(link => link.href);
        });
        console.log('   CSS files found:');
        cssFiles.forEach(file => {
            console.log(`     - ${file}`);
        });
        
        // Check if site.css is loaded
        const siteCssLoaded = cssFiles.some(file => file.includes('site.css'));
        console.log(`   site.css loaded: ${siteCssLoaded}`);
        
        // Check sidebar element
        const sidebarExists = await page.locator('.sidebar').count() > 0;
        console.log(`3. Sidebar element exists: ${sidebarExists}`);
        
        if (sidebarExists) {
            // Get computed styles
            const sidebarInfo = await page.evaluate(() => {
                const sidebar = document.querySelector('.sidebar');
                const computed = window.getComputedStyle(sidebar);
                
                // Check if CSS is actually being applied
                const expectedStyles = {
                    position: 'fixed',
                    width: '250px',
                    height: '100vh',
                    backgroundColor: 'rgb(255, 255, 255)'
                };
                
                const actualStyles = {
                    position: computed.position,
                    width: computed.width,
                    height: computed.height,
                    backgroundColor: computed.backgroundColor,
                    display: computed.display,
                    left: computed.left,
                    top: computed.top,
                    transform: computed.transform,
                    zIndex: computed.zIndex
                };
                
                return {
                    actual: actualStyles,
                    expected: expectedStyles,
                    matches: {
                        position: computed.position === expectedStyles.position,
                        width: computed.width === expectedStyles.width,
                        height: computed.height === expectedStyles.height,
                        background: computed.backgroundColor === expectedStyles.backgroundColor
                    }
                };
            });
            
            console.log('   Sidebar style analysis:');
            console.log('   Expected styles:');
            Object.entries(sidebarInfo.expected).forEach(([key, value]) => {
                console.log(`     ${key}: ${value}`);
            });
            console.log('   Actual styles:');
            Object.entries(sidebarInfo.actual).forEach(([key, value]) => {
                console.log(`     ${key}: ${value}`);
            });
            console.log('   Style matches:');
            Object.entries(sidebarInfo.matches).forEach(([key, value]) => {
                console.log(`     ${key}: ${value ? '✓' : '✗'}`);
            });
        }
        
        // Take screenshot
        await page.screenshot({ path: 'sidebar-css-landing.png', fullPage: true });
        console.log('   ✓ Screenshot saved: sidebar-css-landing.png');
        
        // Check if CSS is being blocked or not loading properly
        console.log('4. Checking for CSS loading errors...');
        const cssLoadErrors = await page.evaluate(() => {
            const links = Array.from(document.querySelectorAll('link[rel="stylesheet"]'));
            const errors = [];
            links.forEach(link => {
                // Try to access the sheet to see if it loaded
                try {
                    if (link.sheet && !link.sheet.cssRules && !link.sheet.rules) {
                        errors.push(`Cannot access rules for: ${link.href}`);
                    }
                } catch (e) {
                    errors.push(`Error accessing: ${link.href} - ${e.message}`);
                }
            });
            return errors;
        });
        
        if (cssLoadErrors.length > 0) {
            console.log('   CSS loading issues found:');
            cssLoadErrors.forEach(error => {
                console.log(`     - ${error}`);
            });
        } else {
            console.log('   No CSS loading errors detected');
        }
        
        // Try to manually inject the sidebar CSS if it's not working
        console.log('5. Attempting to fix sidebar CSS...');
        await page.evaluate(() => {
            const style = document.createElement('style');
            style.innerHTML = `
                .sidebar {
                    width: 250px !important;
                    height: 100vh !important;
                    position: fixed !important;
                    top: 0 !important;
                    left: 0 !important;
                    z-index: 1000 !important;
                    background: #ffffff !important;
                    border-right: 1px solid #e9ecef !important;
                    box-shadow: 2px 0 10px rgba(0, 0, 0, 0.1) !important;
                    overflow-y: auto !important;
                    transition: transform 0.3s ease !important;
                }
                
                .sidebar.sidebar-collapsed {
                    transform: translateX(-250px) !important;
                }
                
                main {
                    margin-left: 250px !important;
                    transition: margin-left 0.3s ease !important;
                }
                
                .page.sidebar-collapsed main {
                    margin-left: 0 !important;
                }
                
                .nav-menu {
                    padding: 1rem 0 !important;
                }
                
                .nav-item {
                    list-style: none !important;
                }
                
                .nav-link {
                    display: flex !important;
                    align-items: center !important;
                    padding: 0.75rem 1.5rem !important;
                    color: #495057 !important;
                    text-decoration: none !important;
                    transition: all 0.3s ease !important;
                }
                
                .nav-link:hover {
                    background-color: #f8f9fa !important;
                    color: #0d1a80 !important;
                }
                
                .nav-link.active {
                    background-color: #0d1a80 !important;
                    color: white !important;
                }
            `;
            document.head.appendChild(style);
        });
        
        // Wait a moment for styles to apply
        await page.waitForTimeout(1000);
        
        // Take screenshot after fix
        await page.screenshot({ path: 'sidebar-css-after-fix.png', fullPage: true });
        console.log('   ✓ Screenshot saved: sidebar-css-after-fix.png');
        
        // Check styles again after fix
        if (sidebarExists) {
            const afterFixStyles = await page.evaluate(() => {
                const sidebar = document.querySelector('.sidebar');
                const computed = window.getComputedStyle(sidebar);
                return {
                    position: computed.position,
                    width: computed.width,
                    height: computed.height,
                    backgroundColor: computed.backgroundColor,
                    left: computed.left,
                    top: computed.top
                };
            });
            console.log('   Sidebar styles after CSS injection:');
            Object.entries(afterFixStyles).forEach(([key, value]) => {
                console.log(`     ${key}: ${value}`);
            });
        }
        
        console.log('\n✓ Investigation complete!');
        console.log('Check the screenshots to see the before and after state.');
        
    } catch (error) {
        console.error('Error during investigation:', error);
        await page.screenshot({ path: 'sidebar-css-error.png', fullPage: true });
    } finally {
        // Keep browser open for manual inspection
        console.log('\nBrowser will remain open for 15 seconds for inspection...');
        await page.waitForTimeout(15000);
        await browser.close();
    }
})();