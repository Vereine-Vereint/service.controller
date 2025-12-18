#!/bin/bash
set -e

SERVICE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd $SERVICE_DIR

# CORE
source ../.env
source ../$CORE_DIR_NAME/core.sh

# VARIABLES
set -o allexport
# set variables for docker or other services here
set +o allexport

# COMMANDS

commands+=([exec]=":Execute a command in the pretix container")
cmd_exec() {
  docker compose exec -it pretix bash
}

# ATTACHMENTS

att_pull() {
  if [[ -n "$PRETIX_EXTENSIONS" ]]; then
    docker pull pretix/standalone:stable
  fi
}

att_post-start() {
  echo "[$SERVICE_NAME] Enabling cronjob..."
  (crontab -l; echo "15,45 * * * * $SERVICE_DIR/service.sh docker exec pretix pretix cron") | crontab -
  echo "[CRON] Added the following cronjob:"
  echo "$(crontab -l | grep "$SERVICE_NAME/service.sh")"
}

att_pre-stop() {
  echo "[$SERVICE_NAME] Disabling cronjob..."
  cronjob=$(crontab -l | grep "$SERVICE_DIR/service.sh docker exec")
  crontab -l | grep -v "$SERVICE_DIR/service.sh docker exec" | crontab -
  echo "[CRON] Removed the following cronjob:"
  echo "$cronjob"
}

att_post-setup() {
  # Setup Pretix - Compress
  echo "[$SERVICE_NAME] Running compress..."
  docker compose exec pretix python /pretix/src/manage.py compress
}

# MAIN
main "$@"
