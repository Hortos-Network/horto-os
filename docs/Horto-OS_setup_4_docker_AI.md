# Horto-OS setup 4 – Docker AI

**Summary**: This guide covers the AI-related Docker services for Horto-OS, including LLM, STT, TTS, and vision-related stacks.

---

## Overview

Horto-OS can run several AI-related services on RK3588 boards.
These are normally managed as Docker stacks, typically through Dockge.

The exact services you can run depend strongly on available RAM, storage, and NPU support.

> [!NOTE]
> On RK3588 systems with 8 GB RAM, the realistic model selection is limited. The smaller DeepSeek/Qwen-class models are the practical starting point.

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

## YOLO (vision)

```yaml
services:
  yolo-detection:
    image: ghcr.io/seeed-projects/recomputer-rk-cv/rk3588-yolo11:latest
    container_name: rk3588-yolo11n
    restart: unless-stopped
    privileged: true
    network_mode: host
    devices:
      - /dev/video1:/dev/video1
      - /dev/dri/renderD129:/dev/dri/renderD129
      - /dev/dri:/dev/dri
      - /dev/dma_heap:/dev/dma_heap
      - /dev/rknpu:/dev/rknpu
      - /dev/mali0:/dev/mali0
    environment:
      - PYTHONUNBUFFERED=1
      - RKNN_LOG_LEVEL=0
    volumes:
      - /proc/device-tree/compatible:/proc/device-tree/compatible:ro
    command: python web_detection.py --model_path model/yolo11n.rknn --video video/test.mp4
```

## rkvoice-stream / openvoicestream (TTS)

For `rkvoice-stream`, the usual path is to create a Dockge stack and then copy the required build context into that stack directory.

Typical compose definition:

```yaml
services:
  rkvoice-stream:
    build:
      context: .
      dockerfile: docker/Dockerfile
    image: rkvoice-stream
    container_name: rkvoice-stream
    restart: unless-stopped
    privileged: true
    network_mode: host
    devices:
      - /dev/dri:/dev/dri
      - /dev/dma_heap:/dev/dma_heap
      - /dev/rknpu:/dev/rknpu
      - /dev/mali0:/dev/mali0
```

Git clone the repository into the docker_repos directory:

```bash
cd /srv/docker/docker_repos/
git clone --recurse-submodule https://github.com/suharvest/rkvoice-stream.git
```

### Copy Required Project Files to the Stack Directory

The Dockerfile for rkvoice-stream expects certain files and directories to be present in the build context (the stack's root directory). You need to manually copy these from the cloned repository (/srv/docker/docker_repos//rkvoice-stream) into your Dockge stack directory (/srv/docker/stacks/rkvoice-stream/).

Navigate to your Dockge stack directory:

```bash
cd /srv/docker/stacks/rkvoice-stream/
```

Then, copy the following folders and the pyproject.toml file:

```bash
cp -r ~/rkvoice-stream/baseline .
cp -r ~/rkvoice-stream/configs .
cp -r ~/rkvoice-stream/docker .
cp -r ~/rkvoice-stream/models .
cp -r ~/rkvoice-stream/rkvoice_stream .
cp ~/rkvoice-stream/pyproject.toml .
```

After these commands, your /srv/docker/stacks/rkvoice-stream/ directory should contain:

```tree
compose.yaml
baseline/
configs/
docker/ (containing Dockerfile)
models/
rkvoice_stream/
pyproject.toml
```

### Deploy the Stack in Dockge

Go back to the Dockge web UI for your rkvoice-stream stack. Click the "Deploy"
or "Update" button. Dockge will now:

Find the Dockerfile in the docker/ subdirectory.
Locate all the necessary files (pyproject.toml, rkvoice_stream/, etc.) in the build context.
Build the rkvoice-stream Docker image.
Start the rkvoice-stream container.
Access the rkvoice-stream Service:
Once the container is running, rkvoice-stream will be accessible directly on
your NanoPi's IP address. The service typically runs on port 8621.

You can access it from any device on your network by navigating to:

http://"MY_HOST_IP":8621

Note: Because network_mode: host is used in the Docker Compose file, the container
shares the host's network. This means no explicit port mapping (ports:) is
required in the compose.yaml file, as the container's internal port 8621 is
directly exposed on the host's port 8621.


## Testing

Example local API test for the LLM endpoint:

```bash
curl http://192.168.10.1:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "DeepSeek-R1-Qwen-1.7B_w8a8_RK3588.rkllm",
    "messages": [{"role": "user", "content": "Do you know about Holochain, p2p app framework ?"}]
  }'
```

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
