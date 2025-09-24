#!/bin/bash

CORE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd $CORE_DIR
BASE_DIR=$(dirname "$CORE_DIR")
set -e

source ./version.sh
echo "[CONTROLLER] $CORE_VERSION ($(git rev-parse --short HEAD))"

# COMMANDS
declare -A commands=(
  [help]=":Show this help message"
)
cmd_help() {
  print_help "" "commands"
}

# FUNCTIONS
source ./func_help.sh

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
commands+=([init]=":Initialize the services directory")
cmd_init() {
  echo "Initializing services..."

  # create .env file in subdirectory. Write "CORE_DIR=<path to core>"
  if [[ ! -f "$BASE_DIR/.env" ]]; then
    # extract dirname of CORE_DIR
    CORE_DIR_NAME=$(basename "$CORE_DIR")
    echo "CORE_DIR_NAME=$CORE_DIR_NAME" >"$BASE_DIR/.env"
    echo "BORG_RSH=\"ssh -i \$HOME/.ssh/id_rsa\"" >>"$BASE_DIR/.env"
    echo "BORG_REPO_BASE=">>"$BASE_DIR/.env"
    echo "BORG_PASSPHRASE=">>"$BASE_DIR/.env"

    echo ".env file created in services directory"
  fi

  # create controller.sh in base directory, which just calls this script
  echo "#!/bin/bash" >"$BASE_DIR/controller.sh"
  echo "cd -- \"\$(dirname -- \"\${BASH_SOURCE[0]}\")\"" >>"$BASE_DIR/controller.sh"
  echo "source .env" >>"$BASE_DIR/controller.sh"
  echo "source \$CORE_DIR_NAME/controller.sh \"\$@\"" >>"$BASE_DIR/controller.sh"
  chmod +x "$BASE_DIR/controller.sh"
  echo "controller.sh created in services directory"
}

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
  echo "Copied template '$template' to '$service_name'"

  cd "$BASE_DIR/$service_name"
  git init -b main >/dev/null
  git add . >/dev/null
  git commit -m "Initial commit from template '$template'" >/dev/null
  echo "Initialized git repository"

  echo "[CORE] Service '$service_name' created from template '$template'"
  # TODO backup service initially
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

  rm -rf "$BASE_DIR/$service_name"
  echo "Service '$service_name' removed"
}

# TODO import command

main "$@"
