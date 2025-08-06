// Debug the Top tab specifically
console.log("=== DEBUGGING TOP TAB ALIGNMENT ===");

// Get all tabs
const allTabs = document.querySelectorAll('.nav-tabs .nav-link');
const topTab = Array.from(allTabs).find(t => t.textContent.includes('Top'));
const otherTabs = Array.from(allTabs).filter(t => !t.textContent.includes('Top'));

if (topTab) {
    console.log("\n1. TOP TAB DETAILS:");
    const topRect = topTab.getBoundingClientRect();
    const topStyles = window.getComputedStyle(topTab);
    console.log("Position:", {
        top: topRect.top,
        height: topRect.height,
        padding: topStyles.padding,
        margin: topStyles.margin,
        lineHeight: topStyles.lineHeight,
        display: topStyles.display
    });
    
    // Check the icon specifically
    const topIcon = topTab.querySelector('i');
    if (topIcon) {
        const iconRect = topIcon.getBoundingClientRect();
        const iconStyles = window.getComputedStyle(topIcon);
        console.log("\nTop tab icon details:");
        console.log({
            class: topIcon.className,
            top: iconRect.top,
            height: iconRect.height,
            fontSize: iconStyles.fontSize,
            lineHeight: iconStyles.lineHeight,
            verticalAlign: iconStyles.verticalAlign,
            position: iconStyles.position,
            topOffset: iconStyles.top
        });
    }
}

if (otherTabs.length > 0) {
    console.log("\n2. OTHER TABS (for comparison):");
    const firstOther = otherTabs[0];
    const otherRect = firstOther.getBoundingClientRect();
    const otherStyles = window.getComputedStyle(firstOther);
    console.log("First other tab position:", {
        text: firstOther.textContent.trim(),
        top: otherRect.top,
        height: otherRect.height
    });
    
    // Compare
    if (topTab) {
        const topRect = topTab.getBoundingClientRect();
        const difference = topRect.top - otherRect.top;
        console.log("\n3. ALIGNMENT DIFFERENCE: " + difference + "px");
        if (Math.abs(difference) > 1) {
            console.log("❌ Top tab is " + (difference > 0 ? 'LOWER' : 'HIGHER') + " by " + Math.abs(difference) + "px");
        } else {
            console.log("✅ Tabs are aligned");
        }
    }
}

// Check parent container
const navTabs = document.querySelector('.nav-tabs');
if (navTabs) {
    const navStyles = window.getComputedStyle(navTabs);
    console.log("\n4. NAV-TABS CONTAINER:");
    console.log({
        display: navStyles.display,
        gridTemplateColumns: navStyles.gridTemplateColumns,
        alignItems: navStyles.alignItems,
        height: navStyles.height
    });
}