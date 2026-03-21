#!/bin/bash

declare -A borg_controller_commands=(
)

if ! declare -f borg_autobackup_services_read >/dev/null; then
  source "$CORE_DIR/borg_commands.sh"
fi

# TODO borg list
# TODO borg import 
# TODO borg delete

commands+=([borg]=":Manage global Borg Services operations")
cmd_borg() {
  local command="$1"

  if [[ ! " ${!borg_controller_commands[@]} " =~ " $command " ]]; then
    print_help "borg " "borg_controller_commands"
    if ! [[ -z "$command" ]]; then
      echo
      echo "Unknown command: borg $command"
    fi
    exit 1
  fi

  BORG_RSH="$(echo $BORG_RSH | sed "s/~/\/home\/$USER/g")"

  cd $SERVICE_DIR
  shift # remove first argument ("borg" command)
  borg_controller_$command "$@"
}


borg_controller_commands+=([change-passphrase]="<name> <old-passphrase>:Change the passphrase of the <name> repository to the new passphrase")
borg_controller_change-passphrase() {
  local name="$1"
  local old_passphrase="$2"

  if [ -z "$name" ]; then
    echo "[CONTROLLER] Repository name is required"
    exit 1
  fi
  if [ -z "$old_passphrase" ]; then
    echo "[CONTROLLER] Old passphrase is required"
    exit 1
  fi

  echo "[CONTROLLER] Changing passphrase for repository '$name'..."
  export BORG_REPO="$BORG_REPO_BASE/$name"

  export BORG_NEW_PASSPHRASE="$BORG_PASSPHRASE" 
  export BORG_PASSPHRASE="$old_passphrase"
  sudo -E borg key change-passphrase
  export BORG_PASSPHRASE="$BORG_NEW_PASSPHRASE"
  echo "[CONTROLLER] Passphrase changed successfully for repository '$name'"
}

borg_controller_commands+=([autobackup-now]=":Create a new backup for all enabled services immediately")
borg_controller_autobackup-now() {
  echo "[CONTROLLER] Creating a new backup for all enabled services..."
  local service

  if ! borg_autobackup_services_read; then
    echo "[CONTROLLER] Failed to read autobackup service list"
    return 1
  fi

  if [[ ${#autobackup_services[@]} -eq 0 ]]; then
    echo "[CONTROLLER] No services configured for autobackup"
    return 0
  fi

  for service in "${autobackup_services[@]}"; do
    echo
    echo "[CONTROLLER] ######################################## Backing up service: $service"
    # Implement the backup logic for each service here
    set +e
    $BASE_DIR/$service/service.sh borg autobackup-now
    if [ $? -ne 0 ]; then
      echo "[CONTROLLER] ######################################## Error backing up service: $service"
    else
      echo "[CONTROLLER] ######################################## Finished service  : $service"
    fi
    set -e
  done
}
