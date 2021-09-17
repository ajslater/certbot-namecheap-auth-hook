# Certbot Namecheap DNS Auth Plugin

[![CircleCI](https://circleci.com/gh/ajslater/certbot-namecheap-auth-hook/tree/main.svg?style=svg)](https://circleci.com/gh/ajslater/certbot-namecheap-auth-hook/tree/main)

## Usage

This is used as volume container mount from certbot. It is executed from the certbot container
and does not have its own runtime. The auth script, auth.sh, jankily installs apk & python
dependencies every time it's run.

## docker-compose.yaml

```yaml
services:
  certbot-namecheap-auth-hook:
    image: ajslater/certbot-namecheap-auth-hook
    env_file: .env
    build: .
    container_name: certbot-namecheap-auth-hook
    volumes:
      - ./config:/auth-hook/config:ro
  certbot:
    image: certbot/certbot
    container_name: certbot
    env_file: .env
    volumes:
      - certbot-etc:/etc/letsencrypt
    volumes_from:
      - certbot-namecheap-auth-hook
    command: renew
    security_opt:
      - no-new-privileges:true
```

## .env Configuration
Defaults shown

```sh
AUTH_HOOK_CONFIG_PATH=config/lexicon.yml #  Configures dns-lexicon

# optional proxy config gets switched on if PROXY_DEST is set
AUTH_HOOK_PROXY_DEST=user@host.tld  # proxy ssh address
AUTH_HOOK_PROXY_PORT=1080 # proxy port
AUTH_HOOK_SSH_ID=config/id_ed25518 # proxy ssh private key
AUTH_HOOK_SSH_PORT=22 # proxy ssh port
```
