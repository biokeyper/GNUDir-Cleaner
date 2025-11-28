#!/bin/bash
export PATH="$(pwd)/tests/mock_bin:$PATH"

# Setup
TEST_DIR="test_pdf_split_env"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
touch "$TEST_DIR/test_doc.pdf"

# Run gnudir.sh
echo "Running gnudir.sh..."
./gnudir.sh --recurse --split-pdf-pages 5 "$TEST_DIR"

# Verify
echo "Checking results..."
if [ -f "$TEST_DIR/doc/test_doc-split-01.pdf" ]; then
    echo "SUCCESS: Split file 01 found."
else
    echo "FAILURE: Split file 01 not found."
    ls -R "$TEST_DIR"
    exit 1
fi

if [ -f "$TEST_DIR/doc/test_doc-split-02.pdf" ]; then
    echo "SUCCESS: Split file 02 found."
else
    echo "FAILURE: Split file 02 not found."
    exit 1
fi

if [ -f "$TEST_DIR/doc/backup/test_doc.pdf" ]; then
    echo "SUCCESS: Original file moved to backup/."
else
    echo "FAILURE: Original file not found in backup/."
    ls -R "$TEST_DIR/doc"
    exit 1
fi

echo "Test Passed."
