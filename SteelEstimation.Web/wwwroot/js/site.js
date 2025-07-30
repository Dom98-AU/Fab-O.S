// Global JavaScript functions for Steel Estimation Platform

// Handle click outside for dropdown menus
window.addClickOutsideHandler = function(dotNetRef) {
    document.addEventListener('click', function(e) {
        if (!e.target.closest('.dropdown')) {
            dotNetRef.invokeMethodAsync('CloseDropdownFromJS');
        }
    });
};

// Position dropdown helper
window.positionDropdown = function(element) {
    const dropdown = element.querySelector('.dropdown-menu');
    if (!dropdown) {
        // If dropdown not found in element, check if it was already moved to body
        const bodyDropdowns = document.body.querySelectorAll('.dropdown-menu');
        for (let d of bodyDropdowns) {
            if (d._originalParent === element) {
                dropdown = d;
                break;
            }
        }
    }
    
    if (dropdown) {
        const button = element.querySelector('button');
        if (button) {
            const rect = button.getBoundingClientRect();
            
            // Move dropdown to body to escape any overflow containers
            if (!dropdown._movedToBody) {
                console.log('Moving dropdown to body');
                document.body.appendChild(dropdown);
                dropdown._movedToBody = true;
                dropdown._originalParent = element;
                console.log('Dropdown parent after move:', dropdown.parentElement?.tagName);
            }
            
            // Ensure dropdown is visible for measurement
            dropdown.style.display = 'block';
            dropdown.style.position = 'fixed';
            dropdown.style.zIndex = '9999';
            dropdown.style.visibility = 'hidden';
            
            // Get measurements
            const dropdownRect = dropdown.getBoundingClientRect();
            
            // Make visible again
            dropdown.style.visibility = 'visible';
            
            // Calculate optimal position
            let left = rect.left;
            let top = rect.bottom + 5;
            
            // Check if dropdown would go off the right edge
            if (left + dropdownRect.width > window.innerWidth) {
                left = window.innerWidth - dropdownRect.width - 10;
            }
            
            // Ensure left doesn't go negative
            if (left < 10) {
                left = 10;
            }
            
            // Check if dropdown would go off the bottom
            if (top + dropdownRect.height > window.innerHeight) {
                // Position above the button if there's more space there
                if (rect.top > window.innerHeight - rect.bottom) {
                    top = rect.top - dropdownRect.height - 5;
                } else {
                    // Keep it below but ensure it's visible
                    top = window.innerHeight - dropdownRect.height - 10;
                }
            }
            
            dropdown.style.left = left + 'px';
            dropdown.style.top = top + 'px';
            
            // Force show the dropdown with important rules
            dropdown.style.setProperty('display', 'block', 'important');
            dropdown.style.setProperty('opacity', '1', 'important');
            dropdown.style.setProperty('visibility', 'visible', 'important');
            dropdown.style.setProperty('background-color', 'white', 'important');
            dropdown.style.setProperty('border', '2px solid red', 'important'); // Temporary debug border
            dropdown.classList.add('show');
            
            // Debug computed styles
            const computedStyle = window.getComputedStyle(dropdown);
            console.log('Dropdown computed styles:', {
                display: computedStyle.display,
                visibility: computedStyle.visibility,
                opacity: computedStyle.opacity,
                position: computedStyle.position,
                zIndex: computedStyle.zIndex,
                left: computedStyle.left,
                top: computedStyle.top,
                width: computedStyle.width,
                height: computedStyle.height
            });
            
            // Check if any parent has transform
            let parent = dropdown.parentElement;
            while (parent && parent !== document.body) {
                const parentStyle = window.getComputedStyle(parent);
                if (parentStyle.transform !== 'none') {
                    console.warn('Parent has transform:', parent, parentStyle.transform);
                }
                parent = parent.parentElement;
            }
            
            console.log('Positioned dropdown at', left, top, 'for', element);
            console.log('Dropdown moved to body:', dropdown._movedToBody);
            console.log('Dropdown in DOM:', document.body.contains(dropdown));
        }
    } else {
        console.error('Dropdown not found for element', element);
    }
};

