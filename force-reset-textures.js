// Force reset all avatar preview images to remove texture
console.log("=== Force Texture Reset ===");

// 1. Clear all image sources to force reload
const previewImages = document.querySelectorAll('.visual-option-btn img');
console.log(`Found ${previewImages.length} preview images to reset`);

previewImages.forEach((img, index) => {
    const originalSrc = img.src;
    
    // Clear and reset each image to force browser to reload
    img.src = '';
    
    // Add a cache-busting parameter
    setTimeout(() => {
        if (originalSrc.includes('dicebear.com')) {
            const url = new URL(originalSrc);
            // Add cache buster
            url.searchParams.set('cb', Date.now());
            // Ensure no texture parameter
            url.searchParams.delete('texture');
            url.searchParams.delete('texture[]');
            img.src = url.toString();
            console.log(`Reset image ${index + 1}`);
        } else {
            img.src = originalSrc;
        }
    }, 100 * index); // Stagger the reloads
});

// 2. Force reload the main avatar
const mainAvatar = document.querySelector('.avatar-preview');
if (mainAvatar && mainAvatar.src.includes('dicebear.com')) {
    const url = new URL(mainAvatar.src);
    url.searchParams.set('cb', Date.now());
    url.searchParams.delete('texture');
    url.searchParams.delete('texture[]');
    mainAvatar.src = url.toString();
    console.log("Reset main avatar");
}

// 3. Trigger Blazor to regenerate previews
console.log("\nTo fully regenerate previews:");
console.log("1. Click on a different color swatch");
console.log("2. Click back to your original color");
console.log("This will trigger the component to regenerate all previews without texture");

// 4. Clear browser image cache for dicebear.com
console.log("\nAlternatively, clear browser cache:");
console.log("1. Open DevTools (F12)");
console.log("2. Right-click the refresh button");
console.log("3. Select 'Empty Cache and Hard Reload'");