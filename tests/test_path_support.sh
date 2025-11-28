#!/bin/bash
export PATH="$(pwd)/tests/mock_bin:$PATH"

# Setup
TEST_DIR="test_path_support_env"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR/subdir"
touch "$TEST_DIR/subdir/mybook.pdf"
touch "$TEST_DIR/notapdf.txt"

echo "=== Test 1: Direct path to PDF ==="
./gnudir.sh --split-pdf-pages 5 --split-target "$TEST_DIR/subdir/mybook.pdf"

if [ -f "$TEST_DIR/subdir/mybook-split-01.pdf" ]; then
    echo "✓ SUCCESS: PDF split with direct path"
else
    echo "✗ FAILURE: PDF not split with direct path"
    ls -R "$TEST_DIR"
    exit 1
fi

if [ -f "$TEST_DIR/subdir/backup/mybook.pdf" ]; then
    echo "✓ SUCCESS: Original moved to backup in same directory"
else
    echo "✗ FAILURE: Original not in backup"
    exit 1
fi

echo ""
echo "=== Test 2: Non-existent file ==="
output=$(./gnudir.sh --split-pdf-pages 5 --split-target "/nonexistent/file.pdf" 2>&1)
if echo "$output" | grep -q "File not found"; then
    echo "✓ SUCCESS: Non-existent file error handled"
else
    echo "✗ FAILURE: No proper error for non-existent file"
    echo "$output"
    exit 1
fi

echo ""
echo "=== Test 3: Non-PDF file ==="
output=$(./gnudir.sh --split-pdf-pages 5 --split-target "$TEST_DIR/notapdf.txt" 2>&1)
if echo "$output" | grep -q "not a PDF"; then
    echo "✓ SUCCESS: Non-PDF file error handled"
else
    echo "✗ FAILURE: No proper error for non-PDF file"
    echo "$output"
    exit 1
fi

echo ""
echo "All tests passed!"
