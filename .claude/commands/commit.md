---
description: Commit changes in one service (or every service with changes) via ./service.sh commit
---

Commit pending changes in a service using its own `service.sh commit "<message>"` (which runs
`git add . && git commit -m <msg>` and triggers a borg backup — see [git.sh](git.sh)).

## Argument

`$ARGUMENTS` is the service name. If empty, scan every service folder in `$BASE_DIR` and pick the
ones whose git working tree is dirty.

## Steps

1. **Pick targets.**
   - If a service name was given: only that one (verify the directory and its `service.sh` exist).
   - Else: list the immediate subdirectories of `$BASE_DIR` that contain a `service.sh` and have
     uncommitted changes (`git -C <dir> status --porcelain` is non-empty). Exclude `.controller/`,
     `.traefik/`, `.tmp/`, `.backup`, and anything starting with `.`.

2. **For each target service**, do the following in order:
   a. `cd` into the service dir and run `git status` + `git diff` (staged and unstaged) to see what
      changed. Read enough of the diff to actually understand the change — don't just summarize
      filenames.
   b. Draft a concise, conventional commit message (`<type>: <subject>`, ~70 chars max) that
      describes the **why** of the change, following the style in `git log` of that service.
   c. Show the user the proposed message and a one-line summary of the changes. Ask the user to
      confirm, edit, or skip — use the AskUserQuestion tool with options like "Use as-is", "Edit
      message", "Skip this service".
   d. Once confirmed, run `./<service>/service.sh commit "<final message>"` from `$BASE_DIR`. Do not
      stage or commit with raw `git` — always go through `service.sh commit` so the borg backup
      hook fires.
   e. Report success and move to the next service.

3. **Don't bundle services.** Each service is its own git repo with its own history — commit them
   separately, one message each.

## Constraints

- Never use `git commit --no-verify` or `--amend` unless the user explicitly asks.
- Never `git add` files you didn't read in the diff — if something unexpected is staged, ask first.
- If the service has no changes, say so and skip it (don't create an empty commit).
- `.controller/` is **not** a service — never commit it via this command. The user commits the
  controller repo manually.