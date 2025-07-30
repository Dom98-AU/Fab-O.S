#!/bin/bash

FILE="PackageWorksheets.razor"

# Find the @code block line
CODE_LINE=$(grep -n "^@code {" "$FILE" | cut -d: -f1)

# Analyze div balance up to @code block
echo "Analyzing div balance up to @code block (line $CODE_LINE)..."

# Get content up to @code block
head -n $((CODE_LINE - 1)) "$FILE" > temp_razor.txt

# Count divs in the content before @code
OPEN_DIVS=$(grep -o "<div" temp_razor.txt | wc -l)
CLOSE_DIVS=$(grep -o "</div>" temp_razor.txt | wc -l)

echo "Before @code block:"
echo "  Opening divs: $OPEN_DIVS"
echo "  Closing divs: $CLOSE_DIVS"
echo "  Difference: $((OPEN_DIVS - CLOSE_DIVS))"

# Find unbalanced sections
echo -e "\nLooking for sections with potential imbalance..."

# Check specific line ranges
for start in 1 200 400 600 800 1000 1200 1400; do
    end=$((start + 199))
    if [ $end -gt $CODE_LINE ]; then
        end=$((CODE_LINE - 1))
    fi
    
    SECTION=$(sed -n "${start},${end}p" "$FILE")
    OPEN=$(echo "$SECTION" | grep -o "<div" | wc -l)
    CLOSE=$(echo "$SECTION" | grep -o "</div>" | wc -l)
    
    if [ $OPEN -ne $CLOSE ]; then
        echo "Lines $start-$end: $OPEN opening, $CLOSE closing (diff: $((OPEN - CLOSE)))"
    fi
done

rm -f temp_razor.txt