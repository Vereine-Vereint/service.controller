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

commands+=([exec-db]="<msg>: Execute a command in the database container")
cmd_exec-db() {
  docker compose exec -it bookstack-db bash -c "mariadb -u root -p${MYSQL_ROOT_PASSWORD}"
}

commands+=([upgrade-db]="<msg>: Execute mariadb-upgrade -u root -p<PASSWORD>")
cmd_upgrade-db() {
  docker compose exec -it bookstack-db bash -c "mariadb-upgrade -u root -p${MYSQL_ROOT_PASSWORD}"
}
# ATTACHMENTS

# Setup function that is called before the docker up command
# att_setup() {
#   echo "Setting up..."
# }

# Configure function that is called before the docker up, start and restart commands
# att_configure() {
#   echo "Configuring..."
# }

# MAIN
main "$@"
