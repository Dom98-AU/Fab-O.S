// Enhanced table functionality - resize, reorder, freeze columns, and view saving
window.enhancedTable = {
    // Initialize enhanced features for a table
    init: function(tableSelector, options = {}) {
        const defaults = {
            enableResize: true,
            enableReorder: true,
            enableViewSaving: true,
            enableFreezeColumns: true,
            enableColumnVisibility: true,
            freezeColumns: 0, // Number of columns to freeze from left
            tableType: 'Generic',
            dotNetRef: null
        };
        
        const settings = { ...defaults, ...options };
        console.log('Enhanced table: Initializing for', tableSelector, settings);
        
        // Store settings for this table
        if (!window.enhancedTableInstances) {
            window.enhancedTableInstances = {};
        }
        window.enhancedTableInstances[tableSelector] = settings;
        
        // Wait for DOM to be ready
        const initializeTable = () => {
            const table = document.querySelector(tableSelector);
            if (!table) {
                console.error('Enhanced table: Table not found:', tableSelector);
                return;
            }
            
            // Add enhanced-table class
            table.classList.add('enhanced-table');
            
            // Apply freeze columns if enabled
            if (settings.enableFreezeColumns && settings.freezeColumns > 0) {
                window.enhancedTable.applyFreezeColumns(table, settings.freezeColumns);
            }
            
            // Ensure the table wrapper has proper scrolling
            const wrapper = table.closest('.table-wrapper');
            if (wrapper) {
                // Check if table needs horizontal scrolling
                if (table.scrollWidth > wrapper.clientWidth) {
                    wrapper.classList.add('has-horizontal-scroll');
                }
                
                // Monitor for table size changes
                const resizeObserver = new ResizeObserver(() => {
                    if (table.scrollWidth > wrapper.clientWidth) {
                        wrapper.classList.add('has-horizontal-scroll');
                    } else {
                        wrapper.classList.remove('has-horizontal-scroll');
                    }
                });
                resizeObserver.observe(table);
                
                // Store observer for cleanup
                if (!window.enhancedTableObservers) {
                    window.enhancedTableObservers = new Map();
                }
                window.enhancedTableObservers.set(tableSelector, resizeObserver);
                
                // Add scroll listener for freeze columns
                if (settings.enableFreezeColumns && settings.freezeColumns > 0) {
                    wrapper.addEventListener('scroll', () => {
                        window.enhancedTable.updateFreezeColumnPositions(table, wrapper);
                    });
                }
            }
            
            // Initialize features
            if (settings.enableReorder && settings.dotNetRef) {
                console.log('Enhanced table: Initializing column reordering');
                // Use the existing column reorder if available
                if (window.columnReorder) {
                    window.columnReorder.initialize(settings.dotNetRef, tableSelector);
                }
            }
            
            // Initialize resize after reorder
            setTimeout(() => {
                if (settings.enableResize) {
                    console.log('Enhanced table: Initializing column resizing');
                    if (window.simpleResize) {
                        window.simpleResize.init();
                    }
                }
            }, 500);
            
            // Initialize view saving
            if (settings.enableViewSaving) {
                console.log('Enhanced table: Initializing view saving');
                window.enhancedTable.initViewSaving(tableSelector, settings);
            }
            
            // Create modals
            window.enhancedTable.createModals();
            
            // Listen for column reorder events from drag and drop
            window.enhancedTable.listenForColumnReorderEvents(tableSelector, settings);
        };
        
        // Try to initialize immediately
        if (document.readyState === 'complete' || document.readyState === 'interactive') {
            setTimeout(initializeTable, 100);
        } else {
            // Wait for DOM content to be loaded
            document.addEventListener('DOMContentLoaded', () => {
                setTimeout(initializeTable, 100);
            });
        }
    },
    
    // Create modal dialogs
    createModals: function() {
        // Check if modals already exist
        if (document.getElementById('enhancedTableModals')) {
            return;
        }
        
        const modalsContainer = document.createElement('div');
        modalsContainer.id = 'enhancedTableModals';
        modalsContainer.innerHTML = `
            <!-- Save View Modal -->
            <div class="modal fade" id="saveViewModal" tabindex="-1">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 class="modal-title">Save Table View</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                        </div>
                        <div class="modal-body">
                            <div class="mb-3">
                                <label for="viewNameInput" class="form-label">View Name</label>
                                <input type="text" class="form-control" id="viewNameInput" placeholder="Enter view name">
                            </div>
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" id="shareViewCheck">
                                <label class="form-check-label" for="shareViewCheck">
                                    Share this view with team members
                                </label>
                            </div>
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" id="makeDefaultCheck">
                                <label class="form-check-label" for="makeDefaultCheck">
                                    Make this my default view
                                </label>
                            </div>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                            <button type="button" class="btn btn-primary" id="saveViewBtn">Save View</button>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Column Visibility Modal -->
            <div class="modal fade" id="columnVisibilityModal" tabindex="-1">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 class="modal-title">Column Visibility</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                        </div>
                        <div class="modal-body">
                            <div id="columnVisibilityList">
                                <!-- Column checkboxes will be added here dynamically -->
                            </div>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                            <button type="button" class="btn btn-primary" id="applyColumnVisibilityBtn">Apply</button>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Freeze Columns Modal -->
            <div class="modal fade" id="freezeColumnsModal" tabindex="-1">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 class="modal-title">Freeze Columns</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                        </div>
                        <div class="modal-body">
                            <div class="mb-3">
                                <label for="freezeColumnCount" class="form-label">Number of columns to freeze from left</label>
                                <input type="number" class="form-control" id="freezeColumnCount" min="0" max="10" value="0">
                                <div class="form-text">Frozen columns will remain visible when scrolling horizontally</div>
                            </div>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                            <button type="button" class="btn btn-primary" id="applyFreezeColumnsBtn">Apply</button>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        document.body.appendChild(modalsContainer);
    },
    
    // Apply freeze columns functionality
    applyFreezeColumns: function(table, freezeCount) {
        // Remove existing frozen columns
        table.querySelectorAll('.frozen-col').forEach(col => {
            col.classList.remove('frozen-col', 'frozen-shadow');
            col.style.position = '';
            col.style.left = '';
            col.style.zIndex = '';
            // Remove all frozen-col-X classes
            Array.from(col.classList).forEach(className => {
                if (className.startsWith('frozen-col-')) {
                    col.classList.remove(className);
                }
            });
        });
        
        if (freezeCount === 0) return;
        
        const headers = table.querySelectorAll('thead th');
        const rows = table.querySelectorAll('tbody tr');
        
        // Mark frozen columns
        for (let i = 0; i < freezeCount && i < headers.length; i++) {
            headers[i].classList.add('frozen-col', `frozen-col-${i}`);
            headers[i].dataset.isFrozen = 'true';
            
            // Apply to body cells
            rows.forEach(row => {
                const cells = row.querySelectorAll('td');
                if (cells[i]) {
                    cells[i].classList.add('frozen-col', `frozen-col-${i}`);
                }
            });
        }
        
        // Calculate and set initial positions
        window.enhancedTable.updateFreezeColumnPositions(table);
    },
    
    // Update frozen column positions on scroll
    updateFreezeColumnPositions: function(table, wrapper) {
        if (!wrapper) {
            wrapper = table.closest('.table-wrapper');
        }
        
        const scrollLeft = wrapper ? wrapper.scrollLeft : 0;
        const frozenCols = table.querySelectorAll('.frozen-col');
        
        // Group by column index
        const columnGroups = {};
        frozenCols.forEach(col => {
            const classes = Array.from(col.classList);
            const frozenClass = classes.find(c => c.startsWith('frozen-col-'));
            if (frozenClass) {
                const index = frozenClass.split('-')[2];
                if (!columnGroups[index]) {
                    columnGroups[index] = [];
                }
                columnGroups[index].push(col);
            }
        });
        
        // Calculate cumulative widths and apply positions
        let cumulativeWidth = 0;
        Object.keys(columnGroups).sort((a, b) => parseInt(a) - parseInt(b)).forEach(index => {
            const cols = columnGroups[index];
            const width = cols[0].offsetWidth;
            
            cols.forEach(col => {
                col.style.position = 'sticky';
                col.style.left = `${cumulativeWidth}px`;
                col.style.zIndex = '10';
                
                // Add shadow effect when scrolled
                if (scrollLeft > 0) {
                    col.classList.add('frozen-shadow');
                } else {
                    col.classList.remove('frozen-shadow');
                }
            });
            
            cumulativeWidth += width;
        });
    },
    
    // Initialize view saving functionality
    initViewSaving: function(tableSelector, settings) {
        const table = document.querySelector(tableSelector);
        if (!table) return;
        
        // Add view controls to the page
        this.addViewControls(table, settings);
        
        // Load default view if exists
        this.loadDefaultView(settings.tableType);
        
        // Save view state on changes
        this.setupAutoSave(table, settings);
    },
    
    // Add view management controls
    addViewControls: function(table, settings) {
        // Find a suitable place to add controls (before the table)
        const wrapper = table.closest('.table-wrapper') || table.parentElement;
        const controlsContainer = wrapper.parentElement;
        
        // Check if controls already exist
        if (controlsContainer.querySelector('.table-view-controls')) {
            return;
        }
        
        // Create view controls
        const viewControls = document.createElement('div');
        viewControls.className = 'table-view-controls mb-3';
        viewControls.innerHTML = `
            <div class="row align-items-center">
                <div class="col-auto">
                    <div class="input-group input-group-sm">
                        <span class="input-group-text"><i class="fas fa-th"></i></span>
                        <select class="form-select form-select-sm" id="viewSelector">
                            <option value="">Default View</option>
                        </select>
                        <button class="btn btn-sm btn-outline-primary" type="button" id="loadViewBtn" title="Load View">
                            <i class="fas fa-folder-open"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-success" type="button" id="saveViewBtn" title="Save View">
                            <i class="fas fa-save"></i>
                        </button>
                        <button class="btn btn-sm btn-primary" type="button" id="saveAsViewBtn" title="Save As New View">
                            <i class="fas fa-file-plus"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-danger" type="button" id="deleteViewBtn" title="Delete View">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </div>
                <div class="col-auto ms-auto">
                    <div class="dropdown">
                        <button class="btn btn-sm btn-outline-secondary dropdown-toggle" type="button" id="columnControlBtn" data-bs-toggle="dropdown" aria-expanded="false">
                            <i class="fas fa-columns"></i> Columns
                        </button>
                        <div class="dropdown-menu dropdown-menu-end p-3" style="min-width: 300px; max-height: 500px; overflow-y: auto;" id="columnControlDropdown">
                            <!-- Column controls will be populated here -->
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        // Insert before the wrapper
        controlsContainer.insertBefore(viewControls, wrapper);
        
        // Set up event handlers
        this.setupViewControlHandlers(viewControls, settings);
        
        // Load available views
        this.loadAvailableViews(settings.tableType);
    },
    
    // Set up event handlers for view controls
    setupViewControlHandlers: function(controls, settings) {
        const viewSelector = controls.querySelector('#viewSelector');
        const loadBtn = controls.querySelector('#loadViewBtn');
        const saveBtn = controls.querySelector('#saveViewBtn');
        const saveAsBtn = controls.querySelector('#saveAsViewBtn');
        const deleteBtn = controls.querySelector('#deleteViewBtn');
        const columnControlBtn = controls.querySelector('#columnControlBtn');
        
        // Load view
        loadBtn.addEventListener('click', () => {
            const viewId = viewSelector.value;
            if (viewId) {
                this.loadView(parseInt(viewId), settings.tableType);
            }
        });
        
        // Save current view
        saveBtn.addEventListener('click', () => {
            const viewId = viewSelector.value;
            if (viewId) {
                this.saveView(parseInt(viewId), settings.tableType);
            } else {
                // No view selected, trigger save as
                saveAsBtn.click();
            }
        });
        
        // Save as new view - show modal
        saveAsBtn.addEventListener('click', () => {
            const modal = new bootstrap.Modal(document.getElementById('saveViewModal'));
            const viewNameInput = document.getElementById('viewNameInput');
            const shareViewCheck = document.getElementById('shareViewCheck');
            const makeDefaultCheck = document.getElementById('makeDefaultCheck');
            const saveViewBtn = document.getElementById('saveViewBtn');
            
            // Clear previous values
            viewNameInput.value = '';
            shareViewCheck.checked = false;
            makeDefaultCheck.checked = false;
            
            // Handle save button click
            const handleSave = () => {
                const viewName = viewNameInput.value.trim();
                if (viewName) {
                    this.saveAsNewView(viewName, shareViewCheck.checked, makeDefaultCheck.checked, settings.tableType);
                    modal.hide();
                }
            };
            
            // Remove previous event listener and add new one
            const newSaveBtn = saveViewBtn.cloneNode(true);
            saveViewBtn.parentNode.replaceChild(newSaveBtn, saveViewBtn);
            newSaveBtn.addEventListener('click', handleSave);
            
            modal.show();
        });
        
        // Delete view
        deleteBtn.addEventListener('click', () => {
            const viewId = viewSelector.value;
            if (viewId && confirm('Are you sure you want to delete this view?')) {
                this.deleteView(parseInt(viewId), settings.tableType);
            }
        });
        
        // Column control dropdown - unified interface
        if (columnControlBtn) {
            const dropdown = document.getElementById('columnControlDropdown');
            
            // Initialize dropdown content on first show
            columnControlBtn.addEventListener('shown.bs.dropdown', () => {
                this.populateColumnControlDropdown(dropdown, settings);
            });
            
            // Handle clicks inside dropdown (prevent closing)
            dropdown.addEventListener('click', (e) => {
                e.stopPropagation();
                
                // Handle various controls
                if (e.target.type === 'checkbox') {
                    this.applyColumnVisibilityFromDropdown();
                } else if (e.target.closest('.move-up-btn')) {
                    const index = parseInt(e.target.closest('.move-up-btn').dataset.columnIndex);
                    this.moveColumn(index, 'up');
                    this.populateColumnControlDropdown(dropdown, settings);
                } else if (e.target.closest('.move-down-btn')) {
                    const index = parseInt(e.target.closest('.move-down-btn').dataset.columnIndex);
                    this.moveColumn(index, 'down');
                    this.populateColumnControlDropdown(dropdown, settings);
                } else if (e.target.closest('.freeze-btn')) {
                    const index = parseInt(e.target.closest('.freeze-btn').dataset.columnIndex);
                    this.toggleFreezeColumn(index);
                    this.populateColumnControlDropdown(dropdown, settings);
                }
            });
        }
    },
    
    // Populate unified column control dropdown
    populateColumnControlDropdown: function(dropdown, settings) {
        const table = document.querySelector('.enhanced-table');
        if (!table || !dropdown) return;
        
        // Get all columns
        const headers = Array.from(table.querySelectorAll('thead th'));
        const frozenCount = table.querySelectorAll('thead .frozen-col').length;
        
        // Clear existing content
        dropdown.innerHTML = `
            <div class="fw-bold mb-2">Column Controls</div>
            <div class="text-muted small mb-2">Show/hide, reorder, and freeze columns</div>
        `;
        
        // Create list container
        const listContainer = document.createElement('div');
        listContainer.className = 'column-control-list';
        
        // Create controls for each column
        headers.forEach((header, index) => {
            const columnName = header.textContent.trim();
            const isVisible = header.style.display !== 'none';
            const isFrozen = header.classList.contains('frozen-col');
            
            const columnDiv = document.createElement('div');
            columnDiv.className = 'column-control-item d-flex align-items-center gap-2 p-2 border-bottom';
            columnDiv.innerHTML = `
                <div class="form-check mb-0">
                    <input class="form-check-input" type="checkbox" id="col-vis-${index}" data-column-index="${index}" ${isVisible ? 'checked' : ''}>
                </div>
                <span class="flex-grow-1 text-truncate" title="${columnName}">${columnName || `Column ${index + 1}`}</span>
                <div class="btn-group btn-group-sm">
                    <button class="btn btn-sm btn-light move-up-btn" data-column-index="${index}" ${index === 0 ? 'disabled' : ''} title="Move up">
                        <i class="fas fa-chevron-up"></i>
                    </button>
                    <button class="btn btn-sm btn-light move-down-btn" data-column-index="${index}" ${index === headers.length - 1 ? 'disabled' : ''} title="Move down">
                        <i class="fas fa-chevron-down"></i>
                    </button>
                    <button class="btn btn-sm btn-light freeze-btn ${isFrozen ? 'active' : ''}" data-column-index="${index}" title="${isFrozen ? 'Unfreeze' : 'Freeze'} column">
                        <i class="fas fa-snowflake ${isFrozen ? 'text-primary' : ''}"></i>
                    </button>
                </div>
            `;
            
            listContainer.appendChild(columnDiv);
        });
        
        dropdown.appendChild(listContainer);
        
        // Add footer with info
        const footerDiv = document.createElement('div');
        footerDiv.className = 'mt-2 pt-2 border-top text-muted small';
        footerDiv.innerHTML = `
            <div><i class="fas fa-info-circle"></i> ${frozenCount} column(s) frozen</div>
            <div>Drag columns in the table for quick reorder</div>
        `;
        dropdown.appendChild(footerDiv);
    },
    
    // Move column up or down
    moveColumn: function(index, direction) {
        const table = document.querySelector('.enhanced-table');
        if (!table) return;
        
        const headers = Array.from(table.querySelectorAll('thead th'));
        const targetIndex = direction === 'up' ? index - 1 : index + 1;
        
        if (targetIndex < 0 || targetIndex >= headers.length) return;
        
        // Get all rows
        const allRows = Array.from(table.querySelectorAll('tr'));
        
        allRows.forEach(row => {
            const cells = Array.from(row.children);
            const fromCell = cells[index];
            const toCell = cells[targetIndex];
            
            if (fromCell && toCell) {
                if (direction === 'up') {
                    toCell.parentNode.insertBefore(fromCell, toCell);
                } else {
                    toCell.parentNode.insertBefore(fromCell, toCell.nextSibling);
                }
            }
        });
        
        // Re-apply freeze columns if needed
        const wrapper = table.closest('.table-wrapper');
        if (wrapper && table.querySelector('.frozen-col')) {
            window.enhancedTable.updateFreezeColumnPositions(table, wrapper);
        }
    },
    
    // Toggle freeze state of a column
    toggleFreezeColumn: function(index) {
        const table = document.querySelector('.enhanced-table');
        if (!table) return;
        
        const header = table.querySelectorAll('thead th')[index];
        if (!header) return;
        
        // Count current frozen columns
        const frozenColumns = Array.from(table.querySelectorAll('thead .frozen-col'));
        const isFrozen = header.classList.contains('frozen-col');
        
        if (isFrozen) {
            // Unfreeze this column and all columns after it
            for (let i = index; i < frozenColumns.length; i++) {
                this.unfreezeColumn(frozenColumns[i], i);
            }
        } else {
            // Freeze all columns up to and including this one
            const headers = table.querySelectorAll('thead th');
            for (let i = 0; i <= index; i++) {
                if (!headers[i].classList.contains('frozen-col')) {
                    this.freezeColumn(headers[i], i);
                }
            }
        }
        
        // Update positions
        window.enhancedTable.updateFreezeColumnPositions(table);
    },
    
    // Freeze a single column
    freezeColumn: function(header, index) {
        const table = header.closest('table');
        const rows = table.querySelectorAll('tbody tr');
        
        header.classList.add('frozen-col', `frozen-col-${index}`);
        header.dataset.isFrozen = 'true';
        
        rows.forEach(row => {
            const cells = row.querySelectorAll('td');
            if (cells[index]) {
                cells[index].classList.add('frozen-col', `frozen-col-${index}`);
            }
        });
    },
    
    // Unfreeze a single column
    unfreezeColumn: function(header, index) {
        const table = header.closest('table');
        const rows = table.querySelectorAll('tbody tr');
        
        // Remove all frozen classes
        Array.from(header.classList).forEach(className => {
            if (className.startsWith('frozen-col')) {
                header.classList.remove(className);
            }
        });
        header.classList.remove('frozen-shadow');
        header.style.position = '';
        header.style.left = '';
        header.style.zIndex = '';
        delete header.dataset.isFrozen;
        
        rows.forEach(row => {
            const cells = row.querySelectorAll('td');
            if (cells[index]) {
                Array.from(cells[index].classList).forEach(className => {
                    if (className.startsWith('frozen-col')) {
                        cells[index].classList.remove(className);
                    }
                });
                cells[index].classList.remove('frozen-shadow');
                cells[index].style.position = '';
                cells[index].style.left = '';
                cells[index].style.zIndex = '';
            }
        });
    },
    
    // Populate column visibility dropdown
    populateColumnVisibilityDropdown: function(dropdown) {
        const table = document.querySelector('.enhanced-table');
        if (!table || !dropdown) return;
        
        // Get all columns
        const headers = Array.from(table.querySelectorAll('thead th'));
        
        // Clear existing content
        dropdown.innerHTML = '<div class="fw-bold mb-2">Show/Hide Columns</div>';
        
        // Create checkboxes for each column
        headers.forEach((header, index) => {
            const columnName = header.textContent.trim();
            const isVisible = header.style.display !== 'none';
            
            const checkboxDiv = document.createElement('div');
            checkboxDiv.className = 'form-check';
            checkboxDiv.innerHTML = `
                <input class="form-check-input" type="checkbox" id="col-vis-${index}" data-column-index="${index}" ${isVisible ? 'checked' : ''}>
                <label class="form-check-label" for="col-vis-${index}">
                    ${columnName || `Column ${index + 1}`}
                </label>
            `;
            
            dropdown.appendChild(checkboxDiv);
        });
        
        // Add "Apply" and "Select All/None" buttons
        const buttonDiv = document.createElement('div');
        buttonDiv.className = 'mt-2 pt-2 border-top d-flex justify-content-between';
        buttonDiv.innerHTML = `
            <button class="btn btn-sm btn-link p-0" id="selectAllColumnsBtn">Select All</button>
            <button class="btn btn-sm btn-link p-0" id="selectNoneColumnsBtn">Select None</button>
        `;
        dropdown.appendChild(buttonDiv);
        
        // Handle select all/none
        document.getElementById('selectAllColumnsBtn').addEventListener('click', () => {
            dropdown.querySelectorAll('input[type="checkbox"]').forEach(cb => cb.checked = true);
            this.applyColumnVisibilityFromDropdown();
        });
        
        document.getElementById('selectNoneColumnsBtn').addEventListener('click', () => {
            dropdown.querySelectorAll('input[type="checkbox"]').forEach(cb => cb.checked = false);
            this.applyColumnVisibilityFromDropdown();
        });
    },
    
    // Apply column visibility from dropdown
    applyColumnVisibilityFromDropdown: function() {
        const table = document.querySelector('.enhanced-table');
        if (!table) return;
        
        const checkboxes = document.querySelectorAll('#columnControlDropdown input[type="checkbox"]');
        const headers = table.querySelectorAll('thead th');
        const rows = table.querySelectorAll('tbody tr');
        
        checkboxes.forEach(checkbox => {
            const columnIndex = parseInt(checkbox.dataset.columnIndex);
            const isVisible = checkbox.checked;
            
            // Apply to header
            if (headers[columnIndex]) {
                headers[columnIndex].style.display = isVisible ? '' : 'none';
            }
            
            // Apply to body cells
            rows.forEach(row => {
                const cells = row.querySelectorAll('td');
                if (cells[columnIndex]) {
                    cells[columnIndex].style.display = isVisible ? '' : 'none';
                }
            });
        });
        
        // Re-apply freeze columns if needed
        const wrapper = table.closest('.table-wrapper');
        if (wrapper && table.querySelector('.frozen-col')) {
            window.enhancedTable.updateFreezeColumnPositions(table, wrapper);
        }
    },
    
    // Show column visibility modal
    showColumnVisibilityModal: function() {
        const modal = new bootstrap.Modal(document.getElementById('columnVisibilityModal'));
        const table = document.querySelector('.enhanced-table');
        const columnList = document.getElementById('columnVisibilityList');
        
        if (!table) return;
        
        // Get all columns
        const headers = Array.from(table.querySelectorAll('thead th'));
        
        // Clear existing list
        columnList.innerHTML = '';
        
        // Create checkboxes for each column
        headers.forEach((header, index) => {
            const columnName = header.textContent.trim();
            const isVisible = header.style.display !== 'none';
            
            const checkboxDiv = document.createElement('div');
            checkboxDiv.className = 'form-check';
            checkboxDiv.innerHTML = `
                <input class="form-check-input" type="checkbox" id="col-vis-${index}" data-column-index="${index}" ${isVisible ? 'checked' : ''}>
                <label class="form-check-label" for="col-vis-${index}">
                    ${columnName || `Column ${index + 1}`}
                </label>
            `;
            
            columnList.appendChild(checkboxDiv);
        });
        
        // Handle apply button
        const applyBtn = document.getElementById('applyColumnVisibilityBtn');
        const newApplyBtn = applyBtn.cloneNode(true);
        applyBtn.parentNode.replaceChild(newApplyBtn, applyBtn);
        
        newApplyBtn.addEventListener('click', () => {
            this.applyColumnVisibilityFromModal();
            modal.hide();
        });
        
        modal.show();
    },
    
    // Apply column visibility from modal
    applyColumnVisibilityFromModal: function() {
        const table = document.querySelector('.enhanced-table');
        if (!table) return;
        
        const checkboxes = document.querySelectorAll('#columnVisibilityList input[type="checkbox"]');
        const headers = table.querySelectorAll('thead th');
        const rows = table.querySelectorAll('tbody tr');
        
        checkboxes.forEach(checkbox => {
            const columnIndex = parseInt(checkbox.dataset.columnIndex);
            const isVisible = checkbox.checked;
            
            // Apply to header
            if (headers[columnIndex]) {
                headers[columnIndex].style.display = isVisible ? '' : 'none';
            }
            
            // Apply to body cells
            rows.forEach(row => {
                const cells = row.querySelectorAll('td');
                if (cells[columnIndex]) {
                    cells[columnIndex].style.display = isVisible ? '' : 'none';
                }
            });
        });
        
        // Re-apply freeze columns if needed
        const wrapper = table.closest('.table-wrapper');
        if (wrapper && table.querySelector('.frozen-col')) {
            window.enhancedTable.updateFreezeColumnPositions(table, wrapper);
        }
    },
    
    // Show freeze columns modal
    showFreezeColumnsModal: function() {
        const modal = new bootstrap.Modal(document.getElementById('freezeColumnsModal'));
        const table = document.querySelector('.enhanced-table');
        const freezeInput = document.getElementById('freezeColumnCount');
        
        if (!table) return;
        
        // Count current frozen columns
        const currentFrozenCount = table.querySelectorAll('thead .frozen-col').length;
        freezeInput.value = currentFrozenCount;
        
        // Set max based on column count
        const totalColumns = table.querySelectorAll('thead th').length;
        freezeInput.max = Math.min(totalColumns - 1, 10);
        
        // Handle apply button
        const applyBtn = document.getElementById('applyFreezeColumnsBtn');
        const newApplyBtn = applyBtn.cloneNode(true);
        applyBtn.parentNode.replaceChild(newApplyBtn, applyBtn);
        
        newApplyBtn.addEventListener('click', () => {
            const freezeCount = parseInt(freezeInput.value) || 0;
            this.applyFreezeColumns(table, freezeCount);
            
            // Update the setting
            const tableSelector = Object.keys(window.enhancedTableInstances).find(selector => 
                document.querySelector(selector) === table
            );
            if (tableSelector && window.enhancedTableInstances[tableSelector]) {
                window.enhancedTableInstances[tableSelector].freezeColumns = freezeCount;
            }
            
            modal.hide();
        });
        
        modal.show();
    },
    
    // Load available views for the table
    loadAvailableViews: async function(tableType) {
        try {
            const response = await fetch(`/api/tableviews/table/${tableType}`);
            if (!response.ok) return;
            
            const views = await response.json();
            const viewSelector = document.querySelector('#viewSelector');
            if (!viewSelector) return;
            
            // Clear existing options
            viewSelector.innerHTML = '<option value="">Default View</option>';
            
            // Add views
            views.forEach(view => {
                const option = document.createElement('option');
                option.value = view.id;
                option.textContent = view.viewName;
                if (view.isDefault) {
                    option.textContent += ' (Default)';
                }
                if (view.isShared && !view.isOwner) {
                    option.textContent += ' (Shared)';
                }
                viewSelector.appendChild(option);
            });
            
            // Select default view
            const defaultView = views.find(v => v.isDefault);
            if (defaultView) {
                viewSelector.value = defaultView.id;
            }
        } catch (error) {
            console.error('Error loading views:', error);
        }
    },
    
    // Load default view if exists
    loadDefaultView: async function(tableType) {
        try {
            const response = await fetch(`/api/tableviews/table/${tableType}`);
            if (!response.ok) return;
            
            const views = await response.json();
            const defaultView = views.find(v => v.isDefault);
            
            if (defaultView) {
                await this.loadView(defaultView.id, tableType);
            }
        } catch (error) {
            console.error('Error loading default view:', error);
        }
    },
    
    // Load a specific view
    loadView: async function(viewId, tableType) {
        try {
            const response = await fetch(`/api/tableviews/${viewId}`);
            if (!response.ok) return;
            
            const view = await response.json();
            
            // Apply column order
            if (view.columnOrder) {
                const columnOrder = JSON.parse(view.columnOrder);
                this.applyColumnOrder(columnOrder);
            }
            
            // Apply column widths
            if (view.columnWidths) {
                const columnWidths = JSON.parse(view.columnWidths);
                this.applyColumnWidths(columnWidths);
            }
            
            // Apply column visibility
            if (view.columnVisibility) {
                const columnVisibility = JSON.parse(view.columnVisibility);
                this.applyColumnVisibility(columnVisibility);
            }
            
            // Show success message
            if (window.showToast) {
                window.showToast(`Loaded view: ${view.viewName}`, 'success');
            }
        } catch (error) {
            console.error('Error loading view:', error);
            if (window.showToast) {
                window.showToast('Failed to load view', 'error');
            }
        }
    },
    
    // Save current table state to existing view
    saveView: async function(viewId, tableType) {
        const state = this.getCurrentTableState();
        
        try {
            const response = await fetch(`/api/tableviews/${viewId}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    viewName: document.querySelector('#viewSelector option:checked')?.textContent.replace(' (Default)', '').replace(' (Shared)', '') || 'Untitled',
                    isDefault: false,
                    isShared: document.querySelector('#shareViewCheck')?.checked || false,
                    columnOrder: JSON.stringify(state.columnOrder),
                    columnWidths: JSON.stringify(state.columnWidths),
                    columnVisibility: JSON.stringify(state.columnVisibility)
                })
            });
            
            if (response.ok) {
                if (window.showToast) {
                    window.showToast('View saved successfully', 'success');
                }
            }
        } catch (error) {
            console.error('Error saving view:', error);
            if (window.showToast) {
                window.showToast('Failed to save view', 'error');
            }
        }
    },
    
    // Save as new view
    saveAsNewView: async function(viewName, isShared, isDefault, tableType) {
        const state = this.getCurrentTableState();
        
        try {
            const response = await fetch('/api/tableviews', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    viewName: viewName,
                    tableType: tableType,
                    isDefault: isDefault,
                    isShared: isShared,
                    columnOrder: JSON.stringify(state.columnOrder),
                    columnWidths: JSON.stringify(state.columnWidths),
                    columnVisibility: JSON.stringify(state.columnVisibility),
                    frozenColumns: state.frozenColumns
                })
            });
            
            if (response.ok) {
                const newView = await response.json();
                if (window.showToast) {
                    window.showToast('View created successfully', 'success');
                }
                // Reload available views
                await this.loadAvailableViews(tableType);
                // Select the new view
                const viewSelector = document.querySelector('#viewSelector');
                if (viewSelector) {
                    viewSelector.value = newView.id;
                }
            }
        } catch (error) {
            console.error('Error creating view:', error);
            if (window.showToast) {
                window.showToast('Failed to create view', 'error');
            }
        }
    },
    
    // Delete view
    deleteView: async function(viewId, tableType) {
        try {
            const response = await fetch(`/api/tableviews/${viewId}`, {
                method: 'DELETE'
            });
            
            if (response.ok) {
                if (window.showToast) {
                    window.showToast('View deleted successfully', 'success');
                }
                // Reload available views
                await this.loadAvailableViews(tableType);
            }
        } catch (error) {
            console.error('Error deleting view:', error);
            if (window.showToast) {
                window.showToast('Failed to delete view', 'error');
            }
        }
    },
    
    // Get current table state
    getCurrentTableState: function() {
        const table = document.querySelector('.enhanced-table');
        if (!table) return {};
        
        const headers = Array.from(table.querySelectorAll('thead th'));
        const columnOrder = headers.map(th => th.textContent.trim());
        
        // Get column widths from localStorage or computed styles
        const columnWidths = {};
        const tableKey = `table_${window.location.pathname}`;
        const savedWidths = localStorage.getItem(`${tableKey}_column_widths`);
        
        if (savedWidths) {
            Object.assign(columnWidths, JSON.parse(savedWidths));
        } else {
            headers.forEach((th, index) => {
                columnWidths[columnOrder[index]] = th.offsetWidth;
            });
        }
        
        // Get column visibility
        const columnVisibility = {};
        headers.forEach((th, index) => {
            columnVisibility[columnOrder[index]] = th.style.display !== 'none';
        });
        
        // Get frozen columns count
        const frozenColumns = table.querySelectorAll('thead .frozen-col').length;
        
        return {
            columnOrder,
            columnWidths,
            columnVisibility,
            frozenColumns
        };
    },
    
    // Apply column order
    applyColumnOrder: function(columnOrder) {
        // This would need to trigger a re-render in Blazor
        // For now, we'll store it and let Blazor handle it
        console.log('Apply column order:', columnOrder);
    },
    
    // Apply column widths
    applyColumnWidths: function(columnWidths) {
        const table = document.querySelector('.enhanced-table');
        if (!table) return;
        
        const headers = Array.from(table.querySelectorAll('thead th'));
        headers.forEach(th => {
            const columnName = th.textContent.trim();
            if (columnWidths[columnName]) {
                th.style.width = `${columnWidths[columnName]}px`;
            }
        });
        
        // Save to localStorage
        const tableKey = `table_${window.location.pathname}`;
        localStorage.setItem(`${tableKey}_column_widths`, JSON.stringify(columnWidths));
    },
    
    // Apply column visibility
    applyColumnVisibility: function(columnVisibility) {
        const table = document.querySelector('.enhanced-table');
        if (!table) return;
        
        const headers = Array.from(table.querySelectorAll('thead th'));
        const rows = table.querySelectorAll('tbody tr');
        
        headers.forEach((th, index) => {
            const columnName = th.textContent.trim();
            const isVisible = columnVisibility[columnName] !== false;
            
            // Apply to header
            th.style.display = isVisible ? '' : 'none';
            
            // Apply to body cells
            rows.forEach(row => {
                const cells = row.querySelectorAll('td');
                if (cells[index]) {
                    cells[index].style.display = isVisible ? '' : 'none';
                }
            });
        });
    },
    
    // Set up auto-save functionality
    setupAutoSave: function(table, settings) {
        // Save state to localStorage on column resize
        if (window.simpleResize) {
            const originalInit = window.simpleResize.init;
            window.simpleResize.init = function() {
                originalInit.call(this);
                
                // Add resize end listener
                document.addEventListener('mouseup', () => {
                    if (window.enhancedTable.autoSaveTimeout) {
                        clearTimeout(window.enhancedTable.autoSaveTimeout);
                    }
                    window.enhancedTable.autoSaveTimeout = setTimeout(() => {
                        const state = window.enhancedTable.getCurrentTableState();
                        const tableKey = `table_${window.location.pathname}`;
                        localStorage.setItem(`${tableKey}_column_widths`, JSON.stringify(state.columnWidths));
                    }, 500);
                });
            };
        }
    },
    
    // Listen for column reorder events from drag and drop
    listenForColumnReorderEvents: function(tableSelector, settings) {
        // Store the event handler so we can remove it later
        if (!window.enhancedTableReorderHandlers) {
            window.enhancedTableReorderHandlers = new Map();
        }
        
        const handleColumnsReordered = (event) => {
            console.log('Enhanced table: Columns reordered via drag and drop', event.detail);
            
            // Check if the dropdown is open
            const dropdown = document.getElementById('columnControlDropdown');
            const dropdownBtn = document.getElementById('columnControlBtn');
            
            if (dropdown && dropdownBtn && dropdownBtn.getAttribute('aria-expanded') === 'true') {
                // Dropdown is open, refresh it
                console.log('Enhanced table: Refreshing column control dropdown');
                setTimeout(() => {
                    window.enhancedTable.populateColumnControlDropdown(dropdown, settings);
                }, 100);
            }
        };
        
        // Listen for the custom event
        document.addEventListener('columnsReordered', handleColumnsReordered);
        
        // Store handler for cleanup
        window.enhancedTableReorderHandlers.set(tableSelector, handleColumnsReordered);
    },
    
    // Clean up a table instance
    cleanup: function(tableSelector) {
        if (window.enhancedTableInstances && window.enhancedTableInstances[tableSelector]) {
            delete window.enhancedTableInstances[tableSelector];
            
            // Clean up ResizeObserver
            if (window.enhancedTableObservers && window.enhancedTableObservers.has(tableSelector)) {
                const observer = window.enhancedTableObservers.get(tableSelector);
                observer.disconnect();
                window.enhancedTableObservers.delete(tableSelector);
            }
            
            // Clean up column reorder if it exists
            if (window.columnReorder && window.columnReorder.cleanup) {
                window.columnReorder.cleanup();
            }
            
            // Remove resize handles
            const table = document.querySelector(tableSelector);
            if (table) {
                table.querySelectorAll('.simple-resize-handle').forEach(handle => handle.remove());
            }
            
            // Remove view controls
            const controls = document.querySelector('.table-view-controls');
            if (controls) {
                controls.remove();
            }
            
            // Clean up column reorder event handler
            if (window.enhancedTableReorderHandlers && window.enhancedTableReorderHandlers.has(tableSelector)) {
                const handler = window.enhancedTableReorderHandlers.get(tableSelector);
                document.removeEventListener('columnsReordered', handler);
                window.enhancedTableReorderHandlers.delete(tableSelector);
            }
        }
    }
};