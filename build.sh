#!/bin/bash

set -e

SRC_DIR="src"

build_combined() {
    local OUTPUT="2-kindle-time-left.lua"
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
    echo "Built: $OUTPUT ($(wc -c < $OUTPUT) bytes)"
}

build_footer_only() {
    local OUTPUT="2-kindle-time-left-no-header.lua"
    echo "Building footer-only patch: $OUTPUT..."

    echo "-- 2-kindle-time-left-no-header.lua" > $OUTPUT
    echo "-- Kindle-style footer patch (without header) for KOReader" >> $OUTPUT
    echo "-- Auto-generated from src/ directory - DO NOT EDIT DIRECTLY" >> $OUTPUT
    echo "" >> $OUTPUT

    FILES=(
        "$SRC_DIR/helpers.lua"
        "$SRC_DIR/footer.lua"
        "$SRC_DIR/main.lua"
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
            esac
        else
            echo "Warning: $file not found"
        fi
    done

    echo ""
    echo "Built: $OUTPUT ($(wc -c < $OUTPUT) bytes)"
}

# Build both versions
build_combined
build_footer_only

echo ""
echo "Build complete!"
