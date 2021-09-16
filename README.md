# Certbot Namecheap DNS Auth Plugin

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
