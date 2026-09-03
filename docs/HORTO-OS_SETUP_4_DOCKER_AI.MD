# Horto-OS setup 4 – Docker AI

**Summary**: This guide covers the AI-related Docker services for Horto-OS,
including LLM, STT, TTS, and vision-related stacks.

---

## Overview

Horto-OS can run several AI-related services on RK3588 boards.
These are normally managed as Docker stacks, typically through Dockge.

The exact services you can run depend strongly on available RAM, storage, and NPU support.

> [!NOTE]
> On RK3588 systems with 8 GB RAM, the realistic model selection is limited.
The smaller DeepSeek/Qwen-class models are the practical starting point.

## Base idea

Use Dockge to manage these services from stack directories under:

```text
/srv/docker/stacks/
```

The Horto-OS repository provides source material and examples under:

```text
/srv/horto-os/docker_source/
```

## Example LLM stack

Example stack snippet for a local LLM container:

```yaml
services:
  deepseek-npu:
    image: ghcr.io/seeed-projects/rk3588-qwen3:1.7b-w8a8-latest
    container_name: deepseek-npu
    restart: unless-stopped
    privileged: true
    network_mode: host
    devices:
      - /dev/dri:/dev/dri
      - /dev/dma_heap:/dev/dma_heap
      - /dev/rknpu:/dev/rknpu
      - /dev/mali0:/dev/mali0
    volumes:
      - /dev:/dev
```

In the case you need to install another model you need to purge the Docker stack,
because deleting from Dockge does not delete files.

```Bash
##### Stop and remove all stopped/lingering containers
docker container prune -f

##### Completely wipe out unused images, build caches, and dangling data layers
docker system prune -a --volumes
```

Uvicorn running on http://MY_HOSTNAME:8001 (Press CTRL+C to quit)

The LLM API is exposed at `http://192.168.10.1:8001/v1`.

To check the API endpoints from the browser, navigate to `http://"MY_HOSTNAME":8001/docs`.

Now you can run a test with the following command inside Horto-OS.

```Bash
curl http://192.168.10.1:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "DeepSeek-R1-Qwen-1.7B_w8a8_RK3588.rkllm",
    "messages": [{"role": "user", "content":
    "Do you know about Holochain, p2p app framework ?"}]
  }'
```


## Open-WebUI

Optional web UI stack:

```yaml
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    restart: "no"
    ports:
      - "3000:8080"
    environment:
      - OPENAI_API_BASE_URL=http://192.168.10.1:8001/v1
      - OLLAMA_BASE_URL=http://127.0.0.1:11434
      - OLLAMA_ENABLED=false
      - ENABLE_OLLAMA=false
    volumes:
      - open-webui:/app/backend/data

volumes:
  open-webui:
```

To use Open-WebUI from the browser, navigate to `http://"MY_HOSTNAME":3000"`.


## Whisper (STT)

```yaml
services:
  whisper-cv:
    image: ghcr.io/seeed-projects/recomputer-rk-cv/rk3588-whisper:latest
    container_name: whisper-cv
    restart: unless-stopped
    privileged: true
    network_mode: host
    devices:
      - /dev/dri:/dev/dri
      - /dev/dma_heap:/dev/dma_heap
      - /dev/rknpu:/dev/rknpu
      - /dev/mali0:/dev/mali0
    environment:
      - RKNN_LOG_LEVEL=0
    volumes:
      - /proc/device-tree/compatible:/proc/device-tree/compatible:ro
```

The Whisper API is exposed at `127.0.0.1:8000`.

To check the API endpoints from the browser, navigate to `http://"MY_HOSTNAME":8000/docs`.

## YOLO (vision)

