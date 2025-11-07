#!/usr/bin/env bash

INCLUDE_TEST=false
ONLY_CMAKE=false
ALL_FILES=false
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
  echo "  -i <pattern>    Add a filename pattern to ignore list."
  echo "  -a              Include all files (ignore all patterns except 'deps' folders)."
  echo "  Extra arguments are added to the ignore list."
  echo
  echo "This script outputs a structured file list and file contents sorted by modification time,"
  echo "with the oldest files at the top and the most recent ones at the bottom."
}

get_mtime_line() {
  file="$1"
  if [ "$(uname)" = "Darwin" ]; then
    printf "%s %s\n" "$(stat -f "%m" "$file")" "$file"
  else
    printf "%s %s\n" "$(stat -c "%Y" "$file")" "$file"
  fi
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -h) usage; exit 0 ;;
    -t) INCLUDE_TEST=true; shift ;;
    -d)
      if [[ -n "$2" ]]; then
        TARGET_DIR="$2"; shift 2
      else
        echo "Error: -d requires a directory argument"; exit 1
      fi ;;
    -c) ONLY_CMAKE=true; shift ;;
    -m)
      if [[ -n "$2" ]]; then
        MATCH_EXPRESSION="$2"; shift 2
      else
        echo "Error: -m requires a pattern argument"; exit 1
      fi ;;
    -i)
      if [[ -n "$2" ]]; then
        EXTRA_IGNORE+=("$2"); shift 2
      else
        echo "Error: -i requires a pattern argument"; exit 1
      fi ;;
    -a) ALL_FILES=true; shift ;;
    *) EXTRA_IGNORE+=("$1"); shift ;;
  esac
done

if [ "$TARGET_DIR" != "." ]; then
  if [ -d "$TARGET_DIR" ]; then
    cd "$TARGET_DIR" || { echo "Failed to change directory to $TARGET_DIR"; exit 1; }
  else
    echo "Directory '$TARGET_DIR' does not exist."; exit 1
  fi
fi

# Always ignore .git
BASE_IGNORES=(".git")

if [ "$ALL_FILES" = true ]; then
  IGNORE_FOLDERS=("deps" "${BASE_IGNORES[@]}")
else
  IGNORE_FOLDERS=("build" "install" "cmake" "deps" ".vscode" "tests" ".venv_poetry" ".venv" ".cache_poetry" ".cache_pip" "__pycache__" ".cache" "${BASE_IGNORES[@]}")
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

FILE_LIST=$(mktemp)

collect_files() {
  while IFS= read -r file; do
    [ -f "$file" ] && get_mtime_line "$file"
  done
}

if [ -n "$MATCH_EXPRESSION" ]; then
  find . \( \( "${PRUNE_PATTERNS[@]}" \) -prune \) -o \
    -type f -iname "$MATCH_EXPRESSION" -print \
    | collect_files | sort -n | cut -d' ' -f2- > "$FILE_LIST"
else
  if [ "$ONLY_CMAKE" = true ]; then
    find . \( \( "${PRUNE_PATTERNS[@]}" \) -prune \) -o \
      -type f \( -iname "CMakeLists.txt" -o -iname "*.cmake" \) -print \
      | collect_files | sort -n | cut -d' ' -f2- > "$FILE_LIST"
  elif [ "$ALL_FILES" = true ]; then
    find . \( \( "${PRUNE_PATTERNS[@]}" \) -prune \) -o \
      -type f -print \
      | collect_files | sort -n | cut -d' ' -f2- > "$FILE_LIST"
  else
    find . \( \( "${PRUNE_PATTERNS[@]}" \) -prune \) -o \
      -type f \( -iname "*.py" -o -iname "*.h" -o -iname "*.hpp" -o -iname "*.c" \
                -o -iname "*.cpp" -o -iname "*.yaml" -o -iname "*.yml" \
                -o -iname "*.json" -o -iname "*.toml" -o -iname "Dockerfile*" \
                -o -iname "*.sh" -o -iname "*.go" -o -iname "Makefile" \
                -o -iname "*.mk" -o -iname "*.env" -o -iname "*.bat" \) -print \
      | collect_files | sort -n | cut -d' ' -f2- > "$FILE_LIST"
  fi
fi

TEMP_DIRS=$(mktemp)
while IFS= read -r file; do
  dir=$(dirname "$file")
  while true; do
    echo "$dir" >> "$TEMP_DIRS"
    [ "$dir" = "." ] && break
    dir=$(dirname "$dir")
  done
done < "$FILE_LIST"

{
  if [ "$ONLY_CMAKE" = true ]; then
    echo "CMake Folder Structure:"
    echo "======================="
  else
    echo "Project Folder Structure:"
    echo "========================"
  fi

  sort -u "$TEMP_DIRS" | sort | sed -e 's|^\./||' -e 's|[^/]*/|  |g'

  echo
  echo "Files with Contents:"
  echo "===================="

  while IFS= read -r file; do
    if [ -f "$file" ]; then
      echo
      echo "==== $file ===="
      echo
      cat "$file"
    fi
  done < "$FILE_LIST"

  printf "\n\n---\n"
} > "$OUTPUT_FILE"

rm "$FILE_LIST" "$TEMP_DIRS"

echo "Structure and file contents written to $OUTPUT_FILE"
