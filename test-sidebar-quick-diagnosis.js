const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.launch({ 
        headless: true  // Run headless for speed
    });
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 },
        ignoreHTTPSErrors: true
    });
    
    const page = await context.newPage();
    
    console.log('Navigating to http://localhost:8080...');
    
    try {
        // Navigate to the application
        await page.goto('http://localhost:8080', { 
            waitUntil: 'domcontentloaded',
            timeout: 15000 
        });
        
        console.log('Page loaded successfully');
        
        // Wait for any dynamic content
        await page.waitForTimeout(3000);
        
        // Take initial screenshot
        await page.screenshot({ 
            path: 'sidebar-diagnosis-current.png',
            fullPage: true 
        });
        console.log('Screenshot saved as sidebar-diagnosis-current.png');
        
        // Check for sidebar element
        const sidebarExists = await page.locator('.sidebar').count() > 0;
        console.log(`\n=== SIDEBAR ELEMENT CHECK ===`);
        console.log(`Sidebar element (.sidebar) exists: ${sidebarExists}`);
        
        if (sidebarExists) {
            // Get sidebar computed styles
            const sidebarStyles = await page.locator('.sidebar').first().evaluate(el => {
                const computed = window.getComputedStyle(el);
                const rect = el.getBoundingClientRect();
                return {
                    position: computed.position,
                    width: computed.width,
                    height: computed.height,
                    left: computed.left,
                    top: computed.top,
                    display: computed.display,
                    float: computed.float,
                    backgroundColor: computed.backgroundColor,
                    zIndex: computed.zIndex,
                    // Actual positioning
                    boundingRect: {
                        top: rect.top,
                        left: rect.left,
                        width: rect.width,
                        height: rect.height
                    }
                };
            });
            
            console.log('\n=== SIDEBAR COMPUTED STYLES ===');
            console.log(JSON.stringify(sidebarStyles, null, 2));
        }
        
        // Check for main element
        const mainExists = await page.locator('main').count() > 0;
        console.log(`\n=== MAIN ELEMENT CHECK ===`);
        console.log(`Main element exists: ${mainExists}`);
        
        if (mainExists) {
            const mainStyles = await page.locator('main').first().evaluate(el => {
                const computed = window.getComputedStyle(el);
                const rect = el.getBoundingClientRect();
                return {
                    marginLeft: computed.marginLeft,
                    paddingLeft: computed.paddingLeft,
                    position: computed.position,
                    width: computed.width,
                    display: computed.display,
                    // Actual positioning
                    boundingRect: {
                        top: rect.top,
                        left: rect.left,
                        width: rect.width,
                        height: rect.height
                    }
                };
            });
            
            console.log('\n=== MAIN ELEMENT STYLES ===');
            console.log(JSON.stringify(mainStyles, null, 2));
        }
        
        // Check overall page structure
        const pageStructure = await page.evaluate(() => {
            const pageContainer = document.querySelector('.page');
            const sidebar = document.querySelector('.sidebar');
            const main = document.querySelector('main');
            
            // Get the actual DOM hierarchy
            let hierarchy = [];
            if (pageContainer) {
                hierarchy.push({
                    element: '.page',
                    display: window.getComputedStyle(pageContainer).display,
                    flexDirection: window.getComputedStyle(pageContainer).flexDirection,
                    children: Array.from(pageContainer.children).map(child => ({
                        tag: child.tagName.toLowerCase(),
                        className: child.className
                    }))
                });
            }
            
            // Check if sidebar and main are siblings
            let areSiblings = false;
            if (sidebar && main && sidebar.parentElement === main.parentElement) {
                areSiblings = true;
            }
            
            return {
                hasPageContainer: !!pageContainer,
                hasSidebar: !!sidebar,
                hasMain: !!main,
                sidebarParent: sidebar ? sidebar.parentElement.className : null,
                mainParent: main ? main.parentElement.className : null,
                areSiblings: areSiblings,
                hierarchy: hierarchy
            };
        });
        
        console.log('\n=== PAGE STRUCTURE ===');
        console.log(JSON.stringify(pageStructure, null, 2));
        
        // Check specific CSS rules for layout
        const layoutCSS = await page.evaluate(() => {
            const rules = [];
            for (let sheet of document.styleSheets) {
                try {
                    for (let rule of sheet.cssRules) {
                        if (rule.selectorText && 
                            (rule.selectorText.includes('.page') || 
                             rule.selectorText.includes('.sidebar') || 
                             rule.selectorText.includes('main'))) {
                            rules.push({
                                selector: rule.selectorText,
                                styles: rule.style.cssText
                            });
                        }
                    }
                } catch (e) {
                    // Skip if we can't access the rules
                }
            }
            return rules;
        });
        
        console.log('\n=== RELEVANT CSS RULES ===');
        layoutCSS.forEach(rule => {
            if (rule.styles.includes('flex') || rule.styles.includes('position') || 
                rule.styles.includes('margin') || rule.styles.includes('width')) {
                console.log(`${rule.selector}: ${rule.styles}`);
            }
        });
        
        // Visual position analysis
        if (sidebarExists && mainExists) {
            const positions = await page.evaluate(() => {
                const sidebar = document.querySelector('.sidebar');
                const main = document.querySelector('main');
                
                const sidebarRect = sidebar.getBoundingClientRect();
                const mainRect = main.getBoundingClientRect();
                
                return {
                    sidebar: {
                        top: Math.round(sidebarRect.top),
                        left: Math.round(sidebarRect.left),
                        right: Math.round(sidebarRect.right),
                        bottom: Math.round(sidebarRect.bottom),
                        width: Math.round(sidebarRect.width),
                        height: Math.round(sidebarRect.height)
                    },
                    main: {
                        top: Math.round(mainRect.top),
                        left: Math.round(mainRect.left), 
                        right: Math.round(mainRect.right),
                        bottom: Math.round(mainRect.bottom),
                        width: Math.round(mainRect.width),
                        height: Math.round(mainRect.height)
                    },
                    analysis: {
                        sidebarIsAbove: sidebarRect.bottom <= mainRect.top + 10,
                        sidebarIsBeside: sidebarRect.right <= mainRect.left + 10,
                        sidebarIsBelow: sidebarRect.top >= mainRect.bottom - 10,
                        overlapping: !(sidebarRect.right <= mainRect.left || 
                                     mainRect.right <= sidebarRect.left || 
                                     sidebarRect.bottom <= mainRect.top || 
                                     mainRect.bottom <= sidebarRect.top)
                    }
                };
            });
            
            console.log('\n=== VISUAL LAYOUT ANALYSIS ===');
            console.log(JSON.stringify(positions, null, 2));
            
            if (positions.analysis.sidebarIsAbove) {
                console.log('\n⚠️  ISSUE DETECTED: Sidebar is positioned ABOVE the main content!');
                console.log('Expected: Sidebar should be on the LEFT side of main content');
            } else if (positions.analysis.sidebarIsBeside) {
                console.log('\n✓ Layout appears correct: Sidebar is beside the main content');
            } else if (positions.analysis.overlapping) {
                console.log('\n⚠️  ISSUE DETECTED: Sidebar and main content are overlapping!');
            }
        }
        
    } catch (error) {
        console.error('Error during diagnosis:', error);
        await page.screenshot({ 
            path: 'sidebar-diagnosis-error.png',
            fullPage: true 
        });
    }
    
    console.log('\n=== DIAGNOSIS COMPLETE ===');
    await browser.close();
})();