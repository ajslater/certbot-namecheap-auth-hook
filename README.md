# Certbot Namecheap DNS Auth Plugin

[![CircleCI](https://circleci.com/gh/ajslater/certbot-namecheap-auth-hook/tree/main.svg?style=svg)](https://circleci.com/gh/ajslater/certbot-namecheap-auth-hook/tree/main)

## Usage

Certbot uses this as a volume container mount. The certbot container runs this code
as this image does not have its own runtime.

### Hacks

The main auth script relies on `curl` and `host` to work. The first time the
auth script runs it will install these for alpine in the certbot container.

The optionally invoked proxy facility will install `ssh` for alpine in the certbot
container.

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
# Required
# AUTH_HOOK_CLIENT_IP=my.whitelisted.client.ip
# AUTH_HOOK_NC_USER=MyNameCheapUserName
# AUTH_HOOK_NC_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Optional ssh http proxy config gets switched on if AUTH_HOOK_PROXY_DEST is set
# AUTH_HOOK_PROXY_DEST=user@host.tld
# AUTH_HOOK_PROXY_PORT=1080
# AUTH_HOOK_SSH_ID=config/id_ed25518
# AUTH_HOOK_SSH_PORT=22
```
