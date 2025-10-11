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

# This is an example command that prints a message from the first argument
# commands+=([example]="<msg>:Example command that prints <msg>")
# cmd_example() {
#   echo "Example: $1"
# }

# ATTACHMENTS

# Setup function that is called before the docker up command
att_setup() {
  docker network create traefik &>/dev/null || true
}

# Configure function that is called before the docker up, start and restart commands
# att_configure() {
#   echo "Configuring..."
# }

# MAIN
main "$@"
