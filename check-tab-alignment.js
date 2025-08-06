// Check tab alignment with precise measurements
console.log("=== TAB ALIGNMENT CHECK ===");

const tabs = document.querySelectorAll('.nav-tabs .nav-link');
console.log(`Found ${tabs.length} tabs`);

if (tabs.length > 0) {
    const measurements = [];
    
    tabs.forEach((tab, index) => {
        const rect = tab.getBoundingClientRect();
        const text = tab.textContent.trim();
        measurements.push({
            text: text,
            top: rect.top,
            bottom: rect.bottom,
            height: rect.height,
            offsetTop: tab.offsetTop
        });
    });
    
    // Check alignment
    console.table(measurements);
    
    // Find if any tab is misaligned
    const topPositions = measurements.map(m => m.top);
    const uniqueTops = [...new Set(topPositions)];
    
    if (uniqueTops.length === 1) {
        console.log("✅ SUCCESS: All tabs are perfectly aligned\!");
    } else {
        console.log("❌ ISSUE: Tabs are not aligned");
        console.log("Unique top positions:", uniqueTops);
        
        // Find which tab is different
        measurements.forEach(m => {
            const avgTop = topPositions.reduce((a,b) => a+b, 0) / topPositions.length;
            if (Math.abs(m.top - avgTop) > 1) {
                console.log(`  - "${m.text}" is misaligned (top: ${m.top}, avg: ${avgTop})`);
            }
        });
    }
}
