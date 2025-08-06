// Enhanced table functionality - resize, reorder, freeze columns, view saving, and multiple view modes
window.enhancedTable = {
    // View mode constants
    VIEW_MODES: {
        LIST: 'list',
        COMPACT_LIST: 'compactList', 
        CARD_VIEW: 'cardView'
    },
    
    // Grouping configurations
    groupingConfigs: {
        customers: {
            'state': {
                label: 'State/Territory',
                extractor: (row) => {
                    const cells = row.querySelectorAll('td');
                    if (cells.length > 3) {
                        const locationCell = cells[3];
                        const text = locationCell.textContent.trim();
                        const match = text.match(/,\s*([A-Z]{2,3})/);
                        return match ? match[1] : 'Other';
                    }
                    return 'Other';
                },
                icon: 'fa-map-marker-alt'
            },
            'status': {
                label: 'Status',
                extractor: (row) => {
                    const statusBadge = row.querySelector('.badge');
                    return statusBadge ? statusBadge.textContent.trim() : 'Unknown';
                },
                icon: 'fa-toggle-on'
            },
            'projects': {
                label: 'Project Count',
                extractor: (row) => {
                    const cells = row.querySelectorAll('td');
                    if (cells.length > 4) {
                        const projectCell = cells[4];
                        const badge = projectCell.querySelector('.badge');
                        if (badge) {
                            const count = parseInt(badge.textContent.trim());
                            if (count === 0) return 'No Projects';
                            if (count === 1) return '1 Project';
                            if (count <= 5) return '2-5 Projects';
                            if (count <= 10) return '6-10 Projects';
                            return '10+ Projects';
                        }
                    }
                    return 'Unknown';
                },
                icon: 'fa-folder'
            },
            'contacts': {
                label: 'Contact Count',
                extractor: (row) => {
                    const cells = row.querySelectorAll('td');
                    if (cells.length > 3) {
                        const contactCell = cells[3];
                        const badge = contactCell.querySelector('.badge');
                        if (badge) {
                            const count = parseInt(badge.textContent.trim());
                            if (count === 0) return 'No Contacts';
                            if (count === 1) return '1 Contact';
                            if (count <= 3) return '2-3 Contacts';
                            return '4+ Contacts';
                        }
                    }
                    return 'Unknown';
                },
                icon: 'fa-users'
            },
            'alphabetical': {
                label: 'Alphabetical',
                extractor: (row) => {
                    const cells = row.querySelectorAll('td');
                    if (cells.length > 0) {
                        const companyName = cells[0].textContent.trim();
                        const firstChar = companyName.charAt(0).toUpperCase();
                        if (firstChar.match(/[A-Z]/)) return firstChar;
                        return '#'; // For numbers and special characters
                    }
                    return '#';
                },
                icon: 'fa-sort-alpha-down'
            }
        },
        default: {
            'column1': {
                label: 'First Column',
                extractor: (row) => {
                    const cells = row.querySelectorAll('td');
                    return cells.length > 0 ? cells[0].textContent.trim() : 'Unknown';
                },
                icon: 'fa-folder'
            }
        }
    },
    
    // Track grouping state
    groupingState: {},
    currentGrouping: null,
    
    // Feature compatibility matrix
    featureCompatibility: {
        list: {
            resize: true,
            reorder: true,
            freezeColumns: true,
            columnVisibility: true,
            sorting: true,
            filtering: true,
            viewSaving: true
        },
        compactList: {
            resize: true,
            reorder: true,
            freezeColumns: true,
            columnVisibility: true,
            sorting: true,
            filtering: true,
            viewSaving: true
        },
        cardView: {
            resize: false,
            reorder: false,
            freezeColumns: false,
            columnVisibility: true, // Which fields to show on cards
            sorting: true,
            filtering: true,
            viewSaving: true,
            cardLayout: true // Cards per row setting
        }
    },
    
    // Initialize enhanced features for a table
    init: function(tableSelector, options = {}) {
        const defaults = {
            viewMode: this.VIEW_MODES.LIST, // Default view mode
            enableViewModes: true, // Enable view mode switching by default
            availableViews: [this.VIEW_MODES.LIST, this.VIEW_MODES.COMPACT_LIST, this.VIEW_MODES.CARD_VIEW],
            cardViewOptions: {
                cardsPerRow: 3,
                templateId: null,
                defaultFields: ['title', 'subtitle', 'status', 'actions']
            },
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
            
            // Store original table HTML for view switching
            if (!table.dataset.originalHtml) {
                table.dataset.originalHtml = table.outerHTML;
            }
            
            // Add enhanced-table class and view mode class
            table.classList.add('enhanced-table');
            table.classList.add(`view-mode-${settings.viewMode}`);
            table.dataset.viewMode = settings.viewMode;
            
            // Initialize view based on current mode
            this.applyViewMode(table, settings);
            
            // Apply freeze columns if enabled and compatible with view mode
            const viewCompatibility = this.featureCompatibility[settings.viewMode];
            if (viewCompatibility.freezeColumns && settings.enableFreezeColumns && settings.freezeColumns > 0) {
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
                
                // Store resize observer for cleanup
                if (!window.enhancedTableObservers) {
                    window.enhancedTableObservers = new Map();
                }
                window.enhancedTableObservers.set(tableSelector, resizeObserver);
                
                // Add MutationObserver to watch for table content changes (e.g., from search/filtering)
                if (settings.viewMode === this.VIEW_MODES.CARD_VIEW) {
                    const mutationObserver = new MutationObserver((mutations) => {
                        // Check if tbody was modified
                        const tbodyModified = mutations.some(mutation => 
                            mutation.target.tagName === 'TBODY' || 
                            mutation.target.closest('tbody')
                        );
                        
                        if (tbodyModified) {
                            // Debounce to avoid multiple updates
                            clearTimeout(this.updateTimeout);
                            this.updateTimeout = setTimeout(() => {
                                console.log('Enhanced table: Table content changed, updating card view');
                                this.applyCardView(table, settings);
                            }, 100);
                        }
                    });
                    
                    // Observe the table for changes
                    mutationObserver.observe(table, {
                        childList: true,
                        subtree: true,
                        characterData: false,
                        attributes: false
                    });
                    
                    // Store mutation observer
                    if (!window.enhancedTableMutationObservers) {
                        window.enhancedTableMutationObservers = new Map();
                    }
                    window.enhancedTableMutationObservers.set(tableSelector, mutationObserver);
                }
                
                // Add scroll listener for freeze columns
                if (settings.enableFreezeColumns && settings.freezeColumns > 0) {
                    wrapper.addEventListener('scroll', () => {
                        window.enhancedTable.updateFreezeColumnPositions(table, wrapper);
                    });
                }
            }
            
            // Initialize features based on view mode compatibility
            const modeCompatibility = this.featureCompatibility[settings.viewMode];
            
            if (modeCompatibility.reorder && settings.enableReorder && settings.dotNetRef) {
                console.log('Enhanced table: Initializing column reordering');
                // Use the existing column reorder if available
                if (window.columnReorder) {
                    window.columnReorder.initialize(settings.dotNetRef, tableSelector);
                }
            }
            
            // Initialize resize after reorder
            setTimeout(() => {
                if (modeCompatibility.resize && settings.enableResize) {
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
    
    // Apply view mode to table
    applyViewMode: function(table, settings) {
        const viewMode = settings.viewMode;
        console.log('Enhanced table: Applying view mode:', viewMode);
        
        switch(viewMode) {
            case this.VIEW_MODES.COMPACT_LIST:
                this.applyCompactListView(table, settings);
                break;
            case this.VIEW_MODES.CARD_VIEW:
                this.applyCardView(table, settings);
                break;
            case this.VIEW_MODES.LIST:
            default:
                this.applyListView(table, settings);
                break;
        }
    },
    
    // Apply standard list view
    applyListView: function(table, settings) {
        // Remove compact and card classes
        table.classList.remove('compact-list', 'card-view');
        table.classList.add('list-view');
        
        // Ensure table is visible
        const wrapper = table.closest('.table-wrapper');
        if (wrapper) {
            wrapper.style.display = '';
        }
    },
    
    // Apply compact list view
    applyCompactListView: function(table, settings) {
        // Remove other view classes
        table.classList.remove('list-view', 'card-view');
        table.classList.add('compact-list');
        
        // Ensure table is visible
        const wrapper = table.closest('.table-wrapper');
        if (wrapper) {
            wrapper.style.display = '';
        }
    },
    
    // Apply card view
    applyCardView: function(table, settings) {
        const wrapper = table.closest('.table-wrapper') || table.parentElement;
        
        // Hide the original table
        table.style.display = 'none';
        
        // Create card container if it doesn't exist
        let cardContainer = wrapper.querySelector('.card-view-container');
        if (!cardContainer) {
            cardContainer = document.createElement('div');
            cardContainer.className = 'card-view-container';
            wrapper.appendChild(cardContainer);
        }
        
        // Render cards
        this.renderCards(table, cardContainer, settings);
    },
    
    // Render cards from table data
    renderCards: function(table, container, settings) {
        // Clear existing cards
        container.innerHTML = '';
        
        // Get table headers for field mapping
        const headers = Array.from(table.querySelectorAll('thead th')).map(th => ({
            text: th.textContent.trim(),
            index: th.cellIndex
        }));
        
        // Get table rows
        const rows = table.querySelectorAll('tbody tr');
        const cardsPerRow = settings.cardViewOptions.cardsPerRow || 3;
        
        // Create card grid
        const cardGrid = document.createElement('div');
        cardGrid.className = 'card-view-grid';
        cardGrid.dataset.cardsPerRow = cardsPerRow;
        
        // Create cards for each row
        rows.forEach((row, rowIndex) => {
            const card = this.createCard(row, headers, settings);
            if (card) {
                cardGrid.appendChild(card);
            }
        });
        
        container.appendChild(cardGrid);
    },
    
    // Create a single card from a table row
    createCard: function(row, headers, settings) {
        const cells = row.querySelectorAll('td');
        if (cells.length === 0) return null;
        
        const card = document.createElement('div');
        card.className = 'card enhanced-table-card';
        card.dataset.rowIndex = row.rowIndex;
        
        // Create card content based on template or default layout
        if (settings.cardViewOptions.templateId) {
            // Use custom template if provided
            const template = document.getElementById(settings.cardViewOptions.templateId);
            if (template) {
                card.innerHTML = this.processCardTemplate(template.innerHTML, cells, headers);
            } else {
                card.innerHTML = this.createDefaultCardContent(cells, headers);
            }
        } else {
            card.innerHTML = this.createDefaultCardContent(cells, headers, settings);
        }
        
        // Maintain row click functionality
        if (row.onclick) {
            card.style.cursor = 'pointer';
            card.onclick = (e) => {
                // Don't trigger if clicking on buttons/links
                if (!e.target.closest('button, a')) {
                    row.onclick.call(row, e);
                }
            };
        }
        
        // Copy any data attributes from the row
        Array.from(row.attributes).forEach(attr => {
            if (attr.name.startsWith('data-')) {
                card.setAttribute(attr.name, attr.value);
            }
        });
        
        return card;
    },
    
    // Create default card content
    createDefaultCardContent: function(cells, headers, settings) {
        let html = '';
        
        // Extract cell content, handling HTML elements
        const getCellContent = (cell) => {
            // If cell contains badges, preserve them
            const badge = cell.querySelector('.badge');
            if (badge) {
                return badge.outerHTML;
            }
            // If cell contains code elements, preserve them
            const code = cell.querySelector('code');
            if (code) {
                return code.outerHTML;
            }
            // Otherwise return text content
            return cell.textContent.trim();
        };
        
        if (cells.length > 0 && headers.length > 0) {
            // Card header with title
            const titleContent = cells[0].querySelector('strong') ? 
                cells[0].querySelector('strong').textContent.trim() : 
                cells[0].textContent.trim();
            
            html += '<div class="card-header">';
            html += `<h5 class="card-title mb-0">${titleContent}</h5>`;
            html += '</div>';
            
            // Card body
            html += '<div class="card-body">';
            
            // Status badges (if any)
            const statusCell = Array.from(cells).find(cell => cell.querySelector('.badge'));
            if (statusCell && statusCell !== cells[0]) {
                html += '<div class="mb-3">';
                html += statusCell.innerHTML;
                html += '</div>';
            }
            
            // Details section
            html += '<div class="card-details">';
            for (let i = 1; i < Math.min(cells.length - 1, headers.length); i++) {
                const header = headers[i].text;
                const value = getCellContent(cells[i]);
                
                // Skip empty values or action columns
                if (value && value !== '-' && !cells[i].querySelector('.btn-group')) {
                    html += `
                        <div class="detail-row d-flex justify-content-between mb-2">
                            <span class="detail-label text-muted">${header}:</span>
                            <span class="detail-value">${value}</span>
                        </div>
                    `;
                }
            }
            html += '</div>';
            
            html += '</div>'; // End card-body
            
            // Card footer with actions (if last column contains buttons)
            const lastCell = cells[cells.length - 1];
            const btnGroup = lastCell.querySelector('.btn-group');
            if (btnGroup) {
                html += '<div class="card-footer bg-transparent">';
                html += '<div class="d-flex justify-content-end">';
                html += btnGroup.outerHTML;
                html += '</div>';
                html += '</div>';
            }
        }
        
        return html;
    },
    
    // Process custom card template
    processCardTemplate: function(template, cells, headers) {
        let processed = template;
        
        // Replace placeholders with cell values
        headers.forEach((header, index) => {
            const placeholder = new RegExp(`{{${header.text}}}`, 'gi');
            const value = cells[index] ? cells[index].textContent.trim() : '';
            processed = processed.replace(placeholder, value);
        });
        
        // Replace index-based placeholders
        cells.forEach((cell, index) => {
            const placeholder = new RegExp(`{{column${index}}}`, 'gi');
            processed = processed.replace(placeholder, cell.textContent.trim());
        });
        
        return processed;
    },
    
    // Switch view mode
    switchViewMode: function(tableSelector, newMode) {
        const settings = window.enhancedTableInstances[tableSelector];
        if (!settings) return;
        
        const table = document.querySelector(tableSelector);
        if (!table) return;
        
        // Clean up existing mutation observer
        if (window.enhancedTableMutationObservers && window.enhancedTableMutationObservers.has(tableSelector)) {
            const observer = window.enhancedTableMutationObservers.get(tableSelector);
            observer.disconnect();
            window.enhancedTableMutationObservers.delete(tableSelector);
        }
        
        // Update settings
        settings.viewMode = newMode;
        
        // Clear existing view
        const wrapper = table.closest('.table-wrapper');
        if (wrapper) {
            const cardContainer = wrapper.querySelector('.card-view-container');
            if (cardContainer) {
                cardContainer.remove();
            }
        }
        
        // Reset table visibility
        table.style.display = '';
        
        // Remove all view mode classes
        table.classList.remove('view-mode-list', 'view-mode-compactList', 'view-mode-cardView');
        table.classList.add(`view-mode-${newMode}`);
        table.dataset.viewMode = newMode;
        
        // Apply new view mode
        this.applyViewMode(table, settings);
        
        // Set up mutation observer for card view
        if (newMode === this.VIEW_MODES.CARD_VIEW) {
            const mutationObserver = new MutationObserver((mutations) => {
                const tbodyModified = mutations.some(mutation => 
                    mutation.target.tagName === 'TBODY' || 
                    mutation.target.closest('tbody')
                );
                
                if (tbodyModified) {
                    clearTimeout(this.updateTimeout);
                    this.updateTimeout = setTimeout(() => {
                        console.log('Enhanced table: Table content changed, updating card view');
                        this.applyCardView(table, settings);
                    }, 100);
                }
            });
            
            mutationObserver.observe(table, {
                childList: true,
                subtree: true,
                characterData: false,
                attributes: false
            });
            
            if (!window.enhancedTableMutationObservers) {
                window.enhancedTableMutationObservers = new Map();
            }
            window.enhancedTableMutationObservers.set(tableSelector, mutationObserver);
        }
        
        // Reinitialize features for new mode
        this.reinitializeFeatures(table, settings);
    },
    
    // Apply grouping to table
    applyGrouping: function(groupBy, tableSelector) {
        const table = document.querySelector(tableSelector || '.enhanced-table');
        if (!table) return;
        
        const settings = window.enhancedTableInstances[tableSelector || '.enhanced-table'];
        if (!settings) return;
        
        // Get appropriate grouping config
        const tableType = settings.tableType ? settings.tableType.toLowerCase() : 'default';
        const groupingConfig = this.groupingConfigs[tableType] || this.groupingConfigs.default;
        
        if (!groupBy || groupBy === 'none') {
            this.removeGrouping(table);
            return;
        }
        
        const config = groupingConfig[groupBy];
        if (!config) {
            console.error('Grouping configuration not found for:', groupBy);
            return;
        }
        
        // Store current grouping
        this.currentGrouping = groupBy;
        
        // Get all data rows (not header rows)
        const tbody = table.querySelector('tbody');
        if (!tbody) return;
        
        const rows = Array.from(tbody.querySelectorAll('tr'));
        if (rows.length === 0) return;
        
        // Group rows by the selected criteria
        const groups = {};
        rows.forEach(row => {
            const groupKey = config.extractor(row);
            if (!groups[groupKey]) {
                groups[groupKey] = [];
            }
            groups[groupKey].push(row);
        });
        
        // Clear tbody
        tbody.innerHTML = '';
        
        // Sort group keys
        const sortedKeys = Object.keys(groups).sort((a, b) => {
            // Special handling for alphabetical sorting
            if (groupBy === 'alphabetical') {
                if (a === '#') return 1;
                if (b === '#') return -1;
            }
            return a.localeCompare(b);
        });
        
        // Create grouped structure
        sortedKeys.forEach(groupKey => {
            const groupRows = groups[groupKey];
            const groupId = `group-${groupBy}-${groupKey.replace(/\s+/g, '-').toLowerCase()}`;
            
            // Create group header row
            const groupHeader = document.createElement('tr');
            groupHeader.className = 'group-header';
            groupHeader.dataset.groupId = groupId;
            groupHeader.dataset.groupKey = groupKey;
            
            // Get column count from first data row
            const colCount = table.querySelectorAll('thead th').length;
            
            groupHeader.innerHTML = `
                <td colspan="${colCount}" class="group-header-cell">
                    <div class="group-header-content">
                        <button class="btn btn-sm btn-link group-toggle-btn" data-group-id="${groupId}">
                            <i class="fas fa-chevron-down group-icon"></i>
                        </button>
                        <i class="fas ${config.icon} group-category-icon"></i>
                        <span class="group-title">${groupKey}</span>
                        <span class="badge bg-secondary ms-2">${groupRows.length}</span>
                        <div class="group-actions ms-auto">
                            <button class="btn btn-sm btn-link text-muted collapse-all-btn" title="Collapse all in this group">
                                <i class="fas fa-compress-alt"></i>
                            </button>
                        </div>
                    </div>
                </td>
            `;
            
            tbody.appendChild(groupHeader);
            
            // Add grouped rows
            groupRows.forEach(row => {
                row.classList.add('grouped-row');
                row.dataset.groupId = groupId;
                tbody.appendChild(row);
            });
        });
        
        // Initialize group collapse/expand handlers
        this.initializeGroupingHandlers(table);
        
        // Add grouped class to table
        table.classList.add('table-grouped');
        table.dataset.groupedBy = groupBy;
        
        // Save grouping state
        if (settings.enableViewSaving) {
            const tableKey = `table_${window.location.pathname}`;
            localStorage.setItem(`${tableKey}_grouping`, groupBy);
        }
    },
    
    // Remove grouping from table
    removeGrouping: function(table) {
        if (!table) return;
        
        const tbody = table.querySelector('tbody');
        if (!tbody) return;
        
        // Get all rows (both headers and data)
        const allRows = Array.from(tbody.querySelectorAll('tr'));
        
        // Filter out group headers and keep only data rows
        const dataRows = allRows.filter(row => !row.classList.contains('group-header'));
        
        // Clear tbody
        tbody.innerHTML = '';
        
        // Re-add data rows without grouping
        dataRows.forEach(row => {
            row.classList.remove('grouped-row');
            delete row.dataset.groupId;
            tbody.appendChild(row);
        });
        
        // Remove grouped class from table
        table.classList.remove('table-grouped');
        delete table.dataset.groupedBy;
        
        // Clear current grouping
        this.currentGrouping = null;
        
        // Clear saved grouping state
        const tableKey = `table_${window.location.pathname}`;
        localStorage.removeItem(`${tableKey}_grouping`);
    },
    
    // Initialize grouping event handlers
    initializeGroupingHandlers: function(table) {
        // Handle group toggle buttons
        table.querySelectorAll('.group-toggle-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                const groupId = btn.dataset.groupId;
                this.toggleGroup(groupId, btn);
            });
        });
        
        // Handle group header clicks
        table.querySelectorAll('.group-header').forEach(header => {
            header.addEventListener('click', (e) => {
                if (!e.target.closest('button')) {
                    const btn = header.querySelector('.group-toggle-btn');
                    if (btn) {
                        btn.click();
                    }
                }
            });
        });
        
        // Handle collapse all buttons
        table.querySelectorAll('.collapse-all-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                const groupHeader = btn.closest('.group-header');
                const groupId = groupHeader.dataset.groupId;
                this.collapseGroup(groupId, groupHeader.querySelector('.group-toggle-btn'));
            });
        });
    },
    
    // Toggle group expand/collapse
    toggleGroup: function(groupId, button) {
        const table = button.closest('table');
        const rows = table.querySelectorAll(`tr.grouped-row[data-group-id="${groupId}"]`);
        const icon = button.querySelector('.group-icon');
        
        const isCollapsed = icon.classList.contains('fa-chevron-right');
        
        if (isCollapsed) {
            this.expandGroup(groupId, button);
        } else {
            this.collapseGroup(groupId, button);
        }
    },
    
    // Expand a group
    expandGroup: function(groupId, button) {
        const table = button.closest('table');
        const rows = table.querySelectorAll(`tr.grouped-row[data-group-id="${groupId}"]`);
        const icon = button.querySelector('.group-icon');
        
        rows.forEach(row => {
            row.style.display = '';
        });
        
        icon.classList.remove('fa-chevron-right');
        icon.classList.add('fa-chevron-down');
        
        // Save state
        this.groupingState[groupId] = 'expanded';
    },
    
    // Collapse a group
    collapseGroup: function(groupId, button) {
        const table = button.closest('table');
        const rows = table.querySelectorAll(`tr.grouped-row[data-group-id="${groupId}"]`);
        const icon = button.querySelector('.group-icon');
        
        rows.forEach(row => {
            row.style.display = 'none';
        });
        
        icon.classList.remove('fa-chevron-down');
        icon.classList.add('fa-chevron-right');
        
        // Save state
        this.groupingState[groupId] = 'collapsed';
    },
    
    // Populate grouping dropdown
    populateGroupingDropdown: function(dropdown, settings) {
        if (!dropdown) return;
        
        // Get appropriate grouping config
        const tableType = settings.tableType ? settings.tableType.toLowerCase() : 'default';
        const groupingConfig = this.groupingConfigs[tableType] || this.groupingConfigs.default;
        
        // Clear existing content
        dropdown.innerHTML = `
            <div class="fw-bold mb-2">Group Table By</div>
            <div class="list-group list-group-flush">
                <a href="#" class="list-group-item list-group-item-action ${!this.currentGrouping ? 'active' : ''}" data-group-by="none">
                    <i class="fas fa-times me-2"></i>
                    No Grouping
                </a>
        `;
        
        // Add grouping options
        Object.keys(groupingConfig).forEach(key => {
            const config = groupingConfig[key];
            const item = document.createElement('a');
            item.href = '#';
            item.className = `list-group-item list-group-item-action ${this.currentGrouping === key ? 'active' : ''}`;
            item.dataset.groupBy = key;
            item.innerHTML = `
                <i class="fas ${config.icon} me-2"></i>
                ${config.label}
            `;
            dropdown.querySelector('.list-group').appendChild(item);
        });
        
        dropdown.innerHTML += `
            </div>
            <div class="mt-2 pt-2 border-top">
                <button class="btn btn-sm btn-outline-secondary w-100" id="expandAllGroupsBtn">
                    <i class="fas fa-expand-alt me-1"></i>Expand All Groups
                </button>
                <button class="btn btn-sm btn-outline-secondary w-100 mt-1" id="collapseAllGroupsBtn">
                    <i class="fas fa-compress-alt me-1"></i>Collapse All Groups
                </button>
            </div>
        `;
        
        // Add click handlers
        dropdown.querySelectorAll('[data-group-by]').forEach(item => {
            item.addEventListener('click', (e) => {
                e.preventDefault();
                const groupBy = item.dataset.groupBy;
                const tableSelector = Object.keys(window.enhancedTableInstances).find(selector => 
                    dropdown.closest('.container-fluid')?.querySelector(selector)
                );
                if (tableSelector) {
                    this.applyGrouping(groupBy, tableSelector);
                    // Update active state
                    dropdown.querySelectorAll('.list-group-item').forEach(i => i.classList.remove('active'));
                    item.classList.add('active');
                }
            });
        });
        
        // Expand/Collapse all handlers
        const expandAllBtn = dropdown.querySelector('#expandAllGroupsBtn');
        if (expandAllBtn) {
            expandAllBtn.addEventListener('click', () => {
                document.querySelectorAll('.group-toggle-btn').forEach(btn => {
                    const icon = btn.querySelector('.group-icon');
                    if (icon.classList.contains('fa-chevron-right')) {
                        btn.click();
                    }
                });
            });
        }
        
        const collapseAllBtn = dropdown.querySelector('#collapseAllGroupsBtn');
        if (collapseAllBtn) {
            collapseAllBtn.addEventListener('click', () => {
                document.querySelectorAll('.group-toggle-btn').forEach(btn => {
                    const icon = btn.querySelector('.group-icon');
                    if (icon.classList.contains('fa-chevron-down')) {
                        btn.click();
                    }
                });
            });
        }
    },
    
    // Reinitialize features after view mode change
    reinitializeFeatures: function(table, settings) {
        const featureCompat = this.featureCompatibility[settings.viewMode];
        
        // Clean up existing features
        if (window.simpleResize) {
            table.querySelectorAll('.simple-resize-handle').forEach(handle => handle.remove());
        }
        
        // Reinitialize based on compatibility
        if (featureCompat.resize && settings.enableResize && window.simpleResize) {
            setTimeout(() => window.simpleResize.init(), 100);
        }
        
        if (featureCompat.reorder && settings.enableReorder && window.columnReorder && settings.dotNetRef) {
            window.columnReorder.initialize(settings.dotNetRef, table);
        }
        
        if (featureCompat.freezeColumns && settings.enableFreezeColumns && settings.freezeColumns > 0) {
            this.applyFreezeColumns(table, settings.freezeColumns);
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
        
        // Create view mode selector HTML
        let viewModeSelectorHtml = '';
        if (settings.enableViewModes && settings.availableViews && settings.availableViews.length > 1) {
            viewModeSelectorHtml = `
                <div class="col-auto">
                    <div class="btn-group btn-group-sm" role="group" aria-label="View Mode">
                        ${settings.availableViews.map(mode => `
                            <input type="radio" class="btn-check" name="viewMode" id="viewMode-${mode}" value="${mode}" ${settings.viewMode === mode ? 'checked' : ''}>
                            <label class="btn btn-outline-primary" for="viewMode-${mode}">
                                ${this.getViewModeIcon(mode)} ${this.getViewModeLabel(mode)}
                            </label>
                        `).join('')}
                    </div>
                </div>
            `;
        }
        
        viewControls.innerHTML = `
            <div class="row align-items-center">
                ${viewModeSelectorHtml}
                <div class="col-auto">
                    <div class="d-flex align-items-center gap-2">
                        <div class="input-group">
                            <span class="input-group-text"><i class="fas fa-bookmark"></i></span>
                            <select class="form-select" id="viewSelector" style="min-width: 200px;">
                                <option value="">Default View</option>
                            </select>
                        </div>
                        <div class="btn-group" role="group">
                            <button class="btn btn-primary" type="button" id="saveAsViewBtn" title="Save As New View">
                                <i class="fas fa-file-plus me-1"></i>
                                <span>Save As New</span>
                            </button>
                            <button class="btn btn-success" type="button" id="saveViewBtn" title="Save Current View">
                                <i class="fas fa-save me-1"></i>
                                <span>Save</span>
                            </button>
                            <button class="btn btn-danger" type="button" id="deleteViewBtn" title="Delete View">
                                <i class="fas fa-trash me-1"></i>
                                <span>Delete</span>
                            </button>
                        </div>
                    </div>
                </div>
                <div class="col-auto ms-auto">
                    <div class="btn-group btn-group-sm" role="group">
                        <div class="dropdown" id="columnControlContainer">
                            <button class="btn btn-sm btn-outline-secondary dropdown-toggle" type="button" id="columnControlBtn" data-bs-toggle="dropdown" aria-expanded="false">
                                <i class="fas fa-columns"></i> Columns
                            </button>
                            <div class="dropdown-menu dropdown-menu-end p-3" style="min-width: 300px; max-height: 500px; overflow-y: auto;" id="columnControlDropdown">
                                <!-- Column controls will be populated here -->
                            </div>
                        </div>
                        <div class="dropdown me-2" id="groupingControlContainer">
                            <button class="btn btn-sm btn-outline-secondary dropdown-toggle" type="button" id="groupingControlBtn" data-bs-toggle="dropdown" aria-expanded="false">
                                <i class="fas fa-layer-group"></i> Group By
                            </button>
                            <div class="dropdown-menu dropdown-menu-end p-3" style="min-width: 250px;" id="groupingDropdown">
                                <!-- Grouping options will be populated here -->
                            </div>
                        </div>
                        <div class="dropdown" id="cardLayoutContainer" style="display: none;">
                            <button class="btn btn-sm btn-outline-secondary dropdown-toggle" type="button" id="cardLayoutBtn" data-bs-toggle="dropdown" aria-expanded="false">
                                <i class="fas fa-th"></i> Layout
                            </button>
                            <div class="dropdown-menu dropdown-menu-end p-3" id="cardLayoutDropdown">
                                <div class="fw-bold mb-2">Cards per Row</div>
                                <div class="btn-group btn-group-sm" role="group">
                                    <input type="radio" class="btn-check" name="cardsPerRow" id="cards-1" value="1">
                                    <label class="btn btn-outline-secondary" for="cards-1">1</label>
                                    <input type="radio" class="btn-check" name="cardsPerRow" id="cards-2" value="2">
                                    <label class="btn btn-outline-secondary" for="cards-2">2</label>
                                    <input type="radio" class="btn-check" name="cardsPerRow" id="cards-3" value="3" checked>
                                    <label class="btn btn-outline-secondary" for="cards-3">3</label>
                                    <input type="radio" class="btn-check" name="cardsPerRow" id="cards-4" value="4">
                                    <label class="btn btn-outline-secondary" for="cards-4">4</label>
                                    <input type="radio" class="btn-check" name="cardsPerRow" id="cards-5" value="5">
                                    <label class="btn btn-outline-secondary" for="cards-5">5</label>
                                    <input type="radio" class="btn-check" name="cardsPerRow" id="cards-6" value="6">
                                    <label class="btn btn-outline-secondary" for="cards-6">6</label>
                                </div>
                            </div>
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
    
    // Get view mode icon
    getViewModeIcon: function(mode) {
        const icons = {
            list: '<i class="fas fa-list-ul"></i>',
            compactList: '<i class="fas fa-bars"></i>',
            cardView: '<i class="fas fa-th"></i>'
        };
        return icons[mode] || '<i class="fas fa-list-ul"></i>';
    },
    
    // Get view mode label
    getViewModeLabel: function(mode) {
        const labels = {
            list: 'List',
            compactList: 'Compact',
            cardView: 'Cards'
        };
        return labels[mode] || 'List';
    },
    
    // Set up event handlers for view controls
    setupViewControlHandlers: function(controls, settings) {
        const viewSelector = controls.querySelector('#viewSelector');
        const loadBtn = controls.querySelector('#loadViewBtn');
        const saveBtn = controls.querySelector('#saveViewBtn');
        const saveAsBtn = controls.querySelector('#saveAsViewBtn');
        const deleteBtn = controls.querySelector('#deleteViewBtn');
        const columnControlBtn = controls.querySelector('#columnControlBtn');
        const groupingControlBtn = controls.querySelector('#groupingControlBtn');
        
        // Initialize grouping dropdown
        if (groupingControlBtn) {
            const groupingDropdown = document.getElementById('groupingDropdown');
            
            groupingControlBtn.addEventListener('shown.bs.dropdown', () => {
                this.populateGroupingDropdown(groupingDropdown, settings);
            });
            
            // Load saved grouping if exists
            if (settings.enableViewSaving) {
                const tableKey = `table_${window.location.pathname}`;
                const savedGrouping = localStorage.getItem(`${tableKey}_grouping`);
                if (savedGrouping) {
                    setTimeout(() => {
                        const tableSelector = Object.keys(window.enhancedTableInstances).find(selector => 
                            controls.closest('.container-fluid')?.querySelector(selector)
                        );
                        if (tableSelector) {
                            this.applyGrouping(savedGrouping, tableSelector);
                        }
                    }, 500);
                }
            }
        }
        
        // Handle view mode switching
        const viewModeRadios = controls.querySelectorAll('input[name="viewMode"]');
        viewModeRadios.forEach(radio => {
            radio.addEventListener('change', (e) => {
                if (e.target.checked) {
                    const tableSelector = Object.keys(window.enhancedTableInstances).find(selector => 
                        controls.closest('.container-fluid')?.querySelector(selector)
                    );
                    if (tableSelector) {
                        this.switchViewMode(tableSelector, e.target.value);
                        
                        // Update control visibility based on view mode
                        this.updateControlsForViewMode(controls, e.target.value);
                    }
                }
            });
        });
        
        // Handle cards per row change
        const cardsPerRowRadios = controls.querySelectorAll('input[name="cardsPerRow"]');
        cardsPerRowRadios.forEach(radio => {
            radio.addEventListener('change', (e) => {
                if (e.target.checked && settings.viewMode === this.VIEW_MODES.CARD_VIEW) {
                    settings.cardViewOptions.cardsPerRow = parseInt(e.target.value);
                    const tableSelector = Object.keys(window.enhancedTableInstances).find(selector => 
                        controls.closest('.container-fluid')?.querySelector(selector)
                    );
                    if (tableSelector) {
                        const table = document.querySelector(tableSelector);
                        this.applyCardView(table, settings);
                    }
                }
            });
        });
        
        // Initialize control visibility
        this.updateControlsForViewMode(controls, settings.viewMode);
        
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
    
    // Update controls visibility based on view mode
    updateControlsForViewMode: function(controls, viewMode) {
        const columnControlContainer = controls.querySelector('#columnControlContainer');
        const cardLayoutContainer = controls.querySelector('#cardLayoutContainer');
        
        if (viewMode === this.VIEW_MODES.CARD_VIEW) {
            // Hide column controls, show card layout controls
            if (columnControlContainer) columnControlContainer.style.display = 'none';
            if (cardLayoutContainer) cardLayoutContainer.style.display = '';
        } else {
            // Show column controls, hide card layout controls
            if (columnControlContainer) columnControlContainer.style.display = '';
            if (cardLayoutContainer) cardLayoutContainer.style.display = 'none';
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
            
            // Apply view mode
            if (view.viewMode) {
                this.switchViewMode(view.viewMode);
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
                    columnVisibility: JSON.stringify(state.columnVisibility),
                    viewMode: state.viewMode
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
                    viewMode: state.viewMode,
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
        
        // Get current view mode
        const viewModeSelector = document.querySelector('input[name="viewMode"]:checked');
        const viewMode = viewModeSelector ? viewModeSelector.value : this.VIEW_MODES.LIST;
        
        return {
            columnOrder,
            columnWidths,
            columnVisibility,
            frozenColumns,
            viewMode
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
            
            // Clean up MutationObserver
            if (window.enhancedTableMutationObservers && window.enhancedTableMutationObservers.has(tableSelector)) {
                const observer = window.enhancedTableMutationObservers.get(tableSelector);
                observer.disconnect();
                window.enhancedTableMutationObservers.delete(tableSelector);
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