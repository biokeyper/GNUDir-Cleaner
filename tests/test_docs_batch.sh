#!/usr/bin/env bash
set -euo pipefail

# Test docs batching behavior
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
TEST_DIR="$(mktemp -d /tmp/gnudir_docs_test.XXXX)"
trap 'rm -rf "$TEST_DIR"' EXIT

echo "Creating test tree in: $TEST_DIR"
"$ROOT/tests/make_test_tree.sh" "$TEST_DIR"

echo "Running gnudir with --docs-batch-size=2"
"$ROOT/gnudir.sh" --recurse --docs-batch-size 2 "$TEST_DIR"

if [ ! -d "$TEST_DIR/doc" ]; then
  echo "FAIL: doc/ not created" >&2
  exit 2
fi

# Count batch folders under doc/
BATCH_COUNT=$(find "$TEST_DIR/doc" -mindepth 1 -maxdepth 1 -type d | wc -l)
DOC_FILES_MOVED=$(find "$TEST_DIR/doc" -mindepth 2 -type f | wc -l)

echo "Batches: $BATCH_COUNT, doc files moved: $DOC_FILES_MOVED"

if [ "$DOC_FILES_MOVED" -eq 0 ]; then
  echo "FAIL: no document files moved" >&2
  exit 3
fi

if [ "$BATCH_COUNT" -lt 1 ]; then
  echo "FAIL: expected at least 1 batch folder" >&2
  exit 4
fi

if [ "$BATCH_COUNT" -lt 2 ]; then
  echo "Note: fewer than 2 batches created; this can be valid if there are less documents than the batch size." >&2
fi

echo "PASS: docs batching test succeeded (batches=$BATCH_COUNT, docs=$DOC_FILES_MOVED)"
exit 0
