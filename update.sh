#!/bin/bash
set -e

# migrate: remove old .github symlink (replaced by .claude)
if [[ -L "$BASE_DIR/.github" ]]; then
  rm "$BASE_DIR/.github"
  echo "Removed obsolete .github symlink"
fi

if [[ ! -L "$BASE_DIR/.claude" ]]; then
  ln -s "$BASE_DIR/$CORE_DIR_NAME/.claude" "$BASE_DIR/.claude"
  echo "Symlinked $BASE_DIR/$CORE_DIR_NAME/.claude to $BASE_DIR/.claude"
fi

if [[ ! -e "$BASE_DIR/CLAUDE.md" ]]; then
  ln -s "$BASE_DIR/$CORE_DIR_NAME/CLAUDE.md" "$BASE_DIR/CLAUDE.md"
  echo "Symlinked $BASE_DIR/$CORE_DIR_NAME/CLAUDE.md to $BASE_DIR/CLAUDE.md"
fi
