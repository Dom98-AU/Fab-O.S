# ViewScape - Advanced Table Visualization System

## Overview
ViewScape is a powerful table visualization system that provides column resizing, reordering, view saving capabilities, and multiple display modes including folder-style grouping for card views.

## How to Use

### 1. Add Required References
```csharp
@inject IJSRuntime JSRuntime
@implements IDisposable
```

### 2. Add Table Class
Give your table a unique CSS class:
```html
<table class="table table-hover my-unique-table">
```

### 3. Add Code-Behind
```csharp
private DotNetObjectReference<YourPage>? dotNetRef;

protected override async Task OnInitializedAsync()
{
    dotNetRef = DotNetObjectReference.Create(this);
    // ... your other initialization code
}

protected override async Task OnAfterRenderAsync(bool firstRender)
{
    if (firstRender)
    {
        // Initialize enhanced table features
        await JSRuntime.InvokeVoidAsync("enhancedTable.init", ".my-unique-table", new
        {
            enableResize = true,
            enableReorder = true,
            enableViewSaving = true,
            tableType = "YourTableType", // Used for saving views
            dotNetRef = dotNetRef
        });
    }
}

[JSInvokable]
public async Task ReorderColumns(string fromColumn, string toColumn, bool dropBefore)
{
    // Handle column reordering if needed
    StateHasChanged();
}

public void Dispose()
{
    dotNetRef?.Dispose();
}
```

## Features

### Column Resizing
- Hover between column headers to see a blue resize line
- Click and drag to resize columns
- Minimum column width: 50px
- Column widths are saved to localStorage

### Column Reordering
- Look for drag handles (⋮⋮) at the start of column headers
- Drag and drop columns to reorder
- First two columns (usually checkboxes) and last column (actions) are not draggable

### View Saving (Coming Soon)
- Save custom column arrangements
- Load saved views
- Set default views per user

## Example Pages Using Enhanced Tables
- `/customers` - Customer list
- `/package/{id}/worksheets` - Package worksheets

## Customization Options

```javascript
{
    enableResize: true,      // Enable column resizing
    enableReorder: true,     // Enable column reordering
    enableViewSaving: true,  // Enable view saving (requires backend)
    tableType: "Generic",    // Table identifier for saved views
    dotNetRef: null         // .NET reference for callbacks
}
```

## CSS Classes Added
- `.enhanced-table` - Added to tables with enhanced features
- `.simple-resize-handle` - Resize handle elements
- `.column-drag-handle` - Drag handle elements

## Browser Support
- Chrome, Edge, Firefox, Safari (latest versions)
- Touch support for mobile devices