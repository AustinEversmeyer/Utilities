#!/bin/bash

# Default values
INCLUDE_TEST=false
ONLY_CMAKE=false
TARGET_DIR="."
EXTRA_IGNORE=()

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -t)
      INCLUDE_TEST=true
      shift
      ;;
    -d)
      if [[ -n "$2" ]]; then
        TARGET_DIR="$2"
        shift 2
      else
        echo "Error: -d requires a directory argument"
        exit 1
      fi
      ;;
    -c)
      ONLY_CMAKE=true
      shift
      ;;
    *)
      EXTRA_IGNORE+=("$1")
      shift
      ;;
  esac
done

# Change directory if TARGET_DIR is specified and exists
if [ "$TARGET_DIR" != "." ]; then
  if [ -d "$TARGET_DIR" ]; then
    cd "$TARGET_DIR" || { echo "Failed to change directory to $TARGET_DIR"; exit 1; }
  else
    echo "Directory '$TARGET_DIR' does not exist."
    exit 1
  fi
fi

# Set default ignored folders
IGNORE_FOLDERS=("build" "install" "cmake" "deps" ".vscode" "tests" ".git" ".venv_poetry" ".venv" ".cache_poetry" ".cache_pip" "__pycache__" ".cache")

# Append extra ignore folders from command line
IGNORE_FOLDERS+=("${EXTRA_IGNORE[@]}")

# If -t was passed, remove any patterns that match tests; otherwise, add a pattern to ignore tests
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
unset 'PRUNE_PATTERNS[${#PRUNE_PATTERNS[@]}-1]'

# Set output file based on mode
if [ "$ONLY_CMAKE" = true ]; then
  OUTPUT_FILE="cmake_files_structure.txt"
else
  OUTPUT_FILE="prompt_script.txt"
fi

{
  if [ "$ONLY_CMAKE" = true ]; then
    echo "CMake Folder Structure:"
    echo "======================="
  else
    echo "Project Folder Structure:"
    echo "========================"
  fi

  # FOLDER TREE: Skip ignored folders and print directories
  find . \( \( "${PRUNE_PATTERNS[@]}" \) -prune \) -o \( -type d -print \) \
    | sed -e 's|[^/]*/|  |g'

  echo

  if [ "$ONLY_CMAKE" = true ]; then
    echo "CMake Files with Contents:"
    echo "=========================="
    find . \( \( "${PRUNE_PATTERNS[@]}" \) -prune \) -o \
           \( -type f \( -name "CMakeLists.txt" -o -name "*.cmake" \) -print \) \
      | while read -r file; do
          if [ -f "$file" ]; then
            echo
            echo "==== $file ===="
            echo
            cat "$file"
          fi
        done
  else
    echo "Files with Contents:"
    echo "===================="
    find . \( \( "${PRUNE_PATTERNS[@]}" \) -prune \) -o \
           \( -type f \
              \( -name "*.py" \
              -o -name "*.h" \
              -o -name "*.hpp" \
              -o -name "*.c" \
              -o -name "*.cpp" \
              -o -name "*.yaml" \
              -o -name "*.yml" \
              -o -name "*.json" \
              -o -name "*.toml" \
              -o -name "Dockerfile*" \
              -o -name "*.sh" \
              -o -name "*.go" \
              -o -name "Makefile" \
              -o -name "*.mk" \
              -o -name "*.env" \
              -o -name "*.bat" \) -print \) \
      | while read -r file; do
          if [ -f "$file" ]; then
            echo
            echo "==== $file ===="
            echo
            cat "$file"
          fi
        done
  fi
} > "$OUTPUT_FILE"

echo "Structure and file contents written to $OUTPUT_FILE"