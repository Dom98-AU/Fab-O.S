// Simple column resize functionality
window.simpleResize = {
    init: function() {
        console.log('Simple resize: Initializing...');
        
        // Wait a bit for the table to be fully rendered
        setTimeout(() => {
            const tables = document.querySelectorAll('.table-resizable, .enhanced-table');
            if (!tables.length) {
                console.log('Simple resize: No resizable tables found');
                return;
            }
            
            tables.forEach(table => {
            
            const headers = table.querySelectorAll('thead th');
            console.log(`Simple resize: Found ${headers.length} headers`);
            
            headers.forEach((header, index) => {
                // Skip first two columns (checkboxes) and last column (actions)
                if (index <= 1 || index === headers.length - 1) {
                    console.log(`Simple resize: Skipping column ${index}`);
                    return;
                }
                
                // Check if this header already has a resize handle
                if (header.querySelector('.simple-resize-handle')) {
                    console.log(`Simple resize: Handle already exists for column ${index}`);
                    return;
                }
                
                // Create a resize handle area
                const handle = document.createElement('div');
                handle.className = 'simple-resize-handle';
                handle.style.cssText = `
                    position: absolute;
                    right: -8px;
                    top: 0;
                    bottom: 0;
                    width: 16px;
                    cursor: col-resize;
                    user-select: none;
                    z-index: 1001;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                `;
                
                // Create the visual line that appears on hover
                const line = document.createElement('div');
                line.className = 'resize-line';
                line.style.cssText = `
                    width: 2px;
                    height: 100%;
                    background-color: #0d6efd;
                    opacity: 0;
                    transition: opacity 0.2s;
                `;
                handle.appendChild(line);
                
                // Make header relative positioned
                header.style.position = 'relative';
                header.appendChild(handle);
                
                console.log(`Simple resize: Added handle to column ${index}: "${header.textContent.trim()}"`);
                
                // Add hover effect to show the line
                handle.addEventListener('mouseenter', function() {
                    line.style.opacity = '1';
                });
                
                handle.addEventListener('mouseleave', function() {
                    line.style.opacity = '0';
                });
                
                // Add resize functionality
                let startX = 0;
                let startWidth = 0;
                let currentHeader = header;
                
                handle.addEventListener('mousedown', function(e) {
                    e.preventDefault();
                    e.stopPropagation();
                    
                    startX = e.pageX;
                    startWidth = currentHeader.offsetWidth;
                    
                    document.body.style.cursor = 'col-resize';
                    
                    // Add visual feedback
                    line.style.opacity = '1';
                    line.style.width = '3px';
                    
                    function handleMouseMove(e) {
                        const diff = e.pageX - startX;
                        const newWidth = Math.max(50, startWidth + diff); // Min width 50px
                        
                        currentHeader.style.width = newWidth + 'px';
                        currentHeader.style.minWidth = newWidth + 'px';
                        currentHeader.style.maxWidth = newWidth + 'px';
                    }
                    
                    function handleMouseUp() {
                        document.body.style.cursor = '';
                        line.style.opacity = '0';
                        line.style.width = '2px';
                        
                        document.removeEventListener('mousemove', handleMouseMove);
                        document.removeEventListener('mouseup', handleMouseUp);
                        
                        // Save the width
                        const columnName = currentHeader.textContent.trim();
                        console.log(`Simple resize: Column "${columnName}" resized to ${currentHeader.offsetWidth}px`);
                    }
                    
                    document.addEventListener('mousemove', handleMouseMove);
                    document.addEventListener('mouseup', handleMouseUp);
                });
            });
            }); // End forEach table
            
            console.log('Simple resize: Initialization complete');
        }, 500);
    }
};