---
name: standardize-docker-compose
description: 'Standardize docker-compose templates to match project conventions. Use when converting service templates to use traefik, two-network architecture, .env versioning, and ./volumes mounts.'
---

# Standardize Docker Compose Templates

## When to Use

When adding or updating a service template to align with the project's docker-compose standards (bookstack, default, karakeep, nextcloud patterns).

## Standardization Checklist

### 1. Remove Container Names
- Delete `container_name:` from all service definitions
- Update any references to container names in `links:`, `depends_on:`, or environment variables to use service names instead

### 2. Port Mappings
- Comment out all `ports:` sections
- Keep ports as comments so the port usage remains documented
- Exception: Only uncomment if explicitly needed for traefik or other infrastructure

### 3. Network Architecture
- Define two networks at top level:
  ```yaml
  networks:
    default:
    traefik:
      external: true
  ```
- Add webserver/main service to both networks: `- default` and `- traefik`
- For services only on the `default` network, omit the `networks:` config (default is already implicit)
- Only add explicit `networks:` to services that need `traefik` or custom network membership

### 4. Traefik Labels
- Add traefik labels only to the webserver/main service:
  ```yaml
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.${COMPOSE_PROJECT_NAME}.rule=Host(`${DOMAIN}`)"
    - "traefik.http.routers.${COMPOSE_PROJECT_NAME}.entrypoints=websecure"
  ```
- Some older templates may have DOMAIN variables like `${PRETIX_DOMAIN}`. Standardize to `${DOMAIN}` for consistency.
- Include service-specific port labels if needed (e.g., karakeep's port 3000)

### 5. Image Versioning
- Move hardcoded versions to `.env` file
- Update image references to use variables: `image: service:${SERVICE_VERSION}`
- Add all version variables to `.env` with reasonable defaults

### 6. Restart Policy
- Change all `restart:` policies to `restart: unless-stopped`

### 7. Volume Paths
- Change all volume mounts to use `./volumes/` prefix
- Example: `/var/lib/postgresql` → `./volumes/db:/var/lib/postgresql`

### 8. Environment Files
- Only add `env_file: - .env` to a service if it actually requires loading environment variables from the file (e.g., when the service uses variables not already provided by docker-compose or the environment). Do not add it by default.

## Example Reference

See [nextcloud template](https://github.com/your-repo/tree/main/.controller/templates/nextcloud) for a complete, standards-compliant example.

## Validation

After standardization:
- No hardcoded image versions remain in docker-compose.yml
- Only the webserver has traefik labels
- Only services on traefik network have explicit `networks:` declaration
- All volumes reference `./volumes/...`
- `.env` file includes all version variables
