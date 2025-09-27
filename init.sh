#!/bin/bash
set -e

# create services directory
read -p "Enter services folder name (services): " BASE_DIR_NAME
BASE_DIR_NAME=${BASE_DIR_NAME:-services}
BASE_DIR=$(pwd)/$BASE_DIR_NAME

mkdir -p $BASE_DIR
cd $BASE_DIR


# clone this repository
read -p "Enter the controller directory name (.controller): " CORE_DIR_NAME
CORE_DIR_NAME=${CORE_DIR_NAME:-.controller}
if [[ -d "$CORE_DIR_NAME" ]]; then
  echo "Directory '$CORE_DIR_NAME' already exists. Updating existing repository..."
  cd "$CORE_DIR_NAME"
  git pull origin main
  cd ..
else
  echo "Cloning service.controller repository into '$CORE_DIR_NAME'..."
  git clone https://github.com/Vereine-Vereint/service.controller.git "$CORE_DIR_NAME"
fi


# create .env file in subdirectory. Write "CORE_DIR=<path to core>"
if [[ ! -f "$BASE_DIR/.env" ]]; then
  echo "creating .env file in services directory..."
  echo "CORE_DIR_NAME=$CORE_DIR_NAME" >"$BASE_DIR/.env"
  echo "BORG_RSH=\"ssh -i \$HOME/.ssh/id_rsa\"" >>"$BASE_DIR/.env"
  echo "BORG_REPO_BASE=">>"$BASE_DIR/.env"
  echo "BORG_PASSPHRASE=">>"$BASE_DIR/.env"
  echo "BORG_AUTOBACKUP_SERVICES=">>"$BASE_DIR/.env"

  echo " -> adjust the $BASE_DIR_NAME/.env file as needed"
fi

# create controller.sh in base directory, which just calls this script
echo "creating controller.sh in services directory..."
echo "#!/bin/bash" >"$BASE_DIR/controller.sh"
echo "cd -- \"\$(dirname -- \"\${BASH_SOURCE[0]}\")\"" >>"$BASE_DIR/controller.sh"
echo "source .env" >>"$BASE_DIR/controller.sh"
echo "source \$CORE_DIR_NAME/controller.sh \"\$@\"" >>"$BASE_DIR/controller.sh"
chmod +x "$BASE_DIR/controller.sh"

echo "Initialization complete."

# TODO make sure borgbackup, crontab, rsync are installed
# ? maybe even docker/docker compose as well?

# create autobackup cronjob
if crontab -l | grep -q "$BASE_DIR/controller.sh borg autobackup-now"; then
  echo "Cronjob for automatic backups already exists."
else
  read -p "Do you want to set up automatic backups? (y/n): " setup_cron
  if [[ "$setup_cron" =~ ^[Yy]$ ]]; then
    read -p "Enter the cron schedule (e.g., '0 3 * * *' for daily at 3 AM): " cron_schedule
    (crontab -l 2>/dev/null; echo "$cron_schedule $BASE_DIR/controller.sh borg autobackup-now >> $BASE_DIR/backup.log 2>&1") | crontab -
    echo "Cronjob added for automatic backups."
  fi
fi