// Setup click outside handler for dropdowns
window.setupClickOutside = function(element, dotnetRef) {
    console.log('Setting up click outside handler', element);
    
    // For portal dropdowns, we need to handle differently
    const columnKey = element.getAttribute('data-column-key');
    console.log('Column key:', columnKey);
    
    // Mark that we're setting up to prevent immediate close
    element._isSettingUp = true;
    
    // Reposition on scroll
    const scrollHandler = () => window.positionDropdown(element);
    const tableWrapper = document.querySelector('.table-wrapper');
    if (tableWrapper) {
        tableWrapper.addEventListener('scroll', scrollHandler);
        element._scrollHandler = scrollHandler;
        element._scrollElement = tableWrapper;
    }
    
    // Also handle window resize
    const resizeHandler = () => window.positionDropdown(element);
    window.addEventListener('resize', resizeHandler);
    element._resizeHandler = resizeHandler;
    
    // Add a longer delay to prevent the opening click from closing the dropdown
    setTimeout(() => {
        element._isSettingUp = false;
        
        const clickHandler = function(event) {
            // Skip if we're still setting up
            if (element._isSettingUp) return;
            
            // Don't close if clicking on the dropdown button
            const button = element.querySelector('button');
            if (button && button.contains(event.target)) {
                return;
            }
            
            // For portal dropdowns, check if click is in any portal dropdown
            const portalDropdown = document.querySelector('.column-filter-dropdown-portal .dropdown-menu');
            if (portalDropdown && portalDropdown.contains(event.target)) {
                return;
            }
            
            // Close if clicking outside
            console.log('Click detected outside dropdown, closing...');
            dotnetRef.invokeMethodAsync('CloseDropdown');
        };
        
        // Use capture phase to handle the event before it bubbles
        document.addEventListener('click', clickHandler, true);
        
        // Store the handler so we can remove it later
        element._clickOutsideHandler = clickHandler;
        element._dotnetRef = dotnetRef;
    }, 300); // Increased delay to ensure dropdown is fully open
};

// Cleanup click outside handler
window.cleanupClickOutside = function(element) {
    // Move dropdown back to original parent if it was moved
    const dropdown = element.querySelector('.dropdown-menu');
    if (!dropdown && document.body.querySelector('.dropdown-menu')) {
        // Try to find it in body
        const bodyDropdowns = document.body.querySelectorAll('.dropdown-menu');
        bodyDropdowns.forEach(d => {
            if (d._originalParent === element) {
                element.appendChild(d);
                delete d._movedToBody;
                delete d._originalParent;
            }
        });
    }
    
    if (element._clickOutsideHandler) {
        document.removeEventListener('click', element._clickOutsideHandler, true);
        delete element._clickOutsideHandler;
        delete element._dotnetRef;
        delete element._isSettingUp;
    }
    
    // Also remove scroll handler
    if (element._scrollHandler && element._scrollElement) {
        element._scrollElement.removeEventListener('scroll', element._scrollHandler);
        delete element._scrollHandler;
        delete element._scrollElement;
    }
    
    // Remove resize handler
    if (element._resizeHandler) {
        window.removeEventListener('resize', element._resizeHandler);
        delete element._resizeHandler;
    }
};

