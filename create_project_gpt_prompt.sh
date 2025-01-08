#!/bin/bash

# Set default ignored folders
IGNORE_FOLDERS=("build" "install" "cmake" "deps" ".vscode" "tests" ".git" ".venv_poetry" ".venv" ".cache_poetry" ".cache_pip")

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
OUTPUT_FILE="prompt_script.txt"

# Write the project structure with files to the output file
{
  echo "Project Folder Structure:";
  echo "========================";

  # Print the folder tree ignoring specified folders
  find . \( "${IGNORE_ARGS[@]}" -type d -print \) | sed -e 's|[^/]*/|  |g';

  # List files (header, source, yaml, json) and their contents, including the current directory
  echo;
  echo "Files with Contents:";
  echo "====================";

  find . \( "${IGNORE_ARGS[@]}" -type f \( -name "*.py" -o -name "*.h" -o -name "*.hpp" -o -name "*.c" -o -name "*.cpp" -o -name "*.yaml" -o -name "*.yml" -o -name "*.json" \) \) -print | while read -r file; do
    if [ -f "$file" ]; then
      echo -e "\n==== $file ====";
      cat "$file";
    fi
  done
} > "$OUTPUT_FILE"

# Notify user of completion
echo "Project structure and file contents written to $OUTPUT_FILE"
