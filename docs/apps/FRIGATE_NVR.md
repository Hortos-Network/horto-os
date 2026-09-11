# Frigate NVR

**Summary**: How to install [Frigate NVR](https://docs.frigate.video/) on Horto OS.

To run Frigate on the RK3588 with hardware-accelerated video decoding (VPU via
MPP) and object detection (NPU via RKNN), you need to use the dedicated Rockchip
image variant (stable-rk) and map the specific hardware paths into the container.

Create the necessary directories for the Frigate configuration and media storage:

```Bash
mkdir -p /srv/docker/app_data/frigate/config
mkdir -p /srv/docker/app_data/frigate/media
```

Here is a clean docker-compose.yml template configured for the RK3588 hardware stack:

```YAML
services:
  frigate:
    container_name: frigate
    restart: unless-stopped
    image: ghcr.io/blakeblackshear/frigate:stable-rk
    shm_size: "256mb" # Adjust based on your camera resolution count
    volumes:
      - /srv/docker/app_data/frigate/config:/config
      - /srv/docker/app_data/frigate/media:/media/frigate
      - type: tmpfs
        target: /tmp/cache
        tmpfs:
          size: 1000000000
    security_opt:
      - apparmor=unconfined
      - systempaths=unconfined
    devices:
      - /dev/dri
      - /dev/dma_heap
      - /dev/rga
      - /dev/mpp_service
    ports:
      - "8971:8971"
      - "8554:8554" # RTSP feeds
    environment:
      - TZ=Europe/Paris
```

**Key Hardware Flags Explained:**

- **`image: ...:stable-rk`**: Pulls the community-supported Rockchip build that
  has the compiled RKNN and MPP runtime binaries built-in.

- **`/dev/mpp_service` & `/dev/rga`**: Exposes Rockchip's Media Process Pipeline
  (MPP) and Raster Graphic Acceleration units directly to the container for zero-copy hardware video decoding.

- **`detectors` configuration**: Inside your Frigate `config.yml`, you will
  configure the detector to use the rknn type targeting the built-in NPU core.

Additional possible parameters in compose file (don't use this as compose file):

```YAML
services:
  frigate:
    container_name: frigate
    network_mode: host
    privileged: true
    restart: unless-stopped
    stop_grace_period: 30s
    image: ghcr.io/blakeblackshear/frigate:stable-rk
    platform: linux/arm64
    shm_size: "512mb"
    devices:
      - /dev/rknpu:/dev/rknpu
      - /dev/dri:/dev/dri
      - /dev/mali0:/dev/mali0
      - /dev/dma_heap:/dev/dma_heap
      - /dev/mpp_service:/dev/mpp_service
      - /dev/rga:/dev/rga
      - /dev/bus/usb:/dev/bus/usb
    volumes:
      - type: tmpfs
        target: /tmp/cache
        tmpfs:
          size: 268435456
    environment:
      FRIGATE_RTSP_PASSWORD: "password-here"
    healthcheck:
      test: ["CMD-SHELL", "python3 -c 'import socket; s = socket.socket(); s.connect((\"127.0.0.1\", 5000))' || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 45s
```

When you container started without errors, you should see the following output
in the logs (default password is created on first run):

```log
frigate.app                    INFO    : ********************************************************
frigate.app                    INFO    : ***    Reset admin password set in the config.      ***
frigate.app                    INFO    : ***    Password: 8ccd4874ccb4f6e75f7f2cf2cbc5bb62   ***
frigate.app                    INFO    : ********************************************************
```

Then head over to 'http://{{MY_HOSTNAME}}:8971' to login with the default credentials.

## Homepage Dashboard

To add the Frigate dashboard section to your Homepage Dashboard, add the following
service to your `services.yaml` file:

```YAML
    -  Frigate NVR:
        icon: frigate.png
        href: http://{{MY_HOSTNAME}}:8971
        description: Frigate NVR
        server: my-docker
        container: frigate
```

To make Frigate NVR to use the RK3588 NPU, add the following 'detectors: section'
to your `/srv/docker/app_data/frigate/config.yaml` file:

```YAML
# auth: # uncomment to enable new default password on first run
#  reset_admin_password: true
mqtt:
  enabled: False
detectors:
    rk3588:
        type: rknn
        device: /dev/rknn0 # or let it scan the cores
        num_cores: 3

# Sometimes it helps to add the cameras in the config.yaml and not in the UI
# and it is in most cases more reliable.
cameras:
  horty_tapo: # Replace with your camera name
    ffmpeg:
      inputs:
              - path: rtsp://<username>:<password>@192.168.10.139:554/stream1
                roles:
                  - record
              - path: rtsp://<username>:<password>@192.168.10.139:554/stream2
                roles:
                  - detect
    detect:
      enabled: true
      width: 640
      height: 480
      fps: 5
version: 0.17-0
```
