#!/bin/bash

# === CONFIGURATION ===
BASE_DIR="00_base_code"
FINAL_DIR="99_final_code"
EDIT_DIRS=("01_Reported" "02_Run" "03_Reliable" "04_Reproducible" "05_Organization_Structure" "06_Other_considerations")
FILES_TO_MERGE=("2_scripts/1a_CatFoodExp2021_analysis_fitness.R")

# === SETUP ===
mkdir -p "$FINAL_DIR"

# === MAIN LOOP ===
for FILE in "${FILES_TO_MERGE[@]}"; do
    echo "=== Merging file: $FILE ==="

    BASE_FILE="$BASE_DIR/$FILE"

    # Determine last merged step based on final_code contents
    LAST_FINAL=$(ls "$FINAL_DIR"/final_after_*.R 2>/dev/null | sort | tail -n 1)
    if [ -z "$LAST_FINAL" ]; then
        CURRENT_BASE="$BASE_FILE"
        echo "Starting from base file: $BASE_FILE"
    else
        CURRENT_BASE="$LAST_FINAL"
        echo "Resuming from latest merged file: $CURRENT_BASE"
    fi

# Determine which directories have already been merged
LAST_DONE=""
if [ -n "$LAST_FINAL" ]; then
    # Extract folder name from the pattern final_after_<foldername>.R
    LAST_DONE=$(basename "$LAST_FINAL" | sed -E 's/final_after_(.*)\.R/\1/')
    echo "Last completed merge: $LAST_DONE"
fi

# If no previous merge found, start from the beginning
if [ -z "$LAST_DONE" ]; then
    SKIP=false
else
    SKIP=true
fi

for EDIT_DIR in "${EDIT_DIRS[@]}"; do
    if [ "$SKIP" = true ]; then
        if [ "$EDIT_DIR" = "$LAST_DONE" ]; then
            SKIP=false
            continue  # Skip this one, start merging from the next folder
        fi
        continue
    fi


        EDIT_FILE="$EDIT_DIR/$FILE"
        if [ ! -f "$EDIT_FILE" ]; then
            echo "No file found in $EDIT_DIR — skipping."
            continue
        fi

        # Create next output filename
        STAGE_FILE="$FINAL_DIR/final_after_${EDIT_DIR}.R"
        mkdir -p "$(dirname "$STAGE_FILE")"

        # Copy the current base to start new merge
        cp "$CURRENT_BASE" "$STAGE_FILE"

        echo "Merging changes from $EDIT_FILE into $STAGE_FILE"
        git merge-file "$STAGE_FILE" "$BASE_FILE" "$EDIT_FILE"

        echo "Resolve any conflicts in $STAGE_FILE, then press Enter to continue..."
        read

        echo "Merge with $EDIT_DIR completed. Output: $STAGE_FILE"
        CURRENT_BASE="$STAGE_FILE"
    done

    echo "Finished merging $FILE"
done

echo "All merges completed. Final results in $FINAL_DIR"
