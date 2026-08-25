# Wyoming Protocol

A peer-to-peer TCP protocol for voice assistants (basically JSONL + PCM audio)

Used in Home Assistant for communication with voice services.

ref: [Wyoming Protocol](https://github.com/OHF-Voice/wyoming.git) (AI Voice Pipeline)

## Why Home Assistant Prefers Wyoming over an OpenAI API for Local Models

Even if your local container hosted an OpenAI-compatible API endpoint 
(like `/v1/audio/transcriptions`), Home Assistant would have to constantly open HTTP connections, dump complete audio files, and parse JSON responses.

Using Wyoming gives you:

- **Lower Latency:** Because it streams over a persistent TCP socket using lightweight binary protocol
  events, there's zero HTTP header overhead.

- **Native Integration:** Home Assistant's _Assist_ pipeline was architected
  natively around Wyoming. Satellites (like ESPHome voice assistants) stream
  audio straight to Wyoming servers without needing an intermediate transcoding step.

## Work in Progress

The Wyoming protocol implementation is currently a work in progress.
The most recent version you find in the [Horto-OS dev_wyoming branch](https://github.com/Hortos-Network/horto-os/tree/dev_wyoming) repository.

## Acknowledgments

To get wyoming compatible API's in to Horto-OS we the libraries from:

- Wyoming for RK3576 [Github repo of Hanzo-Huang](https://github.com/Hanzo-Huang/rk3576-home-assistant-voice.git)
- [Wyoming Protocol](https://github.com/OHF-Voice/wyoming.git) (AI Voice Pipeline)
