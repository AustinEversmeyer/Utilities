#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Array to hold test summaries
declare -a test_summaries

# Find all test executables and loop through them
while IFS= read -r test_executable; do
    # Extract the directory path from the test executable path
    test_dir=$(dirname "$test_executable")
    
    # Change to the test directory
    cd "$test_dir" || exit
    
    # Run the test executable and capture the output
    echo "Running tests in $test_executable"
    output=$("./$(basename "$test_executable")")
    
    # Parse the summary line from the output
    summary_line=$(echo "$output" | grep -E 'test cases:|All tests passed')
    
    # Check if the summary line was found
    if [[ -z "$summary_line" ]]; then
        summary_line="No summary information found."
        color=$RED
    elif echo "$summary_line" | grep -q 'failed'; then
        color=$RED
        # Capture the details of failed tests
        failed_details=$(echo "$output" | awk '/FAILED:/{flag=1} /===============================================================================/{flag=0} flag')
        summary_line="${summary_line}\n${failed_details}"
    else
        color=$GREEN
    fi
    
    # Add the colored summary to the test_summaries array
    test_summaries+=("$test_executable: ${color}$summary_line${NC}")
    
    # Change back to the original directory
    cd - > /dev/null
done < <(find . -type f -executable -name "*tests")

# Print a summary of all test results
echo "--------------------------------"
echo "Test Summary:"
for summary in "${test_summaries[@]}"; do
    echo -e "$summary"
done
