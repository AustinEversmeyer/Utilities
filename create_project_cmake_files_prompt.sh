#!/bin/bash

# Set default ignored folders
IGNORE_FOLDERS=("build" "install" "cmake" "deps" ".vscode" "tests" ".git" ".venv_poetry" ".venv" ".cache_poetry" ".cache_pip" "__pycache__" ".cache")

# Flag to include "test" files and folders
INCLUDE_TEST=false

# Parse command line arguments
for arg in "$@"; do
  if [ "$arg" == "-t" ]; then
    INCLUDE_TEST=true
  else
    IGNORE_FOLDERS+=("$arg")
  fi
done

# If -t was passed, remove any patterns that match tests
if [ "$INCLUDE_TEST" = true ]; then
  for i in "${!IGNORE_FOLDERS[@]}"; do
    if [[ "${IGNORE_FOLDERS[$i]}" == *"test"* ]]; then
      unset 'IGNORE_FOLDERS[i]'
    fi
  done
else
  IGNORE_FOLDERS+=("*test*")
fi

# ------------------------------------------------------------------------------
# Build a single "prune" expression from IGNORE_FOLDERS
# ------------------------------------------------------------------------------
PRUNE_PATTERNS=()
for folder in "${IGNORE_FOLDERS[@]}"; do
  PRUNE_PATTERNS+=( -path "*/$folder" -o )
done

# Remove the trailing "-o"
unset 'PRUNE_PATTERNS[${#PRUNE_PATTERNS[@]}-1]'

# Output file
OUTPUT_FILE="cmake_files_structure.txt"

# Write the project structure with CMake files to the output file
{
  echo "CMake Folder Structure:"
  echo "======================="

  # ----------------------------------------------------------------------------
  # FOLDER TREE
  #
  # Explanation:
  #   find . \
  #     ( (PRUNE_PATTERNS) -prune )  -o  ( -type d -print )
  #
  # This means:
  #   1. If the path matches any ignored folder, prune (skip) it.
  #   2. Otherwise (-o), if it's a directory, print its path.
  # ----------------------------------------------------------------------------
  find . \( \( "${PRUNE_PATTERNS[@]}" \) -prune \) -o \( -type d -print \) \
    | sed -e 's|[^/]*/|  |g'

  echo
  echo "CMake Files with Contents:"
  echo "=========================="

  # ----------------------------------------------------------------------------
  # FILES + CONTENT
  #
  # Similar logic, except we look for -type f with specific -name patterns.
  # ----------------------------------------------------------------------------
  find . \( \( "${PRUNE_PATTERNS[@]}" \) -prune \) -o \
         \( -type f \
            \( -name "CMakeLists.txt" \
            -o -name "*.cmake" \) \
         -print \) \
    | while read -r file; do

        if [ -f "$file" ]; then
          echo
          echo "==== $file ===="
          echo
          cat "$file"
        fi
      done

} > "$OUTPUT_FILE"

# Notify user of completion
echo "CMake files structure and file contents written to $OUTPUT_FILE"
