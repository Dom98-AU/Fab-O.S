// Bundle drag-and-drop functionality for worksheet rows
window.bundleDrag = {
    draggedRow: null,
    draggedItem: null,
    dropTarget: null,
    dotNetRef: null,
    initialized: false,
    
    initialize: function(dotNetRef) {
        console.log('Bundle drag: Initializing');
        this.dotNetRef = dotNetRef;
        
        // Add event listeners to bundle select cells
        this.setupBundleSelects();
        
        // Add event listeners to rows for drag sources
        this.setupRowDragging();
        
        this.initialized = true;
    },
    
    setupBundleSelects: function() {
        // Find all bundle select cells
        const bundleSelects = document.querySelectorAll('td:has(.bundle-select)');
        console.log('Bundle drag: Found', bundleSelects.length, 'bundle select cells');
        
        bundleSelects.forEach(cell => {
            // Make the cell a drop target
            cell.addEventListener('dragover', this.handleDragOver.bind(this));
            cell.addEventListener('drop', this.handleDrop.bind(this));
            cell.addEventListener('dragenter', this.handleDragEnter.bind(this));
            cell.addEventListener('dragleave', this.handleDragLeave.bind(this));
            
            // Add visual indicator that this is a drop zone
            cell.classList.add('bundle-drop-zone');
        });
    },
    
    setupRowDragging: function() {
        // Find all table rows with items
        const rows = document.querySelectorAll('.table-wrapper tbody tr[data-item-id]');
        console.log('Bundle drag: Found', rows.length, 'draggable rows');
        
        rows.forEach(row => {
            // Check if row has a checkbox (not already bundled)
            const checkbox = row.querySelector('.bundle-select-checkbox');
            if (!checkbox) return;
            
            // Make the row draggable
            row.draggable = true;
            row.classList.add('draggable-row');
            
            // Add drag handle to the checkbox cell
            const checkboxCell = checkbox.closest('td');
            if (checkboxCell) {
                const dragHandle = document.createElement('span');
                dragHandle.className = 'row-drag-handle';
                dragHandle.innerHTML = '<i class="fas fa-grip-vertical"></i>';
                dragHandle.title = 'Drag to assign to bundle';
                checkboxCell.insertBefore(dragHandle, checkbox);
                
                // Start drag on handle mousedown
                dragHandle.addEventListener('mousedown', (e) => {
                    row.draggable = true;
                    e.stopPropagation();
                });
            }
            
            // Add drag event listeners
            row.addEventListener('dragstart', this.handleRowDragStart.bind(this));
            row.addEventListener('dragend', this.handleRowDragEnd.bind(this));
        });
    },
    
    handleRowDragStart: function(e) {
        const row = e.target.closest('tr');
        if (!row) return;
        
        const itemId = row.dataset.itemId;
        if (!itemId) return;
        
        this.draggedRow = row;
        this.draggedItem = itemId;
        
        // Add dragging class
        row.classList.add('dragging');
        
        // Set drag data
        e.dataTransfer.effectAllowed = 'copy';
        e.dataTransfer.setData('text/plain', itemId);
        
        // Create custom drag image
        const dragImage = row.cloneNode(true);
        dragImage.style.position = 'absolute';
        dragImage.style.top = '-1000px';
        dragImage.style.width = row.offsetWidth + 'px';
        dragImage.style.opacity = '0.8';
        dragImage.style.backgroundColor = '#e3f2fd';
        document.body.appendChild(dragImage);
        e.dataTransfer.setDragImage(dragImage, e.offsetX, e.offsetY);
        setTimeout(() => document.body.removeChild(dragImage), 0);
        
        // Highlight all bundle drop zones
        document.querySelectorAll('.bundle-drop-zone').forEach(zone => {
            zone.classList.add('drop-zone-active');
        });
    },
    
    handleRowDragEnd: function(e) {
        const row = e.target.closest('tr');
        if (row) {
            row.classList.remove('dragging');
        }
        
        // Remove drop zone highlights
        document.querySelectorAll('.bundle-drop-zone').forEach(zone => {
            zone.classList.remove('drop-zone-active', 'drop-zone-hover');
        });
        
        this.draggedRow = null;
        this.draggedItem = null;
    },
    
    handleDragOver: function(e) {
        if (!this.draggedItem) return;
        
        e.preventDefault();
        e.dataTransfer.dropEffect = 'copy';
        return false;
    },
    
    handleDragEnter: function(e) {
        if (!this.draggedItem) return;
        
        const cell = e.target.closest('td');
        if (cell && cell.classList.contains('bundle-drop-zone')) {
            cell.classList.add('drop-zone-hover');
        }
    },
    
    handleDragLeave: function(e) {
        const cell = e.target.closest('td');
        if (cell && cell.classList.contains('bundle-drop-zone')) {
            cell.classList.remove('drop-zone-hover');
        }
    },
    
    handleDrop: function(e) {
        e.preventDefault();
        e.stopPropagation();
        
        if (!this.draggedItem) return;
        
        const cell = e.target.closest('td');
        if (!cell || !cell.classList.contains('bundle-drop-zone')) return;
        
        // Find the select element in this cell
        const select = cell.querySelector('.bundle-select');
        if (!select) return;
        
        // Get the row this cell belongs to (for bundle type detection)
        const targetRow = cell.closest('tr');
        const targetItemId = targetRow ? targetRow.dataset.itemId : null;
        
        // Determine if this is a delivery bundle or pack bundle based on the select options
        const isPackBundle = select.options[0] && select.options[0].text.includes('pack bundle');
        
        // Find the first available bundle in the select
        let bundleId = null;
        if (select.options.length > 1) {
            // Use the first non-empty option
            bundleId = select.options[1].value;
        }
        
        if (bundleId && this.dotNetRef) {
            // Notify Blazor to assign the item to the bundle
            if (isPackBundle) {
                this.dotNetRef.invokeMethodAsync('AssignItemToPackBundleFromDrag', 
                    parseInt(this.draggedItem), parseInt(bundleId));
            } else {
                this.dotNetRef.invokeMethodAsync('AssignItemToBundleFromDrag', 
                    parseInt(this.draggedItem), parseInt(bundleId));
            }
        }
        
        // Clean up
        cell.classList.remove('drop-zone-hover');
        return false;
    },
    
    // Refresh the drag setup after data changes
    refresh: function() {
        console.log('Bundle drag: Refreshing');
        this.setupBundleSelects();
        this.setupRowDragging();
    },
    
    // Clean up all event listeners
    cleanup: function() {
        // Remove drop zone classes and event listeners
        document.querySelectorAll('.bundle-drop-zone').forEach(cell => {
            cell.classList.remove('bundle-drop-zone', 'drop-zone-active', 'drop-zone-hover');
        });
        
        // Remove drag handles and row draggable state
        document.querySelectorAll('.row-drag-handle').forEach(handle => {
            handle.remove();
        });
        
        document.querySelectorAll('.draggable-row').forEach(row => {
            row.draggable = false;
            row.classList.remove('draggable-row', 'dragging');
        });
        
        this.initialized = false;
    }
};