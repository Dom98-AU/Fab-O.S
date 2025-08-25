const puppeteer = require('puppeteer');
const fs = require('fs');

async function testSidebar() {
    console.log('Starting sidebar test...');
    const browser = await puppeteer.launch({
        headless: 'new',
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    try {
        const page = await browser.newPage();
        await page.setViewport({ width: 1920, height: 1080 });

        // Capture console messages
        const consoleMessages = [];
        page.on('console', msg => {
            consoleMessages.push({
                type: msg.type(),
                text: msg.text(),
                location: msg.location()
            });
        });

        // Capture network errors
        const networkErrors = [];
        page.on('requestfailed', request => {
            networkErrors.push({
                url: request.url(),
                failure: request.failure()
            });
        });

        console.log('1. Navigating to landing page...');
        await page.goto('http://localhost:8080', { 
            waitUntil: 'networkidle0',
            timeout: 30000 
        });
        
        // Take initial screenshot
        await page.screenshot({ 
            path: 'sidebar-test-1-landing.png',
            fullPage: true 
        });
        console.log('   Screenshot saved: sidebar-test-1-landing.png');

        // Get page HTML structure
        const landingHtml = await page.content();
        fs.writeFileSync('sidebar-test-landing.html', landingHtml);
        console.log('   HTML saved: sidebar-test-landing.html');

        // Check for Blazor components
        const blazorComponents = await page.evaluate(() => {
            const comments = [];
            const walker = document.createTreeWalker(
                document.body,
                NodeFilter.SHOW_COMMENT,
                null,
                false
            );
            
            while(walker.nextNode()) {
                comments.push(walker.currentNode.textContent);
            }
            
            return {
                hasBlazorComments: comments.some(c => c.includes('Blazor')),
                blazorComments: comments.filter(c => c.includes('Blazor')),
                totalComments: comments.length
            };
        });
        console.log('   Blazor component check:', blazorComponents);

        // Check for sidebar element
        const sidebarCheck = await page.evaluate(() => {
            const sidebar = document.querySelector('.sidebar');
            const navMenu = document.querySelector('.nav-menu');
            const blazorApp = document.querySelector('#app');
            
            return {
                hasSidebar: !!sidebar,
                sidebarStyles: sidebar ? window.getComputedStyle(sidebar) : null,
                hasNavMenu: !!navMenu,
                navMenuStyles: navMenu ? window.getComputedStyle(navMenu) : null,
                hasBlazorApp: !!blazorApp,
                appContent: blazorApp ? blazorApp.innerHTML.substring(0, 500) : null
            };
        });
        console.log('   Sidebar element check:', {
            hasSidebar: sidebarCheck.hasSidebar,
            hasNavMenu: sidebarCheck.hasNavMenu,
            hasBlazorApp: sidebarCheck.hasBlazorApp
        });

        // Check for authentication
        const authCheck = await page.evaluate(() => {
            return {
                hasLoginForm: !!document.querySelector('form[action*="Login"]'),
                hasLoginButton: !!document.querySelector('button[type="submit"]'),
                pageTitle: document.title,
                currentUrl: window.location.href
            };
        });
        console.log('   Authentication check:', authCheck);

        // If login page, attempt login
        if (authCheck.hasLoginForm) {
            console.log('\n2. Attempting login...');
            
            // Fill login form
            await page.type('input[name="Email"]', 'admin@steelestimation.com');
            await page.type('input[name="Password"]', 'Admin@123');
            
            // Take screenshot before login
            await page.screenshot({ 
                path: 'sidebar-test-2-login-form.png',
                fullPage: true 
            });
            console.log('   Screenshot saved: sidebar-test-2-login-form.png');
            
            // Submit login
            await page.click('button[type="submit"]');
            
            // Wait for navigation
            await page.waitForNavigation({ 
                waitUntil: 'networkidle0',
                timeout: 10000 
            }).catch(e => console.log('   Navigation timeout - checking current state'));
            
            // Take screenshot after login
            await page.screenshot({ 
                path: 'sidebar-test-3-after-login.png',
                fullPage: true 
            });
            console.log('   Screenshot saved: sidebar-test-3-after-login.png');
            
            // Re-check sidebar after login
            const postLoginCheck = await page.evaluate(() => {
                const sidebar = document.querySelector('.sidebar');
                const navMenu = document.querySelector('.nav-menu');
                
                return {
                    hasSidebar: !!sidebar,
                    hasNavMenu: !!navMenu,
                    sidebarVisible: sidebar ? window.getComputedStyle(sidebar).display !== 'none' : false,
                    sidebarWidth: sidebar ? window.getComputedStyle(sidebar).width : null,
                    navItems: document.querySelectorAll('.nav-item').length
                };
            });
            console.log('   Post-login sidebar check:', postLoginCheck);
        }

        // Get final console errors
        const consoleErrors = consoleMessages.filter(m => m.type === 'error');
        if (consoleErrors.length > 0) {
            console.log('\nConsole Errors Found:');
            consoleErrors.forEach(err => {
                console.log(`   - ${err.text}`);
                if (err.location?.url) {
                    console.log(`     at ${err.location.url}:${err.location.lineNumber}`);
                }
            });
        }

        // Get network errors
        if (networkErrors.length > 0) {
            console.log('\nNetwork Errors Found:');
            networkErrors.forEach(err => {
                console.log(`   - ${err.url}`);
                console.log(`     Failure: ${err.failure?.errorText}`);
            });
        }

        // Final DOM inspection
        const domInspection = await page.evaluate(() => {
            const elements = {
                sidebar: document.querySelector('.sidebar'),
                navMenu: document.querySelector('.nav-menu'),
                mainContent: document.querySelector('.main-content'),
                blazorApp: document.querySelector('#app')
            };
            
            const results = {};
            for (const [name, elem] of Object.entries(elements)) {
                if (elem) {
                    const styles = window.getComputedStyle(elem);
                    results[name] = {
                        exists: true,
                        display: styles.display,
                        position: styles.position,
                        width: styles.width,
                        height: styles.height,
                        left: styles.left,
                        top: styles.top,
                        innerHTML: elem.innerHTML.substring(0, 200)
                    };
                } else {
                    results[name] = { exists: false };
                }
            }
            return results;
        });
        
        console.log('\nFinal DOM Inspection:');
        Object.entries(domInspection).forEach(([name, info]) => {
            console.log(`   ${name}:`, info.exists ? `Found (display: ${info.display}, width: ${info.width})` : 'Not found');
        });

    } catch (error) {
        console.error('Test failed:', error);
    } finally {
        await browser.close();
        console.log('\nTest complete. Check screenshots and HTML output.');
    }
}

testSidebar().catch(console.error);