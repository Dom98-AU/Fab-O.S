#!/bin/bash

FILE="PackageWorksheets.razor"

echo "=== Analyzing Razor File Structure ==="

# Find @code block
CODE_LINE=$(grep -n "^@code {" "$FILE" | cut -d: -f1)
echo "Found @code block at line: $CODE_LINE"

# Check what's right before @code block
echo -e "\n=== Lines before @code block ==="
tail -n +$((CODE_LINE - 5)) "$FILE" | head -n 10

# Count braces up to @code block
echo -e "\n=== Brace balance before @code block ==="
head -n $((CODE_LINE - 1)) "$FILE" > temp_before_code.txt
OPEN_BRACES=$(grep -o "{" temp_before_code.txt | wc -l)
CLOSE_BRACES=$(grep -o "}" temp_before_code.txt | wc -l)
echo "Open braces: $OPEN_BRACES"
echo "Close braces: $CLOSE_BRACES"
echo "Balance: $((OPEN_BRACES - CLOSE_BRACES))"

# Find the closing brace for the else block
echo -e "\n=== Finding else block structure ==="
grep -n "^else$" "$FILE" | head -5

rm -f temp_before_code.txt