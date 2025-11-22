#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
TESTDIR=$(bash "$ROOT/tests/make_test_tree.sh")
echo "Test tree at: $TESTDIR"

echo "Running non-recursive test"
bash "$ROOT/gnudir.sh" "$TESTDIR"
echo "Contents of img:"; ls -la "$TESTDIR/img" || true

echo "Recreate test tree and run recursive test"
rm -rf "$TESTDIR" || true
TESTDIR=$(bash "$ROOT/tests/make_test_tree.sh")
bash "$ROOT/gnudir.sh" "$TESTDIR" --recurse
echo "After recursive run:"; find "$TESTDIR" -maxdepth 3 -type f -print

echo "Check for duplicate handling (dup.txt)"
ls -la "$TESTDIR" | sed -n '1,200p'

echo "Check empty dirs (should be removed)"
find "$TESTDIR" -type d -empty -print | sed -n '1,200p' || true

echo "Cleaning up"
rm -rf "$TESTDIR"

echo "Tests finished"
