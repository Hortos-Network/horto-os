Horto OS is a decentralised, privacy-focused operating system designed for **Home Hubs** (the **Horto Box**). 

Topology of the full stack:
![Horto OS topology](../_assets/infographic_topology_horto-os.avif)


> [!NOTE]
> This description of the project aims to inform about what we intend to develop for Horto-OS and not the current state. 

## What is Horto OS?

Horto OS is built upon a fork of the technical substrate provided by
[Coasys](https://coasys.org/), aiming to resolve the fundamental tension between
coherence and sovereignty in networked systems.

At its core, Horto OS runs on Armbian and integrates applications through a unique architecture:

- **NEXUS Stack**: A fork of the Adam Layer, acting as a "Semantic Orchestrator" to create a local semantic web and integrate APIs and AI.
- **Holochain**: An open-source framework for building distributed applications (hApps), enabling agent-centric data integrity and peer-to-peer interactions.
- **Docker Apps**: Standard containerized services like evcc, Frigate, and Horto EM Community.

The **Horto Box** functions as the physical "Brain" of the home, organized into four functional layers:

1.  **Physical & Networking**: Establishes secure communication using Iroh for
peer-to-peer addressing and an integrated LAN router, called Horto IOT Router.
2.  **Platform & Middleware**: The runtime environment based on Nix and Rust,
managing distributed integrity via Holochain and Horto Nexus.
3.  **Application Framework**: Utilizes Docker (often on top of Nix) to run
containerised services like evcc, Horto EM Community (energy management),
and Frigate (security).
4.  **Intelligence & Analytics**: Enables local execution of Small Language
Models (SLMs) (up to 7B parameters, such as DeepSeek or Qwen) for predictive analytics and autonomous behaviour.

**Horto OS also incorporates:**

- **Horto Micro-Payment (Unyt)**: A Holochain-based accounting infrastructure
for micro-payments and billing, supporting multiple currencies like Euro and KWh renewable energy.
- **Synergy**: A unique value-flow mechanism functioning as a holonic reputation
currency system, utilizing a Proof-of-Integration mechanism for tailored reputation engines and tokenized incentives.
- **Technical Reliability**: A hybrid Nix + Docker approach ensures the system
is "unbrickable" with atomic, content-addressed system rollbacks and service isolation.

**Application Framework**:

The core of the Horto-OS stack is focused on deploying a managed service for Home Energy Management (HEMS). As an open operating system, it is also capable of running a variety of Smart Home and Home Server applications. We do not intend to launch all such additional products ourselves.

For instance, you can install Home Assistant or Frigate NVR, but keep in mind that these more resource-hungry applications are constrained by available memory.

In short, this comprehensive framework focuses on **enclosed, stable environments** that prioritize user autonomy and connectivity, while allowing the integration of third-party containerized apps and community-driven Holochain applications.

## Contributing

We welcome contributions to Horto OS! Please refer to the `docs/` folder for
guidelines on how to contribute, report issues, or suggest enhancements.
