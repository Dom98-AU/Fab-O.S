#!/bin/bash

FILE="PackageWorksheets.razor"

echo "Applying minimal fix to $FILE..."

# Create a backup
cp "$FILE" "${FILE}.minimal-backup"

# Fix the indentation issue at line 1399-1400
# The toast-container should be inside the worksheet-content-wrapper
sed -i '1399s/^    </div>/        <\/div>/' "$FILE"
sed -i '1400s/^    </div>/    <\/div>/' "$FILE"

echo "Fix applied. The structure should now be:"
echo "  - Line 1399: closes toast-container"
echo "  - Line 1400: closes worksheet-content-wrapper"  
echo "  - Line 1401: closes worksheet-page-container and else block"

# Verify the fix
echo -e "\nVerifying structure around @code block:"
grep -n -A2 -B5 "^@code {" "$FILE" | tail -10