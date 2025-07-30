// Column Reorder functionality for worksheet tables
window.columnReorder = {
    draggedColumn: null,
    draggedIndex: null,
    dropIndicator: null,
    dotNetRef: null,
    initialized: false,
    currentTableSelector: null,
    scrollInterval: null,
    scrollSpeed: 0,
    isDragging: false,
    
    initialize: function(dotNetRef, tableSelector) {
        console.log('Column reorder: Initializing for', tableSelector);
        
        // Check if we're already initialized for this table
        if (this.initialized && this.currentTableSelector === tableSelector) {
            console.log('Column reorder: Already initialized for this table, skipping');
            return;
        }
        
        // Always clean up first to ensure fresh initialization
        this.cleanup();
        
        this.dotNetRef = dotNetRef;
        this.currentTableSelector = tableSelector;
        const table = document.querySelector(tableSelector);
        if (!table) {
            console.log('Column reorder: Table not found');
            // Try again after a short delay
            setTimeout(() => {
                const retryTable = document.querySelector(tableSelector);
                if (retryTable) {
                    console.log('Column reorder: Table found on retry');
                    this.initialize(dotNetRef, tableSelector);
                }
            }, 500);
            return;
        }
        
        // Create drop indicator element if it doesn't exist
        if (!this.dropIndicator) {
            this.createDropIndicator();
        }
        
        // Get all draggable column headers
        const headers = table.querySelectorAll('thead th');
        console.log('Column reorder: Found', headers.length, 'headers');
        
        // Debug: Log all headers
        headers.forEach((h, i) => {
            console.log(`Header ${i}: "${h.textContent.trim()}", bg: ${h.style.backgroundColor}`);
        });
        
        let dragHandlesAdded = 0;
        headers.forEach((header, index) => {
            // Skip only checkbox columns (first two)
            // Allow drag handles on all other columns including last
            if (index <= 1) {
                console.log(`Skipping header ${index}: "${header.textContent.trim()}" - is checkbox column`);
                return;
            }
            
            // Skip Total Hours column (has specific background color)
            if (header.style.backgroundColor === 'rgb(240, 248, 255)') {
                console.log(`Skipping header ${index}: "${header.textContent.trim()}" - has total hours bg color`);
                return;
            }
            
            // Check if header is frozen using data attribute
            const isFrozen = header.dataset.isFrozen === 'true';
            
            // Check if this header already has a drag handle
            if (header.querySelector('.column-drag-handle')) {
                console.log('Column reorder: Drag handle already exists for', header.textContent);
                // Just update the dataset
                header.dataset.columnIndex = index;
                header.dataset.isFrozen = isFrozen;
                return;
            }
            
            // Setup header data
            header.dataset.columnIndex = index;
            header.dataset.isFrozen = isFrozen;
            
            // Add drag handle visual indicator
            const dragHandle = document.createElement('span');
            dragHandle.className = 'column-drag-handle';
            dragHandle.innerHTML = '⋮⋮';  // Use Unicode characters as fallback
            dragHandle.draggable = true;
            dragHandle.dataset.columnIndex = index;
            dragHandle.dataset.isFrozen = isFrozen;
            dragHandle.title = 'Drag to reorder column';
            
            // Store reference to parent header
            dragHandle._parentHeader = header;
            
            // Debug: Log when drag handle is created
            console.log('Created drag handle for column:', header.textContent.trim(), 'Index:', index);
            
            header.insertBefore(dragHandle, header.firstChild);
            dragHandlesAdded++;
            
            // Store bound event handlers for cleanup
            const handlers = {
                dragstart: this.handleDragStart.bind(this),
                dragend: this.handleDragEnd.bind(this),
                dragover: this.handleDragOver.bind(this),
                drop: this.handleDrop.bind(this),
                dragenter: this.handleDragEnter.bind(this),
                dragleave: this.handleDragLeave.bind(this)
            };
            
            // Add event listeners to the drag handle
            Object.entries(handlers).forEach(([event, handler]) => {
                dragHandle.addEventListener(event, handler);
            });
            
            // Also add some events to the header for better compatibility
            header.addEventListener('dragover', handlers.dragover);
            header.addEventListener('drop', handlers.drop);
            header.addEventListener('dragenter', handlers.dragenter);
            header.addEventListener('dragleave', handlers.dragleave);
            
            // Store handlers for cleanup
            header._dragHandlers = handlers;
            header._dragHandle = dragHandle;
            dragHandle._handlers = handlers;
            
            // Touch events for mobile
            this.addTouchSupport(header);
        });
        
        console.log('Column reorder: Added', dragHandlesAdded, 'drag handles');
        this.initialized = true;
    },
    
    cleanup: function() {
        console.log('Column reorder: Cleaning up');
        
        // Remove all drag handles from the entire document
        document.querySelectorAll('.column-drag-handle').forEach(handle => {
            handle.remove();
        });
        
        if (this.currentTableSelector) {
            const table = document.querySelector(this.currentTableSelector);
            if (table) {
                // Remove all event listeners
                const headers = table.querySelectorAll('thead th');
                headers.forEach(header => {
                    // Remove event listeners from header
                    if (header._dragHandlers) {
                        // Remove from header
                        header.removeEventListener('dragover', header._dragHandlers.dragover);
                        header.removeEventListener('drop', header._dragHandlers.drop);
                        header.removeEventListener('dragenter', header._dragHandlers.dragenter);
                        header.removeEventListener('dragleave', header._dragHandlers.dragleave);
                        delete header._dragHandlers;
                    }
                    
                    // Remove event listeners from drag handle
                    if (header._dragHandle && header._dragHandle._handlers) {
                        const dragHandle = header._dragHandle;
                        Object.entries(dragHandle._handlers).forEach(([event, handler]) => {
                            dragHandle.removeEventListener(event, handler);
                        });
                        delete dragHandle._handlers;
                        delete header._dragHandle;
                    }
                    
                    // Clean up header data
                    delete header.dataset.columnIndex;
                    delete header.dataset.isFrozen;
                });
            }
        }
        
        // Reset state
        this.initialized = false;
        this.currentTableSelector = null;
        this.draggedColumn = null;
        this.draggedIndex = null;
    },
    
    createDropIndicator: function() {
        // Only create if it doesn't exist
        if (!document.querySelector('.column-drop-indicator')) {
            this.dropIndicator = document.createElement('div');
            this.dropIndicator.className = 'column-drop-indicator';
            this.dropIndicator.style.display = 'none';
            document.body.appendChild(this.dropIndicator);
        } else {
            this.dropIndicator = document.querySelector('.column-drop-indicator');
        }
    },
    
    handleDragStart: function(e) {
        console.log('handleDragStart called', e.target);
        
        // Get the actual header element (since we're dragging from the handle)
        const dragHandle = e.target.closest('.column-drag-handle');
        const header = dragHandle ? dragHandle._parentHeader : e.target.closest('th');
        
        console.log('Drag handle:', dragHandle, 'Header:', header);
        
        if (!header) {
            console.log('No header found, returning');
            return;
        }
        
        const isFrozen = header.dataset.isFrozen === 'true';
        
        // Prevent dragging frozen columns
        if (isFrozen) {
            e.preventDefault();
            this.showNotification('Frozen columns cannot be reordered. Unfreeze the column first.');
            return;
        }
        
        // Store initial state before any visual changes
        this.draggedColumn = header;
        this.draggedIndex = parseInt(header.dataset.columnIndex);
        
        // Store column data
        e.dataTransfer.effectAllowed = 'move';
        e.dataTransfer.setData('text/html', header.innerHTML);
        
        // Create and position the ghost image BEFORE setting isDragging
        const ghost = this.createGhostImage(header);
        
        // Calculate proper offset for the ghost image
        // We want the ghost to appear exactly where the header is
        const headerRect = header.getBoundingClientRect();
        const mouseX = e.clientX;
        const mouseY = e.clientY;
        
        // Calculate offset from mouse position to top-left of header
        const offsetX = mouseX - headerRect.left;
        const offsetY = mouseY - headerRect.top;
        
        // Set drag image with correct offset
        e.dataTransfer.setDragImage(ghost, offsetX, offsetY);
        
        // Set isDragging after ghost image is created
        this.isDragging = true;
        
        // Use setTimeout instead of requestAnimationFrame to ensure drag has started
        setTimeout(() => {
            // Add dragging class to column
            header.classList.add('dragging');
            
            const tableWrapper = header.closest('.table-wrapper');
            if (tableWrapper) {
                tableWrapper.classList.add('dragging-active');
                
                // Start auto-scroll monitoring
                this.startAutoScroll(tableWrapper);
            }
            
            // Add smooth transition to all table cells after drag starts
            const table = header.closest('table');
            if (table) {
                table.querySelectorAll('th, td').forEach(cell => {
                    cell.style.transition = 'transform 0.2s ease, width 0.2s ease';
                });
            }
        }, 0);
    },
    
    handleDragEnd: function(e) {
        this.isDragging = false;
        
        // Find the dragging header (could be the handle or the header itself)
        const dragHandle = e.target.closest('.column-drag-handle');
        const header = dragHandle ? dragHandle._parentHeader : e.target.closest('th');
        
        if (header) {
            header.classList.remove('dragging');
        }
        
        this.hideDropIndicator();
        
        // Stop auto-scrolling
        this.stopAutoScroll();
        
        // Remove dragging class from table wrapper
        const tableWrapper = document.querySelector('.table-wrapper');
        if (tableWrapper) {
            tableWrapper.classList.remove('dragging-active');
        }
        
        // Remove dragging class from any headers that might still have it
        document.querySelectorAll('th.dragging').forEach(th => {
            th.classList.remove('dragging');
        });
        
        // Remove transitions after animation completes
        const table = document.querySelector(this.currentTableSelector);
        if (table) {
            setTimeout(() => {
                table.querySelectorAll('th, td').forEach(cell => {
                    cell.style.transition = '';
                    cell.style.transform = '';
                    // Clean up any other inline styles that might have been added
                    if (cell.tagName === 'TH') {
                        cell.style.backgroundColor = '';
                    }
                });
            }, 300);
        }
        
        // Reset dragged column reference
        this.draggedColumn = null;
        this.draggedIndex = null;
    },
    
    handleDragOver: function(e) {
        if (e.preventDefault) {
            e.preventDefault();
        }
        
        e.dataTransfer.dropEffect = 'move';
        
        const targetHeader = e.target.closest('th');
        if (!targetHeader || targetHeader === this.draggedColumn) return;
        
        // Check if we can drop here
        const targetIndex = parseInt(targetHeader.dataset.columnIndex);
        const targetIsFrozen = targetHeader.dataset.isFrozen === 'true';
        
        // Don't allow dropping on checkbox columns (first two)
        // But DO allow dropping on any other column including last column
        if (targetIndex <= 1 || !targetHeader.dataset.columnIndex) return;
        
        // Don't allow dropping on frozen columns
        if (targetIsFrozen) {
            this.hideDropIndicator();
            return;
        }
        
        // Show drop indicator
        this.showDropIndicator(targetHeader, e);
        
        return false;
    },
    
    handleDrop: function(e) {
        if (e.stopPropagation) {
            e.stopPropagation();
        }
        
        const targetHeader = e.target.closest('th');
        if (!targetHeader || targetHeader === this.draggedColumn) return false;
        
        const targetIndex = parseInt(targetHeader.dataset.columnIndex);
        const targetIsFrozen = targetHeader.dataset.isFrozen === 'true';
        
        // Validate drop - allow dropping on any column except first two (checkbox columns)
        if (targetIndex <= 1 || !targetHeader.dataset.columnIndex || targetIsFrozen) {
            return false;
        }
        
        // Get column keys from headers
        const draggedKey = this.getColumnKey(this.draggedColumn);
        const targetKey = this.getColumnKey(targetHeader);
        
        console.log('Dropping column:', draggedKey, 'onto:', targetKey);
        
        // Calculate if we're dropping before or after based on the drop indicator position
        const rect = targetHeader.getBoundingClientRect();
        const midpoint = rect.left + rect.width / 2;
        const dropBefore = e.clientX < midpoint;
        
        // Notify Blazor component of the reorder
        if (this.dotNetRef && draggedKey && targetKey) {
            // Pass the drop position (before/after) to handle proper insertion
            this.dotNetRef.invokeMethodAsync('ReorderColumns', draggedKey, targetKey, dropBefore);
            
            // Trigger custom event to notify enhanced table
            const event = new CustomEvent('columnsReordered', {
                detail: { from: draggedKey, to: targetKey, dropBefore: dropBefore }
            });
            document.dispatchEvent(event);
        }
        
        return false;
    },
    
    handleDragEnter: function(e) {
        // Removed column highlighting - only use drop indicator
    },
    
    handleDragLeave: function(e) {
        // Removed column highlighting - only use drop indicator
    },
    
    showDropIndicator: function(targetHeader, e) {
        const rect = targetHeader.getBoundingClientRect();
        const midpoint = rect.left + rect.width / 2;
        
        this.dropIndicator.style.display = 'block';
        this.dropIndicator.style.height = rect.height + 'px';
        this.dropIndicator.style.top = rect.top + 'px';
        
        // Smooth transition for indicator movement
        if (!this.dropIndicator.style.transition) {
            this.dropIndicator.style.transition = 'all 0.15s ease-out';
        }
        
        // Show indicator on left or right side based on cursor position
        if (e.clientX < midpoint) {
            this.dropIndicator.style.left = (rect.left - 3) + 'px';
        } else {
            this.dropIndicator.style.left = (rect.right - 3) + 'px';
        }
    },
    
    hideDropIndicator: function() {
        if (this.dropIndicator) {
            this.dropIndicator.style.display = 'none';
        }
    },
    
    getColumnKey: function(header) {
        // First check if the header has a data-column-key attribute
        if (header.dataset.columnKey) {
            console.log('Found column key from dataset:', header.dataset.columnKey);
            return header.dataset.columnKey;
        }
        
        // Extract column key from ColumnFilterDropdown component
        const filterDropdown = header.querySelector('[data-column-key]');
        if (filterDropdown) {
            console.log('Found column key from filter dropdown:', filterDropdown.dataset.columnKey);
            return filterDropdown.dataset.columnKey;
        }
        
        // Look for the ColumnKey parameter in the ColumnFilterDropdown
        const blazorComponent = header.querySelector('select, input');
        if (blazorComponent && blazorComponent.getAttribute('data-column-key')) {
            console.log('Found column key from blazor component:', blazorComponent.getAttribute('data-column-key'));
            return blazorComponent.getAttribute('data-column-key');
        }
        
        // Fallback: try to determine from header text
        const headerText = header.textContent.trim();
        console.log('Trying to match header text:', headerText);
        
        const columnKeyMap = {
            'ID': 'ID',
            'Drawing Number': 'DrawingNumber',
            'Description': 'Description',
            'MBE ID': 'MaterialId',
            'QTY': 'Quantity',
            'Length (mm)': 'Length',
            'Weight (kg)': 'Weight',
            'Total Weight': 'TotalWeight',
            'Delivery Bundle': 'DeliveryBundle',
            'Pack Bundle': 'PackBundle',
            'Unload Time/Bundle': 'UnloadTime',
            'Mark/Measure/Cut': 'MarkMeasureCut',
            'Quality Check/Clean': 'QualityCheck',
            'Move to Assembly': 'MoveToAssembly',
            'Move After Weld': 'MoveAfterWeld',
            'Loading Time/Bundle': 'LoadingTime'
        };
        
        // Try exact match first
        if (columnKeyMap[headerText]) {
            console.log('Found exact match for column key:', columnKeyMap[headerText]);
            return columnKeyMap[headerText];
        }
        
        // Then try contains match
        for (const [text, key] of Object.entries(columnKeyMap)) {
            if (headerText.includes(text)) {
                console.log('Found partial match for column key:', key);
                return key;
            }
        }
        
        console.log('No column key found for header:', headerText);
        return null;
    },
    
    // Touch support for mobile devices
    addTouchSupport: function(element) {
        let touchItem = null;
        let touchOffset = { x: 0, y: 0 };
        
        element.addEventListener('touchstart', (e) => {
            touchItem = element;
            const touch = e.targetTouches[0];
            touchOffset.x = touch.pageX - element.offsetLeft;
            touchOffset.y = touch.pageY - element.offsetTop;
            element.style.opacity = '0.5';
        }, { passive: false });
        
        element.addEventListener('touchmove', (e) => {
            if (!touchItem) return;
            
            e.preventDefault();
            const touch = e.targetTouches[0];
            
            // Find element under touch point
            const elementBelow = document.elementFromPoint(touch.clientX, touch.clientY);
            const targetHeader = elementBelow ? elementBelow.closest('th') : null;
            
            if (targetHeader && targetHeader !== touchItem) {
                this.showDropIndicator(targetHeader, { clientX: touch.clientX });
            }
        }, { passive: false });
        
        element.addEventListener('touchend', (e) => {
            if (!touchItem) return;
            
            const touch = e.changedTouches[0];
            const elementBelow = document.elementFromPoint(touch.clientX, touch.clientY);
            const targetHeader = elementBelow ? elementBelow.closest('th') : null;
            
            if (targetHeader && targetHeader !== touchItem) {
                // Simulate drop
                const draggedKey = this.getColumnKey(touchItem);
                const targetKey = this.getColumnKey(targetHeader);
                
                if (this.dotNetRef && draggedKey && targetKey) {
                    this.dotNetRef.invokeMethodAsync('ReorderColumns', draggedKey, targetKey);
                }
            }
            
            touchItem.style.opacity = '';
            touchItem = null;
            this.hideDropIndicator();
        });
    },
    
    // Update column order from Blazor
    updateColumnOrder: function(columnOrder) {
        // This can be called from Blazor to update the visual order after successful reorder
        console.log('Column order updated:', columnOrder);
        
        // After reordering columns, update frozen column positions
        const table = document.querySelector(this.currentTableSelector);
        if (table && window.tableResize && window.tableResize.updateFrozenColumnPositions) {
            // Use setTimeout to ensure DOM has updated
            setTimeout(() => {
                window.tableResize.updateFrozenColumnPositions(table);
            }, 100);
        }
    },
    
    // Save column order to localStorage
    saveColumnOrder: function(packageId, columnOrder) {
        const key = `worksheet-column-order-${packageId}`;
        localStorage.setItem(key, JSON.stringify(columnOrder));
    },
    
    // Load column order from localStorage
    loadColumnOrder: function(packageId) {
        const key = `worksheet-column-order-${packageId}`;
        const stored = localStorage.getItem(key);
        return stored ? JSON.parse(stored) : null;
    },
    
    // Reset to default order
    resetColumnOrder: function() {
        if (this.dotNetRef) {
            this.dotNetRef.invokeMethodAsync('ResetColumnOrder');
        }
    },
    
    // Show notification popup
    showNotification: function(message) {
        // Remove any existing notification
        const existing = document.querySelector('.column-reorder-notification');
        if (existing) {
            existing.remove();
        }
        
        // Create notification element
        const notification = document.createElement('div');
        notification.className = 'column-reorder-notification';
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
        if (!document.querySelector('#column-reorder-animations')) {
            const style = document.createElement('style');
            style.id = 'column-reorder-animations';
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
    },
    
    // Create a better ghost image for dragging
    createGhostImage: function(element) {
        const ghost = element.cloneNode(true);
        
        // Get computed styles from the original element
        const computedStyle = window.getComputedStyle(element);
        
        ghost.style.cssText = `
            position: fixed;
            top: -1000px;
            left: -1000px;
            width: ${element.offsetWidth}px;
            height: ${element.offsetHeight}px;
            opacity: 0.8;
            background: white;
            border: 2px solid #0d6efd;
            border-radius: 4px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
            pointer-events: none;
            margin: 0;
            padding: ${computedStyle.padding};
            font-size: ${computedStyle.fontSize};
            font-weight: ${computedStyle.fontWeight};
            text-align: ${computedStyle.textAlign};
            box-sizing: border-box;
            z-index: 999999;
        `;
        
        // Remove any drag handles from the ghost
        const dragHandle = ghost.querySelector('.column-drag-handle');
        if (dragHandle) {
            dragHandle.remove();
        }
        
        // Ensure text is visible in the ghost
        ghost.style.color = '#000';
        
        document.body.appendChild(ghost);
        
        // Clean up after drag image is set
        setTimeout(() => {
            if (ghost.parentNode) {
                ghost.parentNode.removeChild(ghost);
            }
        }, 100);
        
        return ghost;
    },
    
    // Start auto-scrolling when dragging near edges
    startAutoScroll: function(tableWrapper) {
        if (!tableWrapper) return;
        
        const scrollThreshold = 100; // Distance from edge to start scrolling
        const maxScrollSpeed = 15;
        
        const handleMouseMove = (e) => {
            if (!this.isDragging) return;
            
            const rect = tableWrapper.getBoundingClientRect();
            const x = e.clientX;
            
            // Calculate distance from edges
            const distanceFromLeft = x - rect.left;
            const distanceFromRight = rect.right - x;
            
            // Determine scroll direction and speed
            if (distanceFromLeft < scrollThreshold) {
                // Scroll left
                this.scrollSpeed = -maxScrollSpeed * (1 - distanceFromLeft / scrollThreshold);
            } else if (distanceFromRight < scrollThreshold) {
                // Scroll right
                this.scrollSpeed = maxScrollSpeed * (1 - distanceFromRight / scrollThreshold);
            } else {
                this.scrollSpeed = 0;
            }
            
            // Start or stop scrolling
            if (this.scrollSpeed !== 0 && !this.scrollInterval) {
                this.scrollInterval = setInterval(() => {
                    if (this.isDragging && this.scrollSpeed !== 0) {
                        tableWrapper.scrollLeft += this.scrollSpeed;
                    }
                }, 16); // ~60fps
            } else if (this.scrollSpeed === 0 && this.scrollInterval) {
                clearInterval(this.scrollInterval);
                this.scrollInterval = null;
            }
        };
        
        // Store the handler so we can remove it later
        this._autoScrollHandler = handleMouseMove;
        document.addEventListener('dragover', handleMouseMove);
    },
    
    // Stop auto-scrolling
    stopAutoScroll: function() {
        if (this.scrollInterval) {
            clearInterval(this.scrollInterval);
            this.scrollInterval = null;
        }
        
        if (this._autoScrollHandler) {
            document.removeEventListener('dragover', this._autoScrollHandler);
            this._autoScrollHandler = null;
        }
        
        this.scrollSpeed = 0;
    },
    
};