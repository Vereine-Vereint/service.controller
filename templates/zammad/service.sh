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
VERSION=6.3.0
IMAGE_REPO=ghcr.io/zammad/zammad

ELASTICSEARCH_VERSION=8.12.2

MEMCACHE_VERSION=1.6.25-alpine
MEMCACHE_SERVERS=zammad-memcached:11211

POSTGRES_VERSION=15.6-alpine
POSTGRES_HOST=zammad-postgresql
POSTGRES_PORT=5432
POSTGRES_USER=zammad
POSTGRES_PASS=zammad
POSTGRES_DB=zammad_production

REDIS_VERSION=7.2.4-alpine
REDIS_URL=redis://zammad-redis:6379

NGINX_SERVER_SCHEME=https
NGINX_PORT=8080
set +o allexport

# COMMANDS

commands+=([exec-rails]=":Enter rails console")
cmd_exec-rails() {
  # docker compose run --rm zammad-railsserver rails c
  docker compose exec -it zammad-railsserver /docker-entrypoint.sh rails c
  # Setting.set('ui_ticket_create_default_type', "email-out")
  # Setting.set('ui_ticket_create_notes', {
  #   :"phone-in"=>"Du erstellst gerade eine Notiz zu einem eingehenden Telefonanruf.",
  #   :"phone-out"=>"Du erstellst gerade eine Notiz zu einem ausgehenden Telefonanruf.",
  # })
}

# ATTACHMENTS

att_setup() {
  sudo mkdir -p $SERVICE_DIR/volumes/backup
  sudo mkdir -p $SERVICE_DIR/volumes/elasticsearch
  sudo mkdir -p $SERVICE_DIR/volumes/postgresql
  sudo mkdir -p $SERVICE_DIR/volumes/redis
  sudo mkdir -p $SERVICE_DIR/volumes/storage
  sudo mkdir -p $SERVICE_DIR/volumes/var
  sudo chmod -R 777 $SERVICE_DIR/volumes
}

# MAIN
main "$@"
