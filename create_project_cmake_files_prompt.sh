#!/bin/bash

# Set default ignored folders
IGNORE_FOLDERS=("build" "install" "deps" ".vscode" "tests" ".git")

# Collect additional ignored folders from command line input
for arg in "$@"; do
  IGNORE_FOLDERS+=("$arg")
done

# Convert ignored folders array to find command option
IGNORE_ARGS=()
for folder in "${IGNORE_FOLDERS[@]}"; do
  IGNORE_ARGS+=(-path "*/$folder" -prune -o)
done

# Output file
OUTPUT_FILE="cmake_files_structure.txt"

# Write the project structure with CMake files to the output file
{
  echo "CMake Folder Structure:";
  echo "=======================";

  # Print the folder tree ignoring specified folders
  find . \( "${IGNORE_ARGS[@]}" -type d -print \) | sed -e 's|[^/]*/|  |g';

  # List only CMake files (CMakeLists.txt and *.cmake) and their contents
  echo;
  echo "CMake Files with Contents:";
  echo "==========================";

  find . \( "${IGNORE_ARGS[@]}" -type f \( -name "CMakeLists.txt" -o -name "*.cmake" \) \) -print | while read -r file; do
    if [ -f "$file" ]; then
      echo -e "\n==== $file ====";
      cat "$file";
    fi
  done
} > "$OUTPUT_FILE"

# Notify user of completion
echo "CMake files structure and file contents written to $OUTPUT_FILE"
