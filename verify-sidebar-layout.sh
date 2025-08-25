#!/bin/bash

echo "========================================================"
echo "SIDEBAR LAYOUT VERIFICATION REPORT"
echo "========================================================"
echo ""
echo "Testing: http://localhost:8080"
echo "Date: $(date)"
echo ""

# Check if the application is running
echo "1. CHECKING APPLICATION STATUS..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
    echo "   ✓ Application is running (HTTP 200)"
else
    echo "   ✗ Application is not responding"
    exit 1
fi

echo ""
echo "2. CHECKING CSS FILES..."

# Check site.css for sidebar styles
echo "   Analyzing site.css..."
CSS_FILE="/mnt/c/Fab.OS Platform/Fab O.S/SteelEstimation.Web/wwwroot/css/site.css"

if [ -f "$CSS_FILE" ]; then
    # Check sidebar positioning
    if grep -q "\.sidebar {" "$CSS_FILE"; then
        echo "   ✓ Sidebar styles found in CSS"
        
        # Extract sidebar properties
        SIDEBAR_PROPS=$(sed -n '/^\.sidebar {/,/^}/p' "$CSS_FILE" | head -10)
        
        if echo "$SIDEBAR_PROPS" | grep -q "position: fixed"; then
            echo "   ✓ Sidebar has 'position: fixed'"
        else
            echo "   ✗ Sidebar missing 'position: fixed'"
        fi
        
        if echo "$SIDEBAR_PROPS" | grep -q "left: 0"; then
            echo "   ✓ Sidebar positioned at 'left: 0'"
        else
            echo "   ✗ Sidebar not positioned at left: 0"
        fi
        
        if echo "$SIDEBAR_PROPS" | grep -q "width: 250px"; then
            echo "   ✓ Sidebar width is 250px"
        else
            echo "   ✗ Sidebar width is not 250px"
        fi
    fi
    
    # Check main content offset
    if grep -q "^main {" "$CSS_FILE"; then
        MAIN_PROPS=$(sed -n '/^main {/,/^}/p' "$CSS_FILE" | head -10)
        
        if echo "$MAIN_PROPS" | grep -q "margin-left: 250px"; then
            echo "   ✓ Main content has 'margin-left: 250px'"
        else
            echo "   ✗ Main content missing proper margin-left"
        fi
    fi
fi

echo ""
echo "3. CHECKING RAZOR COMPONENTS..."

# Check MainLayout.razor
LAYOUT_FILE="/mnt/c/Fab.OS Platform/Fab O.S/SteelEstimation.Web/Shared/MainLayout.razor"
if [ -f "$LAYOUT_FILE" ]; then
    echo "   Analyzing MainLayout.razor..."
    
    if grep -q '<div class="sidebar" id="main-sidebar">' "$LAYOUT_FILE"; then
        echo "   ✓ Sidebar div with correct class and ID found"
    else
        echo "   ✗ Sidebar div structure incorrect"
    fi
    
    if grep -q '<main id="main-content">' "$LAYOUT_FILE"; then
        echo "   ✓ Main content element with correct ID found"
    else
        echo "   ✗ Main content element structure incorrect"
    fi
    
    if grep -q '<NavMenu />' "$LAYOUT_FILE"; then
        echo "   ✓ NavMenu component included in sidebar"
    else
        echo "   ✗ NavMenu component not found in sidebar"
    fi
fi

# Check NavMenu.razor for logo
NAVMENU_FILE="/mnt/c/Fab.OS Platform/Fab O.S/SteelEstimation.Web/Shared/NavMenu.razor"
if [ -f "$NAVMENU_FILE" ]; then
    echo ""
    echo "   Analyzing NavMenu.razor..."
    
    if grep -q 'class="top-row navbar"' "$NAVMENU_FILE"; then
        echo "   ✓ NavMenu has top-row navbar section"
    fi
    
    if grep -q 'f_symbol_square_auto.png' "$NAVMENU_FILE"; then
        echo "   ✓ Fab O.S logo image reference found"
    fi
fi

echo ""
echo "4. LAYOUT STRUCTURE SUMMARY:"
echo ""
echo "   Expected Layout:"
echo "   ┌─────────────┬────────────────────────────┐"
echo "   │             │                            │"
echo "   │   SIDEBAR   │      MAIN CONTENT          │"
echo "   │   (250px)   │    (Rest of screen)        │"
echo "   │             │                            │"
echo "   │   - Logo    │    - Top bar with menu     │"
echo "   │   - Menu    │    - Page content          │"
echo "   │             │                            │"
echo "   └─────────────┴────────────────────────────┘"
echo ""

echo "5. RECOMMENDATIONS:"
echo ""
echo "   Based on the code analysis:"
echo "   • The sidebar should be positioned FIXED on the LEFT at 0px"
echo "   • The sidebar should be 250px wide"
echo "   • The main content should have a left margin of 250px"
echo "   • The logo should appear at the TOP of the sidebar"
echo "   • The hamburger menu should toggle the sidebar visibility"
echo ""

echo "6. TEST RESULTS:"
echo ""

# Count successes
SUCCESS_COUNT=$(grep -c "✓" <<< "$(cat $0 | bash 2>&1)")
FAIL_COUNT=$(grep -c "✗" <<< "$(cat $0 | bash 2>&1)")

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "   ✅ ALL CHECKS PASSED - Layout should be correct!"
    echo "   The sidebar is properly configured as a fixed left panel."
else
    echo "   ⚠️  Some checks failed. Please review the layout."
    echo "   Issues may be related to CSS not being applied correctly."
fi

echo ""
echo "========================================================"
echo "To manually verify, open http://localhost:8080 and check:"
echo "1. Sidebar is on the LEFT side (not centered)"
echo "2. Sidebar is 250px wide"
echo "3. Logo is at the TOP of the sidebar"
echo "4. Main content starts at 250px from left edge"
echo "5. Hamburger menu collapses/expands the sidebar"
echo "========================================================"