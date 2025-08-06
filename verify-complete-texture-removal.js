// Comprehensive script to verify texture removal from all avatar elements
console.log("=== COMPLETE TEXTURE REMOVAL VERIFICATION ===");
console.log("Running at:", new Date().toLocaleTimeString());

// 1. Check main avatar preview
console.log("\n1. MAIN AVATAR PREVIEW:");
const mainAvatar = document.querySelector('.avatar-preview');
if (mainAvatar && mainAvatar.src) {
    console.log("URL:", mainAvatar.src);
    if (mainAvatar.src.includes('texture')) {
        console.log("❌ FAIL: Main avatar contains 'texture' in URL");
    } else {
        console.log("✅ PASS: Main avatar has NO texture parameter");
    }
}

// 2. Check all customization preview images
console.log("\n2. CUSTOMIZATION PREVIEW IMAGES:");
const previewImages = document.querySelectorAll('.visual-option-btn img');
console.log(`Found ${previewImages.length} preview images`);

let textureFound = false;
previewImages.forEach((img, index) => {
    if (img.src && img.src.includes('dicebear.com')) {
        const parent = img.closest('.visual-option-btn');
        const label = parent?.querySelector('.option-label')?.textContent || `Image ${index + 1}`;
        
        if (img.src.includes('texture')) {
            console.log(`❌ ${label}: Contains texture in URL`);
            console.log(`   URL: ${img.src}`);
            textureFound = true;
        }
    }
});

if (!textureFound && previewImages.length > 0) {
    console.log("✅ PASS: No texture parameters found in any preview images");
}

// 3. Check for texture-related UI elements
console.log("\n3. UI ELEMENTS CHECK:");
const textureElements = document.querySelectorAll('[class*="texture"], [id*="texture"], [data-*="texture"]');
if (textureElements.length > 0) {
    console.log(`❌ Found ${textureElements.length} elements with 'texture' in attributes`);
    textureElements.forEach(el => {
        console.log(`   - ${el.tagName}: ${el.className || el.id}`);
    });
} else {
    console.log("✅ PASS: No texture-related UI elements found");
}

// 4. Check tab structure
console.log("\n4. TAB STRUCTURE:");
const tabs = document.querySelectorAll('.nav-tabs .nav-link');
console.log(`Found ${tabs.length} tabs:`);
tabs.forEach(tab => {
    const text = tab.textContent.trim();
    console.log(`   - ${text}`);
    if (text.toLowerCase().includes('texture')) {
        console.log("     ❌ WARNING: Tab contains 'texture'");
    }
});

// 5. Check if Sides and Top are separate tabs
const sidesTab = Array.from(tabs).find(t => t.textContent.trim() === 'Sides');
const topTab = Array.from(tabs).find(t => t.textContent.trim() === 'Top');
if (sidesTab && topTab) {
    console.log("✅ PASS: Sides and Top are separate tabs");
} else {
    console.log("❌ FAIL: Sides and Top tabs not properly separated");
}

// 6. Summary
console.log("\n=== SUMMARY ===");
if (!textureFound && !mainAvatar?.src?.includes('texture')) {
    console.log("✅ SUCCESS: Textures completely removed from all avatar images");
} else {
    console.log("❌ ISSUE: Some texture references still present");
    console.log("Try refreshing the page with Ctrl+Shift+R (hard refresh)");
}