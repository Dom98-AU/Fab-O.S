// Table column resize functionality
window.tableResize = {
    initialize: function() {
        console.log('Table resize: Initializing...');
        // Initialize all tables with class 'table-resizable'
        const tables = document.querySelectorAll('table.table-resizable');
        console.log(`Table resize: Found ${tables.length} resizable tables`);
        tables.forEach(table => {
            this.initializeTable(table);
        });
    },
    
    reinitialize: function() {
        // Remove all existing resize handles
        document.querySelectorAll('.resize-handle').forEach(handle => handle.remove());
        
        // Reset initialization flags
        document.querySelectorAll('table.table-resizable').forEach(table => {
            delete table.dataset.resizeInitialized;
        });
        
        // Reinitialize
        this.initialize();
    },
    
    initializeTable: function(table) {
        if (!table || table.dataset.resizeInitialized) {
            console.log('Table resize: Table already initialized or not found');
            return;
        }
        table.dataset.resizeInitialized = 'true';
    
        const cols = table.querySelectorAll('thead th');
        console.log(`Table resize: Processing ${cols.length} columns`);
        
        cols.forEach((col, index) => {
            console.log(`Table resize: Processing column ${index}: "${col.textContent.trim()}"`);
            
            // Skip the last column (actions)
            if (index === cols.length - 1) {
                console.log(`Table resize: Skipping last column (actions)`);
                return;
            }
            
            // Skip columns that have drag handles (first two columns are checkboxes)
            if (index <= 1) {
                console.log(`Table resize: Skipping column ${index} (checkbox column)`);
                return;
            }
            
            // Check if resize handle already exists
            if (col.querySelector('.resize-handle')) {
                console.log(`Table resize: Resize handle already exists for column ${index}`);
                return;
            }
            
            // Create resize handle
            const resizeHandle = document.createElement('div');
            resizeHandle.className = 'resize-handle';
            resizeHandle.style.cssText = `
                position: absolute;
                right: -3px;
                top: 0;
                bottom: 0;
                width: 6px;
                cursor: col-resize;
                background-color: transparent;
                z-index: 1000;
                border-right: 2px solid transparent;
                transition: border-color 0.2s;
            `;
            
            resizeHandle.addEventListener('mouseenter', function() {
                this.style.borderRightColor = '#0d6efd';
                this.style.backgroundColor = 'rgba(13, 110, 253, 0.1)';
            });
            
            resizeHandle.addEventListener('mouseleave', function() {
                this.style.borderRightColor = 'transparent';
                this.style.backgroundColor = 'transparent';
            });
            
            col.appendChild(resizeHandle);
            col.style.position = 'relative';
            col.style.overflow = 'visible';
            console.log(`Table resize: Added resize handle to column ${index}`);
            
            let startX = 0;
            let startWidth = 0;
            
            resizeHandle.addEventListener('mousedown', (e) => {
                // Check if column is frozen
                const isFrozen = col.dataset.isFrozen === 'true';
                if (isFrozen) {
                    e.preventDefault();
                    e.stopPropagation();
                    this.showNotification('Frozen columns cannot be resized. Unfreeze the column first.');
                    return;
                }
                
                startX = e.pageX;
                startWidth = parseInt(window.getComputedStyle(col).width, 10);
                document.body.style.cursor = 'col-resize';
                
                const handleMouseMove = (e) => {
                    const diff = e.pageX - startX;
                    const newWidth = startWidth + diff;
                    
                    if (newWidth > 50) { // Minimum column width
                        col.style.width = newWidth + 'px';
                        
                        // Recalculate frozen column positions immediately during resize
                        this.updateFrozenColumnPositions(table);
                    }
                };
                
                const handleMouseUp = () => {
                    document.body.style.cursor = '';
                    document.removeEventListener('mousemove', handleMouseMove);
                    document.removeEventListener('mouseup', handleMouseUp);
                    
                    // Final position update
                    this.updateFrozenColumnPositions(table);
                    
                    // Save column widths
                    this.saveColumnWidths(table);
                };
                
                document.addEventListener('mousemove', handleMouseMove);
                document.addEventListener('mouseup', handleMouseUp);
                
                e.preventDefault();
            });
        });
        
        // Load saved column widths
        this.loadColumnWidths(table);
        
        // Initial frozen column position calculation
        this.updateFrozenColumnPositions(table);
    },
    
    updateFrozenColumnPositions: function(table) {
        if (!table) {
            console.error('updateFrozenColumnPositions: No table provided');
            return;
        }
        
        console.log('updateFrozenColumnPositions: Starting update...');
        
        // Wait for next animation frame to ensure DOM is ready
        requestAnimationFrame(() => {
            // Get all headers - only from the first row of thead
            const headerRow = table.querySelector('thead tr');
            if (!headerRow) {
                console.error('updateFrozenColumnPositions: No header row found');
                return;
            }
            
            const headerCells = headerRow.querySelectorAll('th');
            const bodyRows = table.querySelectorAll('tbody tr');
            
            console.log(`updateFrozenColumnPositions: Found ${headerCells.length} header columns`);
            
            let cumulativeLeft = 0;
            let frozenCount = 0;
            
            // First, ensure table wrapper has position relative for sticky to work
            const tableWrapper = table.closest('.table-wrapper');
            if (tableWrapper) {
                tableWrapper.style.position = 'relative';
                tableWrapper.style.overflow = 'auto';
            }
            
            // Process each column
            headerCells.forEach((th, index) => {
                // Check if this is a frozen column using data attribute
                const isFrozen = th.dataset.isFrozen === 'true';
                
                if (isFrozen) {
                    console.log(`updateFrozenColumnPositions: Column ${index} "${th.textContent.trim()}" is frozen`);
                    
                    // Get the actual width before applying sticky positioning
                    const rect = th.getBoundingClientRect();
                    const width = rect.width;
                    
                    console.log(`  Setting left: ${cumulativeLeft}px, width: ${width}px`);
                    
                    // Add frozen-col class and set sticky positioning
                    th.classList.add('frozen-col');
                    th.setAttribute('data-is-frozen', 'true');
                    
                    // Apply styles with important to ensure they stick
                    th.style.setProperty('position', 'sticky', 'important');
                    th.style.setProperty('position', '-webkit-sticky', 'important');
                    th.style.setProperty('left', `${cumulativeLeft}px`, 'important');
                    th.style.setProperty('z-index', '11', 'important');
                    th.style.setProperty('background-color', '#e8eef5', 'important');
                    
                    // Update all body cells in this column
                    bodyRows.forEach((row, rowIndex) => {
                        const td = row.cells[index];
                        if (td) {
                            td.classList.add('frozen-col');
                            td.setAttribute('data-is-frozen', 'true');
                            
                            td.style.setProperty('position', 'sticky', 'important');
                            td.style.setProperty('position', '-webkit-sticky', 'important');
                            td.style.setProperty('left', `${cumulativeLeft}px`, 'important');
                            td.style.setProperty('z-index', '2', 'important');
                            td.style.setProperty('background-color', '#f0f4f8', 'important');
                        }
                    });
                    
                    cumulativeLeft += width;
                    frozenCount++;
                } else {
                    // Remove frozen styles if not frozen
                    th.classList.remove('frozen-col');
                    th.removeAttribute('data-is-frozen');
                    th.style.removeProperty('position');
                    th.style.removeProperty('left');
                    th.style.removeProperty('z-index');
                    th.style.removeProperty('background-color');
                    
                    bodyRows.forEach(row => {
                        const td = row.cells[index];
                        if (td) {
                            td.classList.remove('frozen-col');
                            td.removeAttribute('data-is-frozen');
                            td.style.removeProperty('position');
                            td.style.removeProperty('left');
                            td.style.removeProperty('z-index');
                            td.style.removeProperty('background-color');
                        }
                    });
                }
            });
            
            console.log(`updateFrozenColumnPositions: Updated ${frozenCount} frozen columns with total width ${cumulativeLeft}px`);
            
            // Force a reflow to ensure styles are applied
            table.offsetHeight;
            
            // Log final state of frozen columns
            const frozenHeaders = table.querySelectorAll('th.frozen-col');
            frozenHeaders.forEach((th, i) => {
                const computed = window.getComputedStyle(th);
                console.log(`Frozen column ${i} final state:`, {
                    text: th.textContent.trim(),
                    position: computed.position,
                    left: computed.left,
                    zIndex: computed.zIndex
                });
            });
        });
    },

    saveColumnWidths: function(table) {
        if (!table) return;
        
        // Generate a unique key for this table based on its location
        const tableKey = this.getTableKey(table);
        
        const cols = table.querySelectorAll('th');
        const widths = [];
        
        cols.forEach(col => {
            widths.push(col.style.width || '');
        });
        
        localStorage.setItem(`table-widths-${tableKey}`, JSON.stringify(widths));
    },
    
    loadColumnWidths: function(table) {
        if (!table) return;
        
        const tableKey = this.getTableKey(table);
        const savedWidths = localStorage.getItem(`table-widths-${tableKey}`);
        
        if (!savedWidths) return;
        
        try {
            const widths = JSON.parse(savedWidths);
            const cols = table.querySelectorAll('th');
            
            widths.forEach((width, index) => {
                if (width && cols[index]) {
                    cols[index].style.width = width;
                }
            });
            
            // Recalculate frozen column positions after loading widths
            this.updateFrozenColumnPositions(table);
        } catch (e) {
            console.error('Error loading column widths:', e);
        }
    },
    
    getTableKey: function(table) {
        // Generate a unique key based on table location and class
        const pathname = window.location.pathname;
        const className = table.className;
        const tableIndex = Array.from(document.querySelectorAll('table')).indexOf(table);
        return `${pathname}-${className}-${tableIndex}`;
    },
    
    // Show notification popup
    showNotification: function(message) {
        // Remove any existing notification
        const existing = document.querySelector('.table-resize-notification');
        if (existing) {
            existing.remove();
        }
        
        // Create notification element
        const notification = document.createElement('div');
        notification.className = 'table-resize-notification';
        notification.style.cssText = `
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background-color: #333;
            color: white;
            padding: 16px 24px;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
            z-index: 10001;
            font-size: 14px;
            max-width: 400px;
            text-align: center;
            animation: fadeIn 0.3s ease-out;
        `;
        notification.textContent = message;
        
        // Add to body
        document.body.appendChild(notification);
        
        // Remove after delay
        setTimeout(() => {
            notification.style.animation = 'fadeOut 0.3s ease-out';
            setTimeout(() => notification.remove(), 300);
        }, 3000);
        
        // Add animations if not already defined
        if (!document.querySelector('#table-resize-animations')) {
            const style = document.createElement('style');
            style.id = 'table-resize-animations';
            style.textContent = `
                @keyframes fadeIn {
                    from { opacity: 0; transform: translate(-50%, -50%) scale(0.9); }
                    to { opacity: 1; transform: translate(-50%, -50%) scale(1); }
                }
                @keyframes fadeOut {
                    from { opacity: 1; transform: translate(-50%, -50%) scale(1); }
                    to { opacity: 0; transform: translate(-50%, -50%) scale(0.9); }
                }
            `;
            document.head.appendChild(style);
        }
    }
};