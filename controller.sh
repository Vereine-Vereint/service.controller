#!/bin/bash

CORE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd $CORE_DIR
BASE_DIR=$(dirname "$CORE_DIR")
set -e

source ./version.sh
echo "[CONTROLLER] $CORE_VERSION ($(git rev-parse --short HEAD))"

set -o allexport
source ../.env
set +o allexport

# COMMANDS
declare -A commands=(
  [help]=":Show this help message"
)
cmd_help() {
  print_help "" "commands"
}

# FUNCTIONS
source ./func_help.sh
source ./controller_borg.sh

# MAIN
main() {
  local command="$1"

  if [[ ! " ${!commands[@]} " =~ " $command " ]]; then
    cmd_help
    if ! [[ -z "$command" ]]; then
      echo
      echo "Unknown command: $command"
    fi
    exit 1
  fi

  echo

  cd $BASE_DIR
  shift
  cmd_$command "$@"
}

# COMMANDS
commands+=([create]="<name> <template>:Create a new service using a template")
cmd_create() {
  echo "Creating new service..."
  local service_name="$1"
  local template="$2"
  if [[ -z "$service_name" ]]; then
    echo "Service name is required"
    exit 1
  fi
  if [[ -z "$template" ]]; then
    echo "Using default template"
    template="default"
  fi

  # check if the service already exists
  if [[ -d "$BASE_DIR/$service_name" ]]; then
    echo "Service '$service_name' already exists"
    exit 1
  fi

  local template_dir="$CORE_DIR/templates/$template"
  if [[ ! -d "$template_dir" ]]; then
    echo "Template '$template' does not exist"
    exit 1
  fi

  cp -r "$template_dir" "$BASE_DIR/$service_name"
  chmod +x "$BASE_DIR/$service_name/service.sh"
  echo "Copied template '$template' to '$service_name'"

  cd "$BASE_DIR/$service_name"
  git init -b main >/dev/null
  git add . >/dev/null
  git commit -m "Initial commit from template '$template'" >/dev/null
  echo "Initialized git repository"

  echo "[CONTROLLER] Service '$service_name' created from template '$template'"

  # ask if borg repo should be created
  read -p "Do you want to create a Borg backup repository for this service now? (y/N): " create_borg
  if [[ "$create_borg" == "y" || "$create_borg" == "Y" ]]; then
    ./service.sh borg init
  fi

}

commands+=([import]="<name>:Import an existing service from borg")
cmd_import() {
  echo "[CONTROLLER] Importing service..."
  local service_name="$1"
  if [[ -z "$service_name" ]]; then
    echo "Service name is required"
    exit 1
  fi

  if [[ -d "$BASE_DIR/$service_name" ]]; then
    echo "Service '$service_name' already exists"
    echo "Delete the existing service before importing"
    exit 1
  fi

  export BORG_RSH="$(echo $BORG_RSH | sed "s/~/\/home\/$USER/g")"
  export BORG_REPO="$BORG_REPO_BASE/$service_name"
  export BORG_PASSPHRASE="$BORG_PASSPHRASE"
  name=$(sudo -E borg list --sort-by timestamp | tail -n 1 | awk '{print $1}')
  if [ -z "$name" ]; then
    echo "[CONTROLLER] No backups found for service '$service_name'"
    exit 1
  fi

  mkdir -p "$BASE_DIR/$service_name"
  cd "$BASE_DIR/$service_name"

  echo "[CONTROLLER] Importing repository for service '$service_name' with backup '$name'"

  sudo -E borg extract --progress "::$name"
  if [ $? -ne 0 ]; then
    echo "[CONTROLLER] Restore failed"
    exit 1
  fi

  echo "[CONTROLLER] Service '$service_name' imported from borg backup"
}

commands+=([remove]="<name>:Remove an existing service")
cmd_remove() {
  echo "Removing service..."
  local service_name="$1"
  if [[ -z "$service_name" ]]; then
    echo "Service name is required"
    exit 1
  fi

  if [[ ! -d "$BASE_DIR/$service_name" ]]; then
    echo "Service '$service_name' does not exist"
    exit 1
  fi

  # make second check
  read -p "Are you sure you want to remove service '$service_name'? This action cannot be undone. (y/N): " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborting"
    exit 0
  fi

  sudo rm -rf "$BASE_DIR/$service_name"
  echo "Service '$service_name' removed"
}

commands+=([update]=":Update the controller to the latest version")
cmd_update() {
  echo "Updating controller..."
  cd $CORE_DIR
  git pull origin main
  echo "Controller updated to latest version"
}

main "$@"
