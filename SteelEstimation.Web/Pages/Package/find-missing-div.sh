#!/bin/bash

FILE="PackageWorksheets.razor"
CODE_LINE=$(grep -n "^@code {" "$FILE" | cut -d: -f1)

echo "Analyzing div structure up to @code block (line $CODE_LINE)..."

# Track div balance line by line
balance=0
line_num=0

while IFS= read -r line; do
    line_num=$((line_num + 1))
    
    # Stop at @code block
    if [ $line_num -eq $CODE_LINE ]; then
        break
    fi
    
    # Count opening divs in this line
    opens=$(echo "$line" | grep -o "<div" | wc -l)
    # Count closing divs in this line
    closes=$(echo "$line" | grep -o "</div>" | wc -l)
    
    if [ $opens -gt 0 ] || [ $closes -gt 0 ]; then
        balance=$((balance + opens - closes))
        
        # Show lines where balance goes negative or very high
        if [ $balance -lt 0 ] || [ $balance -gt 10 ]; then
            echo "Line $line_num (balance: $balance): $line" | head -c 120
            echo "..."
        fi
    fi
done < "$FILE"

echo -e "\nFinal balance before @code block: $balance"

# Find the last few div tags before @code
echo -e "\nLast 10 div-related lines before @code block:"
head -n $((CODE_LINE - 1)) "$FILE" | grep -n "div" | tail -10