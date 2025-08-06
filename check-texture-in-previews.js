// Script to check if texture is still appearing in preview images
function checkPreviewImages() {
    console.log("\n=== Checking Avatar Preview Images ===");
    
    // Find all preview images in the customization options
    const previewImages = document.querySelectorAll('.visual-option-btn img');
    console.log(`Found ${previewImages.length} preview images`);
    
    let textureCount = 0;
    previewImages.forEach((img, index) => {
        if (img.src && img.src.includes('texture')) {
            textureCount++;
            console.log(`❌ Image ${index + 1} contains texture in URL:`, img.src);
        }
    });
    
    if (textureCount === 0) {
        console.log("✅ No textures found in preview images");
    } else {
        console.log(`❌ Found ${textureCount} images with texture in URL`);
    }
    
    // Check main avatar preview
    const mainAvatar = document.querySelector('.avatar-preview');
    if (mainAvatar) {
        console.log("\n=== Main Avatar Preview ===");
        console.log("URL:", mainAvatar.src);
        if (mainAvatar.src.includes('texture')) {
            console.log("❌ Main avatar contains texture");
        } else {
            console.log("✅ Main avatar has no texture");
        }
    }
    
    // Check cache in component
    console.log("\n=== Checking Component State ===");
    const blazorComponent = document.querySelector('[data-enhance]');
    if (blazorComponent && blazorComponent._blazorComponent) {
        console.log("Component found, checking preview cache...");
        // This would need access to the component internals
    }
}

// Run the check
checkPreviewImages();

// Also monitor for new images being loaded
const observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
        mutation.addedNodes.forEach((node) => {
            if (node.tagName === 'IMG' && node.src && node.src.includes('texture')) {
                console.log("❌ New image with texture detected:", node.src);
            }
        });
    });
});

// Start observing
observer.observe(document.body, { 
    childList: true, 
    subtree: true,
    attributes: true,
    attributeFilter: ['src']
});

console.log("Observer started - monitoring for texture in new images");