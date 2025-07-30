#!/bin/bash

# Bash script to validate Razor file structure
FILE="PackageWorksheets.razor"

echo -e "\033[36mValidating $FILE structure...\033[0m"

# Count opening and closing div tags
OPEN_DIVS=$(grep -o "<div" "$FILE" | wc -l)
CLOSE_DIVS=$(grep -o "</div>" "$FILE" | wc -l)

echo -e "\033[33mOpening divs: $OPEN_DIVS\033[0m"
echo -e "\033[33mClosing divs: $CLOSE_DIVS\033[0m"

if [ "$OPEN_DIVS" -eq "$CLOSE_DIVS" ]; then
    echo -e "\033[32m✓ DIV tags are balanced\033[0m"
else
    DIFF=$((OPEN_DIVS - CLOSE_DIVS))
    echo -e "\033[31m✗ DIV tags are NOT balanced (difference: $DIFF)\033[0m"
fi

# Check for @code block
if grep -q "@code {" "$FILE"; then
    echo -e "\033[32m✓ @code block found\033[0m"
else
    echo -e "\033[31m✗ @code block not found\033[0m"
fi

# Count Razor control structures
IF_COUNT=$(grep -o "@if" "$FILE" | wc -l)
FOREACH_COUNT=$(grep -o "@foreach" "$FILE" | wc -l)

echo -e "\n\033[33m@if blocks: $IF_COUNT\033[0m"
echo -e "\033[33m@foreach blocks: $FOREACH_COUNT\033[0m"

# Find lines with potential issues
echo -e "\n\033[36mChecking for common issues...\033[0m"

# Check for lines where EstimationId is used before @code block
CODE_LINE=$(grep -n "^@code {" "$FILE" | cut -d: -f1)
if [ ! -z "$CODE_LINE" ]; then
    EST_BEFORE_CODE=$(head -n "$CODE_LINE" "$FILE" | grep -n "EstimationId" | head -5)
    if [ ! -z "$EST_BEFORE_CODE" ]; then
        echo -e "\033[31mEstimationId used before @code block:\033[0m"
        echo "$EST_BEFORE_CODE"
    fi
fi

echo -e "\n\033[36mValidation complete.\033[0m"