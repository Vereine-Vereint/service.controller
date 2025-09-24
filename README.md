# Service Controller

This repository controls all services in different directories.

## Basic structure

| .env # all borg variables for borg, used for backing up and restoring services
| service.controller/
| | - controller.sh # add or remove any services
| | - core.sh # core functionality for other services
|
| service/
| | - service.sh # uses core from service.controller.
