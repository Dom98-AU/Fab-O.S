const puppeteer = require('puppeteer');

async function testCSSLoading() {
    console.log('Starting CSS diagnostics test...\n');
    const browser = await puppeteer.launch({ 
        headless: false,
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
        defaultViewport: { width: 1920, height: 1080 }
    });

    try {
        const page = await browser.newPage();
        
        // Enable request interception to monitor CSS files
        await page.setRequestInterception(true);
        
        const cssRequests = [];
        const cssResponses = {};
        
        page.on('request', request => {
            if (request.resourceType() === 'stylesheet') {
                cssRequests.push({
                    url: request.url(),
                    method: request.method()
                });
            }
            request.continue();
        });
        
        page.on('response', response => {
            if (response.request().resourceType() === 'stylesheet') {
                cssResponses[response.url()] = {
                    status: response.status(),
                    statusText: response.statusText(),
                    headers: response.headers()
                };
            }
        });

        // Navigate to login page
        console.log('1. Navigating to http://localhost:8080...');
        await page.goto('http://localhost:8080', { waitUntil: 'networkidle2' });
        
        // Take screenshot of initial page
        await page.screenshot({ path: 'css-test-1-initial.png', fullPage: true });
        console.log('   Screenshot saved: css-test-1-initial.png');
        
        // Check initial CSS files loaded
        console.log('\n2. CSS files requested on initial page:');
        cssRequests.forEach(req => {
            const response = cssResponses[req.url];
            console.log(`   - ${req.url.split('/').pop()}`);
            if (response) {
                console.log(`     Status: ${response.status} ${response.statusText}`);
            }
        });

        // Login
        console.log('\n3. Logging in...');
        await page.type('#Email', 'admin@steelestimation.com');
        await page.type('#Password', 'Admin@123');
        await page.click('button[type="submit"]');
        
        // Wait for navigation after login
        await page.waitForNavigation({ waitUntil: 'networkidle2' });
        await page.waitForTimeout(2000);
        
        console.log('   Successfully logged in');
        
        // Take screenshot after login
        await page.screenshot({ path: 'css-test-2-logged-in.png', fullPage: true });
        console.log('   Screenshot saved: css-test-2-logged-in.png');

        // Check all CSS files loaded after login
        console.log('\n4. All CSS files loaded (cumulative):');
        const uniqueCSS = [...new Set(cssRequests.map(r => r.url))];
        for (const url of uniqueCSS) {
            const fileName = url.split('/').pop();
            const response = cssResponses[url];
            console.log(`   - ${fileName}`);
            if (response) {
                console.log(`     Status: ${response.status} ${response.statusText}`);
                console.log(`     Full URL: ${url}`);
            }
        }

        // Check for sidebar.css specifically
        console.log('\n5. Checking for sidebar.css specifically:');
        const sidebarCSSFound = uniqueCSS.some(url => url.includes('sidebar.css'));
        if (sidebarCSSFound) {
            console.log('   ✓ sidebar.css was requested');
            const sidebarURL = uniqueCSS.find(url => url.includes('sidebar.css'));
            const sidebarResponse = cssResponses[sidebarURL];
            console.log(`   Status: ${sidebarResponse?.status} ${sidebarResponse?.statusText}`);
        } else {
            console.log('   ✗ sidebar.css was NOT requested');
        }

        // Execute JavaScript to check loaded stylesheets
        console.log('\n6. Checking all loaded stylesheets via JavaScript:');
        const stylesheets = await page.evaluate(() => {
            const links = Array.from(document.querySelectorAll('link[rel="stylesheet"]'));
            return links.map(link => ({
                href: link.href,
                media: link.media || 'all',
                disabled: link.disabled
            }));
        });
        
        stylesheets.forEach(sheet => {
            const fileName = sheet.href.split('/').pop();
            console.log(`   - ${fileName}`);
            console.log(`     URL: ${sheet.href}`);
            console.log(`     Media: ${sheet.media}, Disabled: ${sheet.disabled}`);
        });

        // Check for custom-sidebar element
        console.log('\n7. Checking for sidebar element:');
        const sidebarCheck = await page.evaluate(() => {
            const sidebar = document.querySelector('.custom-sidebar');
            const navMenu = document.querySelector('.nav-menu');
            const sidebarNav = document.querySelector('.sidebar');
            
            return {
                customSidebar: sidebar ? {
                    exists: true,
                    classes: sidebar.className,
                    id: sidebar.id || 'none',
                    tagName: sidebar.tagName,
                    childrenCount: sidebar.children.length
                } : { exists: false },
                navMenu: navMenu ? {
                    exists: true,
                    classes: navMenu.className,
                    tagName: navMenu.tagName
                } : { exists: false },
                anySidebar: sidebarNav ? {
                    exists: true,
                    classes: sidebarNav.className,
                    tagName: sidebarNav.tagName
                } : { exists: false }
            };
        });
        
        console.log('   .custom-sidebar element:', sidebarCheck.customSidebar.exists ? 'FOUND' : 'NOT FOUND');
        if (sidebarCheck.customSidebar.exists) {
            console.log(`     Classes: "${sidebarCheck.customSidebar.classes}"`);
            console.log(`     Tag: ${sidebarCheck.customSidebar.tagName}`);
            console.log(`     Children: ${sidebarCheck.customSidebar.childrenCount}`);
        }
        
        console.log('   .nav-menu element:', sidebarCheck.navMenu.exists ? 'FOUND' : 'NOT FOUND');
        if (sidebarCheck.navMenu.exists) {
            console.log(`     Classes: "${sidebarCheck.navMenu.classes}"`);
        }
        
        console.log('   .sidebar element:', sidebarCheck.anySidebar.exists ? 'FOUND' : 'NOT FOUND');
        if (sidebarCheck.anySidebar.exists) {
            console.log(`     Classes: "${sidebarCheck.anySidebar.classes}"`);
        }

        // Check computed styles
        console.log('\n8. Checking computed styles for sidebar:');
        const computedStyles = await page.evaluate(() => {
            const sidebar = document.querySelector('.custom-sidebar') || 
                           document.querySelector('.nav-menu') || 
                           document.querySelector('.sidebar') ||
                           document.querySelector('[class*="sidebar"]');
            
            if (!sidebar) return { found: false };
            
            const styles = window.getComputedStyle(sidebar);
            return {
                found: true,
                selector: sidebar.className || sidebar.tagName,
                background: styles.backgroundColor,
                color: styles.color,
                width: styles.width,
                position: styles.position,
                display: styles.display,
                padding: styles.padding,
                margin: styles.margin,
                border: styles.border
            };
        });
        
        if (computedStyles.found) {
            console.log(`   Element found: .${computedStyles.selector}`);
            console.log(`   Background: ${computedStyles.background}`);
            console.log(`   Color: ${computedStyles.color}`);
            console.log(`   Width: ${computedStyles.width}`);
            console.log(`   Position: ${computedStyles.position}`);
            console.log(`   Display: ${computedStyles.display}`);
            console.log(`   Padding: ${computedStyles.padding}`);
        } else {
            console.log('   No sidebar element found to check styles');
        }

        // Check if site.css contains sidebar styles
        console.log('\n9. Checking if site.css contains sidebar styles:');
        const siteCSSContent = await page.evaluate(async () => {
            try {
                const siteCSSLink = Array.from(document.querySelectorAll('link[rel="stylesheet"]'))
                    .find(link => link.href.includes('site.css'));
                
                if (!siteCSSLink) return { found: false };
                
                const response = await fetch(siteCSSLink.href);
                const text = await response.text();
                
                return {
                    found: true,
                    url: siteCSSLink.href,
                    size: text.length,
                    hasSidebarStyles: text.includes('sidebar'),
                    hasCustomSidebar: text.includes('custom-sidebar'),
                    hasNavMenu: text.includes('nav-menu'),
                    first500Chars: text.substring(0, 500)
                };
            } catch (e) {
                return { found: false, error: e.message };
            }
        });
        
        if (siteCSSContent.found) {
            console.log(`   site.css found at: ${siteCSSContent.url}`);
            console.log(`   File size: ${siteCSSContent.size} bytes`);
            console.log(`   Contains 'sidebar': ${siteCSSContent.hasSidebarStyles}`);
            console.log(`   Contains 'custom-sidebar': ${siteCSSContent.hasCustomSidebar}`);
            console.log(`   Contains 'nav-menu': ${siteCSSContent.hasNavMenu}`);
            console.log(`   First 500 characters:\n${siteCSSContent.first500Chars}`);
        } else {
            console.log('   site.css not found or couldn\'t be fetched');
            if (siteCSSContent.error) {
                console.log(`   Error: ${siteCSSContent.error}`);
            }
        }

        // Check actual sidebar HTML structure
        console.log('\n10. Checking actual sidebar HTML structure:');
        const sidebarHTML = await page.evaluate(() => {
            const possibleSelectors = [
                '.custom-sidebar',
                '.nav-menu',
                '.sidebar',
                'nav',
                '[class*="sidebar"]',
                '[id*="sidebar"]'
            ];
            
            for (const selector of possibleSelectors) {
                const element = document.querySelector(selector);
                if (element) {
                    return {
                        found: true,
                        selector: selector,
                        outerHTML: element.outerHTML.substring(0, 500),
                        innerHTML: element.innerHTML.substring(0, 300)
                    };
                }
            }
            
            return { found: false };
        });
        
        if (sidebarHTML.found) {
            console.log(`   Found sidebar with selector: ${sidebarHTML.selector}`);
            console.log(`   Outer HTML (first 500 chars):\n${sidebarHTML.outerHTML}`);
        } else {
            console.log('   No sidebar element found in HTML');
        }

        // Check for inline styles
        console.log('\n11. Checking for inline styles:');
        const inlineStyles = await page.evaluate(() => {
            const styletags = document.querySelectorAll('style');
            return {
                count: styletags.length,
                contents: Array.from(styletags).map(tag => ({
                    content: tag.textContent.substring(0, 200),
                    hasSidebar: tag.textContent.includes('sidebar')
                }))
            };
        });
        
        console.log(`   Found ${inlineStyles.count} <style> tags`);
        inlineStyles.contents.forEach((style, index) => {
            console.log(`   Style tag ${index + 1}: Contains 'sidebar': ${style.hasSidebar}`);
            if (style.hasSidebar) {
                console.log(`     Content: ${style.content}`);
            }
        });

        // Final visual check
        console.log('\n12. Taking final screenshots with DevTools open...');
        
        // Open DevTools-like inspection
        await page.evaluate(() => {
            const sidebar = document.querySelector('.custom-sidebar') || 
                           document.querySelector('.nav-menu') || 
                           document.querySelector('.sidebar') ||
                           document.querySelector('[class*="sidebar"]');
            if (sidebar) {
                sidebar.style.border = '3px solid red';
                sidebar.style.boxShadow = '0 0 10px red';
            }
        });
        
        await page.screenshot({ path: 'css-test-3-highlighted.png', fullPage: true });
        console.log('   Screenshot saved: css-test-3-highlighted.png (sidebar highlighted in red if found)');

        console.log('\n=== CSS Diagnostics Complete ===\n');
        console.log('Summary:');
        console.log(`- Total CSS files loaded: ${uniqueCSS.length}`);
        console.log(`- sidebar.css requested: ${sidebarCSSFound ? 'YES' : 'NO'}`);
        console.log(`- .custom-sidebar element exists: ${sidebarCheck.customSidebar.exists ? 'YES' : 'NO'}`);
        console.log(`- site.css contains sidebar styles: ${siteCSSContent.hasSidebarStyles ? 'YES' : 'NO'}`);
        console.log('\nCheck the screenshots for visual confirmation.');

    } catch (error) {
        console.error('Error during CSS diagnostics:', error);
    } finally {
        await browser.close();
    }
}

testCSSLoading();