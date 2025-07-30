window.setupClipboardPaste = function (dotNetRef) {
    document.addEventListener('paste', async function (e) {
        // Check if we have a paste target element that's active
        const pasteTarget = document.querySelector('.image-paste-target.paste-ready');
        if (!pasteTarget) return;

        e.preventDefault();
        
        const items = e.clipboardData.items;
        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            
            if (item.type.indexOf('image') !== -1) {
                const blob = item.getAsFile();
                const reader = new FileReader();
                
                reader.onload = async function(event) {
                    const base64 = event.target.result;
                    const fileName = `paste-${Date.now()}.png`;
                    
                    // Call back to Blazor component
                    await dotNetRef.invokeMethodAsync('HandlePastedImage', base64, fileName);
                };
                
                reader.readAsDataURL(blob);
            }
        }
    });
    
    // Also handle keyboard shortcut for paste
    document.addEventListener('keydown', function(e) {
        if (e.ctrlKey && e.key === 'v') {
            const pasteTarget = document.querySelector('.image-paste-target');
            if (pasteTarget && document.activeElement !== pasteTarget) {
                pasteTarget.click();
            }
        }
    });
};