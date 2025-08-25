const { chromium } = require('playwright');
const fs = require('fs');

async function testSidebarFunctionality() {
    console.log('Starting comprehensive sidebar functionality test...');
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    
    // Test results object
    const testResults = {
        timestamp: timestamp,
        tests: [],
        screenshots: [],
        overall: 'PENDING'
    };

    const browser = await chromium.launch({ 
        headless: false,
        args: ['--disable-blink-features=AutomationControlled']
    });
    
    const context = await browser.newContext({
        ignoreHTTPSErrors: true,
        viewport: { width: 1920, height: 1080 }
    });
    
    const page = await context.newPage();
    
    try {
        // Step 1: Navigate to the application
        console.log('\n1. Navigating to http://localhost:8080...');
        await page.goto('http://localhost:8080', { 
            waitUntil: 'networkidle',
            timeout: 30000 
        });
        await page.waitForTimeout(2000);
        
        // Take screenshot of landing page
        const landingScreenshot = `sidebar-test-1-landing-${timestamp}.png`;
        await page.screenshot({ path: landingScreenshot, fullPage: true });
        testResults.screenshots.push(landingScreenshot);
        console.log('   ✓ Landing page loaded and screenshot taken');
        
        // Step 2: Click Sign In and Login
        console.log('\n2. Clicking Sign In button and logging in...');
        
        // Click the Sign In button
        await page.click('button:has-text("Sign In"), a:has-text("Sign In"), .sign-in-button');
        await page.waitForTimeout(2000);
        
        // Now fill in the login form
        console.log('   Filling in login credentials...');
        
        // Try multiple selectors for email field
        const emailFilled = await page.locator('input[type="email"], input[name="Input.Email"], #Input_Email, input[placeholder*="email" i]').first().fill('admin@steelestimation.com');
        
        // Try multiple selectors for password field
        const passwordFilled = await page.locator('input[type="password"], input[name="Input.Password"], #Input_Password').first().fill('Admin@123');
        
        // Take screenshot before login
        const loginScreenshot = `sidebar-test-2-login-form-${timestamp}.png`;
        await page.screenshot({ path: loginScreenshot, fullPage: true });
        testResults.screenshots.push(loginScreenshot);
        
        // Click login/submit button
        await page.click('button[type="submit"], button:has-text("Log in"), button:has-text("Sign in"), input[type="submit"]');
        
        // Wait for navigation after login
        console.log('   Waiting for login to complete...');
        await page.waitForTimeout(5000); // Give more time for login
        
        // Check if we're logged in by looking for logout button or user menu
        const isLoggedIn = await page.locator('button:has-text("Logout"), a:has-text("Logout"), .user-menu, .user-avatar').count() > 0;
        
        if (!isLoggedIn) {
            console.log('   ⚠ Login might have failed, continuing with test...');
        } else {
            console.log('   ✓ Successfully logged in');
        }
        
        // Step 3: Verify initial sidebar state
        console.log('\n3. Verifying initial sidebar state...');
        
        // Check if sidebar exists with multiple possible selectors
        const sidebarSelectors = [
            '.sidebar',
            '#sidebar',
            'nav.sidebar',
            'aside.sidebar',
            '.nav-sidebar',
            '.left-sidebar',
            '.side-nav',
            '[class*="sidebar"]'
        ];
        
        let sidebarFound = false;
        for (const selector of sidebarSelectors) {
            const count = await page.locator(selector).count();
            if (count > 0) {
                sidebarFound = true;
                console.log(`   ✓ Sidebar found with selector: ${selector}`);
                break;
            }
        }
        
        if (!sidebarFound) {
            console.log('   ✗ Sidebar element not found');
        }
        
        // Verify logo presence and centering
        const logoCheck = await page.evaluate(() => {
            const logoSelectors = [
                '.sidebar-logo img',
                '.sidebar img',
                '.nav-logo img',
                '.logo-container img',
                '.sidebar .logo img',
                'img[alt*="logo" i]'
            ];
            
            let logo = null;
            for (const selector of logoSelectors) {
                logo = document.querySelector(selector);
                if (logo) break;
            }
            
            if (!logo) return { exists: false };
            
            const logoRect = logo.getBoundingClientRect();
            const parent = logo.closest('.sidebar, #sidebar, nav.sidebar, aside.sidebar, .nav-sidebar, [class*="sidebar"]');
            const parentRect = parent ? parent.getBoundingClientRect() : null;
            
            return {
                exists: true,
                src: logo.src,
                width: logoRect.width,
                height: logoRect.height,
                left: logoRect.left,
                parentWidth: parentRect ? parentRect.width : 0,
                isCentered: parentRect ? Math.abs((logoRect.left - parentRect.left) - (parentRect.right - logoRect.right)) < 20 : false,
                computedStyles: logo.parentElement ? window.getComputedStyle(logo.parentElement).textAlign : 'unknown'
            };
        });
        
        testResults.tests.push({
            name: 'Logo Verification',
            passed: logoCheck.exists,
            details: logoCheck
        });
        
        console.log(`   ${logoCheck.exists ? '✓' : '✗'} Logo found: ${logoCheck.exists}`);
        if (logoCheck.exists) {
            console.log(`   ${logoCheck.isCentered ? '✓' : '✗'} Logo centered: ${logoCheck.isCentered}`);
        }
        
        // Check hamburger button visibility
        const hamburgerSelectors = [
            '.hamburger-menu',
            '.menu-toggle',
            '.sidebar-toggle',
            'button[onclick*="toggleSidebar"]',
            'button[onclick*="toggle"]',
            '.navbar-toggler',
            '.toggle-sidebar',
            '.menu-button',
            '[class*="hamburger"]',
            '[class*="toggle"]'
        ];
        
        let hamburgerFound = false;
        let hamburgerSelector = '';
        for (const selector of hamburgerSelectors) {
            const visible = await page.locator(selector).first().isVisible().catch(() => false);
            if (visible) {
                hamburgerFound = true;
                hamburgerSelector = selector;
                console.log(`   ✓ Hamburger button found with selector: ${selector}`);
                break;
            }
        }
        
        testResults.tests.push({
            name: 'Hamburger Button Visibility',
            passed: hamburgerFound,
            details: { visible: hamburgerFound, selector: hamburgerSelector }
        });
        
        if (!hamburgerFound) {
            console.log('   ✗ Hamburger button not found');
        }
        
        // Take screenshot of initial expanded state
        const expandedScreenshot = `sidebar-test-3-expanded-${timestamp}.png`;
        await page.screenshot({ path: expandedScreenshot, fullPage: true });
        testResults.screenshots.push(expandedScreenshot);
        console.log('   ✓ Initial expanded state screenshot taken');
        
        // Get initial sidebar state
        const initialSidebarState = await page.evaluate(() => {
            const sidebar = document.querySelector('.sidebar, #sidebar, nav.sidebar, aside.sidebar, .nav-sidebar, [class*="sidebar"]');
            const mainContent = document.querySelector('.main-content, main, .content, #main-content, [class*="main"]');
            
            return {
                sidebarWidth: sidebar ? sidebar.offsetWidth : 0,
                sidebarVisible: sidebar ? window.getComputedStyle(sidebar).display !== 'none' : false,
                mainContentMargin: mainContent ? window.getComputedStyle(mainContent).marginLeft : '0',
                sidebarTransform: sidebar ? window.getComputedStyle(sidebar).transform : 'none'
            };
        });
        
        console.log(`   Initial sidebar width: ${initialSidebarState.sidebarWidth}px`);
        
        // Step 4: Test collapse functionality
        if (hamburgerFound) {
            console.log('\n4. Testing sidebar collapse...');
            
            // Click hamburger to collapse
            await page.locator(hamburgerSelector).first().click();
            await page.waitForTimeout(1500); // Wait for animation
            
            // Verify collapsed state
            const collapsedState = await page.evaluate(() => {
                const sidebar = document.querySelector('.sidebar, #sidebar, nav.sidebar, aside.sidebar, .nav-sidebar, [class*="sidebar"]');
                const mainContent = document.querySelector('.main-content, main, .content, #main-content, [class*="main"]');
                const body = document.body;
                
                const sidebarStyles = sidebar ? window.getComputedStyle(sidebar) : null;
                const isCollapsed = body.classList.contains('sidebar-collapsed') || 
                                   sidebar?.classList.contains('collapsed') ||
                                   (sidebarStyles && (
                                       sidebarStyles.transform.includes('translateX(-') ||
                                       parseFloat(sidebarStyles.marginLeft) < 0 ||
                                       parseFloat(sidebarStyles.left) < 0
                                   ));
                
                return {
                    isCollapsed: isCollapsed,
                    sidebarWidth: sidebar ? sidebar.offsetWidth : 0,
                    sidebarTransform: sidebarStyles ? sidebarStyles.transform : 'none',
                    sidebarLeft: sidebarStyles ? sidebarStyles.left : '0',
                    sidebarMarginLeft: sidebarStyles ? sidebarStyles.marginLeft : '0',
                    mainContentMargin: mainContent ? window.getComputedStyle(mainContent).marginLeft : '0',
                    bodyClasses: body.className,
                    sidebarClasses: sidebar ? sidebar.className : '',
                    transition: sidebarStyles ? sidebarStyles.transition : 'none'
                };
            });
            
            testResults.tests.push({
                name: 'Sidebar Collapse',
                passed: collapsedState.isCollapsed,
                details: collapsedState
            });
            
            console.log(`   ${collapsedState.isCollapsed ? '✓' : '✗'} Sidebar collapsed: ${collapsedState.isCollapsed}`);
            console.log(`   Transform: ${collapsedState.sidebarTransform}`);
            console.log(`   Transition: ${collapsedState.transition}`);
            
            // Take screenshot of collapsed state
            const collapsedScreenshot = `sidebar-test-4-collapsed-${timestamp}.png`;
            await page.screenshot({ path: collapsedScreenshot, fullPage: true });
            testResults.screenshots.push(collapsedScreenshot);
            console.log('   ✓ Collapsed state screenshot taken');
            
            // Step 5: Test expand functionality
            console.log('\n5. Testing sidebar re-expand...');
            
            // Click hamburger to expand
            await page.locator(hamburgerSelector).first().click();
            await page.waitForTimeout(1500); // Wait for animation
            
            // Verify expanded state
            const reExpandedState = await page.evaluate(() => {
                const sidebar = document.querySelector('.sidebar, #sidebar, nav.sidebar, aside.sidebar, .nav-sidebar, [class*="sidebar"]');
                const mainContent = document.querySelector('.main-content, main, .content, #main-content, [class*="main"]');
                const body = document.body;
                
                const sidebarStyles = sidebar ? window.getComputedStyle(sidebar) : null;
                const isExpanded = !body.classList.contains('sidebar-collapsed') && 
                                  !sidebar?.classList.contains('collapsed') &&
                                  (sidebarStyles && (
                                      sidebarStyles.transform === 'none' || 
                                      sidebarStyles.transform === 'translateX(0px)' ||
                                      parseFloat(sidebarStyles.left) >= 0
                                  ));
                
                return {
                    isExpanded: isExpanded,
                    sidebarWidth: sidebar ? sidebar.offsetWidth : 0,
                    sidebarTransform: sidebarStyles ? sidebarStyles.transform : 'none',
                    sidebarLeft: sidebarStyles ? sidebarStyles.left : '0',
                    mainContentMargin: mainContent ? window.getComputedStyle(mainContent).marginLeft : '0',
                    bodyClasses: body.className,
                    sidebarClasses: sidebar ? sidebar.className : ''
                };
            });
            
            testResults.tests.push({
                name: 'Sidebar Re-expand',
                passed: reExpandedState.isExpanded,
                details: reExpandedState
            });
            
            console.log(`   ${reExpandedState.isExpanded ? '✓' : '✗'} Sidebar re-expanded: ${reExpandedState.isExpanded}`);
            console.log(`   Final sidebar width: ${reExpandedState.sidebarWidth}px`);
            
            // Take screenshot of re-expanded state
            const reExpandedScreenshot = `sidebar-test-5-reexpanded-${timestamp}.png`;
            await page.screenshot({ path: reExpandedScreenshot, fullPage: true });
            testResults.screenshots.push(reExpandedScreenshot);
            console.log('   ✓ Re-expanded state screenshot taken');
            
            // Step 6: Test animation smoothness
            console.log('\n6. Testing animation smoothness...');
            
            // Check for CSS transitions
            const animationTest = await page.evaluate(() => {
                const sidebar = document.querySelector('.sidebar, #sidebar, nav.sidebar, aside.sidebar, .nav-sidebar, [class*="sidebar"]');
                
                if (!sidebar) return { smooth: false, error: 'Sidebar not found' };
                
                const sidebarStyles = window.getComputedStyle(sidebar);
                const hasTransition = sidebarStyles.transition && !sidebarStyles.transition.includes('none');
                const transitionDuration = sidebarStyles.transitionDuration;
                
                return {
                    smooth: hasTransition,
                    transition: sidebarStyles.transition,
                    duration: transitionDuration,
                    hasAnimation: hasTransition
                };
            });
            
            testResults.tests.push({
                name: 'Animation Smoothness',
                passed: animationTest.smooth,
                details: animationTest
            });
            
            console.log(`   ${animationTest.smooth ? '✓' : '✗'} Smooth transitions: ${animationTest.smooth}`);
            console.log(`   Transition settings: ${animationTest.transition}`);
            console.log(`   Duration: ${animationTest.duration}`);
        } else {
            console.log('\n4-6. Skipping toggle tests - hamburger button not found');
        }
        
        // Final state screenshot
        const finalScreenshot = `sidebar-test-6-final-${timestamp}.png`;
        await page.screenshot({ path: finalScreenshot, fullPage: true });
        testResults.screenshots.push(finalScreenshot);
        
        // Determine overall test result
        const allTestsPassed = testResults.tests.every(test => test.passed);
        testResults.overall = allTestsPassed ? 'PASSED' : 'FAILED';
        
        // Generate test report
        console.log('\n' + '='.repeat(60));
        console.log('TEST RESULTS SUMMARY');
        console.log('='.repeat(60));
        console.log(`Overall Result: ${testResults.overall}`);
        console.log(`\nIndividual Tests:`);
        testResults.tests.forEach(test => {
            console.log(`  ${test.passed ? '✓' : '✗'} ${test.name}: ${test.passed ? 'PASSED' : 'FAILED'}`);
            if (!test.passed && test.details) {
                console.log(`     Details: ${JSON.stringify(test.details, null, 2).split('\n').join('\n     ')}`);
            }
        });
        console.log(`\nScreenshots captured:`);
        testResults.screenshots.forEach(screenshot => {
            console.log(`  - ${screenshot}`);
        });
        
        // Save detailed report
        const reportContent = JSON.stringify(testResults, null, 2);
        fs.writeFileSync(`sidebar-test-report-${timestamp}.json`, reportContent);
        console.log(`\nDetailed report saved to: sidebar-test-report-${timestamp}.json`);
        
    } catch (error) {
        console.error('\n❌ Test failed with error:', error);
        testResults.overall = 'ERROR';
        testResults.error = error.message;
        
        // Take error screenshot
        const errorScreenshot = `sidebar-test-error-${timestamp}.png`;
        await page.screenshot({ path: errorScreenshot, fullPage: true });
        console.log(`Error screenshot saved: ${errorScreenshot}`);
    } finally {
        await browser.close();
        console.log('\n' + '='.repeat(60));
        console.log('Test execution completed');
        console.log('='.repeat(60));
    }
}

// Run the test
testSidebarFunctionality().catch(console.error);