// Initialize tables with enhanced features
window.initializeWorksheetTables = function() {
    console.log('Initializing worksheet tables...');
    
    const tableWrapper = document.querySelector('.table-wrapper');
    if (!tableWrapper) {
        console.log('Table wrapper not found');
        return;
    }
    
    // Reset any previous scroll position to prevent misalignment
    tableWrapper.scrollLeft = 0;
    
    // Check if table has horizontal scroll
    const table = tableWrapper.querySelector('table');
    if (table && table.scrollWidth > tableWrapper.clientWidth) {
        console.log('Table has horizontal scroll, applying frozen column styles');
        tableWrapper.classList.add('has-horizontal-scroll');
        
        // Add horizontal scroll indicator
        addHorizontalScrollIndicator(tableWrapper);
    }
    
    // Setup frozen columns - apply sticky positioning based on data-is-frozen attribute
    const allCells = document.querySelectorAll('th[data-is-frozen="true"], td[data-is-frozen="true"]');
    console.log('Found', allCells.length, 'cells marked as frozen');
    
    allCells.forEach((cell) => {
        // Apply sticky positioning
        cell.style.position = 'sticky';
        cell.style.position = '-webkit-sticky';
        
        if (cell.tagName === 'TH') {
            cell.style.zIndex = '11';
            cell.style.backgroundColor = '#e8eef5';
        } else {
            cell.style.zIndex = '2';
            cell.style.backgroundColor = '#f0f4f8';
        }
    });
    
    // Force browser to recalculate layout
    table.offsetHeight;
    
    // Initialize table resize functionality (includes frozen column position calculation)
    if (window.tableResize) {
        window.tableResize.initialize();
    }
    
    // Add keyboard shortcuts for horizontal scrolling
    setupHorizontalScrollShortcuts(tableWrapper);
    
    // Setup table row and cell highlighting
    setupTableHighlighting();
    
    // Add debug button for frozen columns
    addFrozenColumnsDebugButton();
};

// Debug button for frozen columns
function addFrozenColumnsDebugButton() {
    // Remove existing debug button if present
    const existing = document.querySelector('.frozen-columns-debug-btn');
    if (existing) existing.remove();
    
    const debugBtn = document.createElement('button');
    debugBtn.className = 'btn btn-sm btn-warning frozen-columns-debug-btn';
    debugBtn.innerHTML = '<i class="fas fa-bug"></i> Debug Frozen';
    debugBtn.style.cssText = `
        position: fixed;
        bottom: 20px;
        right: 20px;
        z-index: 9999;
        opacity: 0.8;
    `;
    
    debugBtn.addEventListener('click', () => {
        const table = document.querySelector('.table-wrapper table');
        if (!table) {
            console.log('No table found');
            return;
        }
        
        // Create debug output div if it doesn't exist
        let debugDiv = document.querySelector('.frozen-debug-output');
        if (!debugDiv) {
            debugDiv = document.createElement('div');
            debugDiv.className = 'frozen-debug-output';
            debugDiv.style.cssText = `
                position: fixed;
                top: 10px;
                right: 10px;
                width: 600px;
                max-height: 80vh;
                background: white;
                border: 2px solid #333;
                padding: 10px;
                overflow-y: auto;
                z-index: 10000;
                font-family: monospace;
                font-size: 12px;
                box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            `;
            document.body.appendChild(debugDiv);
            
            // Add close button
            const closeBtn = document.createElement('button');
            closeBtn.textContent = 'X';
            closeBtn.style.cssText = 'position: absolute; top: 5px; right: 5px; cursor: pointer;';
            closeBtn.onclick = () => debugDiv.remove();
            debugDiv.appendChild(closeBtn);
        }
        
        let output = '<h3>FROZEN COLUMNS DEBUG INFO</h3>';
        
        // Check all headers
        const headers = table.querySelectorAll('thead tr th');
        output += `<p>Total headers: ${headers.length}</p>`;
        
        output += '<table border="1" style="width: 100%; border-collapse: collapse; margin: 10px 0;">';
        output += '<tr><th>Index</th><th>Text</th><th>data-is-frozen</th><th>position</th><th>left</th><th>z-index</th><th>frozen-col class</th></tr>';
        
        headers.forEach((th, index) => {
            const computedStyle = window.getComputedStyle(th);
            const isFrozen = th.dataset.isFrozen === 'true';
            
            output += `<tr style="background: ${isFrozen ? '#ffffcc' : 'white'}">`;
            output += `<td>${index}</td>`;
            output += `<td>${th.textContent.trim()}</td>`;
            output += `<td>${th.dataset.isFrozen || 'undefined'}</td>`;
            output += `<td>${computedStyle.position}</td>`;
            output += `<td>${computedStyle.left}</td>`;
            output += `<td>${computedStyle.zIndex}</td>`;
            output += `<td>${th.classList.contains('frozen-col')}</td>`;
            output += '</tr>';
        });
        output += '</table>';
        
        // Check if updateFrozenColumnPositions exists
        output += '<h4>JavaScript Functions Status:</h4>';
        output += `<p>window.tableResize exists: ${!!window.tableResize}</p>`;
        output += `<p>window.tableResize.updateFrozenColumnPositions exists: ${!!(window.tableResize && window.tableResize.updateFrozenColumnPositions)}</p>`;
        output += `<p>window.updateFrozenColumns exists: ${!!window.updateFrozenColumns}</p>`;
        
        // Call updateFrozenColumnPositions manually
        if (window.tableResize && window.tableResize.updateFrozenColumnPositions) {
            output += '<p>Calling updateFrozenColumnPositions manually...</p>';
            window.tableResize.updateFrozenColumnPositions(table);
            
            // Re-check after update
            output += '<h4>After Manual Update:</h4>';
            output += '<table border="1" style="width: 100%; border-collapse: collapse; margin: 10px 0;">';
            output += '<tr><th>Index</th><th>Text</th><th>position</th><th>left</th></tr>';
            
            headers.forEach((th, index) => {
                if (th.dataset.isFrozen === 'true') {
                    const computedStyle = window.getComputedStyle(th);
                    output += `<tr style="background: #ccffcc">`;
                    output += `<td>${index}</td>`;
                    output += `<td>${th.textContent.trim()}</td>`;
                    output += `<td>${computedStyle.position}</td>`;
                    output += `<td>${computedStyle.left}</td>`;
                    output += '</tr>';
                }
            });
            output += '</table>';
        }
        
        // Check table wrapper
        const wrapper = document.querySelector('.table-wrapper');
        if (wrapper) {
            const wrapperStyle = window.getComputedStyle(wrapper);
            output += '<h4>Table Wrapper Info:</h4>';
            output += `<p>scrollLeft: ${wrapper.scrollLeft}</p>`;
            output += `<p>scrollWidth: ${wrapper.scrollWidth}</p>`;
            output += `<p>clientWidth: ${wrapper.clientWidth}</p>`;
            output += `<p>hasScroll: ${wrapper.scrollWidth > wrapper.clientWidth}</p>`;
            output += `<p>position: ${wrapperStyle.position}</p>`;
            output += `<p>overflow-x: ${wrapperStyle.overflowX}</p>`;
        }
        
        debugDiv.innerHTML = output;
    });
    
    document.body.appendChild(debugBtn);
}

