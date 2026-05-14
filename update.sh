#!/bin/bash
set -e

# Idempotently link $link_path -> $target_path.
#  - already the correct symlink → no-op
#  - nothing at $link_path → create the symlink
#  - anything else (real dir/file, wrong symlink) → describe it, ask y/N,
#    rm -rf and recreate on confirmation; skip otherwise.
ensure_symlink() {
  local target="$1"
  local link="$2"

  if [[ -L "$link" && "$(readlink "$link")" == "$target" ]]; then
    return 0
  fi

  if [[ ! -e "$link" && ! -L "$link" ]]; then
    ln -s "$target" "$link"
    echo "Symlinked $target to $link"
    return 0
  fi

  echo "[CONTROLLER] $link exists but is not the expected symlink:"
  if [[ -L "$link" ]]; then
    echo "  current symlink target: $(readlink "$link")"
  elif [[ -d "$link" ]]; then
    local entries
    entries=$(ls -A "$link" 2>/dev/null | tr '\n' ' ')
    echo "  it is a directory containing: ${entries:-<empty>}"
  elif [[ -f "$link" ]]; then
    echo "  it is a regular file"
  fi
  echo "  expected symlink target: $target"
  read -p "Replace it with a symlink to $target? (y/N): " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    rm -rf "$link"
    ln -s "$target" "$link"
    echo "Replaced $link with symlink to $target"
  else
    echo "Skipped $link"
  fi
}

# migrate: remove old .github symlink (replaced by .claude)
if [[ -L "$BASE_DIR/.github" ]]; then
  rm "$BASE_DIR/.github"
  echo "Removed obsolete .github symlink"
fi

ensure_symlink "$BASE_DIR/$CORE_DIR_NAME/.claude" "$BASE_DIR/.claude"
ensure_symlink "$BASE_DIR/$CORE_DIR_NAME/CLAUDE.md" "$BASE_DIR/CLAUDE.md"
