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

#! SETUP THE GITHUB RUNNER INITIALLY:
# ./config.sh --url https://github.com/CONNECTA-Regensburg --token TOKEN --unattended  --name EXAMPLE-$(hostname) --replace --labels EXAMPLE

att_setup() {
  cd actions-runner
  if ! sudo ./svc.sh status | grep -q "active (running)"; then
    echo "Setting up GitHub Actions Runner service..."
    sudo ./svc.sh install
    sudo ./svc.sh start
  fi
  cd ..
}

att_remove() {
  cd actions-runner
  if sudo ./svc.sh status | grep -q "active (running)"; then
    echo "Stopping GitHub Actions Runner service..."
    sudo ./svc.sh stop
    sudo ./svc.sh uninstall
  fi
  cd ..
}

# Configure function that is called before the docker up, start and restart commands
# att_configure() {
#   echo "Configuring..."
# }

# MAIN
main "$@"
