# Homepage (Dashboard)

**Summary**: Homepage is the lightweight dashboard used to access and monitor Horto-OS services.

---

## Purpose

Homepage is used as the main landing page for:

- local application links,
- remote application links,
- Docker-backed service status,
- selected service widgets like EVCC,
- host resource widgets.

## Compose stack

Current compose content from `docker_source/stacks/homepage/compose.yaml`:

```yaml
services:
  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    environment:
      - HOMEPAGE_ALLOWED_HOSTS=*
    ports:
      - 3021:3000
    volumes:
      - /srv/docker/app_data/homepage/config:/app/config
      - /var/run/docker.sock:/var/run/docker.sock:ro # Optional: allows Homepage to auto-discover your other containers
      - /srv/horto-os/_assets:/app/public/images # for serving images from /srv/horto-os/_assets to Homepage
    restart: unless-stopped
networks: {}
```

### Notes

- The Docker socket mount allows Homepage to show container state for configured services.
- The `_assets` mount allows Homepage to serve background images and other static files.
- The service is exposed on host port `3021`.

Access it locally at:

```text
http://<your-hostname-or-ip>:3021
```

## Deployment path

The source Homepage config lives in:

```text
/srv/horto-os/docker_source/app_data/homepage/config/
```

The active copied config is written to:

```text
/srv/docker/app_data/homepage/config/
```

Initialize it with:

```bash
sh /srv/horto-os/scripts/d1_docker_init.sh
```

This copies the full Docker source tree and renders placeholders such as:

- `{{MY_HOSTNAME}}`
- `{{MY_URL}}`

inside the copied files.

## Docker integration

Homepage Docker integration is configured in:

```text
/srv/docker/app_data/homepage/config/docker.yaml
```

Current config source:

```yaml
---
# For configuration options and examples, please see:
# https://gethomepage.dev/configs/docker/

# local docker
my-docker:
  socket: /var/run/docker.sock
```

This enables service cards to show live container status when the service entry contains:

```yaml
server: my-docker
container: <container-name>
```

## Service cards

The main service definitions live in:

```text
/srv/docker/app_data/homepage/config/services.yaml
```

Typical patterns:

### Local app with Docker status

```yaml
- Dockge:
    href: http://{{MY_HOSTNAME}}:5001
    description: Docker Service Management
    server: my-docker
    container: dockge
```

### Local app with widget

```yaml
- EVCC (HEMS):
    href: http://{{MY_HOSTNAME}}:7070
    description: Home Energy Manager
    server: my-docker
    container: evcc
    widget:
      type: evcc
      url: https://evcc-hos01.{{MY_URL}}
```

### Simple link-only system service

```yaml
- Cockpit:
    href: http://{{MY_HOSTNAME}}:9890
    description: Server Management
```

Cockpit is a system service, not a Docker container, so it should usually remain a link-only card.

## Remote links

> [!NOTE]
> In case you want to access your Horto-OS over the internet, you can use `services_remote.yaml` instead of `services.yaml`. Rename `services.yaml` into `services_local.yaml` and copy `services_remote.yaml` into `services.yaml`. After a container restart your Horto OS can be accessed over the internet, which introduces security risks. Be sure to secure your Cloudflare tunnel with ACL. See [Cloudflare Tunnels](Cloudflare%20Tunnels.md) for more information.

Remote/public links can be defined separately in: 

```text
/srv/docker/app_data/homepage/config/services_remote.yaml
```

These typically use `{{MY_URL}}` for Cloudflare-hosted services.

Example:

```yaml
- Dockge:
    href: https://dockge-hos01.{{MY_URL}}
    description: Docker Service Management
```

## Background image

The background is configured in:

```text
/srv/docker/app_data/homepage/config/settings.yaml
```

Current source config:

```yaml
# For configuration options and examples, please see:
# https://gethomepage.dev/configs/settings/

title: Horto OS Dashboard

# Needs restart to change image.
background:
  image: /images/frontpage_WP-BP.avif
  saturate: 50
  brightness: 50
  opacity: 50
```

This works together with the compose mount:

```yaml
- /srv/horto-os/_assets:/app/public/images
```

So the host file:

```text
/srv/horto-os/_assets/frontpage_WP-BP.avif
```

is exposed inside Homepage as:

```text
/images/frontpage_WP-BP.avif
```

> [!NOTE]
> Restart or recreate the Homepage container after changing the background image settings.

## Common troubleshooting

### Background does not appear

Check:

1. the image file exists under `/srv/horto-os/_assets/`,
2. the volume mount is present in the Homepage compose file,
3. the path in `settings.yaml` matches `/images/<filename>`,
4. the Homepage container was restarted.

### Docker status does not appear

Check:

1. Docker socket is mounted,
2. `docker.yaml` contains a real Docker source,
3. the service card contains both `server:` and `container:`,
4. the container name matches the actual running container name.

## Related topics

- [HORTO-OS_SETUP_4_DOCKER](HORTO-OS_SETUP_4_DOCKER.MD)
- [HORTO-OS_SETUP_4_DOCKER_AI](HORTO-OS_SETUP_4_DOCKER_AI.MD)
