// Script to inspect the actual URLs being used for preview images
console.log("=== Inspecting Avatar URLs ===");

// Check all preview images
const previewImages = document.querySelectorAll('.visual-option-btn img');
console.log(`\nFound ${previewImages.length} preview images`);

previewImages.forEach((img, index) => {
    const parent = img.closest('.visual-option-btn');
    const label = parent?.querySelector('.option-label')?.textContent || 'Unknown';
    
    if (img.src && img.src.includes('dicebear.com')) {
        console.log(`\n${label}:`);
        console.log(img.src);
        
        // Check if texture parameter is present
        if (img.src.includes('texture')) {
            console.log("✓ Has texture parameter");
        } else {
            console.log("✗ NO texture parameter");
        }
    }
});

// Check main avatar
const mainAvatar = document.querySelector('.avatar-preview');
if (mainAvatar && mainAvatar.src) {
    console.log("\n=== Main Avatar ===");
    console.log(mainAvatar.src);
    if (mainAvatar.src.includes('texture')) {
        console.log("✓ Has texture parameter");
    } else {
        console.log("✗ NO texture parameter");
    }
}