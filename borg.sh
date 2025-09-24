
declare -A borg_commands=(
  [init]=":Create remote repository"
  [pwgen]=":Generate a random passphrase"
  [info]=":Show repository information"
  [list]=":Lists all backups"

  [backup]="<name>:Backup current data"
  [restore-fresh]="<name>:Delete and restore data from backup"
  [restore-diff]="<name>:Restore data from backup (without deleting current data, using diff)"
  [export]="<file> <name>:Export backup to a .tar file"
  [delete]="<name>:Delete backup"

  [compact]=":Compact the repository"
  [prune]=":Prune old backups"

  ["break-lock"]=":Break the repository lock !USE WITH CAUTION!"
  
  ["autobackup-now"]="<logfile>:Automatically backup and prune now"
  ["autobackup-enable"]="<time>:Enable automatic backups (default time: '0 3 * * *')"
  ["autobackup-disable"]=":Disable automatic backups"
)

add_global_subcommand "borg" "restore"
add_global_subcommand "borg" "backup"
add_global_subcommand "borg" "prune"

commands+=([borg]=":Manage Backup and Restore operations")
cmd_borg() {
  local command="$1"

  if [[ ! " ${!borg_commands[@]} " =~ " $command " ]]; then
    print_help "borg " "borg_commands"
    if ! [[ -z "$command" ]]; then
      echo
      echo "Unknown command: borg $command"
    fi
    exit 1
  fi

  borg_check

  BORG_RSH="$(echo $BORG_RSH | sed "s/~/\/home\/$USER/g")"

  cd $SERVICE_DIR
  shift # remove first argument ("borg" command)
  borg_$command "$@"
}

borg_check() {
  # Check if borg is installed
  if ! command -v borg &>/dev/null; then
    echo "[BORG] Borg is not installed"
    # try to install with apt
    if command -v apt &>/dev/null; then
      echo "[BORG] Installing borg with apt"
      sudo apt update
      sudo apt install -y borgbackup
    else
      echo "[BORG] Please install borg manually"
      exit 1
    fi
  fi

  # Check if BORG_REPO, BORG_PASSPHRASE are set
  if [ -z "$BORG_REPO" ]; then
    echo "[BORG] BORG_REPO is not set"
    exit 1
  fi
  # if [ -z "$BORG_RSH" ]; then
  #   echo "[BORG] BORG_RSH is not set"
  #   exit 1
  # fi
  # if [ -z "$BORG_PASSPHRASE" ]; then
  #   echo "[BORG] BORG_PASSPHRASE is not set"
  #   exit 1
  # fi
}

source "$CORE_DIR/borg_commands.sh"