// Add horizontal scroll indicator and keyboard shortcuts
function addHorizontalScrollIndicator(tableWrapper) {
    // Check if indicator already exists
    if (document.querySelector('.horizontal-scroll-helper')) return;
    
    const indicator = document.createElement('div');
    indicator.className = 'horizontal-scroll-helper';
    indicator.innerHTML = '<i class="fas fa-arrows-alt-h"></i> Use Shift + Mouse Wheel to scroll horizontally';
    document.body.appendChild(indicator);
    
    // Show indicator when table is in view but not fully visible horizontally
    let hideTimeout;
    
    const checkScroll = () => {
        const rect = tableWrapper.getBoundingClientRect();
        const isVisible = rect.top < window.innerHeight && rect.bottom > 0;
        const hasHorizontalScroll = tableWrapper.scrollWidth > tableWrapper.clientWidth;
        const notFullyScrolled = tableWrapper.scrollLeft < (tableWrapper.scrollWidth - tableWrapper.clientWidth);
        
        if (isVisible && hasHorizontalScroll && notFullyScrolled) {
            indicator.classList.add('show');
            clearTimeout(hideTimeout);
            hideTimeout = setTimeout(() => {
                indicator.classList.remove('show');
            }, 3000);
        }
    };
    
    // Check on scroll and resize
    window.addEventListener('scroll', checkScroll);
    window.addEventListener('resize', checkScroll);
    tableWrapper.addEventListener('scroll', checkScroll);
    
    // Initial check
    setTimeout(checkScroll, 500);
}

