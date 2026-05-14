# Migration Checklist

Work through this top-to-bottom for the install you're on. Tick each box only after the step is
visibly done. See [SKILL.md](SKILL.md) for the concepts, mapping table, compose diff, and
**Safe migration ordering** (read that section first — the order below is non-destructive on
purpose).

## Discovery
- [ ] Find the traefik service dir: `ls -d "$BASE_DIR"/traefik-*` → call it `$TRAEFIK_DIR`.
- [ ] Confirm legacy layout: `$TRAEFIK_DIR/conf/` exists **and** `$TRAEFIK_DIR/docker-compose.yml`
      contains `./conf/:/etc/traefik/conf/`. If either is missing, skip — already migrated or N/A.
- [ ] List the files under `$TRAEFIK_DIR/conf/` and read each one.

## Classification
- [ ] For every `conf/*.yml`, decide its owning service per the mapping table in SKILL.md.
      Record the decision in a short list before copying anything (this is the high-risk step).
- [ ] For any file that mixes concerns, plan the split (which YAML blocks go where).
- [ ] If uncertain about any file, surface the list to the user and confirm before continuing.

## Copy conf files (do NOT delete the originals)
- [ ] For each owning service: create `<service-dir>/traefik/` if it doesn't already exist.
- [ ] **Copy** (`cp`, not `mv`) each YAML into its owning service's `traefik/` directory.
      Preserve filenames where it makes sense; rename if a more descriptive name fits the new
      single-service scope (e.g. `ticket.yml` → `pretix/traefik/routes.yml`).
- [ ] For files that needed splitting: write the per-service portions into each owning service's
      `traefik/` dir. Leave the original intact in `$TRAEFIK_DIR/conf/`.
- [ ] **Leave `$TRAEFIK_DIR/conf/` untouched.** Traefik is still reading from it — every YAML
      must stay until the mount is swapped and verified.
- [ ] Sanity-check coverage: for each file in `$TRAEFIK_DIR/conf/`, confirm at least one
      destination under `<service>/traefik/` was written. Cross off your classification list as
      you go — every entry should be covered before moving on.

## Bring up owning services (registers the bind mounts; live config still unchanged)
- [ ] For each service that received a new `traefik/` subdir: `./service.sh up`. (Idempotent —
      this triggers `traefik_link.sh` to bind-mount `<service>/traefik/` →
      `$BASE_DIR/.traefik/<service>/` without restarting the container if it's already running.)
- [ ] Verify the mounts are in place: `ls "$BASE_DIR/.traefik/"` should now contain a subdir per
      migrated service, each with the expected YAMLs (`ls "$BASE_DIR/.traefik/<service>/"`).
- [ ] At this point traefik **still uses the legacy `./conf/` mount** — nothing changed for it.
      Routing behavior must be identical to pre-migration. Quick smoke test of one route is
      worth doing here to confirm.

## Cutover: swap the traefik mount
- [ ] Edit `$TRAEFIK_DIR/docker-compose.yml`: swap `./conf/:/etc/traefik/conf/` for
      `../.traefik/:/etc/traefik/conf/`.
- [ ] (Recommended) Replace the hardcoded `image: traefik:vX.Y` with
      `image: traefik:${TRAEFIK_VERSION}` and add `TRAEFIK_VERSION=vX.Y` to `$TRAEFIK_DIR/.env`.
- [ ] Diff the compose file (`git diff` inside `$TRAEFIK_DIR`) — only the mount line (and
      optionally the image line) should have changed.
- [ ] Restart traefik: `./service.sh down && ./service.sh up`. This is the single switchover
      moment — the live config source changes from `conf/` to the bind-mounted `.traefik/` tree.

## Validation (do this before deleting anything)
- [ ] `./service.sh logs` on the traefik service — no "file provider" parsing errors, no
      `"middleware ... does not exist"` warnings.
- [ ] Spot-check one route per moved file: hit the host in a browser or with `curl -I` and
      verify the expected status / redirect / forwardAuth behavior.
- [ ] Confirm that middlewares referenced as `<name>@file` from compose labels still resolve.
- [ ] **If validation fails:** revert the docker-compose mount line, restart traefik. The
      original `$TRAEFIK_DIR/conf/` is still intact — you're back to the pre-migration state
      with zero data loss. Investigate before retrying.

## Clean up (only after validation passes)
- [ ] Delete the now-deprecated conf directory: `rm -rf "$TRAEFIK_DIR/conf/"`.
- [ ] Diff the traefik service one more time — `conf/` removal should be the only additional
      change beyond the earlier compose edit.
- [ ] Each migrated service's git repo: commit the new `traefik/` subdir
      (`./service.sh git commit "add traefik/ conf"`).
- [ ] The traefik service's git repo: commit the docker-compose mount swap and the `conf/`
      removal in one commit.
