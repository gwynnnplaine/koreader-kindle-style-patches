#!/bin/bash

set -e

SRC_DIR="src"
OUTPUT="2-kindle-time-left.lua"

echo "Building combined patch: $OUTPUT..."

echo "-- 2-kindle-time-left.lua" > $OUTPUT
echo "-- Combined Kindle-style footer and centered clock header for KOReader" >> $OUTPUT
echo "-- Auto-generated from src/ directory - DO NOT EDIT DIRECTLY" >> $OUTPUT
echo "" >> $OUTPUT

FILES=(
    "$SRC_DIR/helpers.lua"
    "$SRC_DIR/footer.lua"
    "$SRC_DIR/main.lua"
    "$SRC_DIR/header.lua"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Adding $(basename $file)..."

        case "$(basename $file)" in
            helpers.lua)
                echo "" >> $OUTPUT
                echo "-- ============ FOOTER SECTION ============" >> $OUTPUT
                echo "" >> $OUTPUT
                ;;
            header.lua)
                echo "" >> $OUTPUT
                echo "-- ============ HEADER SECTION ============" >> $OUTPUT
                echo "" >> $OUTPUT
                ;;
        esac

        echo "" >> $OUTPUT
        echo "-- === $(basename $file) ===" >> $OUTPUT
        echo "" >> $OUTPUT

        case "$(basename $file)" in
            helpers.lua)
                grep -v '^return helpers' "$file" >> $OUTPUT
                ;;
            footer.lua|main.lua)
                grep -v '^local helpers = require' "$file" >> $OUTPUT
                ;;
            *)
                cat "$file" >> $OUTPUT
                ;;
        esac
    else
        echo "Warning: $file not found"
    fi
done

echo ""
echo "Build complete: $OUTPUT"
echo "File size: $(wc -c < $OUTPUT) bytes"
