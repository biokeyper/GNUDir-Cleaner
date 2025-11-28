#!/bin/bash
export PATH="$(pwd)/tests/mock_bin:$PATH"

# Setup
TEST_DIR="test_split_target_env"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
touch "$TEST_DIR/target.pdf"
touch "$TEST_DIR/other.pdf"

# Run gnudir.sh with targeting (case-sensitive check)
echo "Running gnudir.sh with --split-target target.pdf..."
./gnudir.sh --recurse --split-pdf-pages 5 --split-target "target.pdf" "$TEST_DIR"

# Verify match
echo "Checking results for match..."
if [ -f "$TEST_DIR/doc/target-split-01.pdf" ]; then
    echo "SUCCESS: target.pdf was split."
else
    echo "FAILURE: target.pdf was NOT split."
    ls -R "$TEST_DIR"
    exit 1
fi

# Verify mismatch (should not split)
# We need to reset or use a different file.
touch "$TEST_DIR/CaseTest.pdf"
echo "Running gnudir.sh with --split-target casetest.pdf (should fail match)..."
./gnudir.sh --recurse --split-pdf-pages 5 --split-target "casetest.pdf" "$TEST_DIR"

if [ -f "$TEST_DIR/doc/CaseTest-split-01.pdf" ]; then
    echo "FAILURE: CaseTest.pdf was split despite case mismatch."
    exit 1
else
    echo "SUCCESS: CaseTest.pdf was NOT split (case mismatch respected)."
fi

if [ -f "$TEST_DIR/doc/other-split-01.pdf" ]; then
    echo "FAILURE: other.pdf was split (should have been ignored)."
    exit 1
else
    echo "SUCCESS: other.pdf was NOT split."
fi

echo "Test Passed."