// Setup keyboard shortcuts for horizontal scrolling
function setupHorizontalScrollShortcuts(tableWrapper) {
    // Shift + mouse wheel for horizontal scroll
    tableWrapper.addEventListener('wheel', (e) => {
        if (e.shiftKey) {
            e.preventDefault();
            tableWrapper.scrollLeft += e.deltaY;
        }
    });
    
    // Arrow keys when table is focused
    tableWrapper.setAttribute('tabindex', '0');
    tableWrapper.addEventListener('keydown', (e) => {
        const scrollAmount = 50;
        
        switch(e.key) {
            case 'ArrowLeft':
                if (e.ctrlKey || e.metaKey) {
                    e.preventDefault();
                    tableWrapper.scrollLeft -= scrollAmount;
                }
                break;
            case 'ArrowRight':
                if (e.ctrlKey || e.metaKey) {
                    e.preventDefault();
                    tableWrapper.scrollLeft += scrollAmount;
                }
                break;
            case 'Home':
                if (e.ctrlKey || e.metaKey) {
                    e.preventDefault();
                    tableWrapper.scrollLeft = 0;
                }
                break;
            case 'End':
                if (e.ctrlKey || e.metaKey) {
                    e.preventDefault();
                    tableWrapper.scrollLeft = tableWrapper.scrollWidth;
                }
                break;
        }
    });
}

// Handle bundle selection
window.bundleSelection = {
    selectedItems: new Set(),
    
    toggleItem: function(itemId, isChecked) {
        if (isChecked) {
            this.selectedItems.add(itemId);
        } else {
            this.selectedItems.delete(itemId);
        }
        this.updateSelectionUI();
    },
    
    toggleAll: function(isChecked) {
        const checkboxes = document.querySelectorAll('.bundle-select-checkbox');
        checkboxes.forEach(cb => {
            cb.checked = isChecked;
            const itemId = parseInt(cb.dataset.itemId);
            if (isChecked) {
                this.selectedItems.add(itemId);
            } else {
                this.selectedItems.delete(itemId);
            }
        });
        this.updateSelectionUI();
    },
    
    clearSelection: function() {
        this.selectedItems.clear();
        const checkboxes = document.querySelectorAll('.bundle-select-checkbox');
        checkboxes.forEach(cb => cb.checked = false);
        const selectAllCheckbox = document.querySelector('.bundle-select-all');
        if (selectAllCheckbox) selectAllCheckbox.checked = false;
        this.updateSelectionUI();
    },
    
    updateSelectionUI: function() {
        // This will be called from Blazor to update the UI
        if (window.bundleSelectionCallback) {
            window.bundleSelectionCallback(Array.from(this.selectedItems));
        }
    }
};

// Smooth scroll to element
window.scrollToElement = function(elementId) {
    const element = document.getElementById(elementId);
    if (element) {
        element.scrollIntoView({ behavior: 'smooth', block: 'center' });
        // Highlight the element briefly
        element.classList.add('highlight-flash');
        setTimeout(() => element.classList.remove('highlight-flash'), 2000);
    }
};

// Handle table row and cell click highlighting
window.setupTableHighlighting = function() {
    const tableWrapper = document.querySelector('.table-wrapper');
    if (!tableWrapper) return;
    
    // Remove any existing event listeners
    if (tableWrapper._highlightHandler) {
        tableWrapper.removeEventListener('click', tableWrapper._highlightHandler);
    }
    
    // Click handler for rows and cells
    const clickHandler = function(e) {
        const clickedCell = e.target.closest('td');
        const clickedRow = e.target.closest('tr');
        
        // Skip if clicking on buttons, inputs, or links
        if (e.target.closest('button, input, select, textarea, a, .dropdown-menu')) {
            return;
        }
        
        // Skip header rows
        if (clickedRow && clickedRow.closest('thead')) {
            return;
        }
        
        if (clickedCell && clickedRow) {
            // Clear previous highlights
            tableWrapper.querySelectorAll('.active-row').forEach(row => {
                row.classList.remove('active-row');
            });
            tableWrapper.querySelectorAll('.active-cell').forEach(cell => {
                cell.classList.remove('active-cell');
            });
            
            // Add active row class
            clickedRow.classList.add('active-row');
            
            // Add active cell class
            clickedCell.classList.add('active-cell');
            
            // Store the active row ID if available
            const rowId = clickedRow.getAttribute('data-row-id');
            if (rowId) {
                tableWrapper.dataset.activeRowId = rowId;
            }
        }
    };
    
    tableWrapper.addEventListener('click', clickHandler);
    tableWrapper._highlightHandler = clickHandler;
    
    // Optional: Clear highlights when clicking outside the table
    document.addEventListener('click', function(e) {
        if (!e.target.closest('.table-wrapper')) {
            const tableWrapper = document.querySelector('.table-wrapper');
            if (tableWrapper) {
                tableWrapper.querySelectorAll('.active-row').forEach(row => {
                    row.classList.remove('active-row');
                });
                tableWrapper.querySelectorAll('.active-cell').forEach(cell => {
                    cell.classList.remove('active-cell');
                });
            }
        }
    });
};

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    console.log('Steel Estimation site.js loaded');
    setupTableHighlighting();
});

