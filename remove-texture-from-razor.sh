#!/bin/bash

# Script to remove all texture-related code from the Razor component

FILE="/mnt/wsl/docker-desktop-bind-mounts/Ubuntu/48ebf8f80051d67f3b0d6c60f1ad1cdb2ebaa0f5fcbca8abf63fa46b927e42ec/SteelEstimation.Web/Components/EnhancedAvatarSelectorV2.razor"
TEMP_FILE="${FILE}.temp"

# Copy the file
cp "$FILE" "$TEMP_FILE"

# Remove all lines containing texture-related code
sed -i '/texture/Id' "$TEMP_FILE"
sed -i '/Texture/d' "$TEMP_FILE"

# Remove empty lines that result from deletion
sed -i '/^[[:space:]]*$/N;/^\n$/d' "$TEMP_FILE"

# Count remaining occurrences
echo "Texture occurrences before: $(grep -i texture "$FILE" | wc -l)"
echo "Texture occurrences after: $(grep -i texture "$TEMP_FILE" | wc -l)"

# Show what will be removed
echo "Lines that will be removed:"
grep -n -i texture "$FILE"

# Replace the original file
# mv "$TEMP_FILE" "$FILE"