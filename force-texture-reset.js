// Force complete texture reset for Blazor Server app
console.log("=== FORCE TEXTURE RESET ===");

// 1. Clear all texture references from DOM
function clearTextureFromDOM() {
    console.log("\n--- Clearing texture from DOM ---");
    
    // Remove active class from all texture buttons
    document.querySelectorAll('[data-texture].active').forEach(btn => {
        btn.classList.remove('active');
        console.log(`Cleared active state from texture: ${btn.getAttribute('data-texture')}`);
    });
    
    // Update all avatar images to remove texture
    document.querySelectorAll('img[src*="dicebear"]').forEach(img => {
        if (img.src.includes('texture')) {
            const url = new URL(img.src);
            url.searchParams.delete('texture[]');
            url.searchParams.delete('textureProbability');
            img.src = url.toString();
            console.log("Removed texture from avatar image");
        }
    });
}

// 2. Intercept Blazor SignalR messages
function interceptBlazorMessages() {
    console.log("\n--- Installing Blazor interceptor ---");
    
    if (window.Blazor && window.Blazor._internal) {
        const originalSend = window.Blazor._internal.navigationManager.send;
        window.Blazor._internal.navigationManager.send = function(...args) {
            // Log and modify if needed
            console.log("Blazor message:", args);
            return originalSend.apply(this, args);
        };
        console.log("✅ Blazor interceptor installed");
    } else {
        console.log("⚠️ Blazor internal API not available");
    }
}

// 3. Force component re-render
function forceComponentRerender() {
    console.log("\n--- Forcing component re-render ---");
    
    // Trigger Blazor state change
    const avatarSelector = document.querySelector('enhanced-avatar-selector-v2, [data-component="avatar-selector"]');
    if (avatarSelector) {
        // Dispatch custom event to trigger re-render
        avatarSelector.dispatchEvent(new CustomEvent('force-refresh', { bubbles: true }));
        console.log("Dispatched force-refresh event");
    }
    
    // Click a different tab and back to texture
    const textureTab = document.querySelector('[data-tab="texture"], button:contains("Texture")');
    const faceTab = document.querySelector('[data-tab="face"], button:contains("Face")');
    
    if (faceTab && textureTab) {
        console.log("Switching tabs to force refresh...");
        faceTab.click();
        setTimeout(() => {
            textureTab.click();
            console.log("Returned to texture tab");
        }, 100);
    }
}

// 4. Clear browser caches
function clearBrowserCaches() {
    console.log("\n--- Clearing browser caches ---");
    
    // Clear localStorage
    const keysToRemove = [];
    for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && (key.includes('avatar') || key.includes('dicebear'))) {
            keysToRemove.push(key);
        }
    }
    keysToRemove.forEach(key => {
        localStorage.removeItem(key);
        console.log(`Removed localStorage: ${key}`);
    });
    
    // Clear sessionStorage
    const sessionKeysToRemove = [];
    for (let i = 0; i < sessionStorage.length; i++) {
        const key = sessionStorage.key(i);
        if (key && (key.includes('avatar') || key.includes('dicebear'))) {
            sessionKeysToRemove.push(key);
        }
    }
    sessionKeysToRemove.forEach(key => {
        sessionStorage.removeItem(key);
        console.log(`Removed sessionStorage: ${key}`);
    });
}

// 5. Main reset function
window.forceTextureReset = function() {
    console.log("\n=== EXECUTING FORCE TEXTURE RESET ===");
    
    // Step 1: Clear DOM
    clearTextureFromDOM();
    
    // Step 2: Clear caches
    clearBrowserCaches();
    
    // Step 3: Force re-render
    forceComponentRerender();
    
    // Step 4: Verify
    setTimeout(() => {
        console.log("\n--- Verification ---");
        const avatarImg = document.querySelector('.avatar-preview');
        if (avatarImg) {
            const hasTexture = avatarImg.src.includes('texture');
            if (!hasTexture) {
                console.log("✅ SUCCESS: Texture has been cleared!");
            } else {
                console.log("⚠️ Texture still present, may need page reload");
            }
        }
    }, 500);
    
    console.log("\n✅ Force reset complete");
    console.log("If texture persists, perform a hard refresh (Ctrl+F5)");
};

// Auto-execute initial cleanup
clearTextureFromDOM();

console.log("\n=== INSTRUCTIONS ===");
console.log("Run: forceTextureReset() to execute complete reset");
console.log("Then perform a hard refresh (Ctrl+F5) if needed");