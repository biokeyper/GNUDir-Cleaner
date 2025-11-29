#!/bin/bash
export PATH="$(pwd)/tests/mock_bin:$PATH"

# Setup
TEST_DIR="test_standalone_env"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
touch "$TEST_DIR/book.pdf"
touch "$TEST_DIR/image.jpg"
touch "$TEST_DIR/video.mp4"
touch "$TEST_DIR/random.txt"

echo "=== Test: PDF splitting should NOT organize other files ==="
output=$(./gnudir.sh --split-pdf-pages 5 --split-target "$TEST_DIR/book.pdf" 2>&1)

# Check that PDF was split
if [ -f "$TEST_DIR/book-split-01.pdf" ]; then
    echo "✓ SUCCESS: PDF was split"
else
    echo "✗ FAILURE: PDF was NOT split"
    echo "$output"
    exit 1
fi

# Check that organization was skipped
if echo "$output" | grep -q "Skipping file organization"; then
    echo "✓ SUCCESS: File organization was skipped"
else
    echo "✗ FAILURE: Organization message not found"
    echo "$output"
    exit 1
fi

# Check that other files were NOT moved
if [ -f "$TEST_DIR/image.jpg" ] && [ -f "$TEST_DIR/video.mp4" ] && [ -f "$TEST_DIR/random.txt" ]; then
    echo "✓ SUCCESS: Other files were NOT organized"
else
    echo "✗ FAILURE: Some files were moved"
    ls -R "$TEST_DIR"
    exit 1
fi

# Check that img/vid/nany directories were NOT created
if [ ! -d "$TEST_DIR/img" ] && [ ! -d "$TEST_DIR/vid" ] && [ ! -d "$TEST_DIR/nany" ]; then
    echo "✓ SUCCESS: Category directories were NOT created"
else
    echo "✗ FAILURE: Category directories were created"
    ls -R "$TEST_DIR"
    exit 1
fi

echo ""
echo "All tests passed!"
