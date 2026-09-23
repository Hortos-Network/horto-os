# What is Horto OS?

Horto OS is a decentralised, privacy-focused operating system designed for **HORTEX nodes** or **Home Hubs** (the **Horto Box**).

Topology of the full stack: ![Horto OS topology](../_assets/Infographic_topology_horto-os.avif)

> \[!NOTE\] This description of the project aims to inform about what we intend to develop for Horto-OS and not the current state.

## What is Horto OS?

Horto OS is built upon a fork of the technical substrate provided by [Coasys](https://coasys.org/), aiming to resolve the fundamental tension between coherence and sovereignty in networked systems.

At its core, Horto OS runs on DebianArmbian and integrates applications through a unique architecture:

- **NEXUS Framework**: The core energy device automation and monitoring happen within NEXUS.

- **Adam Layer**: The Adam Layer from [Coasys](https://coasys.org/), acting as a "Semantic Orchestrator" to create a local semantic web and integrate APIs and AI.

- **Holochain**: An open-source framework for building distributed applications (hApps), enabling agent-centric data integrity and peer-to-peer interactions.

- **Unyt**: A multi-tier value/currency and payment rail framework (Holochain based).

## Deployment Profiles

### Home Hub (HEMS)

The **Horto Box** functions as the physical "Brain" of the home, organized into four functional layers:

1. **Physical & Networking**: Establishes secure communication using Iroh for peer-to-peer addressing and an integrated LAN router, called Horto IOT Router.

2. **Platform & Middleware**: The runtime environment based on Nix and Rust, managing distributed integrity via Holochain Adam Layer and NEXUS (energy management)

3. **Application Framework**: Utilizes Docker (often on top of Nix) to run containerised AI models and services like Frigate (security)

4. **Intelligence & Analytics**: Enables local execution of Small Language Models (SLMs) (up to 7B parameters, such as DeepSeek or Qwen) for predictive analytics and autonomous behaviour.

**Application Framework (HEMS deployment)**:

The core of the Horto-OS Home stack is focused on deploying a managed service for Home Energy Management (HEMS). As an open operating system, it is also capable of running a variety of Smart Home and Home Server applications. We do not intend to launch all such additional products ourselves.

For instance, you can install Home Assistant or Frigate NVR, but keep in mind that these more resource-hungry applications are constrained by available memory.

In short, this comprehensive framework focuses on **enclosed, stable environments** that prioritize user autonomy and connectivity, while allowing the integration of third-party containerized apps and community-driven Holochain applications.


### Core and Sat nodes (HORTEX)

HORTEX is our future sovereign, hardware-agnostic, open-source peer-to-peer (P2P) energy management and accounting infrastructure. Rather than treating microgrids or residential home energy management as centralized utility projects,HORTEX treats every individual household, commercial building, or industrial facility as an autonomous microgrid node.
