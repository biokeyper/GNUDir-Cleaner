#!/bin/bash
export PATH="$(pwd)/tests/mock_bin:$PATH"

# Setup
TEST_DIR="test_ux_improvements"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
touch "$TEST_DIR/test.pdf"

echo "=== Test 1: Detailed logging for direct path ===" 
output=$(./gnudir.sh --split-pdf-pages 5 --split-target "$TEST_DIR/test.pdf" 2>&1)

if echo "$output" | grep -q "Splitting completed:"; then
    echo "✓ SUCCESS: Detailed logging header found"
else
    echo "✗ FAILURE: No detailed logging header"
    echo "$output"
    exit 1
fi

if echo "$output" | grep -q "✓.*test-split-.*\.pdf.*pages"; then
    echo "✓ SUCCESS: Split file details shown"
else
    echo "✗ FAILURE: Split file details not shown"
    echo "$output"
    exit 1
fi

if echo "$output" | grep -q "Total:.*files"; then
    echo "✓ SUCCESS: Total summary shown"
else
    echo "✗ FAILURE: Total summary not shown"
    echo "$output"
    exit 1
fi

echo ""
echo "=== Test 2: Fallback search ===" 
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
touch "$TEST_DIR/fallback.pdf"

output=$(./gnudir.sh --split-pdf-pages 5 --split-target "fallback.pdf" "$TEST_DIR" 2>&1)

if echo "$output" | grep -q "File not found in doc/"; then
    echo "✓ SUCCESS: doc/ search attempted first"
else
    echo "✗ FAILURE: No doc/ search message"
    echo "$output"
    exit 1
fi

if echo "$output" | grep -q "Searching in"; then
    echo "✓ SUCCESS: Fallback search message shown"
else
    echo "✗ FAILURE: No fallback search message"
    echo "$output"
    exit 1
fi

if echo "$output" | grep -q "Found:.*fallback.pdf"; then
    echo "✓ SUCCESS: File found in fallback"
else
    echo "✗ FAILURE: File not found in fallback"
    echo "$output"
    exit 1
fi

if [ -f "$TEST_DIR/fallback-split-01.pdf" ]; then
    echo "✓ SUCCESS: File was split after fallback"
else
    echo "✗ FAILURE: File was not split"
    ls -R "$TEST_DIR"
    exit 1
fi

echo ""
echo "All tests passed!"
