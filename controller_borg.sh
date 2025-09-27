#!/bin/bash

declare -A borg_controller_commands=(
)

# TODO borg import 
# TODO borg list
# TODO borg change-passphrase
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
    echo "[BORG] Repository name is required"
    exit 1
  fi
  if [ -z "$old_passphrase" ]; then
    echo "[BORG] Old passphrase is required"
    exit 1
  fi

  echo "[BORG] Changing passphrase for repository '$name'..."
  export BORG_REPO="$BORG_REPO_BASE/$name"

  export BORG_NEW_PASSPHRASE="$BORG_PASSPHRASE" 
  export BORG_PASSPHRASE="$old_passphrase"
  sudo -E borg key change-passphrase
  export BORG_PASSPHRASE="$BORG_NEW_PASSPHRASE"
  echo "[BORG] Passphrase changed successfully for repository '$name'"
}
