// Script to verify no texture parameters in avatar URLs
console.log("=== Verifying Avatar URLs ===");

// Check all image elements
const images = document.querySelectorAll('img');
let textureCount = 0;

images.forEach((img, index) => {
    if (img.src && img.src.includes('dicebear.com')) {
        console.log(`\nImage ${index + 1}:`);
        console.log(`URL: ${img.src}`);
        
        // Parse URL to check for texture parameter
        try {
            const url = new URL(img.src);
            const params = new URLSearchParams(url.search);
            let hasTexture = false;
            
            // Check for texture parameters
            for (const [key, value] of params) {
                if (key.includes('texture')) {
                    hasTexture = true;
                    console.log(`❌ Found texture parameter: ${key}=${value}`);
                    textureCount++;
                }
            }
            
            if (!hasTexture) {
                console.log('✅ No texture parameter found');
            }
        } catch (e) {
            console.log('Could not parse URL:', e.message);
        }
    }
});

if (textureCount === 0) {
    console.log("\n✅ SUCCESS: No texture parameters found in any DiceBear URLs");
} else {
    console.log(`\n❌ FAILURE: Found ${textureCount} images with texture parameters`);
}

// Also check if DiceBear API is returning textures even without parameters
console.log("\n=== Checking if API returns textures by default ===");
console.log("Look at the visual appearance of the avatars above.");
console.log("If you see circuit patterns, dots, or metal textures, the API might be adding them by default.");