```yaml
services:
  yolo-detection:
    image: ghcr.io/seeed-projects/recomputer-rk-cv/rk3588-yolo11:latest
    container_name: rk3588-yolo11n
    restart: no # Or 'no' if you only want it to run once and exit
    privileged: true
    network_mode: host
    devices:
      - /dev/video1:/dev/video1 # For camera input
      - /dev/dri/renderD129:/dev/dri/renderD129 # For display rendering
      - /dev/dri:/dev/dri # General DRI access, often needed for display
      - /dev/dma_heap:/dev/dma_heap # DMA heap for memory management
      - /dev/rknpu:/dev/rknpu # Access to the Rockchip NPU
      - /dev/mali0:/dev/mali0 # Access to the Mali GPU (if used for display/pre-processing)
    environment:
      - PYTHONUNBUFFERED=1
      - RKNN_LOG_LEVEL=0
    volumes:
      - /proc/device-tree/compatible:/proc/device-tree/compatible:ro
      # If 'model' and 'video' directories are on the host, you'll need to mount them:
      # - ./model:/app/model:ro # Assuming models are in a 'model' folder next to compose file
      # - ./video:/app/video:ro # Assuming videos are in a 'video' folder next to compose file
    command: python web_detection.py --model_path model/yolo11n.rknn --video video/test.mp4 --port 8002
networks: {}
```

The YOLO API is exposed at `127.0.0.1:8002`.

To check the API endpoints from the browser, navigate to `http://"MY_HOSTNAME":8002/docs`.

## Piper (TTS)

For `piper`, the usual path is to create a Dockge stack and then copy the
required build context into that stack directory.

Typical compose definition:

```yaml
services:
  wyoming-piper-rk35xx:
    image: ghcr.io/hanzo-huang/wyoming-piper-rk3576:sha-d4da453
    container_name: wyoming-piper-rk35xx
    restart: unless-stopped
    ports:
      - "10200:10200" # Standard Wyoming port for Home Assistant
    devices:
      - /dev/dri:/dev/dri
      - /dev/dma_heap:/dev/dma_heap
      - /dev/rknpu:/dev/rknpu
      - /dev/mali0:/dev/mali0
    volumes:
      - ./model:/app/model:ro # Point this to your local folder containing your Piper RKNN model files
    command: "python", "/app/wyoming_service.py", "--uri", "tcp://0.0.0.0:10200", "--model-dir", "/app/model"

```

Download the models into the docker_repos directory:

```bash
mkdir -p /srv/docker/docker_repos/piper
cd /srv/docker/docker_repos/piper
wget wget https://github.com/Hanzo-Huang/rk3576-home-assistant-voice/releases/download/models-v1/piper-rk3576-models.tar.gz
```

### Copy Required model files to the Stack Directory

Navigate to your docker_repos/piper directory:

```bash
tar -xzf piper-rk3576-models.tar.gz -C /srv/docker/stacks/
```


After these commands, your /srv/docker/stacks/piper/model/ directory should contain:

```tree
config.json
decoder_rk3576.rknn
encoder.onnx
```

### Deploy the Stack in Dockge

Go back to the Dockge web UI for your rkvoice-stream stack. Click the "Deploy"
or "Update" button. Dockge will now:


Build the piper Docker image.
Start the piper container.
Access the piper Service:

The Voice Stream API is exposed at `127.0.0.1:8621`.

To check the API endpoints from the browser, navigate to `http://"MY_HOSTNAME":8621/docs`.


## Homepage integration

Once the containers run with stable `container_name` values, Homepage can show
them the through Docker integration.

Typical entries in `services.yaml` use:

```yaml
server: my-docker
container: deepseek-npu
```

or similar for:

- `open-webui`
- `cloudflare-tunnel`
- `rkvoice-stream`
- `whisper-cv`
- `rk3588-yolo11n`

## Remote access

Cloudflared can expose selected services remotely.
This is especially useful for:

- Open-WebUI
- EVCC
- Dockge
- Homepage
- Cockpit

Remote links can be templated with `MY_URL` in the Homepage config.

## Continue

- [Homepage (Dashboard)](Homepage%20%28Dashboard%29.md)
- [What is Horto OS?](What%20is%20Horto%20OS%3F.md)
