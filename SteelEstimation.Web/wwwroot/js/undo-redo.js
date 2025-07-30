window.undoRedoManager = {
    dotNetHelper: null,
    
    initialize: function(dotNetHelper) {
        // Store the reference if provided
        if (dotNetHelper) {
            this.dotNetHelper = dotNetHelper;
        }
        
        // Remove any existing event listener to prevent duplicates
        if (this.keydownHandler) {
            document.removeEventListener('keydown', this.keydownHandler);
        }
        
        // Create and store the handler
        this.keydownHandler = function(event) {
            // Check if we're in an input field
            const activeElement = document.activeElement;
            const isInputField = activeElement && (
                activeElement.tagName === 'INPUT' ||
                activeElement.tagName === 'TEXTAREA' ||
                activeElement.contentEditable === 'true'
            );
            
            // Check if Ctrl (or Cmd on Mac) is pressed
            const isCtrlOrCmd = event.ctrlKey || event.metaKey;
            
            if (isCtrlOrCmd && !isInputField) {
                if (event.key === 'z' && !event.shiftKey) {
                    // Ctrl+Z: Undo
                    event.preventDefault();
                    const undoButton = document.querySelector('button[title*="Undo"]:not([disabled])');
                    if (undoButton) {
                        undoButton.click();
                    }
                } else if ((event.key === 'z' && event.shiftKey) || event.key === 'y') {
                    // Ctrl+Shift+Z or Ctrl+Y: Redo
                    event.preventDefault();
                    const redoButton = document.querySelector('button[title*="Redo"]:not([disabled])');
                    if (redoButton) {
                        redoButton.click();
                    }
                }
            }
        };
        
        document.addEventListener('keydown', this.keydownHandler);
    }
};