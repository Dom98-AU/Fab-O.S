// Final check for textures in avatar customization
console.log("=== Final Texture Verification ===");

// 1. Check all preview images
const previewImages = document.querySelectorAll('.visual-option-btn img');
console.log(`\nChecking ${previewImages.length} preview images...`);

let texturesFound = [];
previewImages.forEach((img, index) => {
    if (img.src && img.src.includes('dicebear.com')) {
        try {
            const url = new URL(img.src);
            const params = Array.from(url.searchParams.entries());
            const textureParams = params.filter(([key]) => key.includes('texture'));
            
            if (textureParams.length > 0) {
                const parent = img.closest('.visual-option-btn');
                const label = parent?.querySelector('.option-label')?.textContent || 'Unknown';
                texturesFound.push({
                    label,
                    url: img.src,
                    textureParams
                });
            }
        } catch (e) {}
    }
});

// 2. Visual inspection helper
console.log("\n=== Visual Inspection Guide ===");
console.log("Look for these texture patterns in the preview images:");
console.log("❌ Circuits - Green circuit board patterns");
console.log("❌ Dots - Polka dot patterns");
console.log("❌ Metal - Metallic gradient");
console.log("❌ Lines - Line patterns");
console.log("✅ Solid colors only - No patterns");

// 3. Check main avatar
const mainAvatar = document.querySelector('.avatar-preview');
if (mainAvatar && mainAvatar.src.includes('dicebear.com')) {
    console.log("\n=== Main Avatar ===");
    console.log("URL:", mainAvatar.src);
    try {
        const url = new URL(mainAvatar.src);
        const hasTexture = Array.from(url.searchParams.keys()).some(key => key.includes('texture'));
        console.log(hasTexture ? "❌ Has texture parameter" : "✅ No texture parameter");
    } catch (e) {}
}

// 4. Summary
if (texturesFound.length === 0) {
    console.log("\n✅ SUCCESS: No texture parameters found in URLs!");
    console.log("Please visually verify that the avatars show solid colors only.");
} else {
    console.log(`\n❌ Found ${texturesFound.length} images with texture parameters:`);
    texturesFound.forEach(item => {
        console.log(`- ${item.label}: ${item.textureParams.map(([k,v]) => `${k}=${v}`).join(', ')}`);
    });
}

// 5. Clear cache reminder
console.log("\n💡 If you still see textures visually:");
console.log("1. Hard refresh the page (Ctrl+Shift+R or Cmd+Shift+R)");
console.log("2. Clear browser cache");
console.log("3. Try incognito/private mode");