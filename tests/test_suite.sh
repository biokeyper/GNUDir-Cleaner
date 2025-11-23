#!/usr/bin/env bash
# Comprehensive test script for gnudir
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
TEST_TMP="$(mktemp -d /tmp/gnudir_test_suite.XXXX)"
trap 'rm -rf "$TEST_TMP"' EXIT

echo "Creating test tree in $TEST_TMP"
"$ROOT/tests/make_test_tree.sh" "$TEST_TMP"

echo "Running non-recursive dry-run"
"$ROOT/gnudir.sh" --dry-run --verbose "$TEST_TMP"

echo "Running recursive organize"
"$ROOT/gnudir.sh" --recurse "$TEST_TMP"

echo "Verifying categories exist"
for d in img vid doc arc audio apps; do
  if [ ! -d "$TEST_TMP/$d" ]; then
    echo "Missing expected directory: $d" >&2
    exit 2
  fi
done

# `nany` is optional — may be absent when there are no leftovers
if [ -d "$TEST_TMP/nany" ]; then
  echo "Optional directory present: nany"
fi

echo "Checking that files were moved (non-empty categories)"
non_empty=0
for d in img vid doc arc apps; do
  if [ "$(find "$TEST_TMP/$d" -maxdepth 1 -type f | wc -l)" -gt 0 ]; then
    non_empty=$((non_empty+1))
  fi
done

if [ "$non_empty" -lt 2 ]; then
  echo "Not enough categories populated" >&2
  exit 3
fi

echo "All tests passed in $TEST_TMP"
exit 0
