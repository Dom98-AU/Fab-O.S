const { chromium } = require('playwright');

(async () => {
    console.log('Starting sidebar layout test...\n');
    
    const browser = await chromium.launch({ 
        headless: true,
        args: ['--disable-dev-shm-usage', '--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const page = await browser.newPage({
        viewport: { width: 1920, height: 1080 }
    });
    
    try {
        console.log('Navigating to http://localhost:8080...');
        await page.goto('http://localhost:8080', { 
            waitUntil: 'domcontentloaded',
            timeout: 30000 
        });
        
        // Wait for page to stabilize
        await page.waitForTimeout(2000);
        
        // Take initial screenshot
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        await page.screenshot({ 
            path: `sidebar-layout-test-${timestamp}.png`, 
            fullPage: false 
        });
        console.log(`✓ Screenshot saved: sidebar-layout-test-${timestamp}.png\n`);
        
        // Check for sidebar element
        const sidebar = await page.$('.sidebar, #main-sidebar');
        if (sidebar) {
            console.log('✓ Sidebar element found\n');
            
            // Get sidebar position and dimensions
            const sidebarBox = await sidebar.boundingBox();
            console.log('=== SIDEBAR LAYOUT ANALYSIS ===');
            console.log(`Position: Left=${sidebarBox?.x}px, Top=${sidebarBox?.y}px`);
            console.log(`Dimensions: Width=${sidebarBox?.width}px, Height=${sidebarBox?.height}px`);
            
            // Check if sidebar is on the left
            if (sidebarBox?.x === 0) {
                console.log('✓ PASS: Sidebar is positioned on the LEFT (x=0)');
            } else {
                console.log(`✗ FAIL: Sidebar is NOT on the left (x=${sidebarBox?.x}px, expected 0px)`);
            }
            
            // Check sidebar width
            if (sidebarBox?.width === 250) {
                console.log('✓ PASS: Sidebar width is correct (250px)');
            } else {
                console.log(`✗ FAIL: Sidebar width is incorrect (${sidebarBox?.width}px, expected 250px)`);
            }
            
            // Check if sidebar is full height
            if (sidebarBox?.height >= 900) {
                console.log(`✓ PASS: Sidebar is full height (${sidebarBox?.height}px)`);
            } else {
                console.log(`⚠ WARNING: Sidebar may not be full height (${sidebarBox?.height}px)`);
            }
        } else {
            console.log('✗ FAIL: Sidebar element not found');
        }
        
        // Check for logo
        const logo = await page.$('.sidebar img, .navbar-brand img, .brand-logo');
        if (logo) {
            const logoBox = await logo.boundingBox();
            console.log('\n=== LOGO POSITIONING ===');
            console.log(`Position: Left=${logoBox?.x}px, Top=${logoBox?.y}px`);
            
            if (logoBox && logoBox.y < 150) {
                console.log(`✓ PASS: Logo is at the TOP of sidebar (y=${logoBox.y}px)`);
            } else {
                console.log(`✗ FAIL: Logo is NOT at the top (y=${logoBox?.y}px, expected < 150px)`);
            }
        } else {
            console.log('\n✗ FAIL: Logo element not found');
        }
        
        // Check main content
        const mainContent = await page.$('main, #main-content, .main-content');
        if (mainContent) {
            const mainBox = await mainContent.boundingBox();
            console.log('\n=== MAIN CONTENT OFFSET ===');
            console.log(`Position: Left=${mainBox?.x}px`);
            
            if (mainBox && mainBox.x >= 250) {
                console.log(`✓ PASS: Main content is offset properly (x=${mainBox.x}px, sidebar width=250px)`);
            } else {
                console.log(`✗ FAIL: Main content may overlap sidebar (x=${mainBox?.x}px, expected >= 250px)`);
            }
        } else {
            console.log('\n✗ FAIL: Main content element not found');
        }
        
        // Check for hamburger menu
        const hamburger = await page.$('.menu-toggle-btn, .navbar-toggler, button:has(i.fa-bars)');
        if (hamburger) {
            console.log('\n=== HAMBURGER MENU ===');
            console.log('✓ Hamburger menu found');
            
            // Click to test collapse
            await hamburger.click();
            await page.waitForTimeout(500);
            
            // Check if sidebar collapsed
            const sidebarCollapsed = await page.$eval('body', el => {
                const pageEl = el.querySelector('.page');
                return pageEl?.classList.contains('sidebar-collapsed');
            });
            
            if (sidebarCollapsed) {
                console.log('✓ PASS: Sidebar collapse toggle works');
                await page.screenshot({ 
                    path: `sidebar-collapsed-${timestamp}.png`, 
                    fullPage: false 
                });
                console.log(`✓ Collapsed state screenshot saved`);
            } else {
                console.log('✗ FAIL: Sidebar did not collapse');
            }
            
            // Toggle back
            await hamburger.click();
            await page.waitForTimeout(500);
        } else {
            console.log('\n⚠ WARNING: Hamburger menu not found');
        }
        
        // Get computed styles
        const styles = await page.evaluate(() => {
            const sidebar = document.querySelector('.sidebar, #main-sidebar');
            const main = document.querySelector('main, #main-content');
            const results = {};
            
            if (sidebar) {
                const sidebarStyles = window.getComputedStyle(sidebar);
                results.sidebar = {
                    position: sidebarStyles.position,
                    width: sidebarStyles.width,
                    left: sidebarStyles.left,
                    transform: sidebarStyles.transform,
                    zIndex: sidebarStyles.zIndex
                };
            }
            
            if (main) {
                const mainStyles = window.getComputedStyle(main);
                results.main = {
                    marginLeft: mainStyles.marginLeft,
                    position: mainStyles.position
                };
            }
            
            return results;
        });
        
        console.log('\n=== COMPUTED STYLES ===');
        if (styles.sidebar) {
            console.log('Sidebar styles:', styles.sidebar);
            
            // Verify fixed positioning
            if (styles.sidebar.position === 'fixed') {
                console.log('✓ PASS: Sidebar has fixed positioning');
            } else {
                console.log(`✗ FAIL: Sidebar position is ${styles.sidebar.position}, expected 'fixed'`);
            }
        }
        
        if (styles.main) {
            console.log('Main content styles:', styles.main);
            
            // Check margin-left
            const marginLeft = parseInt(styles.main.marginLeft);
            if (marginLeft === 250) {
                console.log('✓ PASS: Main content has correct left margin (250px)');
            } else {
                console.log(`⚠ WARNING: Main content margin-left is ${marginLeft}px, expected 250px`);
            }
        }
        
        console.log('\n=== TEST SUMMARY ===');
        console.log('Layout test complete. Check screenshots for visual verification.');
        console.log(`Screenshots saved with timestamp: ${timestamp}`);
        
    } catch (error) {
        console.error('Test error:', error);
    } finally {
        await browser.close();
    }
})();