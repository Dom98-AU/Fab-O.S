# Save View Functionality Test Guide

## Prerequisites
1. Navigate to http://localhost:8080
2. Login with:
   - Email: admin@steelestimation.com
   - Password: Admin@123

## Test Steps

### 1. Navigate to Customers Page
- Go to http://localhost:8080/customers
- Verify the enhanced table loads with view controls at the top

### 2. Test View Mode Switching
- Look for the view mode buttons: **List | Compact | Cards**
- Click **Cards** to switch to card view
- Verify cards are displayed instead of table rows

### 3. Test Cards Per Row (in Card View)
- Click the **Layout** button (appears next to Columns button)
- Select different options: 1, 2, 3, 4, 5, or 6 cards per row
- Verify the cards resize and rearrange accordingly

### 4. Test Save View Functionality

#### Save a New View:
1. While in card view with your preferred layout:
2. Look for the save buttons next to the view dropdown
3. Click the **blue button with plus icon** (Save As New View)
4. In the modal that appears:
   - Enter a name like "My Card View - 2 Columns"
   - Optionally check "Set as default view"
   - Click **Save**
5. Verify you see a success toast message

#### Load a Saved View:
1. Click the dropdown that shows "Default View"
2. Select your saved view from the list
3. Verify the table switches to your saved configuration

#### Update an Existing View:
1. Make changes (e.g., switch to 4 cards per row)
2. With your view selected in dropdown
3. Click the **green save button** (Save View)
4. Verify success message

#### Delete a View:
1. Select your view from the dropdown
2. Click the **red trash button** (Delete View)
3. Confirm deletion
4. Verify the view is removed from dropdown

### 5. Test Search with Views
1. In card view, type in the search box (e.g., "Tech")
2. Verify cards are filtered to show only matching results
3. Switch to List view
4. Verify search results persist
5. Clear search
6. Verify all records show again

### 6. Test Column Controls Visibility
- In **List/Compact** view: Columns button should be visible
- In **Card** view: Columns button should be hidden, Layout button visible

## Expected Results

✅ **View Modes**: All three modes (List, Compact, Cards) work correctly
✅ **Card Layout**: Cards resize based on selected cards per row
✅ **Save View**: Can save, load, update, and delete views
✅ **Search**: Works across all view modes
✅ **Persistence**: Saved views remember:
  - View mode (List/Compact/Card)
  - Cards per row setting
  - Column order and visibility (for list views)
  - Frozen columns (for list views)

## Troubleshooting

If views don't save:
1. Check browser console for errors (F12)
2. Ensure you're logged in with proper permissions
3. Try clearing browser cache (Ctrl+F5)

If cards don't display:
1. Ensure JavaScript is loaded (check for v=12)
2. Check if enhanced-table.js loaded successfully
3. Try switching views back and forth