#!/bin/bash

INCLUDE_TEST=false
ONLY_CMAKE=false
MATCH_EXPRESSION=""
TARGET_DIR="."
EXTRA_IGNORE=()

usage() {
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  -h              Display this help message and exit."
  echo "  -t              Include test folders (default excludes folders with 'test')."
  echo "  -d <directory>  Specify target directory (default is current directory)."
  echo "  -c              Only process CMake files (CMakeLists.txt or *.cmake)."
  echo "  -m <pattern>    Specify a filename pattern to match files."
  echo "  Extra arguments are added to the ignore list."
  echo
  echo "This script outputs a structured file list and file contents sorted by modification time,"
  echo "with the oldest files at the top and the most recent ones at the bottom."
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -h)
      usage
      exit 0
      ;;
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
    -m)
      if [[ -n "$2" ]]; then
        MATCH_EXPRESSION="$2"
        shift 2
      else
        echo "Error: -m requires a pattern argument"
        exit 1
      fi
      ;;
    *)
      EXTRA_IGNORE+=("$1")
      shift
      ;;
  esac
done

if [ "$TARGET_DIR" != "." ]; then
  if [ -d "$TARGET_DIR" ]; then
    cd "$TARGET_DIR" || { echo "Failed to change directory to $TARGET_DIR"; exit 1; }
  else
    echo "Directory '$TARGET_DIR' does not exist."
    exit 1
  fi
fi

IGNORE_FOLDERS=("build" "install" "cmake" "deps" ".vscode" "tests" ".git" ".venv_poetry" ".venv" ".cache_poetry" ".cache_pip" "__pycache__" ".cache")
IGNORE_FOLDERS+=("${EXTRA_IGNORE[@]}")

if [ "$INCLUDE_TEST" = true ]; then
  for i in "${!IGNORE_FOLDERS[@]}"; do
    if [[ "${IGNORE_FOLDERS[$i]}" == *"test"* ]]; then
      unset 'IGNORE_FOLDERS[i]'
    fi
  done
else
  IGNORE_FOLDERS+=("*test*")
fi

PRUNE_PATTERNS=()
for folder in "${IGNORE_FOLDERS[@]}"; do
  PRUNE_PATTERNS+=( -path "*/$folder" -o )
done
unset 'PRUNE_PATTERNS[${#PRUNE_PATTERNS[@]}-1]'

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

  find . \( \( "${PRUNE_PATTERNS[@]}" \) -prune \) -o \( -type d -print \) \
    | sed -e 's|[^/]*/|  |g'

  echo
  echo "Files with Contents:"
  echo "===================="

  if [ -n "$MATCH_EXPRESSION" ]; then
    find . \( \( "${PRUNE_PATTERNS[@]}" \) -prune \) -o \
      \( -type f -iname "$MATCH_EXPRESSION" -printf '%T@ %p\n' \) \
      | sort -n | cut -d' ' -f2- | while read -r file; do
          if [ -f "$file" ]; then
            echo
            echo "==== $file ===="
            echo
            cat "$file"
          fi
        done
  else
    if [ "$ONLY_CMAKE" = true ]; then
      find . \( \( "${PRUNE_PATTERNS[@]}" \) -prune \) -o \
        \( -type f \( -name "CMakeLists.txt" -o -name "*.cmake" \) -printf '%T@ %p\n' \) \
        | sort -n | cut -d' ' -f2- | while read -r file; do
            if [ -f "$file" ]; then
              echo
              echo "==== $file ===="
              echo
              cat "$file"
            fi
          done
    else
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
             -o -name "*.bat" \) -printf '%T@ %p\n' \) \
        | sort -n | cut -d' ' -f2- | while read -r file; do
            if [ -f "$file" ]; then
              echo
              echo "==== $file ===="
              echo
              cat "$file"
            fi
          done
    fi
  fi

  echo -e "\n\n----\n"
} > "$OUTPUT_FILE"

echo "Structure and file contents written to $OUTPUT_FILE"