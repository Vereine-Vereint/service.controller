# Bind-mounts $SERVICE_DIR/traefik into $BASE_DIR/.traefik/$SERVICE_DIR_NAME so the
# traefik service can serve per-service conf files from a single mounted directory.
# Docker bind mounts don't follow symlinks across mount boundaries, so we use
# `mount --bind` instead. Both functions are idempotent.

traefik_link_setup() {
  local src="$SERVICE_DIR/traefik"
  if [[ ! -d "$src" ]]; then
    return 0
  fi
  local dst="$BASE_DIR/.traefik/$SERVICE_DIR_NAME"
  sudo mkdir -p "$BASE_DIR/.traefik" "$dst"
  if mountpoint -q "$dst" 2>/dev/null; then
    return 0
  fi
  if ! sudo mount --bind "$src" "$dst"; then
    echo "[CORE] Warning: failed to bind-mount $src -> $dst"
    return 1
  fi
  echo "[CORE] Bind-mounted $src -> $dst"
}

traefik_link_teardown() {
  local dst="$BASE_DIR/.traefik/$SERVICE_DIR_NAME"
  if mountpoint -q "$dst" 2>/dev/null; then
    if ! sudo umount "$dst" 2>/dev/null; then
      sudo umount -l "$dst" 2>/dev/null || true
    fi
    echo "[CORE] Unmounted $dst"
  fi
  sudo rmdir "$dst" 2>/dev/null || true
}
