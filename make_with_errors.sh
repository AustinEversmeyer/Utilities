#!/bin/bash

# File: make_with_errors.sh
# Make sure to give executable permissions to this script using chmod +x make_with_errors.sh

# Run make with all output captured
make -j 20 "$@" 2>&1 | tee make_output.txt

# Display non-error output
grep -v "^make.*: \*\*\*.*Stop." make_output.txt

# Display errors, assuming errors include 'error:'
echo "Compilation Errors:"
grep "^make.*: \*\*\*.*Stop." make_output.txt