// Safe function caller - prevents errors when functions aren't loaded yet
window.safeCall = function(functionName, ...args) {
    try {
        // Split function name by dots to handle nested functions
        const parts = functionName.split('.');
        let func = window;
        
        for (const part of parts) {
            if (func && typeof func[part] !== 'undefined') {
                func = func[part];
            } else {
                console.warn(`Function ${functionName} not found`);
                return undefined;
            }
        }
        
        if (typeof func === 'function') {
            return func.apply(null, args);
        } else {
            console.warn(`${functionName} is not a function`);
            return undefined;
        }
    } catch (error) {
        console.error(`Error calling ${functionName}:`, error);
        return undefined;
    }
};

// Console interceptor for debug console
window.setupConsoleInterceptor = function(dotNetRef) {
    // Store original console methods
    const originalLog = console.log;
    const originalError = console.error;
    const originalWarn = console.warn;
    
    // Override console.log
    console.log = function(...args) {
        // Call original
        originalLog.apply(console, args);
        
        // Forward to Blazor if reference exists
        if (dotNetRef) {
            try {
                const message = args.map(arg => 
                    typeof arg === 'object' ? JSON.stringify(arg, null, 2) : String(arg)
                ).join(' ');
                
                dotNetRef.invokeMethodAsync('AddConsoleMessage', message, 'info');
            } catch (e) {
                // Silently fail if Blazor is not ready
            }
        }
    };
    
    // Override console.error
    console.error = function(...args) {
        // Call original
        originalError.apply(console, args);
        
        // Forward to Blazor if reference exists
        if (dotNetRef) {
            try {
                const message = args.map(arg => 
                    typeof arg === 'object' ? JSON.stringify(arg, null, 2) : String(arg)
                ).join(' ');
                
                dotNetRef.invokeMethodAsync('AddConsoleMessage', message, 'error');
            } catch (e) {
                // Silently fail if Blazor is not ready
            }
        }
    };
    
    // Override console.warn
    console.warn = function(...args) {
        // Call original
        originalWarn.apply(console, args);
        
        // Forward to Blazor if reference exists
        if (dotNetRef) {
            try {
                const message = args.map(arg => 
                    typeof arg === 'object' ? JSON.stringify(arg, null, 2) : String(arg)
                ).join(' ');
                
                dotNetRef.invokeMethodAsync('AddConsoleMessage', message, 'warning');
            } catch (e) {
                // Silently fail if Blazor is not ready
            }
        }
    };
    
    // Return a cleanup function
    return {
        restore: function() {
            console.log = originalLog;
            console.error = originalError;
            console.warn = originalWarn;
        }
    };
};

// Manual frozen column update function that can be called from Blazor
window.updateFrozenColumns = function() {
    console.log('Manual frozen column update requested');
    
    const table = document.querySelector('.table-wrapper table');
    if (!table) {
        console.error('No table found for frozen column update');
        return;
    }
    
    // Call the table resize update function
    if (window.tableResize && window.tableResize.updateFrozenColumnPositions) {
        console.log('Calling tableResize.updateFrozenColumnPositions');
        window.tableResize.updateFrozenColumnPositions(table);
    } else {
        console.error('tableResize.updateFrozenColumnPositions not available');
    }
};