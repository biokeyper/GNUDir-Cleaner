#!/bin/bash
export PATH="$(pwd)/tests/mock_bin:$PATH"

# Setup
TEST_DIR="test_folder_organization"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
touch "$TEST_DIR/mybook.pdf"

echo "=== Test: Folder organization structure ==="
./gnudir.sh --split-pdf-pages 5 --split-target "$TEST_DIR/mybook.pdf"

# Check that document folder was created
if [ -d "$TEST_DIR/mybook" ]; then
    echo "✓ SUCCESS: Document folder created"
else
    echo "✗ FAILURE: Document folder not created"
    ls -R "$TEST_DIR"
    exit 1
fi

# Check that split files are in document folder
if [ -f "$TEST_DIR/mybook/mybook-split-01.pdf" ]; then
    echo "✓ SUCCESS: Split files in document folder"
else
    echo "✗ FAILURE: Split files not in document folder"
    ls -R "$TEST_DIR"
    exit 1
fi

# Check that backup is a subdirectory of document folder
if [ -d "$TEST_DIR/mybook/backup" ]; then
    echo "✓ SUCCESS: Backup is subdirectory of document folder"
else
    echo "✗ FAILURE: Backup not in document folder"
    ls -R "$TEST_DIR"
    exit 1
fi

# Check that original is in backup
if [ -f "$TEST_DIR/mybook/backup/mybook.pdf" ]; then
    echo "✓ SUCCESS: Original in backup subfolder"
else
    echo "✗ FAILURE: Original not in backup"
    ls -R "$TEST_DIR"
    exit 1
fi

# Check output message
output=$(./gnudir.sh --split-pdf-pages 5 --split-target "$TEST_DIR/another.pdf" 2>&1)
if echo "$output" | grep -q "Output directory:"; then
    echo "✓ SUCCESS: Output directory message shown"
else
    echo "✗ FAILURE: No output directory message"
    echo "$output"
fi

echo ""
echo "All tests passed!"
