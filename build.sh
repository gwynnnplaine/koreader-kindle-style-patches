#!/bin/bash
# Build script for 2-kindle-time-left.lua
# Concatenates source files in order

set -e

SRC_DIR="src"
OUTPUT="2-kindle-time-left.lua"

# Define file order explicitly
FILES=(
    "$SRC_DIR/config.lua"
    "$SRC_DIR/helpers.lua"
    # "$SRC_DIR/presets.lua"
    "$SRC_DIR/footer.lua"
    # "$SRC_DIR/main.lua",

)

echo "Building $OUTPUT..."

# Add header
echo "-- 2-kindle-time-left.lua" > $OUTPUT
echo "-- Kindle-style footer patch for KOReader" >> $OUTPUT
echo "-- Auto-generated from src/ directory - DO NOT EDIT DIRECTLY" >> $OUTPUT
echo "-- Edit files in src/ and run ./build.sh instead" >> $OUTPUT
echo "" >> $OUTPUT

# Concatenate files in defined order
# Concatenate files in defined order
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Adding $(basename $file)..."
        echo "" >> $OUTPUT
        echo "-- === $(basename $file) ===" >> $OUTPUT
        echo "" >> $OUTPUT

        case "$(basename $file)" in
            helpers.lua|config.lua)
                # Keep the module definition, strip 'return' statement
                grep -v '^return helpers' "$file" | grep -v '^return CONFIG' >> $OUTPUT
                ;;
            footer.lua|main.lua|presets.lua)
                # Strip local module imports (all variations)
                grep -v '^local helpers = require' "$file" | \
                grep -v '^local CONFIG = require' >> $OUTPUT
                ;;
            *)
                cat "$file" >> $OUTPUT
                ;;
        esac
    else
        echo "Warning: $file not found"
    fi
done

echo "Build complete: $OUTPUT"
echo "File size: $(wc -c < $OUTPUT) bytes"
