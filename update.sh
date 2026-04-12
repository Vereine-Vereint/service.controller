#!/bin/bash
set -e

if [[ ! -L "$BASE_DIR/.github" ]]; then
  ln -s "$BASE_DIR/$CORE_DIR_NAME/.github" "$BASE_DIR/.github"
  echo "Symlinked $BASE_DIR/$CORE_DIR_NAME/.github to $BASE_DIR/.github"
fi
