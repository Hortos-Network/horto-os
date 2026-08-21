# Docker apps for Horto OS

**Summary**: How to install Docker and basic Docker apps for Horto OS.


---

> [!NOTE]
> Memory constraints: Keep in mind that with a RK3588 based board with 8 GB RAM
there are some memory constraints.


## Step by Step guide

## Docker

First you need you need to install the full Docker stack.

```Bash
armbian-config --cmd CON001
```

Ref: [docs.armbian.com/User-Guide_Armbian-Software/Containers](https://docs.armbian.com/User-Guide_Armbian-Software/Containers/)

> [!NOTE]
>We recommend to use the install script, which automatically copies all the necessary files.
>`d1_docker_init.sh`:

```bash
sh /srv/horto-os/scripts/d1_docker_init.sh
```

## Dockge, docker compose.yaml stack

Ref: [github.com/louislam/dockge](https://github.com/louislam/dockge)

For the further installation of container we rely on Dockge instead of
Portainer, which is packaged with [Armbian](Armbian).

- **Portainer** is a heavy, all-encompassing management suite that abstracts almost everything in Docker (networks, volumes, single containers, images, registries) behind its own database and internal logic.

- **Dockge** is file-centric. It doesn't trap your configuration in a database; your `compose.yaml` files live natively on your disk in `/opt/stacks/`, meaning you can manage, back up, or run standard `docker compose` commands in the terminal just as easily as through its web GUI.

We don't follow the standard basic instructions from the repository to install Dockge. Instead, Horto-OS keeps Docker app data under `/srv/docker`.

```Bash
#### Create directories that store your stacks and Dockge's store
mkdir -p /srv/docker/stacks /srv/docker/dockge
cd /srv/docker/dockge
```


Copy the Dockge docker compose.yaml file or the following text into /srv/docker/dockge/compose.yaml.

```yaml
services:
  dockge:
    image: louislam/dockge:1
    container_name: dockge
    restart: unless-stopped
    ports:
      # Host Port : Container Port
      - 5001:5001
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data:/app/data
      # If you want to use private registries, you need to share the auth file with Dockge:
      # - /root/.docker/:/root/.docker

      # Stacks Directory
      # ⚠️ READ IT CAREFULLY. If you did it wrong, your data could end up writing into a WRONG PATH.
      # ⚠️ 1. FULL path only. No relative path (MUST)
      # ⚠️ 2. Left Stacks Path === Right Stacks Path (MUST)
      - /srv/docker/stacks:/srv/docker/stacks
    environment:
      # Tell Dockge where is your stacks directory
      - DOCKGE_STACKS_DIR=/srv/docker/stacks
```


Run this command in the dockge folder:

```Bash
##### Be sure are in the /srv/docker/dockge folder!!
##### Start the server
docker compose up -d
```

Once it spins up, you can access the web UI at `http://<your-hostname-or-ip>:5001`.

## Docker source copy

The Horto-OS repository contains Docker sources and app data under:

```text
/srv/horto-os/docker_source/
```

To copy the full tree into `/srv/docker/` and render placeholders in the copied files, run:

```bash
sh /srv/horto-os/scripts/d1_docker_init.sh
```


## EVCC (Home Energy Management System)

EVCC [evcc.io](https://evcc.io) can be installed via armbian-config.
But we don't recommend to it this way and use Dockge instead.

Example command to install evcc:

```YAML
services:
  evcc:
    command:
      - evcc
    container_name: evcc
    image: evcc/evcc:latest
    ports:
      - 7070:7070/tcp
      - 8887:8887/tcp
      - 9522:9522/udp
      - 5353:5353/udp
      - 4712:4712/tcp
    volumes:
      - /home/user/evcc.yaml:/etc/evcc.yaml
      - /home/user/.evcc:/root/.evcc
      - /etc/machine-id:/etc/machine-id
      - /var/lib/dbus/machine-id:/var/lib/dbus/machine-id
    network_mode: host
    restart: unless-stopped
    # optional:
    #user: <UID>:<GID>
```

URL: `https://<your.IP>:7070`

### All EVCC Ports

| Host Port | Container Port | Description            | Required |
| --------- | -------------- | ---------------------- | -------- |
| 7070      | 7070/tcp       | Web UI, API            | Yes      |
| 8887      | 8887/tcp       | OCPP Server            | No       |
| 9522      | 9522/udp       | SMA Sunny Home Manager | No       |
| 7090      | 7090/udp       | KEBA Chargers          | No       |
| 5353      | 5353/udp       | mDNS                   | No       |
| 4712      | 4712/tcp       | EEBus                  | No       |
| 8899      | 8899/udp       | Modbus UDP             | No       |



## Homepage (Dashboard)

Homepage [gethomepage.io](https://gethomepage.io) can be installed via Dockge.
Assets such as background images are automatically copied by `d1_docker_init.sh`:

```bash
sh /srv/horto-os/scripts/d1_docker_init.sh
```

This copies the `_assets/` folder into `/srv/docker/assets/`, which can then be mounted in the Homepage container.

```YAML
services:
  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    restart: unless-stopped
    environment:
      - HOMEPAGE_ALLOWED_HOSTS=*
    ports:
      - 3021:3000
    env_file: .env
    volumes:
      - /srv/docker/app_data/homepage/config:/app/config
      - /var/run/docker.sock:/var/run/docker.sock:ro # Optional: allows Homepage to auto-discover your other containers
      - /srv/docker/assets:/app/public/images # for serving images from /srv/docker/assets to Homepage
networks: {}
```

### Cloudflared Compose Stack (remote access)

The easiest way to remotely access different apps running on Horto-OS
is [Cloudflare Tunnels](https://developers.cloudflare.com/tunnel/).

You can create a dedicated stack in Dockge with a configuration like this:


```YAML
services:
  cloudflare-tunnel:
    image: cloudflare/cloudflared:latest
    container_name: cloudflare-tunnel
    restart: unless-stopped
    network_mode: host
    command: tunnel --no-autoupdate run
    environment:
      - TUNNEL_TOKEN=eyJhIjoi...your_token_here...
```

You generate the `TUNNEL_TOKEN` in the Cloudflare Zero Trust dashboard.

Once deployed, map your subdomains in Cloudflare to the local services running on the host. Horto-OS also supports templated dashboard links using `MY_URL` and `MY_HOSTNAME`.

As the most of the apps on Horto OS are not designed to be exposed to the internet it is highly recommended to use Cloudflare’s Zero Trust Access Control. A guide how to set it up you can find here [[Cloudflare_Tunnels Zero Trust Access]].
## 6. Continue with Docker AI setup

After the Docker setup is complete, continue with:

- [Horto-OS setup 4 – Docker AI](Horto-OS_setup_4_docker_AI.md)
